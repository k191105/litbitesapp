import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart'; // For addPostFrameCallback
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:quotes_app/quote.dart';
import 'package:quotes_app/models/notification_prefs.dart';
import 'package:quotes_app/models/period_catalog.dart';
import 'package:quotes_app/services/analytics.dart';
import 'streak_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // ID namespace for our notifications to avoid conflicts
  static const int _baseNotificationId = 1000;
  static const int _streakNotificationId = 999;
  static const String _prefsKey = 'notif_prefs_v1';

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
    int notificationCount = 0;
    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      final targetDate = now.add(Duration(days: dayOffset));
      final weekday = targetDate.weekday; // 1=Monday, 7=Sunday

      if (!prefs.isActiveOnWeekday(weekday)) {
        continue; // Skip this day
      }

      for (final time in prefs.times) {
        final scheduledTime = _createScheduledTime(targetDate, time);

        // Skip if the time has already passed today
        if (scheduledTime.isBefore(now)) {
          continue;
        }

        final quote = pickQuoteForSlot(
          scheduledTime,
          prefs,
          feed: feed ?? [],
          favoriteQuotes: favoriteQuotes ?? [],
        );

        if (quote != null) {
          final notificationId = _baseNotificationId + notificationCount;
          await _scheduleNotification(
            notificationId,
            _getTitleForTime(time),
            quote.text,
            quote.id,
            scheduledTime,
          );

          notificationCount++;

          // Respect daily cap
          if (notificationCount >= prefs.dailyCap * 7) {
            break;
          }
        }
      }
    }

    debugPrint('🎯 Scheduled $notificationCount notifications over 7 days');

    // Log analytics
    Analytics.instance.logEvent(Analytics.notifScheduledTotal, {
      'count_7d': notificationCount,
    });

    // Schedule streak reminder if needed
    await _scheduleStreakReminderIfNeeded();

    // Save the scheduling time for future reference
    final sp = await SharedPreferences.getInstance();
    await sp.setInt('last_sync_timestamp', now.millisecondsSinceEpoch);
  }

  /// Pick a quote for a specific notification slot
  static Quote? pickQuoteForSlot(
    DateTime when,
    NotificationPrefs prefs, {
    required List<Quote> feed,
    required List<Quote> favoriteQuotes,
  }) {
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
    final recentIds = _getRecentQuoteIds();
    final nonRecentCandidates = candidates
        .where((q) => !recentIds.contains(q.id))
        .toList();

    final selectedCandidates = nonRecentCandidates.isNotEmpty
        ? nonRecentCandidates
        : candidates;

    // Use deterministic selection based on time to avoid duplicate quotes at same time
    final seed =
        when.millisecondsSinceEpoch ~/ (1000 * 60 * 60); // Hour-based seed
    final random = Random(seed);
    final selectedQuote =
        selectedCandidates[random.nextInt(selectedCandidates.length)];

    // Remember this quote
    _addToRecentQuoteIds(selectedQuote.id, prefs.lookbackDays);

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

  /// Get recent quote IDs to avoid repetition
  static Set<String> _getRecentQuoteIds() {
    // This would ideally be async, but for simplicity we'll use a synchronous approach
    // In production, you might want to cache this in memory
    return {}; // Simplified for now
  }

  /// Add quote ID to recent list
  static void _addToRecentQuoteIds(String quoteId, int lookbackDays) {
    // Simplified for now - in production, maintain a ring buffer in SharedPreferences
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

  static Future<void> _scheduleStreakReminderIfNeeded() async {
    final streakService = StreakService.instance;
    final data = await streakService.loadData(); // A method to expose the data
    final today = streakService
        .getTodayLocal(); // A method to get today's date string
    final lastEngagementDate = data['last_engagement_local_date'];

    if (lastEngagementDate != today) {
      final reminderTime = _nextInstanceOfTime(DateTime.now(), 20); // 8 PM

      debugPrint('⏰ Scheduling streak reminder for: $reminderTime');

      await _scheduleNotification(
        _streakNotificationId, // Use a special ID for streak reminders
        'Don\'t Break Your Streak!',
        'Keep your reading streak alive with today\'s quote',
        'streak_reminder',
        reminderTime,
      );
    }
  }

  static tz.TZDateTime _nextInstanceOfTime(DateTime now, int hour) {
    final tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
    );
    return scheduledDate.isBefore(now)
        ? scheduledDate.add(const Duration(days: 1))
        : scheduledDate;
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
