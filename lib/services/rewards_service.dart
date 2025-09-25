import 'dart:async';

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

  int _calculateNextMilestone(int currentStreak) {
    const interval = 3;
    if (currentStreak == 0) return interval;
    return ((currentStreak / interval).floor() + 1) * interval;
  }

  List<String> _getFeaturesForMilestone(int milestone) {
    // Only include rewardable features that actually unlock user-facing UX
    const rewardableFeatures = <String>[
      EntitlementsService.browseAuthor,
      EntitlementsService.browsePeriod,
      EntitlementsService.premiumThemes,
      EntitlementsService.premiumFonts,
      EntitlementsService.learnTrainer,
    ];
    final cycleIndex =
        ((milestone / 3) - 1).floor() % rewardableFeatures.length;
    return [rewardableFeatures[cycleIndex]];
  }

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
              displayName:
                  EntitlementsService.proFeatureDisplayNames[key] ?? key,
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
      final featureDisplayNames = features
          .map((f) => EntitlementsService.proFeatureDisplayNames[f] ?? f)
          .toList();

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
}
