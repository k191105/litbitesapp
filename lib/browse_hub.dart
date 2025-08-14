import 'package:flutter/material.dart';
import 'package:quotes_app/browse.dart';
import 'package:quotes_app/browse_by_author.dart';
import 'package:quotes_app/browse_by_period.dart';
import 'package:quotes_app/quote.dart';
import 'package:quotes_app/services/entitlements_service.dart';
import 'package:quotes_app/utils/feature_gate.dart';

class BrowseHubPage extends StatelessWidget {
  final List<Quote> allQuotes;
  final Set<String> initialSelectedTags;
  final Set<String> initialSelectedAuthors;

  const BrowseHubPage({
    super.key,
    required this.allQuotes,
    required this.initialSelectedTags,
    required this.initialSelectedAuthors,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Browse',
          style: TextStyle(
            fontFamily: 'Georgia',
            color: Theme.of(context).primaryColor,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildBrowseCard(
            context,
            icon: Icons.search_outlined,
            title: 'Search Quotes',
            description: 'Find quotes with direct search.',
            onTap: () {
              requireFeature(
                context,
                EntitlementsService.search,
                onAllowed: () {
                  _showSearchPlaceholder(context);
                },
                onBlocked: () {
                  openPaywall(context: context, contextKey: 'search');
                },
              );
            },
            enabled: true,
          ),
          const SizedBox(height: 16),
          _buildBrowseCard(
            context,
            icon: Icons.sell_outlined,
            title: 'Browse by Tags',
            description: 'Filter quotes by specific tags.',
            onTap: () {
              requireFeature(
                context,
                EntitlementsService.browseTags,
                onAllowed: () async {
                  final selectedTags = await Navigator.push<Set<String>>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BrowsePage(
                        allQuotes: allQuotes,
                        initialSelectedTags: initialSelectedTags,
                      ),
                    ),
                  );
                  if (selectedTags != null && context.mounted) {
                    Navigator.pop(context, {'tags': selectedTags});
                  }
                },
                onBlocked: () {
                  openPaywall(context: context, contextKey: 'browse_tags');
                },
              );
            },
            enabled: true,
          ),
          const SizedBox(height: 16),
          _buildBrowseCard(
            context,
            icon: Icons.person_search_outlined,
            title: 'Browse by Author',
            description: 'Find all quotes from a specific author.',
            onTap: () async {
              final selectedAuthors = await Navigator.push<Set<String>>(
                context,
                MaterialPageRoute(
                  builder: (context) => BrowseByAuthorPage(
                    allQuotes: allQuotes,
                    initialSelectedAuthors: initialSelectedAuthors,
                  ),
                ),
              );
              if (selectedAuthors != null && context.mounted) {
                Navigator.pop(context, {'authors': selectedAuthors});
              }
            },
            enabled: true,
          ),
          const SizedBox(height: 16),
          _buildBrowseCard(
            context,
            icon: Icons.history_edu_outlined,
            title: 'Browse by Period',
            description: 'Explore quotes from different historical periods.',
            onTap: () {
              requireFeature(
                context,
                EntitlementsService.browsePeriod,
                onAllowed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          BrowseByPeriodPage(allQuotes: allQuotes),
                    ),
                  );
                },
                onBlocked: () {
                  openPaywall(context: context, contextKey: 'browse_period');
                },
              );
            },
            enabled: true,
          ),
        ],
      ),
    );
  }

  void _showSearchPlaceholder(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
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
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Icon(
                Icons.search_outlined,
                size: 48,
                color: Theme.of(context).primaryColor.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              Text(
                'Search Coming Soon',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Direct quote search is in development and will be available in the next update.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).primaryColor.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Got it'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBrowseCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Card(
        elevation: enabled ? 2 : 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Theme.of(context).cardColor,
        child: InkWell(
          onTap: enabled
              ? onTap
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('This feature is coming soon!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 36,
                  color: Theme.of(context).primaryColor.withOpacity(0.7),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        enabled ? description : 'Coming soon!',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 14,
                          fontStyle: enabled
                              ? FontStyle.normal
                              : FontStyle.italic,
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
