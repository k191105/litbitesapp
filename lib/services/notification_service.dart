import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:quotes_app/quote.dart';
import 'streak_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
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

  static Future<void> scheduleForToday({
    required List<Quote> feed,
    required List<Quote> favoriteQuotes,
    required DateTime now,
  }) async {
    debugPrint('📱 Starting notification scheduling...');
    await _notificationsPlugin.cancelAll();

    final favoriteIds = favoriteQuotes.map((q) => q.id).toSet();
    final unfavorited = feed.where((q) => !favoriteIds.contains(q.id)).toList();

    if (unfavorited.isEmpty) {
      debugPrint('❌ No unfavorited quotes available for notifications');
      return;
    }

    debugPrint('✅ Found ${unfavorited.length} unfavorited quotes');

    final morningQuote = unfavorited[0];
    final eveningQuote = unfavorited.length > 1
        ? unfavorited[1]
        : unfavorited[Random().nextInt(unfavorited.length)];

    final morningTime = _nextInstanceOfTime(now, 8);
    final eveningTime = _nextInstanceOfTime(now, 18);

    debugPrint('⏰ Scheduling morning notification for: $morningTime');
    debugPrint('⏰ Scheduling evening notification for: $eveningTime');

    await _scheduleNotification(
      0,
      'Today\'s Quote',
      morningQuote.text,
      morningQuote.id,
      morningTime,
    );

    await _scheduleNotification(
      1,
      'Something to think about',
      eveningQuote.text,
      eveningQuote.id,
      eveningTime,
    );

    debugPrint('🎯 Notifications scheduled successfully!');

    // Schedule streak reminder for 8PM if needed
    await _scheduleStreakReminderIfNeeded();
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
        999, // Use a special ID for streak reminders
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
