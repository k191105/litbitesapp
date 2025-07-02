import 'package:flutter/material.dart';
import 'package:quotes_app/author_quiz_page.dart';
import 'package:quotes_app/flashcards_page.dart';
import 'package:quotes_app/quiz_page.dart';
import 'package:quotes_app/quote_quiz_page.dart';
import 'quote.dart';

class LearnHubPage extends StatelessWidget {
  final bool isDarkMode;
  final List<Quote> allQuotes;
  final List<Quote> favoriteQuotes;

  const LearnHubPage({
    super.key,
    required this.isDarkMode,
    required this.allQuotes,
    required this.favoriteQuotes,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode
          ? Colors.black
          : const Color.fromARGB(255, 240, 234, 225),
      appBar: AppBar(
        title: Text(
          'Learn',
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
          _buildQuizCard(context),
          const SizedBox(height: 16),
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
                description: 'Review quotes and authors.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FlashcardsPage(
                        favoriteQuotes: favoriteQuotes,
                        isDarkMode: isDarkMode,
                      ),
                    ),
                  );
                },
                isDarkMode: isDarkMode,
              ),
              _buildLearnModeCard(
                context,
                icon: Icons.person_search,
                title: 'Author Details',
                description: 'Test your knowledge of authors.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AuthorQuizPage(
                        favoriteQuotes: favoriteQuotes,
                        allQuotes: allQuotes,
                        isDarkMode: isDarkMode,
                      ),
                    ),
                  );
                },
                isDarkMode: isDarkMode,
              ),
              _buildLearnModeCard(
                context,
                icon: Icons.format_quote,
                title: 'Quote Quizzes',
                description: 'Identify authors and sources.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuoteQuizPage(
                        favoriteQuotes: favoriteQuotes,
                        allQuotes: allQuotes,
                        isDarkMode: isDarkMode,
                      ),
                    ),
                  );
                },
                isDarkMode: isDarkMode,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCard(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizPage(
                isDarkMode: isDarkMode,
                allQuotes: allQuotes,
                favoriteQuotes: favoriteQuotes,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purpleAccent.withOpacity(0.8),
                Colors.blueAccent.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.quiz, color: Colors.white, size: 40),
              SizedBox(height: 16),
              Text(
                'Comprehensive Quiz',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'A 20-question challenge synthesizing all topics.',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLearnModeCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDarkMode ? Colors.grey[850] : Colors.white,
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
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
              Column(
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
                    description,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 14,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
