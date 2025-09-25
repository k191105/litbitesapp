import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quotes_app/services/analytics.dart';
import 'package:quotes_app/services/entitlements_service.dart';
import 'package:quotes_app/services/time_provider.dart';

// TODO: TimeProvider refactor - DateTime.now() calls replaced with timeProvider.now()

class StreakService {
  static final StreakService instance = StreakService._();
  StreakService._();

  // Persistence Keys
  static const _lastEngagementDateKey = 'last_engagement_local_date';
  static const _streakCountKey = 'streak_count';
  static const _milestonesShownKey = 'milestones_shown';
  static const _weeklyViewKey =
      'weekly_view'; // Stores list of local date strings "YYYY-MM-DD"

  String getTodayLocal() {
    final now = timeProvider.now();
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
    ).format(timeProvider.now().subtract(const Duration(days: 1)));
    int previousStreak = streakCount;

    if (lastEngagementDate == yesterday) {
      // Consecutive day, increment streak.
      streakCount++;
    } else {
      // Not consecutive, reset streak.
      streakCount = 1;
      weeklyView.clear();
      milestonesShown.clear();
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

    final isMilestoneDay = streakCount > 0 && streakCount % 3 == 0;

    if (isMilestoneDay && !milestonesShown.contains(streakCount)) {
      newMilestone = streakCount;
      milestonesShown.add(newMilestone);
      await Analytics.instance.logEvent('streak.milestone_shown', {
        'n': newMilestone,
      });

      // Grant feature passes by cycling through the pro features
      final proFeatures = EntitlementsService.proFeatureDisplayNames.keys
          .toList();
      final cycleIndex = ((newMilestone / 3) - 1).floor() % proFeatures.length;
      final featureToAward = proFeatures[cycleIndex];
      awardedFeatureKeys.add(featureToAward);

      await EntitlementsService.instance.grantFeaturePass(
        featureToAward,
        const Duration(days: 5),
        source: 'streak_$newMilestone',
      );
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

  String? _getAnimationForMilestone(int? milestone) {
    if (milestone == null) return null;
    return milestone % 2 == 1 ? 'confetti' : 'fireworks';
  }

  Future<int> getStreakCount() async {
    final data = await loadData();
    return data[_streakCountKey];
  }

  Future<List<Map<String, dynamic>>> getWeeklyView() async {
    final data = await loadData();
    final int streakCount = data[_streakCountKey];
    if (streakCount == 0) return [];

    final today = timeProvider.now();
    final dayFormatter = DateFormat.E();

    final daysInStreakWeek = (streakCount - 1) % 7;
    final startOfStreakWeekDate = today.subtract(
      Duration(days: daysInStreakWeek),
    );

    final daysToShow = <Map<String, dynamic>>[];

    for (int i = 0; i < 7; i++) {
      final date = startOfStreakWeekDate.add(Duration(days: i));
      final isCompleted = i <= daysInStreakWeek;

      // Calculate the streak count for this specific day in the view
      final streakOnDay = streakCount - (daysInStreakWeek - i);
      final isRewardDay = streakOnDay > 0 && streakOnDay % 3 == 0;

      daysToShow.add({
        'dayName': dayFormatter.format(date),
        'isToday': i == daysInStreakWeek,
        'isCompleted': isCompleted,
        'isRewardDay': isRewardDay,
      });
    }
    return daysToShow;
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
      ).format(timeProvider.now().subtract(Duration(days: 1))),
      streakCount: milestone - 1,
    );
  }
}
