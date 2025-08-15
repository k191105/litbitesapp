import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:quotes_app/author_quiz_page.dart';
import 'package:quotes_app/flashcards_page.dart';
import 'package:quotes_app/quiz_page.dart';
import 'package:quotes_app/quote_quiz_page.dart';
import 'package:quotes_app/services/entitlements_service.dart';
import 'package:quotes_app/utils/feature_gate.dart';
import 'package:quotes_app/theme/lb_theme_extension.dart';
import 'package:quotes_app/learn/personalised_quiz_setup_page.dart';
import 'package:quotes_app/recommendation_service.dart';
import 'package:quotes_app/srs_service.dart';
import 'quote.dart';

class LearnHubPage extends StatefulWidget {
  final List<Quote> allQuotes;
  final List<Quote> favoriteQuotes;
  final Map<String, int> viewCounts;

  const LearnHubPage({
    super.key,
    required this.allQuotes,
    required this.favoriteQuotes,
    required this.viewCounts,
  });

  @override
  State<LearnHubPage> createState() => _LearnHubPageState();
}

class _LearnHubPageState extends State<LearnHubPage> {
  bool _trainerAllowed = false; // Pro or Feature Pass: learn_trainer
  int _struggledQuotesCount = 0;
  int _learnedQuotesCount = 0;
  int _favoritesCount = 0;
  int _totalViews = 0;

  @override
  void initState() {
    super.initState();
    _checkProStatus();
    _loadStats();
  }

  void _checkProStatus() async {
    final isPro = await EntitlementsService.instance.isPro();
    final hasTrainerPass = await EntitlementsService.instance.isFeatureActive(
      'learn_trainer',
    );
    final struggledQuotes = await SRSService().getStruggledQuotes();
    if (!mounted) return;
    setState(() {
      _trainerAllowed = isPro || hasTrainerPass;
      _struggledQuotesCount = struggledQuotes.length;
    });
  }

  Future<void> _loadStats() async {
    final learnedCount = await SRSService().getLearnedQuotesCount();
    setState(() {
      _learnedQuotesCount = learnedCount;
      _favoritesCount = widget.favoriteQuotes.length;
      _totalViews = widget.viewCounts.values.fold(0, (a, b) => a + b);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Learn', style: theme.textTheme.titleLarge),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.primaryColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildHeroQuizCard(context, locked: !_trainerAllowed),
          const SizedBox(height: 16),
          _buildStatsRow(context),
          const SizedBox(height: 16),
          _buildSectionHeader(
            context,
            title: 'Modes',
            subtitle: 'Choose how you want to practice',
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildLearnModeCard(
                context,
                icon: Icons.style,
                title: 'Flashcards',
                description: 'Review quotes and authors',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          FlashcardsPage(favoriteQuotes: widget.favoriteQuotes),
                    ),
                  );
                },
              ),
              _buildLearnModeCard(
                context,
                icon: Icons.person_search,
                title: 'Author Details',
                description: 'Test your knowledge of authors',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AuthorQuizPage(
                        favoriteQuotes: widget.favoriteQuotes,
                        allQuotes: widget.allQuotes,
                      ),
                    ),
                  );
                },
              ),
              _buildLearnModeCard(
                context,
                icon: Icons.format_quote,
                title: 'Quote Quizzes',
                description: 'Identify authors and sources',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuoteQuizPage(
                        favoriteQuotes: widget.favoriteQuotes,
                        allQuotes: widget.allQuotes,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    String? subtitle,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleLarge),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHeroQuizCard(BuildContext context, {bool locked = false}) {
    final cs = Theme.of(context).colorScheme;
    final cardContent = Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              cs.primary.withOpacity(0.1),
              cs.secondary.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: InkWell(
          onTap: () {
            requireFeature(
              context,
              'learn_trainer',
              onAllowed: () async {
                final config = await Navigator.of(context)
                    .push<PersonalisedQuizConfig>(
                      MaterialPageRoute(
                        builder: (context) => PersonalisedQuizSetupPage(
                          favoriteQuotes: widget.favoriteQuotes,
                        ),
                      ),
                    );
                if (config != null && mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizPage(
                        allQuotes: widget.allQuotes,
                        favoriteQuotes: widget.favoriteQuotes
                            .where((q) => config.quoteIds.contains(q.id))
                            .toList(),
                        viewCounts: widget.viewCounts,
                      ),
                    ),
                  );
                }
              },
              onBlocked: () =>
                  openPaywall(context: context, contextKey: 'learn_trainer'),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cs.primary.withOpacity(0.85),
                  cs.secondary.withOpacity(0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.quiz, color: Colors.white, size: 40),
                const SizedBox(height: 16),
                Text(
                  'Personalised Quiz',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'A configurable challenge that spans authors, quotes, and sources.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!locked) return cardContent;

    return Stack(
      children: [
        cardContent,
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple, Colors.blue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'PRO',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _statChip(
            context,
            label: 'Quotes Learned',
            value: _learnedQuotesCount.toString(),
            icon: Icons.school,
            color: cs.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statChip(
            context,
            label: 'Total Favourites',
            value: _favoritesCount.toString(),
            icon: Icons.favorite,
            color: cs.primary,
          ),
        ),
      ],
    );
  }

  Widget _statChip(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final lb = Theme.of(context).extension<LBTheme>();
    return Container(
      decoration: BoxDecoration(
        color: (lb?.controlSurface) ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              (lb?.controlBorder) ??
              Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(value, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLearnModeCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    bool locked = false,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final lb = theme.extension<LBTheme>();

    final baseCard = Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: (lb?.controlSurface) ?? theme.cardColor,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              cs.primary.withOpacity(0.1),
              cs.secondary.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  size: 36,
                  color: theme.primaryColor.withOpacity(0.9),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!locked) return baseCard;

    return Stack(
      children: [
        baseCard,
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'PRO',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
