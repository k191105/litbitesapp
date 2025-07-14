import 'package:flutter/material.dart';
import 'package:quotes_app/browse.dart';
import 'package:quotes_app/browse_by_author.dart';
import 'package:quotes_app/browse_by_period.dart';
import 'package:quotes_app/quote.dart';

class BrowseHubPage extends StatelessWidget {
  final bool isDarkMode;
  final List<Quote> allQuotes;
  final Set<String> initialSelectedTags;
  final Set<String> initialSelectedAuthors;

  const BrowseHubPage({
    super.key,
    required this.isDarkMode,
    required this.allQuotes,
    required this.initialSelectedTags,
    required this.initialSelectedAuthors,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode
          ? Colors.black
          : const Color.fromARGB(255, 240, 234, 225),
      appBar: AppBar(
        title: Text(
          'Browse',
          style: TextStyle(
            fontFamily: 'Georgia',
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: isDarkMode
            ? Colors.black
            : const Color.fromARGB(255, 240, 234, 225),
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildBrowseCard(
            context,
            icon: Icons.sell_outlined,
            title: 'Browse by Tags',
            description: 'Filter quotes by specific tags.',
            onTap: () async {
              final selectedTags = await Navigator.push<Set<String>>(
                context,
                MaterialPageRoute(
                  builder: (context) => BrowsePage(
                    allQuotes: allQuotes,
                    initialSelectedTags: initialSelectedTags,
                    isDarkMode: isDarkMode,
                  ),
                ),
              );
              if (selectedTags != null && context.mounted) {
                Navigator.pop(context, {'tags': selectedTags});
              }
            },
            isDarkMode: isDarkMode,
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
                    isDarkMode: isDarkMode,
                  ),
                ),
              );
              if (selectedAuthors != null && context.mounted) {
                Navigator.pop(context, {'authors': selectedAuthors});
              }
            },
            isDarkMode: isDarkMode,
            enabled: true,
          ),
          const SizedBox(height: 16),
          _buildBrowseCard(
            context,
            icon: Icons.history_edu_outlined,
            title: 'Browse by Period',
            description: 'Explore quotes from different historical periods.',
            onTap: () {},
            isDarkMode: isDarkMode,
            enabled: false,
          ),
        ],
      ),
    );
  }

  Widget _buildBrowseCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    required bool isDarkMode,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Card(
        elevation: enabled ? 2 : 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: isDarkMode ? Colors.grey[850] : Colors.white,
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
                  color: isDarkMode ? Colors.white70 : Colors.black54,
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
                          color: isDarkMode ? Colors.white : Colors.black,
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
                          color: isDarkMode ? Colors.white70 : Colors.black87,
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
