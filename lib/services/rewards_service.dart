import 'dart:async';
import 'dart:math';

import 'package:quotes_app/services/entitlements_service.dart';
import 'package:quotes_app/services/streak_service.dart';

class RewardsSnapshot {
  final String tier;
  final List<ActivePass> activePasses;
  final NextPassInfo? nextPass;
  final int currentStreak;

  RewardsSnapshot({
    required this.tier,
    required this.activePasses,
    required this.currentStreak,
    this.nextPass,
  });
}

class ActivePass {
  final String featureKey;
  final String displayName;
  final Duration timeRemaining;

  ActivePass({
    required this.featureKey,
    required this.displayName,
    required this.timeRemaining,
  });
}

class NextPassInfo {
  final int nextMilestone;
  final int daysRemaining;
  final List<String> featureKeysAtNextMilestone;
  final List<String> featureDisplayNamesAtNextMilestone;

  NextPassInfo({
    required this.nextMilestone,
    required this.daysRemaining,
    required this.featureKeysAtNextMilestone,
    required this.featureDisplayNamesAtNextMilestone,
  });
}

class RewardsService {
  static final RewardsService instance = RewardsService._();
  RewardsService._();

  static const _featureDisplayNames = {
    EntitlementsService.browseTags: 'Browse by Tag',
    EntitlementsService.browseAuthor: 'Browse by Author',
    EntitlementsService.browsePeriod: 'Browse by Period',
    EntitlementsService.premiumThemes: 'Premium Themes',
    EntitlementsService.premiumFonts: 'Premium Fonts',
    EntitlementsService.premiumShareStyles: 'Share Styles',
    EntitlementsService.srsUnlimited: 'SRS Unlimited',
  };

  static final _proFeatures = [
    EntitlementsService.browseAuthor, // Now gated
    EntitlementsService.browsePeriod,
    EntitlementsService.premiumThemes,
    EntitlementsService.premiumFonts,
    EntitlementsService.premiumShareStyles,
    EntitlementsService.srsUnlimited,
    // Note: browseTags removed as it's now free
  ];

  static const _milestoneRewards = {
    7: [EntitlementsService.browseAuthor],
    14: [EntitlementsService.browsePeriod],
    21: [EntitlementsService.premiumThemes],
    30: [EntitlementsService.premiumFonts],
  };

  Future<RewardsSnapshot> load() async {
    final isPro = await EntitlementsService.instance.isPro();
    final tier = isPro ? "Pro" : "Free";
    final streakCount = await StreakService.instance.getStreakCount();

    final activePasses = <ActivePass>[];
    if (!isPro) {
      final activeKeys = await EntitlementsService.instance.activeFeatureKeys();
      // Define features that are now free (don't show passes for these)
      final freeFeatures = {EntitlementsService.browseTags};

      for (final key in activeKeys) {
        // Skip showing passes for features that are now free
        if (freeFeatures.contains(key)) continue;

        final remaining = await EntitlementsService.instance.timeRemaining(key);
        if (remaining != null && !remaining.isNegative) {
          activePasses.add(
            ActivePass(
              featureKey: key,
              displayName: _featureDisplayNames[key] ?? key,
              timeRemaining: remaining,
            ),
          );
        }
      }
    }

    NextPassInfo? nextPass;
    if (!isPro) {
      final nextMilestone = _calculateNextMilestone(streakCount);
      final daysRemaining = nextMilestone - streakCount;
      final features = _getFeaturesForMilestone(nextMilestone);
      final featureDisplayNames = nextMilestone == 7
          ? ['Mystery Pro Feature']
          : features.map((f) => _featureDisplayNames[f] ?? f).toList();

      nextPass = NextPassInfo(
        nextMilestone: nextMilestone,
        daysRemaining: daysRemaining,
        featureKeysAtNextMilestone: features,
        featureDisplayNamesAtNextMilestone: featureDisplayNames,
      );
    }

    return RewardsSnapshot(
      tier: tier,
      activePasses: activePasses,
      nextPass: nextPass,
      currentStreak: streakCount,
    );
  }

  int _calculateNextMilestone(int currentStreak) {
    if (currentStreak < 7) return 7;
    if (currentStreak < 14) return 14;
    if (currentStreak < 21) return 21;
    if (currentStreak < 30) return 30;

    const baseMilestone = 30;
    const interval = 7;
    final cyclesPastBase = ((currentStreak - baseMilestone) / interval).floor();
    return baseMilestone + (cyclesPastBase + 1) * interval;
  }

  List<String> _getFeaturesForMilestone(int milestone) {
    if (milestone == 7) {
      return [EntitlementsService.browseAuthor];
    }
    var key = milestone;
    if (!_milestoneRewards.containsKey(key)) {
      if (key > 30) {
        final rewardKeys = [
          EntitlementsService.browseAuthor,
          EntitlementsService.browsePeriod,
          EntitlementsService.premiumThemes,
          EntitlementsService.premiumFonts,
        ];
        final cycleIndex = ((key - 31) ~/ 7) % rewardKeys.length;
        return [rewardKeys[cycleIndex]];
      }
    }
    return _milestoneRewards[key] ?? [];
  }
}
