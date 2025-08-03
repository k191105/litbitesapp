import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StreakService {
  static const String _currentWeekKey = 'current_week_data';
  static const String _totalStreakKey = 'total_streak_count';
  static const String _weekStartDayKey = 'week_start_day';

  // Get the current week's start date (from when user first started this week)
  Future<DateTime> _getCurrentWeekStart() async {
    final prefs = await SharedPreferences.getInstance();
    final weekStartString = prefs.getString(_weekStartDayKey);

    if (weekStartString != null) {
      final weekStart = DateTime.parse(weekStartString);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // If it's been more than 7 days, start a new week
      if (today.difference(weekStart).inDays >= 7) {
        await prefs.setString(_weekStartDayKey, today.toIso8601String());
        await prefs.remove(_currentWeekKey); // Clear current week data
        return today;
      }

      return weekStart;
    } else {
      // First time - start week today
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      await prefs.setString(_weekStartDayKey, today.toIso8601String());
      return today;
    }
  }

  Future<Map<String, dynamic>> getCurrentWeekData() async {
    final prefs = await SharedPreferences.getInstance();
    final weeklyJson = prefs.getString(_currentWeekKey);

    if (weeklyJson != null) {
      return json.decode(weeklyJson) as Map<String, dynamic>;
    }

    return {};
  }

  Future<void> saveCurrentWeekData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentWeekKey, json.encode(data));
  }

  Future<int> getTotalStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalStreakKey) ?? 0;
  }

  Future<void> saveTotalStreak(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_totalStreakKey, count);
  }

  Future<Map<String, dynamic>> recordAppLaunch() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayKey = today.toIso8601String().split('T')[0];

    final currentWeekData = await getCurrentWeekData();

    // Check if already engaged today
    if (currentWeekData[todayKey] == true) {
      return {
        'isNewEngagement': false,
        'weeklyView': await getWeeklyView(),
        'currentStreak': await getCurrentWeekStreak(),
        'totalStreak': await getTotalStreak(),
        'milestone': null,
      };
    }

    // Record today's engagement
    currentWeekData[todayKey] = true;
    await saveCurrentWeekData(currentWeekData);

    // Update total streak
    final totalStreak = await getTotalStreak();
    await saveTotalStreak(totalStreak + 1);
    final newTotalStreak = totalStreak + 1;

    // Calculate current week streak
    final currentWeekStreak = await getCurrentWeekStreak();

    // Check for simple milestones (perfect week = 7, perfect month = 30)
    String? milestone;
    if (currentWeekStreak == 7) {
      milestone = 'confetti'; // Perfect week
    } else if (newTotalStreak == 30) {
      milestone = 'confetti'; // Perfect month
    }

    debugPrint('📱 App launch recorded for $todayKey');
    debugPrint('📊 Current week streak: $currentWeekStreak');
    debugPrint('🎯 Total streak: $newTotalStreak');
    if (milestone != null) {
      debugPrint('🎉 Milestone reached: $milestone');
    }

    return {
      'isNewEngagement': true,
      'weeklyView': await getWeeklyView(),
      'currentStreak': currentWeekStreak,
      'totalStreak': newTotalStreak,
      'milestone': milestone,
      'isNewStreak': currentWeekStreak == 1,
    };
  }

  Future<int> getCurrentWeekStreak() async {
    final currentWeekData = await getCurrentWeekData();
    return currentWeekData.values
        .where((completed) => completed == true)
        .length;
  }

  Future<List<Map<String, dynamic>>> getWeeklyView() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = await _getCurrentWeekStart();
    final currentWeekData = await getCurrentWeekData();

    List<Map<String, dynamic>> weekView = [];

    // Create day names starting from the week start day
    final weekStartDayOfWeek = weekStart.weekday; // 1=Monday, 7=Sunday
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (int i = 0; i < 7; i++) {
      final dayDate = weekStart.add(Duration(days: i));
      final dayKey = dayDate.toIso8601String().split('T')[0];
      final isCompleted = currentWeekData[dayKey] == true;
      final isToday =
          dayDate.day == today.day &&
          dayDate.month == today.month &&
          dayDate.year == today.year;

      // Get the correct day name (cycle through dayNames starting from weekStartDayOfWeek)
      final dayNameIndex = (weekStartDayOfWeek - 1 + i) % 7;

      weekView.add({
        'day': dayNames[dayNameIndex],
        'date': dayDate,
        'isCompleted': isCompleted,
        'isToday': isToday,
      });
    }

    return weekView;
  }

  Future<String> getStreakMessage(int currentStreak, bool isNewStreak) async {
    if (isNewStreak) {
      return 'New Streak Started';
    } else if (currentStreak == 1) {
      return '1 Day Streak!';
    } else {
      return '$currentStreak Day Streak!';
    }
  }

  Future<bool> shouldSendReminder() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayKey = today.toIso8601String().split('T')[0];

    final currentWeekData = await getCurrentWeekData();

    // Return true if user hasn't engaged today
    return currentWeekData[todayKey] != true;
  }

  Future<void> markReminderSent() async {
    // For the new system, we don't need to track reminder sent separately
    // The shouldSendReminder method checks engagement directly
  }
}
