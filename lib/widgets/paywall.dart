import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:quotes_app/services/analytics.dart';
import 'package:quotes_app/services/purchase_service.dart';
import 'package:quotes_app/services/revenuecat_keys.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:quotes_app/theme/lb_theme_extension.dart';

class Paywall extends StatefulWidget {
  final String contextKey;
  final PurchasePlan initialPlan;

  const Paywall({
    super.key,
    required this.contextKey,
    this.initialPlan = PurchasePlan.annual,
  });

  @override
  State<Paywall> createState() => _PaywallState();
}

class _PaywallState extends State<Paywall> {
  late PurchasePlan _selectedPlan;
  // bool _showLifetime = false; // deprecated: lifetime removed
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedPlan = widget.initialPlan;
    Analytics.instance.logEvent('paywall.view', {'context': widget.contextKey});
    Future.microtask(() async {
      await PurchaseService.instance.ensureOfferingsLoaded();
      if (mounted) setState(() {});
    });
  }

  Map<String, List<String>> get _contextualBullets => {
    'browse_tags': [
      'Unlock all tags and eras',
      'Open the full library (~5,000 quotes)',
      'Follow interests deeper with Tag/Period',
    ],
    'browse_author': [
      'Browse by author A–Z',
      'Deep author collections',
      'Full library access (~5,000 quotes)',
      'Discover new voices',
    ],
    'browse_period': [
      'Browse by Period (Romanticism → Modernism)',
      'Unlock the premium library',
      'See era‑specific highlights',
      'Time‑based discovery made easy',
    ],
    'settings_theme': [
      'All premium themes and fonts',
      'Share without watermark',
      'Home/lock‑screen widgets',
      'Make it feel uniquely yours',
      'Unlock premium quote library',
    ],
    'settings_font': [
      'Premium fonts unlocked',
      'Beautiful, readable typography',
      'Share without watermark',
      'Make every quote look right',
    ],
    'profile_upgrade': [
      'Full premium library unlocked',
      'Browse by Author & Period',
      'Curated Author Collections',
      'Personalised Learning',
      'Custom notifications & Smart Schedule',
    ],
    'reward_upgrade': [
      'Keep your unlocked feature forever',
      'Full library (~5,000) + Search',
      'All premium customization',
      'Personalised Learning',
    ],
    'learn_trainer': [
      'Guided sessions tailored to you',
      'Adaptive difficulty',
      'Review mistakes faster',
      'Master quotes with spaced repetition',
    ],
    'srs_unlimited': [
      'Personalised learning',
      'Master quotes with spaced repetition',
      'Track your progress',
      'Build lasting memory',
    ],
    'notif_customization': [
      'Pick times that fit your day',
      'Filter by authors or tags',
      'Weekday schedules',
      'Personalized reminder flow',
    ],
  };

  List<String> get _bullets =>
      _contextualBullets[widget.contextKey] ??
      _contextualBullets['profile_upgrade']!;

  String _contextualHeadline() {
    switch (widget.contextKey) {
      case 'browse_tags':
        return 'Explore by tag & era — without limits';
      case 'browse_author':
        return 'Browse authors A–Z, fully unlocked';
      case 'browse_period':
        return 'See every era, fully unlocked';
      case 'settings_theme':
        return 'Make it yours. Premium looks.';
      case 'settings_font':
        return 'Typography that feels right.';
      case 'reward_upgrade':
        return 'Keep today\'s reward forever';
      case 'learn_trainer':
        return 'Learn smarter with guided sessions';
      case 'srs_unlimited':
        return 'Master every quote with unlimited reviews';
      case 'notif_customization':
        return 'Reminders that fit your schedule';
      default:
        return 'Read smarter. Unlock more.';
    }
  }

  String _ctaLabel() {
    final trialDescription = PurchaseService.instance.getTrialDescription(
      _selectedPlan,
    );
    if (trialDescription != null) {
      return trialDescription;
    }
    return 'Continue';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).disabledColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildHeadline(),
                const SizedBox(height: 24),
                _buildBullets(),
                _buildAllProFeaturesExpandable(),
                const SizedBox(height: 24),
                _buildPlanCards(),
                const SizedBox(height: 24),
                _buildCTASection(),
                const SizedBox(height: 16),
                _buildLegalFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Literature Bites',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
            fontFamily: 'EBGaramond',
          ),
        ),
        const SizedBox(width: 8),
        // Lottie.asset('assets/lottie/badge_sparkle.json', width: 24, height: 24),
      ],
    );
  }

  Widget _buildHeadline() {
    return Text(
      _contextualHeadline(),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).primaryColor,
        height: 1.15,
      ),
    );
  }

  Widget _buildBullets() {
    return Column(
      children: _bullets.map((bullet) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.secondary,
                      Theme.of(context).colorScheme.primary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  bullet,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).primaryColor.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAllProFeaturesExpandable() {
    final Map<String, List<String>> groups = {
      'Explore': [
        'Full premium quotes library',
        'Browse by Author & Period',
        'Curated Author Collections',
        'Intelligent recommendation algorithm',
      ],
      'Customize': ['Premium themes & fonts', 'Make it feel uniquely yours'],
      'Learn': ['Personalised learning', 'Spaced Repetition', 'Progress stats'],
      'Notifications': [
        'Custom count & times',
        'Smart Schedule',
        'Customise by author/tag',
      ],
    };

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 8),
        initiallyExpanded: false,
        title: Row(
          children: [
            Icon(
              Icons.workspace_premium_outlined,
              color: Theme.of(context).primaryColor.withOpacity(0.8),
            ),
            const SizedBox(width: 8),
            Text(
              'Everything in Pro',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        children: groups.entries
            .map((e) => _featureGroup(e.key, e.value))
            .toList(),
      ),
    );
  }

  Widget _featureGroup(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).primaryColor.withOpacity(0.9),
              ),
            ),
          ),
          ...items.map(
            (it) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      it,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: Theme.of(context).primaryColor.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCards() {
    return Column(
      children: [
        _buildPlanCard(PurchasePlan.annual, isRecommended: true),
        const SizedBox(height: 12),
        _buildPlanCard(PurchasePlan.monthly),
      ],
    );
  }

  Widget _buildPlanCard(PurchasePlan plan, {bool isRecommended = false}) {
    final theme = Theme.of(context);
    final lbTheme = theme.extension<LBTheme>()!;
    final isSelected = _selectedPlan == plan;

    final rawName = PurchaseService.instance.getPlanDisplayName(plan);
    final planName = (rawName != null && rawName.trim().isNotEmpty)
        ? rawName
        : (plan == PurchasePlan.annual ? 'Pro Annual' : 'Pro Monthly');

    final price = PurchaseService.instance.getPlanPrice(plan);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlan = plan;
        });
        Analytics.instance.logEvent('paywall.select_plan', {'plan': plan.id});
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : lbTheme.controlBorder.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.05)
              : lbTheme.controlSurface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  planName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                if (isRecommended)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.secondary,
                          theme.colorScheme.primary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Best Value',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              price ?? '—',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            if (plan == PurchasePlan.annual)
              Text(
                '${PurchaseService.instance.getAnnualPerMonthPrice() ?? '... '}/month',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).primaryColor.withOpacity(0.6),
                ),
              ),
            if (plan == PurchasePlan.annual)
              Text(
                'Best value for regular readers',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).primaryColor.withOpacity(0.55),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCTASection() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.secondary,
                  Theme.of(context).colorScheme.primary,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handlePurchase,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _ctaLabel(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedPlan = PurchasePlan.monthly;
                });
                Analytics.instance.logEvent('paywall.select_plan', {
                  'plan': 'monthly',
                });
              },
              child: Text(
                'See monthly',
                style: TextStyle(
                  color: Theme.of(context).primaryColor.withOpacity(0.7),
                ),
              ),
            ),
            TextButton(
              onPressed: _handleRestore,
              child: Text(
                'Restore purchases',
                style: TextStyle(
                  color: Theme.of(context).primaryColor.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegalFooter() {
    final price = PurchaseService.instance.getPlanPrice(_selectedPlan);
    final trialDescription = PurchaseService.instance.getTrialDescription(
      _selectedPlan,
    );

    String text;
    if (trialDescription != null) {
      text =
          '$trialDescription, then $price per ${_selectedPlan == PurchasePlan.monthly ? 'month' : 'year'}. Cancel anytime.';
    } else {
      text =
          'Billed $price per ${_selectedPlan == PurchasePlan.monthly ? 'month' : 'year'}. Cancel anytime.';
    }

    return Column(
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).primaryColor.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Cancel anytime • Keep your favorites and notes',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).primaryColor.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => launchUrl(
                Uri.parse(
                  'https://singhalkrishiv.wixsite.com/literature-bites/privacy-policy',
                ),
              ),
              child: Text(
                'Privacy',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).primaryColor.withOpacity(0.6),
                ),
              ),
            ),
            Text(
              ' • ',
              style: TextStyle(
                color: Theme.of(context).primaryColor.withOpacity(0.6),
              ),
            ),
            TextButton(
              onPressed: () => launchUrl(
                Uri.parse(
                  'https://singhalkrishiv.wixsite.com/literature-bites/privacy-policy',
                ),
              ),
              child: Text(
                'Terms',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).primaryColor.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handlePurchase() async {
    setState(() {
      _isLoading = true;
    });

    Analytics.instance.logEvent('paywall.cta_press', {
      'plan': _selectedPlan.id,
    });

    try {
      final success = await PurchaseService.instance.purchase(_selectedPlan.id);

      if (success && mounted) {
        Navigator.of(
          context,
        ).pop(true); // Return true to indicate successful purchase
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome to Literature Bites Pro!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRestore() async {
    Analytics.instance.logEvent('paywall.restore');

    try {
      await PurchaseService.instance.restore();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchases restored successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
