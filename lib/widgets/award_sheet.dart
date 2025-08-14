import 'package:flutter/material.dart';
import 'package:quotes_app/services/analytics.dart';

const Map<String, String> _featureDisplayNames = {
  'search': 'Search',
  'browse_tags': 'Browse by Tag',
  'browse_period': 'Browse by Period',
  'premium_themes': 'Premium Themes',
  'premium_fonts': 'Premium Fonts',
};

class AwardSheet extends StatelessWidget {
  final List<String> awardedFeatureKeys;
  final VoidCallback onSeeRewards;
  final ValueChanged<String> onTryFeature;

  const AwardSheet({
    super.key,
    required this.awardedFeatureKeys,
    required this.onSeeRewards,
    required this.onTryFeature,
  });

  @override
  Widget build(BuildContext context) {
    Analytics.instance.logEvent('award_sheet_opened', {
      'features': awardedFeatureKeys,
    });
    final bool isSingleAward = awardedFeatureKeys.length == 1;
    final String featureName = isSingleAward
        ? _featureDisplayNames[awardedFeatureKeys.first] ?? 'A New Feature'
        : 'New Features';

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Unlocked: $featureName for 7 days',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (!isSingleAward)
            ...awardedFeatureKeys.map(
              (key) => Text(
                '• ${_featureDisplayNames[key] ?? key}',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
          if (!isSingleAward) const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (isSingleAward) {
                onTryFeature(awardedFeatureKeys.first);
              } else {
                onSeeRewards();
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(isSingleAward ? 'Try It' : 'See My Rewards'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (isSingleAward) onSeeRewards();
            },
            child: Text(isSingleAward ? 'See My Rewards' : 'Dismiss'),
          ),
        ],
      ),
    );
  }
}
