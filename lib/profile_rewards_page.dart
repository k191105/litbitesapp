import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:quotes_app/services/analytics.dart';
import 'package:quotes_app/services/rewards_service.dart';
import 'package:quotes_app/info_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:quotes_app/services/purchase_service.dart';
import 'package:quotes_app/services/entitlements_service.dart';
import 'package:quotes_app/services/revenuecat_keys.dart';
import 'package:quotes_app/utils/membership_feedback.dart';
import 'package:quotes_app/browse_hub.dart';
import 'package:quotes_app/learn_hub.dart';
import 'package:quotes_app/widgets/settings_sheet.dart';
import 'package:quotes_app/quote.dart';
import 'package:quotes_app/quote_service.dart';
import 'package:quotes_app/utils/feature_gate.dart';

class ProfileRewardsPage extends StatefulWidget {
  const ProfileRewardsPage({super.key});

  @override
  State<ProfileRewardsPage> createState() => _ProfileRewardsPageState();
}

class _ProfileRewardsPageState extends State<ProfileRewardsPage> {
  late Future<RewardsSnapshot> _rewardsFuture;
  int _favoriteQuotesCount = 0;
  List<Quote> _allQuotes = [];
  List<Quote> _favoriteQuotes = [];
  Map<String, int> _viewCounts = {};
  Map<String, int> _likeCounts = {};
  bool _isRestoring = false;
  bool _isRefreshing = false;

  bool get _isMembershipBusy => _isRestoring || _isRefreshing;

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

    _allQuotes = await QuoteService.loadQuotes();
    _favoriteQuotes = _allQuotes
        .where((q) => favoriteIds.contains(q.id))
        .toList();

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
      body: MembershipFeedback.loadingOverlay(
        context,
        isLoading: _isMembershipBusy,
        child: FutureBuilder<RewardsSnapshot>(
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

  void _navigateToFeature(String featureKey) {
    switch (featureKey) {
      case EntitlementsService.browseAuthor:
      case EntitlementsService.browsePeriod:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BrowseHubPage(
              allQuotes: _allQuotes,
              favoriteQuotes: _favoriteQuotes,
              viewCounts: _viewCounts,
              initialSelectedAuthors: const {},
              initialSelectedTags: const {},
            ),
          ),
        );
        break;
      case EntitlementsService.premiumThemes:
      case EntitlementsService.premiumFonts:
      case EntitlementsService.premiumShareStyles:
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => FractionallySizedBox(
            heightFactor: 0.75,
            child: SettingsSheet(
              allQuotes: _allQuotes,
              favoriteQuotes: _favoriteQuotes,
              viewCounts: _viewCounts,
            ),
          ),
        );
        break;
      case EntitlementsService.srsUnlimited:
      case EntitlementsService.learnTrainer:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LearnHubPage(
              allQuotes: _allQuotes,
              favoriteQuotes: _favoriteQuotes,
              viewCounts: _viewCounts,
              likeCounts: _likeCounts,
            ),
          ),
        );
        break;
    }
  }

  Widget _buildActivePasses(List<ActivePass> passes, {required bool isPro}) {
    if (isPro) {
      final proFeatures = EntitlementsService.proFeatureDisplayNames.values
          .toList();
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
                        _navigateToFeature(pass.featureKey);
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
                '—',
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
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: _isRestoring ? null : _handleRestore,
          child: _isRestoring
              ? _buildButtonSpinner(theme)
              : const Text('Restore Purchases'),
        ),
        TextButton(
          onPressed: () async {
            await launchUrl(
              Uri.parse('itms-apps://apps.apple.com/account/subscriptions'),
              mode: LaunchMode.externalApplication,
            );
          },
          child: const Text('Manage Subscription'),
        ),
        FilledButton(
          onPressed: _isRefreshing ? null : _handleRefresh,
          child: _isRefreshing
              ? _buildButtonSpinner(theme)
              : const Text('Refresh Membership Status'),
        ),
      ],
    );
  }

  Future<void> _handleRestore() async {
    if (_isRestoring) return;
    setState(() {
      _isRestoring = true;
    });
    Analytics.instance.logEvent('profile.restore');
    final start = DateTime.now();
    final isProBefore = await EntitlementsService.instance.isPro();
    debugPrint(
      '[MembershipFlow][restore] Restore started at ${start.toIso8601String()}',
    );

    try {
      final customerInfo = await PurchaseService.instance.restore();
      final isProAfter =
          customerInfo.entitlements.all[rcEntitlementKey]?.isActive ?? false;
      if (!mounted) return;

      final restored = isProAfter && !isProBefore;
      final durationMs = DateTime.now().difference(start).inMilliseconds;
      debugPrint(
        '[MembershipFlow][restore] Completed in ${durationMs}ms | restored=$restored | activeEntitlements=${customerInfo.entitlements.active.keys.join(',')}',
      );
      await MembershipFeedback.showMessage(
        context,
        title: restored ? 'Restore Complete' : 'No Purchases Found',
        message: restored
            ? 'Membership restored. Welcome to Literature Bites Pro!'
            : 'No purchases to restore.',
      );
      _loadData();
    } catch (e) {
      final durationMs = DateTime.now().difference(start).inMilliseconds;
      debugPrint(
        '[MembershipFlow][restore] Failed in ${durationMs}ms | error=$e',
      );
      if (!mounted) return;
      await MembershipFeedback.showMessage(
        context,
        title: 'Restore Failed',
        message: 'Restore failed: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRestoring = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
    });
    Analytics.instance.logEvent('profile.refresh_membership');
    final start = DateTime.now();
    final isProBefore = await EntitlementsService.instance.isPro();
    debugPrint(
      '[MembershipFlow][refresh] Refresh started at ${start.toIso8601String()}',
    );

    try {
      final customerInfo = await PurchaseService.instance
          .syncEntitlementFromRC();
      final isProAfter =
          customerInfo.entitlements.all[rcEntitlementKey]?.isActive ?? false;

      if (!mounted) return;

      final gainedPro = isProAfter && !isProBefore;
      final durationMs = DateTime.now().difference(start).inMilliseconds;
      debugPrint(
        '[MembershipFlow][refresh] Completed in ${durationMs}ms | gainedPro=$gainedPro | activeEntitlements=${customerInfo.entitlements.active.keys.join(',')}',
      );
      await MembershipFeedback.showMessage(
        context,
        title: gainedPro ? 'Membership Updated' : 'Already Up To Date',
        message: gainedPro
            ? 'Membership restored. Welcome to Literature Bites Pro!'
            : 'Membership status is up to date.',
      );
      _loadData();
    } catch (e) {
      final durationMs = DateTime.now().difference(start).inMilliseconds;
      debugPrint(
        '[MembershipFlow][refresh] Failed in ${durationMs}ms | error=$e',
      );
      if (!mounted) return;
      await MembershipFeedback.showMessage(
        context,
        title: 'Refresh Failed',
        message: 'Could not refresh membership. $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Widget _buildButtonSpinner(ThemeData theme) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
      ),
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
