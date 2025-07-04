import 'package:flutter/material.dart';
import 'package:quotes_app/author_quotes_page.dart';
import 'package:quotes_app/quote.dart';

class BrowseByAuthorPage extends StatefulWidget {
  final List<Quote> allQuotes;
  final bool isDarkMode;

  const BrowseByAuthorPage({
    super.key,
    required this.allQuotes,
    required this.isDarkMode,
  });

  @override
  State<BrowseByAuthorPage> createState() => _BrowseByAuthorPageState();
}

class _BrowseByAuthorPageState extends State<BrowseByAuthorPage> {
  late Map<String, List<Quote>> _quotesByAuthor;
  List<String> _authors = [];

  @override
  void initState() {
    super.initState();
    _groupQuotesByAuthor();
  }

  void _groupQuotesByAuthor() {
    final Map<String, List<Quote>> authorMap = {};
    for (final quote in widget.allQuotes) {
      final authorName = quote.authorInfo;
      if (authorMap.containsKey(authorName)) {
        authorMap[authorName]!.add(quote);
      } else {
        authorMap[authorName] = [quote];
      }
    }
    _quotesByAuthor = authorMap;
    _authors = authorMap.keys.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode
          ? Colors.black
          : const Color.fromARGB(255, 240, 234, 225),
      appBar: AppBar(
        title: Text(
          'Browse by Author',
          style: TextStyle(
            fontFamily: 'Georgia',
            color: widget.isDarkMode ? Colors.white : Colors.black,
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
      body: ListView.builder(
        itemCount: _authors.length,
        itemBuilder: (context, index) {
          final author = _authors[index];
          final quoteCount = _quotesByAuthor[author]!.length;
          return ListTile(
            title: Text(
              author,
              style: TextStyle(
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w600,
                color: widget.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            subtitle: Text(
              '$quoteCount quote${quoteCount > 1 ? 's' : ''}',
              style: TextStyle(
                fontFamily: 'Georgia',
                color: widget.isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AuthorQuotesPage(
                    authorName: author,
                    quotes: _quotesByAuthor[author]!,
                    isDarkMode: widget.isDarkMode,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
