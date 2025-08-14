import 'package:flutter/material.dart';
import 'package:quotes_app/quote.dart';

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
  'William Shakespeare',
  'Mark Twain',
  'Ernest Hemingway',
  'Jane Austen',
  'Charles Dickens',
  'Kurt Vonnegut',
  'Philip K. Dick',
  'Franz Kafka',
  'Simone de Beauvoir',
  'George Eliot', // Mary Ann Evans
  'Hermann Hesse',
  'Seneca',
  'Marcus Aurelius',
  'Epictetus',
];

class BrowseByAuthorPage extends StatefulWidget {
  final List<Quote> allQuotes;
  final Set<String> initialSelectedAuthors;

  const BrowseByAuthorPage({
    super.key,
    required this.allQuotes,
    required this.initialSelectedAuthors,
  });

  @override
  State<BrowseByAuthorPage> createState() => _BrowseByAuthorPageState();
}

class _BrowseByAuthorPageState extends State<BrowseByAuthorPage> {
  List<_Author> _allAuthors = [];
  List<_Author> _recommendedAuthors = [];
  List<_Author> _otherAuthors = [];
  List<_Author> _filteredAuthors = [];
  final Set<_Author> _selectedAuthors = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
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

    _selectedAuthors.addAll(
      _allAuthors.where(
        (author) => widget.initialSelectedAuthors.contains(author.name),
      ),
    );

    _searchController.addListener(() {
      _filterAuthors();
    });
  }

  @override
  void dispose() {
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Browse by Author',
          style: TextStyle(
            fontFamily: 'Georgia',
            color: Theme.of(context).primaryColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final selectedNames = _selectedAuthors.map((a) => a.name).toSet();
              Navigator.of(context).pop(selectedNames);
            },
            child: Text(
              'Done',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for an author...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).primaryColor.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _searchController.text.isNotEmpty
                  ? _buildFilteredAuthorList()
                  : _buildCategorizedAuthorList(),
            ),
          ],
        ),
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
        style: TextStyle(
          fontFamily: 'EBGaramond',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildAuthorTile(_Author author) {
    final isSelected = _selectedAuthors.contains(author);
    return ListTile(
      title: Text(
        author.name,
        style: TextStyle(
          fontFamily: 'EBGaramond',
          color: Theme.of(context).primaryColor,
        ),
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
        activeColor: Theme.of(context).primaryColor,
        checkColor: Theme.of(context).scaffoldBackgroundColor,
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
}
