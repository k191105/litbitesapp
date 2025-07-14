import 'package:flutter/material.dart';
import 'quote.dart';

class _Author implements Comparable<_Author> {
  final String name;
  final int score;

  const _Author({required this.name, required this.score});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _Author &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  int compareTo(_Author other) {
    if (other.score == score) {
      return name.compareTo(other.name);
    }
    return other.score.compareTo(score);
  }
}

class OnboardingPage extends StatefulWidget {
  final List<Quote> allQuotes;
  const OnboardingPage({super.key, required this.allQuotes});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

const List<String> _curatedAuthors = [
  'Albert Camus',
  'Oscar Wilde',
  'Bertrand Russell',
  'Friedrich Nietzsche',
  'Jean-Paul Sartre',
  'Fyodor Dostoevsky',
  'Leo Tolstoy',
  'George Orwell',
  'Aldous Huxley',
  'Virginia Woolf',
  'James Joyce',
  'Ernest Hemingway',
  'Jane Austen',
  'Charles Dickens',
  'Kurt Vonnegut',
  'Philip K. Dick',
  'Franz Kafka',
  'Simone de Beauvoir',
  'Hermann Hesse',
];

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String? _selectedFrequency;
  List<String> _allTags = [];
  final Set<String> _selectedTags = {};
  List<_Author> _allAuthors = [];
  List<_Author> _recommendedAuthors = [];
  List<_Author> _otherAuthors = [];
  List<_Author> _filteredAuthors = [];
  final Set<_Author> _selectedAuthors = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _allTags = widget.allQuotes.expand((quote) => quote.tags).toSet().toList()
      ..sort();

    final Map<String, int> authorScores = {};
    for (var quote in widget.allQuotes) {
      final authorName = quote.authorName;
      final authorScore = quote.author_score ?? 0;
      if (!authorScores.containsKey(authorName) ||
          authorScores[authorName]! < authorScore) {
        authorScores[authorName] = authorScore;
      }
    }
    _allAuthors =
        authorScores.entries
            .map((entry) => _Author(name: entry.key, score: entry.value))
            .toList()
          ..sort();

    _recommendedAuthors = _allAuthors
        .where((author) => _curatedAuthors.contains(author.name))
        .toList();
    _otherAuthors = _allAuthors
        .where((author) => !_curatedAuthors.contains(author.name))
        .toList();

    _recommendedAuthors.sort();
    _otherAuthors.sort();

    _filteredAuthors = _allAuthors;

    _searchController.addListener(() {
      _filterAuthors();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterAuthors() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredAuthors = _allAuthors
          .where((author) => author.name.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 240, 234, 225),
      body: PageView(
        controller: _pageController,
        onPageChanged: (int page) {
          setState(() {
            _currentPage = page;
          });
        },
        children: [_buildWelcomePage(), _buildTagsPage(), _buildAuthorsPage()],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 2),
          Text(
            'Welcome to',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontFamily: 'EBGaramond',
              color: Colors.grey[600],
            ),
          ),
          const Text(
            'Literature Bites',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 40,
              fontFamily: 'EBGaramond',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Discover timeless wisdom from the world\'s greatest minds. Let\'s personalize your experience.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'EBGaramond',
              height: 1.5,
            ),
          ),
          const Spacer(flex: 1),
          Text(
            'How often do you read?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'EBGaramond',
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          _buildChoiceChip("Just starting"),
          const SizedBox(height: 12),
          _buildChoiceChip("Casually"),
          const SizedBox(height: 12),
          _buildChoiceChip("I'm an avid reader!"),
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String label) {
    final bool isSelected = _selectedFrequency == label;
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _selectedFrequency = label;
        });
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        side: BorderSide(
          color: isSelected ? Colors.black : Colors.grey[300]!,
          width: isSelected ? 1.5 : 1,
        ),
        backgroundColor: isSelected ? Colors.black.withOpacity(0.05) : null,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'EBGaramond',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildTagsPage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 1),
          const Text(
            'What do you like to read?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontFamily: 'EBGaramond',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Select a few genres to help us recommend quotes you\'ll love. You can change this any time.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'EBGaramond',
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 12.0,
                runSpacing: 12.0,
                alignment: WrapAlignment.center,
                children: _allTags.map((tag) => _buildTagChip(tag)).toList(),
              ),
            ),
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }

  Widget _buildAuthorsPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 1),
          const Text(
            'Any favorite authors?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontFamily: 'EBGaramond',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'This helps us find quotes from writers you already enjoy.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'EBGaramond',
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for an author...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.black.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            flex: 5,
            child: _searchController.text.isNotEmpty
                ? _buildFilteredAuthorList()
                : _buildCategorizedAuthorList(),
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }

  Widget _buildFilteredAuthorList() {
    return ListView.builder(
      itemCount: _filteredAuthors.length,
      itemBuilder: (context, index) {
        return _buildAuthorTile(_filteredAuthors[index]);
      },
    );
  }

  Widget _buildCategorizedAuthorList() {
    final itemCount =
        _recommendedAuthors.length +
        _otherAuthors.length +
        (_otherAuthors.isNotEmpty ? 2 : 1);

    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Recommended Header
        if (index == 0) {
          return _buildSectionHeader('Recommended Authors');
        }
        // Recommended List
        if (index <= _recommendedAuthors.length) {
          final author = _recommendedAuthors[index - 1];
          return _buildAuthorTile(author);
        }
        // All Authors Header
        if (_otherAuthors.isNotEmpty &&
            index == _recommendedAuthors.length + 1) {
          return _buildSectionHeader('All Authors');
        }
        // All Authors List
        final author = _otherAuthors[index - _recommendedAuthors.length - 2];
        return _buildAuthorTile(author);
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'EBGaramond',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildAuthorTile(_Author author) {
    final isSelected = _selectedAuthors.contains(author);
    return ListTile(
      title: Text(
        author.name,
        style: const TextStyle(fontFamily: 'EBGaramond'),
      ),
      trailing: Checkbox(
        value: isSelected,
        onChanged: (bool? value) {
          setState(() {
            if (value == true) {
              _selectedAuthors.add(author);
            } else {
              _selectedAuthors.remove(author);
            }
          });
        },
        activeColor: Colors.black,
      ),
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedAuthors.remove(author);
          } else {
            _selectedAuthors.add(author);
          }
        });
      },
    );
  }

  Widget _buildTagChip(String tag) {
    final bool isSelected = _selectedTags.contains(tag);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedTags.remove(tag);
          } else {
            _selectedTags.add(tag);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30.0),
        ),
        child: Text(
          tag,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontSize: 14.0,
            fontWeight: FontWeight.w500,
            fontFamily: 'EBGaramond',
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      height: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () {
              // Skip onboarding
              Navigator.of(context).pop();
            },
            child: const Text(
              'Skip',
              style: TextStyle(
                color: Colors.grey,
                fontFamily: 'EBGaramond',
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_currentPage < 2) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              } else {
                // Finish onboarding
                final OnboardingResult result = OnboardingResult(
                  selectedTags: _selectedTags,
                  selectedAuthors: _selectedAuthors.map((a) => a.name).toSet(),
                );
                Navigator.of(context).pop(result);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: Text(
              _currentPage == 2 ? 'Finish' : 'Next',
              style: const TextStyle(
                fontFamily: 'EBGaramond',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingResult {
  final Set<String> selectedTags;
  final Set<String> selectedAuthors;

  OnboardingResult({required this.selectedTags, required this.selectedAuthors});
}
