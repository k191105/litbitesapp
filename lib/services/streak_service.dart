import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quotes_app/services/analytics.dart';
import 'package:quotes_app/services/entitlements_service.dart';

class StreakService {
  static final StreakService instance = StreakService._();
  StreakService._();

  // Persistence Keys
  static const _lastEngagementDateKey = 'last_engagement_local_date';
  static const _streakCountKey = 'streak_count';
  static const _milestonesShownKey = 'milestones_shown';
  static const _weeklyViewKey =
      'weekly_view'; // Stores list of local date strings "YYYY-MM-DD"

  // Milestone definitions
  static const _milestoneDays = [3, 7, 14, 21, 30];
  static const _repeatingMilestoneInterval = 7;

  // Feature pass mapping
  static const _milestoneRewards = {
    7: ['search'],
    14: ['browse_period'], // Removed browse_tags as it's now free
    21: ['premium_themes'],
    30: ['premium_fonts'],
  };

  String getTodayLocal() {
    final now = DateTime.now();
    return DateFormat('yyyy-MM-dd').format(now);
  }

  Future<Map<String, dynamic>> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final weeklyViewJson = prefs.getString(_weeklyViewKey);
    final milestonesJson = prefs.getString(_milestonesShownKey);

    return {
      _lastEngagementDateKey: prefs.getString(_lastEngagementDateKey),
      _streakCountKey: prefs.getInt(_streakCountKey) ?? 0,
      _milestonesShownKey: (milestonesJson != null)
          ? (json.decode(milestonesJson) as List).cast<int>()
          : <int>[],
      _weeklyViewKey: (weeklyViewJson != null)
          ? (json.decode(weeklyViewJson) as List).cast<String>()
          : <String>[],
    };
  }

  Future<void> _saveData({
    String? lastEngagementDate,
    int? streakCount,
    List<int>? milestonesShown,
    List<String>? weeklyView,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (lastEngagementDate != null) {
      await prefs.setString(_lastEngagementDateKey, lastEngagementDate);
    }
    if (streakCount != null) {
      await prefs.setInt(_streakCountKey, streakCount);
    }
    if (milestonesShown != null) {
      await prefs.setString(_milestonesShownKey, json.encode(milestonesShown));
    }
    if (weeklyView != null) {
      await prefs.setString(_weeklyViewKey, json.encode(weeklyView));
    }
  }

  Future<Map<String, dynamic>> recordAppLaunch() async {
    final today = getTodayLocal();
    final data = await loadData();

    String? lastEngagementDate = data[_lastEngagementDateKey];
    int streakCount = data[_streakCountKey];
    List<int> milestonesShown = data[_milestonesShownKey];
    List<String> weeklyView = data[_weeklyViewKey];

    if (lastEngagementDate == today) {
      // Already engaged today, do nothing.
      return {'isNewEngagement': false, 'weeklyView': await getWeeklyView()};
    }

    final yesterday = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now().subtract(const Duration(days: 1)));
    int previousStreak = streakCount;

    if (lastEngagementDate == yesterday) {
      // Consecutive day, increment streak.
      streakCount++;
    } else {
      // Not consecutive, reset streak.
      streakCount = 1;
      weeklyView.clear();
    }

    await Analytics.instance.logEvent('streak.increment', {
      'from': previousStreak,
      'to': streakCount,
    });

    // Update weekly view
    weeklyView.add(today);
    if (weeklyView.length > 7) {
      weeklyView = weeklyView.sublist(weeklyView.length - 7);
    }

    // Check for new milestones
    int? newMilestone;
    List<String> awardedFeatureKeys = [];

    int milestoneCandidate = _getMilestoneForStreak(streakCount);
    if (milestoneCandidate > 0 &&
        !milestonesShown.contains(milestoneCandidate)) {
      newMilestone = milestoneCandidate;
      milestonesShown.add(newMilestone);
      await Analytics.instance.logEvent('streak.milestone_shown', {
        'n': newMilestone,
      });

      // Grant feature passes
      final features = _getFeaturesForMilestone(newMilestone);
      if (features.isNotEmpty) {
        awardedFeatureKeys.addAll(features);
        for (var featureKey in features) {
          await EntitlementsService.instance.grantFeaturePass(
            featureKey,
            const Duration(days: 7),
            source: 'streak_$newMilestone',
          );
        }
      }
    }

    await _saveData(
      lastEngagementDate: today,
      streakCount: streakCount,
      milestonesShown: milestonesShown,
      weeklyView: weeklyView,
    );

    return {
      'isNewEngagement': true,
      'streakCount': streakCount,
      'milestone': newMilestone,
      'celebrationType': _getAnimationForMilestone(newMilestone),
      'awardedFeatureKeys': awardedFeatureKeys,
      'weeklyView': await getWeeklyView(),
    };
  }

  int _getMilestoneForStreak(int streak) {
    if (_milestoneDays.contains(streak)) {
      return streak;
    }
    if (streak > _milestoneDays.last &&
        (streak - _milestoneDays.last) % _repeatingMilestoneInterval == 0) {
      return streak;
    }
    return 0;
  }

  String? _getAnimationForMilestone(int? milestone) {
    if (milestone == null) return null;
    if (milestone == 3) return 'confetti';
    if (_milestoneDays.contains(milestone) || milestone > _milestoneDays.last)
      return 'fireworks';
    return null;
  }

  List<String> _getFeaturesForMilestone(int milestone) {
    int key = milestone;
    if (!_milestoneRewards.containsKey(key)) {
      // Handle repeating milestones (e.g., 37, 44, ...)
      if (key > 30) {
        int cycleIndex = ((key - 31) ~/ 7) % _milestoneRewards.length;
        key = _milestoneRewards.keys.elementAt(cycleIndex);
      }
    }
    return _milestoneRewards[key] ?? [];
  }

  Future<int> getStreakCount() async {
    final data = await loadData();
    return data[_streakCountKey];
  }

  Future<List<Map<String, dynamic>>> getWeeklyView() async {
    final data = await loadData();
    final List<String> engagementDates = data[_weeklyViewKey];
    if (engagementDates.isEmpty) return [];

    final today = getTodayLocal();
    final dayFormatter = DateFormat.E();
    final dateFormatter = DateFormat('yyyy-MM-dd');

    // Determine the start date of the current streak segment to display.
    // This will be the last 7 days of the streak.
    final List<String> displayDates = engagementDates.length > 7
        ? engagementDates.sublist(engagementDates.length - 7)
        : engagementDates;

    final List<Map<String, dynamic>> weeklyViewData = [];

    // If the streak is less than 7 days, fill the rest with empty days
    int emptySlots = 7 - displayDates.length;

    for (var dateString in displayDates) {
      final date = dateFormatter.parse(dateString);
      weeklyViewData.add({
        'dayName': dayFormatter.format(date),
        'isToday': dateString == today,
        'isCompleted': true, // All dates in the list are completed days
      });
    }

    // Add empty slots for the rest of the week
    for (int i = 0; i < emptySlots; i++) {
      final nextDay = dateFormatter
          .parse(displayDates.last)
          .add(Duration(days: i + 1));
      weeklyViewData.add({
        'dayName': dayFormatter.format(nextDay),
        'isToday': dateFormatter.format(nextDay) == today,
        'isCompleted': false,
      });
    }

    return weeklyViewData;
  }

  // dev panel helpers
  Future<void> resetStreak() async {
    await _saveData(
      lastEngagementDate: null,
      streakCount: 0,
      milestonesShown: [],
      weeklyView: [],
    );
  }

  Future<void> simulateMilestone(int milestone) async {
    await _saveData(
      lastEngagementDate: DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.now().subtract(Duration(days: 1))),
      streakCount: milestone - 1,
    );
  }
}
