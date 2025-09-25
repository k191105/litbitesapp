import 'package:flutter/material.dart';
import 'package:quotes_app/browse.dart';
import 'package:quotes_app/browse_by_author.dart';
import 'package:quotes_app/browse_by_period_filter.dart';
import 'package:quotes_app/quote.dart';
import 'package:quotes_app/services/entitlements_service.dart';
import 'package:quotes_app/utils/feature_gate.dart';
import 'package:quotes_app/widgets/settings_sheet.dart';
import 'package:quotes_app/widgets/tag_chip.dart';
import 'package:quotes_app/widgets/pro_badge.dart';
import 'package:quotes_app/utils/gate_overlay.dart';
import 'package:quotes_app/theme/lb_theme_extension.dart';

class BrowseHubPage extends StatefulWidget {
  final List<Quote> allQuotes;
  final List<Quote> favoriteQuotes;
  final Map<String, int> viewCounts;
  final Set<String> initialSelectedTags;
  final Set<String> initialSelectedAuthors;

  const BrowseHubPage({
    super.key,
    required this.allQuotes,
    required this.favoriteQuotes,
    required this.viewCounts,
    required this.initialSelectedTags,
    required this.initialSelectedAuthors,
  });

  @override
  State<BrowseHubPage> createState() => _BrowseHubPageState();
}

class _BrowseHubPageState extends State<BrowseHubPage> {
  bool _showAllCollections = false;
  bool _authorFeatureAllowed = false;
  bool _periodFeatureAllowed = false;

  @override
  void initState() {
    super.initState();
    _checkProStatus();
  }

  void _checkProStatus() async {
    final isPro = await EntitlementsService.instance.isPro();
    final hasAuthorPass = await EntitlementsService.instance.isFeatureActive(
      EntitlementsService.browseAuthor,
    );
    final hasPeriodPass = await EntitlementsService.instance.isFeatureActive(
      EntitlementsService.browsePeriod,
    );
    if (mounted) {
      setState(() {
        _authorFeatureAllowed = isPro || hasAuthorPass;
        _periodFeatureAllowed = isPro || hasPeriodPass;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            titleSpacing: 16,
            toolbarHeight: 88,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Browse'),
                const SizedBox(height: 4),
                Text(
                  'Explore by tags, author, period or custom packs',
                  style: textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => _showSettings(context),
              ),
            ],
          ),
          _buildSection(
            context,
            title: 'For You',
            subtitle: 'Shortcuts and your top tags',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildButtonCard(
                  context,
                  icon: Icons.favorite_border,
                  title: 'Your Favorites',
                  subtitle: 'Revisit your favorite quotes',
                  onTap: () {
                    Navigator.of(context).pop({'favorites': true});
                  },
                ),
                const SizedBox(height: 12),
                _buildButtonCard(
                  context,
                  icon: Icons.sell_outlined,
                  title: 'Explore by Tags',
                  subtitle: 'Find quotes by specific tags',
                  onTap: () async {
                    final selectedTags = await Navigator.push<Set<String>>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BrowsePage(
                          allQuotes: widget.allQuotes,
                          initialSelectedTags: widget.initialSelectedTags,
                        ),
                      ),
                    );
                    if (selectedTags != null && context.mounted) {
                      Navigator.pop(context, {'tags': selectedTags});
                    }
                  },
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Your Top Tags',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _getTopTags().map((tag) {
                      return TagChip(
                        tag: tag,
                        isSelected: false,
                        onTap: (selectedTag) => _onTagTap(selectedTag),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          _buildSection(
            context,
            title: 'Authors',
            subtitle: 'Find all quotes from specific authors',
            showProBadge: !_authorFeatureAllowed,
            child: _buildButtonCard(
              context,
              icon: Icons.person_outline,
              title: 'Browse by Authors',
              subtitle: 'See every author in the library',
              showGradientBorder: !_authorFeatureAllowed,
              onTap: () {
                requireFeature(
                  context,
                  EntitlementsService.browseAuthor,
                  onAllowed: () async {
                    final result = await Navigator.push<Set<String>>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BrowseByAuthorPage(
                          allQuotes: widget.allQuotes,
                          initialSelectedAuthors: widget.initialSelectedAuthors,
                        ),
                      ),
                    );
                    if (result != null && context.mounted) {
                      Navigator.of(context).pop({'authors': result});
                    }
                  },
                  onBlocked: () => openPaywall(
                    context: context,
                    contextKey: 'browse_author',
                  ),
                );
              },
            ),
          ),
          _buildAuthorCollectionGrid(context),
          _buildPeriodsSection(context),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    String? subtitle,
    required Widget child,
    bool showProBadge = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (showProBadge) ...[
                        const SizedBox(width: 8),
                        const ProBadge(),
                      ],
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildButtonCard(
    BuildContext context, {
    required IconData icon,
    required dynamic title, // Can be String or Widget
    required String subtitle,
    required VoidCallback onTap,
    bool showGradientBorder = false,
  }) {
    final lbTheme = Theme.of(context).extension<LBTheme>();
    final cs = Theme.of(context).colorScheme;

    Widget cardContent = Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 1,
      color: lbTheme?.controlSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: showGradientBorder
              ? Colors.transparent
              : (lbTheme?.controlBorder ??
                    Theme.of(context).colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: title is String
                              ? Text(
                                  title,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                )
                              : title as Widget,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );

    if (showGradientBorder) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              cs.secondary.withOpacity(0.6),
              cs.primary.withOpacity(0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Container(
          margin: const EdgeInsets.all(1), // Thin border width
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            color: lbTheme?.controlSurface ?? Theme.of(context).cardColor,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(11),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: title is String
                                  ? Text(
                                      title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    )
                                  : title as Widget,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return cardContent;
  }

  void _onTagTap(String tag) {
    Navigator.of(context).pop({
      'tags': {tag},
    });
  }

  static const List<Map<String, dynamic>> _authorCollections = [
    {
      'title': 'The Stoics',
      'subtitle': 'Timeless wisdom',
      'authors': [
        'Seneca',
        'Epictetus',
        'Marcus Aurelius',
        'Zeno of Citium',
        'Chrysippus',
        'Musonius Rufus',
        'Hierocles',
        'Posidonius',
      ],
    },
    {
      'title': 'The Romantics',
      'subtitle': 'Passionate verses',
      'authors': [
        'William Wordsworth',
        'John Keats',
        'Lord Byron',
        'Percy Bysshe Shelley',
        'Samuel Taylor Coleridge',
        'William Blake',
        'Mary Shelley',
        'Sir Walter Scott',
      ],
    },
    {
      'title': 'Modernist Voices',
      'subtitle': 'New perspectives',
      'authors': [
        'Virginia Woolf',
        'James Joyce',
        'T.S. Eliot',
        'Ezra Pound',
        'Gertrude Stein',
        'Marcel Proust',
        'Franz Kafka',
        'William Faulkner',
      ],
    },
    {
      'title': 'Women of Letters',
      'subtitle': 'Influential voices',
      'authors': [
        'Virginia Woolf',
        'Jane Austen',
        'Emily Dickinson',
        'Sylvia Plath',
        'George Eliot',
        'Charlotte Brontë',
        'Simone de Beauvoir',
        'Mary Wollstonecraft',
      ],
    },
    {
      'title': 'Russian Greats',
      'subtitle': 'Literary giants',
      'authors': [
        'Leo Tolstoy',
        'Fyodor Dostoevsky',
        'Anton Chekhov',
        'Alexander Pushkin',
        'Nikolai Gogol',
        'Ivan Turgenev',
        'Mikhail Bulgakov',
        'Boris Pasternak',
      ],
    },
    {
      'title': 'The Transcendentalists',
      'subtitle': 'Nature & individualism',
      'authors': [
        'Ralph Waldo Emerson',
        'Henry David Thoreau',
        'Walt Whitman',
        'Margaret Fuller',
        'Bronson Alcott',
        'Orestes Brownson',
        'Jones Very',
        'Theodore Parker',
      ],
    },
    {
      'title': 'Political Minds',
      'subtitle': 'Historic speeches',
      'authors': [
        'Winston Churchill',
        'Abraham Lincoln',
        'Mahatma Gandhi',
        'Nelson Mandela',
        'Martin Luther King Jr.',
        'Thomas Jefferson',
        'John Locke',
        'Niccolò Machiavelli',
      ],
    },
    {
      'title': 'Existential Currents',
      'subtitle': 'Meaning & absurdity',
      'authors': [
        'Albert Camus',
        'Jean-Paul Sartre',
        'Friedrich Nietzsche',
        'Søren Kierkegaard',
        'Simone de Beauvoir',
        'Martin Heidegger',
        'Fyodor Dostoevsky',
        'Franz Kafka',
      ],
    },
  ];

  static const List<Map<String, dynamic>> _periods = [
    {
      'title': 'Enlightenment',
      'range': '1680-1800',
      'start_year': 1680,
      'end_year': 1800,
    },
    {
      'title': 'Romanticism',
      'range': '1780-1850',
      'start_year': 1780,
      'end_year': 1850,
    },
    {
      'title': 'Victorian',
      'range': '1837-1901',
      'start_year': 1837,
      'end_year': 1901,
    },
    {
      'title': 'Modernism',
      'range': '1900-1945',
      'start_year': 1900,
      'end_year': 1945,
    },
    {
      'title': 'Contemporary',
      'range': '1945-Present',
      'start_year': 1945,
      'end_year': 2024,
    },
  ];

  List<Map<String, dynamic>> _getFilteredCollections() {
    final allAuthors = widget.allQuotes.map((q) => q.authorName).toSet();
    return _authorCollections.where((collection) {
      final authors = collection['authors'] as List<String>;
      return authors.any((author) => allAuthors.contains(author));
    }).toList();
  }

  Widget _buildPeriodsSection(BuildContext context) {
    final lbTheme = Theme.of(context).extension<LBTheme>();
    final cs = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Periods',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (!_periodFeatureAllowed) ...[
                        const SizedBox(width: 8),
                        const ProBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Explore quotes from different historical periods',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _periods.length,
                itemBuilder: (context, index) {
                  final period = _periods[index];
                  return SizedBox(
                    width: 160,
                    child: Card(
                      elevation: 0,
                      color: lbTheme?.controlSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color:
                              lbTheme?.controlBorder ??
                              Theme.of(
                                context,
                              ).colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          requireFeature(
                            context,
                            EntitlementsService.browsePeriod,
                            onAllowed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      BrowseByPeriodFilterPage(
                                        allQuotes: widget.allQuotes,
                                      ),
                                  settings: RouteSettings(
                                    arguments: {
                                      'selectedPeriod': period['title'],
                                      'startYear': period['start_year'],
                                      'endYear': period['end_year'],
                                    },
                                  ),
                                ),
                              );
                              // Handle the returned filter
                              if (result != null && context.mounted) {
                                Navigator.of(context).pop(result);
                              }
                            },
                            onBlocked: () => openPaywall(
                              context: context,
                              contextKey: 'browse_period',
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                period['title'] as String,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                period['range'] as String,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: cs.onSurface.withOpacity(0.6),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            _buildButtonCard(
              context,
              icon: Icons.timeline_outlined,
              title: 'Browse by Period',
              subtitle: 'Open the period collections',
              showGradientBorder: !_periodFeatureAllowed,
              onTap: () {
                requireFeature(
                  context,
                  EntitlementsService.browsePeriod,
                  onAllowed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BrowseByPeriodFilterPage(
                          allQuotes: widget.allQuotes,
                        ),
                      ),
                    );
                    // Handle the returned filter
                    if (result != null && context.mounted) {
                      Navigator.of(context).pop(result);
                    }
                  },
                  onBlocked: () => openPaywall(
                    context: context,
                    contextKey: 'browse_period',
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorCollectionGrid(BuildContext context) {
    final filteredCollections = _getFilteredCollections();
    final collectionsToShow = _showAllCollections
        ? filteredCollections
        : filteredCollections.take(4).toList();

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Author Collections',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (!_authorFeatureAllowed) ...[
                        const SizedBox(width: 8),
                        const ProBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Curated packs of writers',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: collectionsToShow.length,
              itemBuilder: (context, index) {
                final collection = collectionsToShow[index];
                return _buildCollectionTile(
                  context,
                  collection,
                  _authorFeatureAllowed,
                );
              },
            ),
            if (filteredCollections.length > 4)
              Padding(
                padding: const EdgeInsets.only(top: 12.0, right: 16.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _showAllCollections = !_showAllCollections;
                      });
                    },
                    child: Text(
                      _showAllCollections
                          ? 'Show less'
                          : '+ ${filteredCollections.length - 4} more collections',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionTile(
    BuildContext context,
    Map<String, dynamic> collection,
    bool isAllowed,
  ) {
    final lbTheme = Theme.of(context).extension<LBTheme>();
    final cs = Theme.of(context).colorScheme;
    final title = collection['title'] as String;
    final authors = List<String>.from(collection['authors'] as List);
    final preview = (authors.take(2).toList())..sort();
    final subtitle = 'Authors like ${preview.join(', ')}';

    final tileContent = SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 0,
        color: lbTheme?.controlSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: lbTheme?.controlBorder ?? cs.outline.withOpacity(0.2),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cs.primary.withOpacity(0.05),
                cs.secondary.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withOpacity(0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return GateOverlay(
      allowed: isAllowed,
      onBlocked: () =>
          openPaywall(context: context, contextKey: 'browse_author'),
      child: GestureDetector(
        onTap: isAllowed
            ? () async {
                final result = await Navigator.push<Set<String>>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BrowseByAuthorPage(
                      allQuotes: widget.allQuotes,
                      initialSelectedAuthors: authors.toSet(),
                    ),
                  ),
                );
                if (result != null && context.mounted) {
                  Navigator.of(context).pop({'authors': result});
                }
              }
            : null,
        child: tileContent,
      ),
    );
  }

  List<String> _getTopTags() {
    final Map<String, int> tagCounts = {};

    // 1. From favorites
    if (widget.favoriteQuotes.isNotEmpty) {
      for (var quote in widget.favoriteQuotes) {
        for (var tag in quote.tags) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }
    }

    // 2. Fallback to recently viewed
    if (tagCounts.isEmpty && widget.viewCounts.isNotEmpty) {
      // This is a simplified stand-in. A proper implementation
      // would need a list of recently viewed quote IDs.
      final viewedQuotes = widget.allQuotes
          .where((q) => widget.viewCounts.containsKey(q.id))
          .toList();
      viewedQuotes.sort(
        (a, b) => widget.viewCounts[b.id]!.compareTo(widget.viewCounts[a.id]!),
      );
      final recentQuotes = viewedQuotes.take(100);

      for (var quote in recentQuotes) {
        for (var tag in quote.tags) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }
    }

    // 3. Fallback to corpus counts
    if (tagCounts.isEmpty) {
      for (var quote in widget.allQuotes) {
        for (var tag in quote.tags) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }
    }

    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedTags.map((e) => e.key).take(5).toList();
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const FractionallySizedBox(
          heightFactor: 0.75,
          child: SettingsSheet(),
        );
      },
    );
  }
}
