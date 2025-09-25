import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:quotes_app/quote.dart';
import 'package:quotes_app/models/notification_prefs.dart';
import 'package:quotes_app/models/period_catalog.dart';
import 'package:quotes_app/services/analytics.dart';
import 'package:quotes_app/services/time_provider.dart';

// TODO: TimeProvider refactor - DateTime.now() calls replaced with timeProvider.now()

class NotificationService {
  /// Get current time from context for widget use
  static DateTime nowFromContext(BuildContext context) {
    return context.now;
  }

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // ID namespace for our notifications to avoid conflicts
  static const int _baseNotificationId = 1000;
  static const String _prefsKey = 'notif_prefs_v1';
  static const String _recentKey = 'recent_quotes_v1';

  /// Initialize timezones - must be called before any scheduling
  static void initTimezones() {
    tz.initializeTimeZones();
  }

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    final details = await _notificationsPlugin
        .getNotificationAppLaunchDetails();
    _initialPayload = details?.notificationResponse?.payload;

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
  }

  static String? _initialPayload;

  /// Should be called once after runApp to process notification that launched the app
  static void handleInitialNotification() {
    if (_initialPayload != null) {
      navigatorKey.currentState?.pushNamed(
        '/quote',
        arguments: _initialPayload,
      );
      _initialPayload = null; // Clear to avoid duplicate navigation
    }
  }

  static void onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse,
  ) async {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      debugPrint('notification payload: $payload');
      navigatorKey.currentState?.pushNamed('/quote', arguments: payload);
    }
  }

  /// Load notification preferences from SharedPreferences
  static Future<NotificationPrefs> loadNotificationPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final prefsJson = prefs.getString(_prefsKey);

    if (prefsJson == null) {
      // Migration: create default preferences
      final defaultPrefs = NotificationPrefs.defaultFree();
      await saveNotificationPrefs(defaultPrefs);
      return defaultPrefs;
    }

    try {
      final map = json.decode(prefsJson) as Map<String, dynamic>;
      return NotificationPrefs.fromJson(map);
    } catch (e) {
      debugPrint('Error loading notification prefs: $e');
      // Return default and save it
      final defaultPrefs = NotificationPrefs.defaultFree();
      await saveNotificationPrefs(defaultPrefs);
      return defaultPrefs;
    }
  }

  /// Save notification preferences to SharedPreferences
  static Future<void> saveNotificationPrefs(NotificationPrefs prefs) async {
    final sp = await SharedPreferences.getInstance();
    final prefsJson = json.encode(prefs.toJson());
    await sp.setString(_prefsKey, prefsJson);
  }

  /// Request notification permissions if needed
  static Future<bool> requestPermissionsIfNeeded() async {
    final androidPermission = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    final iosPermission = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    return (androidPermission ?? true) && (iosPermission ?? true);
  }

  /// Sync notifications with preferences - main entry point for prefs-based scheduling
  static Future<void> syncWithPrefs(
    NotificationPrefs prefs,
    DateTime now, {
    List<Quote>? feed,
    List<Quote>? favoriteQuotes,
  }) async {
    debugPrint('📱 Syncing notifications with preferences...');

    // Check permissions first
    final hasPermission = await requestPermissionsIfNeeded();
    if (!hasPermission) {
      debugPrint('❌ Notification permissions denied');
      return;
    }

    // Cancel all our previous notifications (preserve streak notifications)
    await _cancelOurNotifications();

    if (prefs.times.isEmpty) {
      debugPrint('📱 No notification times configured');
      return;
    }

    // Schedule notifications for the next 7 days
    int totalScheduled = 0;
    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      final targetDate = now.add(Duration(days: dayOffset));
      final weekday = targetDate.weekday; // 1=Monday, 7=Sunday

      if (!prefs.isActiveOnWeekday(weekday)) {
        continue; // Skip this day
      }

      // Enforce per-day cap
      int dailyScheduled = 0;
      final sortedTimes = _sortTimes(prefs.times);

      for (final time in sortedTimes) {
        final scheduledTime = _createScheduledTime(targetDate, time);

        // Skip if the time has already passed today
        if (scheduledTime.isBefore(now)) {
          continue;
        }

        final quote = await pickQuoteForSlot(
          scheduledTime,
          prefs,
          feed: feed ?? [],
          favoriteQuotes: favoriteQuotes ?? [],
        );

        if (quote != null) {
          final notificationId = _baseNotificationId + totalScheduled;
          await _scheduleNotification(
            notificationId,
            _getTitleForTime(time),
            quote.text,
            quote.id,
            scheduledTime,
          );

          totalScheduled++;
          dailyScheduled++;

          // Respect daily cap - break if we've reached the limit for this day
          if (dailyScheduled >= prefs.dailyCap) {
            break;
          }
        }
      }
    }

    debugPrint('🎯 Scheduled $totalScheduled notifications over 7 days');

    // Log analytics
    Analytics.instance.logEvent(Analytics.notifScheduledTotal, {
      'count_7d': totalScheduled,
    });

    // Save the scheduling time for future reference
    final sp = await SharedPreferences.getInstance();
    await sp.setInt('last_sync_timestamp', now.millisecondsSinceEpoch);
  }

  /// Pick a quote for a specific notification slot
  static Future<Quote?> pickQuoteForSlot(
    DateTime when,
    NotificationPrefs prefs, {
    required List<Quote> feed,
    required List<Quote> favoriteQuotes,
  }) async {
    // Get available quotes based on filters
    List<Quote> candidates = _filterQuotesByPrefs(feed, prefs);

    if (candidates.isEmpty) {
      // Fall back to personalized feed (existing logic)
      final favoriteIds = favoriteQuotes.map((q) => q.id).toSet();
      candidates = feed.where((q) => !favoriteIds.contains(q.id)).toList();
    }

    if (candidates.isEmpty) {
      // Last resort: use any quote from feed
      candidates = feed;
    }

    if (candidates.isEmpty) {
      return null;
    }

    // Avoid recent quotes
    final recentIds = await _getRecentQuoteIds();
    final nonRecentCandidates = candidates
        .where((q) => !recentIds.contains(q.id))
        .toList();

    final selectedCandidates = nonRecentCandidates.isNotEmpty
        ? nonRecentCandidates
        : candidates;

    if (selectedCandidates.isEmpty) {
      return null;
    }

    // Use deterministic selection based on time to avoid duplicate quotes at same time
    final seed =
        when.millisecondsSinceEpoch ~/ (1000 * 60 * 60); // Hour-based seed
    final random = Random(seed);
    final selectedQuote =
        selectedCandidates[random.nextInt(selectedCandidates.length)];

    // Remember this quote
    await _addToRecentQuoteIds(selectedQuote.id, prefs.lookbackDays);

    return selectedQuote;
  }

  /// Filter quotes by preferences
  static List<Quote> _filterQuotesByPrefs(
    List<Quote> quotes,
    NotificationPrefs prefs,
  ) {
    List<Quote> filtered = quotes;

    // Filter by authors
    if (prefs.authors.isNotEmpty) {
      filtered = filtered
          .where((q) => prefs.authors.contains(q.authorName))
          .toList();
    }

    // Filter by tags
    if (prefs.tags.isNotEmpty) {
      filtered = filtered
          .where((q) => q.tags.any((tag) => prefs.tags.contains(tag)))
          .toList();
    }

    // Filter by period
    if (prefs.startYear != null && prefs.endYear != null) {
      filtered = PeriodCatalog.getQuotesForRange(
        filtered,
        prefs.startYear!,
        prefs.endYear!,
      );
    }

    return filtered;
  }

  /// Cancel our notifications (preserve streak notifications)
  static Future<void> _cancelOurNotifications() async {
    // Cancel notifications in our ID range
    for (int i = _baseNotificationId; i < _baseNotificationId + 1000; i++) {
      await _notificationsPlugin.cancel(i);
    }
  }

  /// Get title for notification based on time
  static String _getTitleForTime(TimeOfDay time) {
    if (time.hour < 12) {
      return 'Morning Quote';
    } else if (time.hour < 17) {
      return 'Afternoon Reflection';
    } else {
      return 'Evening Thought';
    }
  }

  /// Create a TZDateTime for a specific date and time
  static tz.TZDateTime _createScheduledTime(DateTime date, TimeOfDay time) {
    return tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  /// Sort times by total minutes to ensure correct ordering
  static List<TimeOfDay> _sortTimes(List<TimeOfDay> times) {
    return List<TimeOfDay>.from(times)..sort(
      (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
    );
  }

  /// Get recent quote IDs to avoid repetition
  static Future<Set<String>> _getRecentQuoteIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentJson = prefs.getString(_recentKey);

      if (recentJson == null) {
        return {};
      }

      final List<dynamic> recentList = json.decode(recentJson);
      final recentQuotes = recentList.cast<Map<String, dynamic>>();

      // Filter out old entries
      final now = timeProvider.now().millisecondsSinceEpoch;
      final recentIds = <String>{};

      for (final entry in recentQuotes) {
        final timestamp = entry['timestamp'] as int;
        final quoteId = entry['quoteId'] as String;

        // Keep entries within lookback period
        if (now - timestamp < const Duration(days: 14).inMilliseconds) {
          recentIds.add(quoteId);
        }
      }

      return recentIds;
    } catch (e) {
      debugPrint('Error loading recent quotes: $e');
      return {};
    }
  }

  /// Add quote ID to recent list with timestamp
  static Future<void> _addToRecentQuoteIds(
    String quoteId,
    int lookbackDays,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentJson = prefs.getString(_recentKey);
      final now = timeProvider.now().millisecondsSinceEpoch;

      List<Map<String, dynamic>> recentList = [];
      if (recentJson != null) {
        recentList = (json.decode(recentJson) as List)
            .cast<Map<String, dynamic>>();
      }

      // Add new entry
      recentList.add({'quoteId': quoteId, 'timestamp': now});

      // Keep only recent entries
      final cutoff = now - Duration(days: lookbackDays).inMilliseconds;
      recentList = recentList
          .where((entry) => entry['timestamp'] > cutoff)
          .toList();

      // Limit to reasonable size to prevent storage bloat
      if (recentList.length > 100) {
        recentList = recentList.sublist(recentList.length - 100);
      }

      await prefs.setString(_recentKey, json.encode(recentList));
    } catch (e) {
      debugPrint('Error saving recent quote: $e');
    }
  }

  /// Legacy method - now delegates to prefs-based system
  static Future<void> scheduleForToday({
    required List<Quote> feed,
    required List<Quote> favoriteQuotes,
    required DateTime now,
  }) async {
    // Load preferences and use the new system
    final prefs = await loadNotificationPrefs();
    await syncWithPrefs(prefs, now, feed: feed, favoriteQuotes: favoriteQuotes);
  }

  /// Clear all recent quotes data (for testing/debugging)
  static Future<void> clearRecentQuotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentKey);
    } catch (e) {
      debugPrint('Error clearing recent quotes: $e');
    }
  }

  static Future<void> _scheduleNotification(
    int id,
    String title,
    String body,
    String payload,
    tz.TZDateTime scheduledTime,
  ) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_quotes_channel',
          'Daily Quotes',
          channelDescription: 'Channel for daily quote notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }
}
