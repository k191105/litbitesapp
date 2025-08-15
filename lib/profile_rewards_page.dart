import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:quotes_app/services/analytics.dart';
import 'package:quotes_app/services/rewards_service.dart';
import 'package:quotes_app/info_card.dart';
import 'package:quotes_app/utils/feature_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileRewardsPage extends StatefulWidget {
  const ProfileRewardsPage({super.key});

  @override
  State<ProfileRewardsPage> createState() => _ProfileRewardsPageState();
}

class _ProfileRewardsPageState extends State<ProfileRewardsPage> {
  late Future<RewardsSnapshot> _rewardsFuture;
  int? _longestStreak; // TODO: Track this properly
  int _favoriteQuotesCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    Analytics.instance.logEvent('profile.opened');
  }

  void _loadData() {
    _rewardsFuture = RewardsService.instance.load();
    _loadStats();
    setState(() {});
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds = prefs.getStringList('favoriteQuoteIds') ?? [];
    setState(() {
      _favoriteQuotesCount = favoriteIds.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Your Profile & Rewards',
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
      ),
      body: FutureBuilder<RewardsSnapshot>(
        future: _rewardsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No data available.'));
          }

          final rewards = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildHeader(rewards.tier),
                const SizedBox(height: 24),
                _buildActivePasses(
                  rewards.activePasses,
                  isPro: rewards.tier == "Pro",
                ),
                const SizedBox(height: 24),
                if (rewards.nextPass != null)
                  _buildNextReward(rewards.nextPass!),
                const SizedBox(height: 24),
                _buildUsageStats(rewards),
                const SizedBox(height: 24),
                _buildFooter(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(String tier) {
    bool isPro = tier == "Pro";
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isPro) ...[
                        Lottie.asset(
                          'assets/lottie/badge_sparkle.json',
                          width: 20,
                          height: 20,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        isPro ? 'Pro' : 'Standard',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (isPro)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.blue, Colors.purple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Pro User',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                )
              else
                GradientOutlinedButton(
                  onPressed: () {
                    openPaywall(
                      context: context,
                      contextKey: 'profile_upgrade',
                    ).then((result) {
                      if (result == true) {
                        _loadData(); // Refresh the entire page
                      }
                    });
                  },
                  backgroundColor: Theme.of(context).cardColor,
                  child: const Text(
                    'Upgrade',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivePasses(List<ActivePass> passes, {required bool isPro}) {
    if (isPro) {
      final proFeatures = [
        'Premium Quote Library',
        'Browse by Author',
        'Browse by Period',
        'Curated Author Collections',
        'Premium Themes',
        'Premium Fonts',
        'Personalised Notifications',
        'Personalised Learning',
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'All Pro Features Unlocked',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: proFeatures.length,
            itemBuilder: (context, index) {
              final feature = proFeatures[index];
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade300, Colors.purple.shade300],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    feature,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      );
    }
    if (passes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            "You don’t have any passes yet—earn one by keeping your streak!",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Passes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: passes.length,
            itemBuilder: (context, index) {
              final pass = passes[index];
              return Container(
                width: 180,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade300, Colors.purple.shade300],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      pass.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Expires in ${_formatDuration(pass.timeRemaining)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Analytics.instance.logEvent('profile.active_pass_try', {
                          'feature': pass.featureKey,
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Available once feature entry points ship',
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Try',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    if (d.inDays > 0) {
      return '${d.inDays}d ${d.inHours.remainder(24)}h';
    }
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    return '${d.inMinutes}m';
  }

  Widget _buildNextReward(NextPassInfo nextPass) {
    Analytics.instance.logEvent('profile.next_reward_seen', {
      'nextMilestone': nextPass.nextMilestone,
      'daysRemaining': nextPass.daysRemaining,
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Next free pass in ${nextPass.daysRemaining} days',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Lottie.asset(
                'assets/lottie/pulse_streak.json',
                width: 24,
                height: 24,
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: 1 - (nextPass.daysRemaining / 7),
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll unlock: ${nextPass.featureDisplayNamesAtNextMilestone.join(', ')} at day ${nextPass.nextMilestone}',
          ),
        ],
      ),
    );
  }

  Widget _buildUsageStats(RewardsSnapshot rewards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Usage Stats',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Current Streak',
                rewards.currentStreak.toString(),
                Icons.local_fire_department_outlined,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                'Longest Streak',
                _longestStreak?.toString() ?? '—',
                Icons.trending_up,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                'Favorited',
                _favoriteQuotesCount.toString(),
                Icons.favorite_outline,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: TextButton(
            onPressed: () {
              // TODO: Implement restore purchases
            },
            child: const Text('Restore purchases'),
          ),
        ),
        Expanded(
          child: TextButton(
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Coming soon')));
            },
            child: const Text('Manage Subscription'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon, {
    Color? color,
  }) {
    final cardColor = color ?? Theme.of(context).primaryColor.withOpacity(0.7);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: cardColor),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color ?? Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).primaryColor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
