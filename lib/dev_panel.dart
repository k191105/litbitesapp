import 'package:flutter/material.dart';
import 'package:quotes_app/services/entitlements_service.dart';
import 'package:quotes_app/services/streak_service.dart';

class DevPanelPage extends StatefulWidget {
  const DevPanelPage({super.key});

  @override
  DevPanelPageState createState() => DevPanelPageState();
}

class DevPanelPageState extends State<DevPanelPage> {
  bool _isPro = false;
  Map<String, DateTime> _passes = {};
  int _streakCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final isPro = await EntitlementsService.instance.isPro();
    final passes = await EntitlementsService.instance.getFeaturePasses();
    final streakCount = await StreakService.instance.getStreakCount();
    setState(() {
      _isPro = isPro;
      _passes = passes;
      _streakCount = streakCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Developer Panel')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildProStatusSection(),
          const Divider(),
          _buildStreakSection(),
          const Divider(),
          _buildFeaturePassesSection(),
        ],
      ),
    );
  }

  Widget _buildProStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pro Status', style: Theme.of(context).textTheme.headlineSmall),
        SwitchListTile(
          title: Text(_isPro ? 'Pro Active' : 'Pro Inactive'),
          value: _isPro,
          onChanged: (value) async {
            await EntitlementsService.instance.setPro(value);
            await _loadStatus();
          },
        ),
      ],
    );
  }

  Widget _buildStreakSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Streak: $_streakCount days',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton(
              onPressed: () async {
                await StreakService.instance.simulateMilestone(3);
                await _loadStatus();
              },
              child: const Text('Simulate Day 3'),
            ),
            ElevatedButton(
              onPressed: () async {
                await StreakService.instance.simulateMilestone(7);
                await _loadStatus();
              },
              child: const Text('Simulate Day 7'),
            ),
            ElevatedButton(
              onPressed: () async {
                await StreakService.instance.simulateMilestone(14);
                await _loadStatus();
              },
              child: const Text('Simulate Day 14'),
            ),
            ElevatedButton(
              onPressed: () async {
                await StreakService.instance.resetStreak();
                await _loadStatus();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reset Streak'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeaturePassesSection() {
    final allFeatures = [
      EntitlementsService.search,
      EntitlementsService.browseTags,
      EntitlementsService.browsePeriod,
      EntitlementsService.premiumThemes,
      EntitlementsService.premiumFonts,
      EntitlementsService.premiumShareStyles,
      EntitlementsService.srsUnlimited,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Feature Passes',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        ...allFeatures.map((key) => _buildPassControl(key)),
        const SizedBox(height: 16),
        if (_passes.isNotEmpty)
          ElevatedButton(
            onPressed: () async {
              await EntitlementsService.instance.clearAllPasses();
              await _loadStatus();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All Passes'),
          ),
      ],
    );
  }

  Widget _buildPassControl(String featureKey) {
    final expiry = _passes[featureKey];
    final isActive = expiry != null && expiry.isAfter(DateTime.now());

    return ListTile(
      title: Text(featureKey),
      subtitle: Text(isActive ? 'Expires: ${expiry.toLocal()}' : 'Inactive'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () async {
              await EntitlementsService.instance.grantFeaturePass(
                featureKey,
                const Duration(days: 7),
              );
              await _loadStatus();
            },
            child: const Text('Grant 7 Days'),
          ),
          if (isActive) ...[
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () async {
                await EntitlementsService.instance.revokeFeaturePass(
                  featureKey,
                );
                await _loadStatus();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Revoke'),
            ),
          ],
        ],
      ),
    );
  }
}
