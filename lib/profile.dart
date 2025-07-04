import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:animated_digit/animated_digit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'quote.dart';

class ProfilePage extends StatefulWidget {
  final int seenQuotesCount;
  final int favoriteQuotesCount;
  final List<Quote> favoriteQuotes;
  final List<Quote> seenQuotes;
  final bool isDarkMode;

  const ProfilePage({
    super.key,
    required this.seenQuotesCount,
    required this.favoriteQuotesCount,
    required this.favoriteQuotes,
    required this.seenQuotes,
    required this.isDarkMode,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _quizzesCompleted = 0;
  double _averageScore = 0.0;
  bool _personalizedSuggestions = true;

  @override
  void initState() {
    super.initState();
    _loadProfileStats();
    _loadSettings();
  }

  Future<void> _loadProfileStats() async {
    final prefs = await SharedPreferences.getInstance();
    final quizzesCompleted = prefs.getInt('quizzesCompleted') ?? 0;
    final totalCorrect = prefs.getInt('totalCorrectAnswers') ?? 0;
    final totalAnswered = prefs.getInt('totalQuestionsAnswered') ?? 0;

    setState(() {
      _quizzesCompleted = quizzesCompleted;
      _averageScore = totalAnswered > 0
          ? (totalCorrect / totalAnswered) * 100
          : 0.0;
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _personalizedSuggestions =
          prefs.getBool('personalizedSuggestions') ?? true;
    });
  }

  Future<void> _updatePersonalizedSuggestions(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('personalizedSuggestions', value);
    setState(() {
      _personalizedSuggestions = value;
    });
  }

  List<String> _getTopItems(
    List<Quote> quotes,
    dynamic Function(Quote) getter, {
    int count = 3,
  }) {
    if (quotes.isEmpty) return [];
    final allItems = quotes
        .expand((q) {
          final value = getter(q);
          if (value is List<String>) {
            return value;
          } else if (value is String) {
            return [value];
          }
          return <String>[];
        })
        .where((item) => item.isNotEmpty)
        .toList();

    if (allItems.isEmpty) return [];

    final itemCounts = allItems.groupFoldBy<String, int>(
      (item) => item,
      (previous, item) => (previous ?? 0) + 1,
    );

    final sortedItems = itemCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedItems.map((e) => e.key).take(count).toList();
  }

  @override
  Widget build(BuildContext context) {
    final topFavoriteThemes = _getTopItems(
      widget.favoriteQuotes,
      (q) => q.themes,
    );
    final topSeenThemes = _getTopItems(widget.seenQuotes, (q) => q.themes);
    final topAuthors = _getTopItems(widget.favoriteQuotes, (q) => q.authorInfo);

    return Scaffold(
      backgroundColor: widget.isDarkMode
          ? Colors.black
          : const Color.fromARGB(255, 240, 234, 225),
      appBar: AppBar(
        title: Text(
          'Your Literary Profile',
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black,
            fontFamily: 'Georgia',
          ),
        ),
        backgroundColor: widget.isDarkMode
            ? Colors.black
            : const Color.fromARGB(255, 240, 234, 225),
        elevation: 0,
        iconTheme: IconThemeData(
          color: widget.isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SwitchListTile(
            title: Text(
              'Personalized Suggestions',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 21,
                foreground: Paint()
                  ..shader = const LinearGradient(
                    colors: [Colors.purpleAccent, Colors.blueAccent],
                  ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
              ),
            ),
            subtitle: Text(
              'See Quotes picked for you based on your preferences. Suggestions improve as you like more quotes.',
              style: TextStyle(
                fontFamily: 'Georgia',
                color: widget.isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            value: _personalizedSuggestions,
            onChanged: (bool value) {
              _updatePersonalizedSuggestions(value);
            },
            activeColor: Colors.blueAccent,
          ),
          const SizedBox(height: 12),
          const Divider(thickness: 1.2),
          const SizedBox(height: 16),
          FadeInUp(
            duration: const Duration(milliseconds: 400),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Quotes Seen',
                    widget.seenQuotesCount,
                    Icons.visibility_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Favorited',
                    widget.favoriteQuotesCount,
                    Icons.favorite_outline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (_quizzesCompleted > 0)
            FadeInUp(
              duration: const Duration(milliseconds: 400),
              delay: const Duration(milliseconds: 100),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Quizzes Done',
                      _quizzesCompleted,
                      Icons.quiz_outlined,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Average Score',
                      _averageScore.round(),
                      Icons.star_border_outlined,
                      isPercentage: true,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          if (topFavoriteThemes.isNotEmpty)
            FadeInUp(
              duration: const Duration(milliseconds: 400),
              delay: const Duration(milliseconds: 200),
              child: _buildListCard(
                context,
                'Your Favorite Themes',
                topFavoriteThemes,
                Icons.palette_outlined,
              ),
            ),
          const SizedBox(height: 10),
          if (topAuthors.isNotEmpty)
            FadeInUp(
              duration: const Duration(milliseconds: 400),
              delay: const Duration(milliseconds: 300),
              child: _buildListCard(
                context,
                'Your Top Authors',
                topAuthors,
                Icons.edit_outlined,
              ),
            ),
          const SizedBox(height: 10),
          if (topSeenThemes.isNotEmpty)
            FadeInUp(
              duration: const Duration(milliseconds: 400),
              delay: const Duration(milliseconds: 400),
              child: _buildListCard(
                context,
                'Most Explored Themes',
                topSeenThemes,
                Icons.explore_outlined,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    int value,
    IconData icon, {
    bool isPercentage = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? Colors.grey[850] : Colors.white,
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
          Icon(
            icon,
            size: 28,
            color: widget.isDarkMode ? Colors.white70 : Colors.black54,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AnimatedDigitWidget(
                value: value,
                textStyle: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Georgia',
                  color: widget.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              if (isPercentage)
                Text(
                  '%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Georgia',
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              color: widget.isDarkMode ? Colors.white70 : Colors.black87,
              fontFamily: 'Georgia',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard(
    BuildContext context,
    String title,
    List<String> items,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? Colors.grey[850] : Colors.white,
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
          Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: widget.isDarkMode ? Colors.white70 : Colors.black54,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Georgia',
                  color: widget.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 6,
                    color: widget.isDarkMode ? Colors.white38 : Colors.black38,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: 'Georgia',
                        color: widget.isDarkMode
                            ? Colors.white.withOpacity(0.9)
                            : Colors.black.withOpacity(0.9),
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
}
