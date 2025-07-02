import 'package:flutter/material.dart';
import 'quote.dart';

class BrowsePage extends StatefulWidget {
  final List<Quote> allQuotes;
  final Set<String> initialSelectedTags;
  final bool isDarkMode;

  const BrowsePage({
    super.key,
    required this.allQuotes,
    required this.initialSelectedTags,
    required this.isDarkMode,
  });

  @override
  BrowsePageState createState() => BrowsePageState();
}

class BrowsePageState extends State<BrowsePage> {
  late Set<String> _selectedTags;
  List<String> _allTags = [];
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _selectedTags = Set.from(widget.initialSelectedTags);
    _extractAllTags();
  }

  void _extractAllTags() {
    final Set<String> uniqueTags = {};
    for (final quote in widget.allQuotes) {
      uniqueTags.addAll(quote.tags);
    }
    _allTags = uniqueTags.toList()..sort();
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  void _clearAllTags() {
    setState(() {
      _selectedTags.clear();
    });
  }

  void _findQuotes() {
    Navigator.pop(context, _selectedTags);
  }

  Widget _buildTagItem(String tag) {
    final bool isSelected = _selectedTags.contains(tag);
    final int quotesWithTag = widget.allQuotes
        .where((quote) => quote.tags.contains(tag))
        .length;

    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected
          ? (_isDarkMode
                ? Colors.white.withOpacity(0.15)
                : Colors.black.withOpacity(0.1))
          : (_isDarkMode ? Colors.grey[800] : Colors.white),
      child: ListTile(
        leading: IconButton(
          icon: Icon(
            isSelected ? Icons.remove_circle : Icons.add_circle_outline,
            color: isSelected
                ? (_isDarkMode ? Colors.white : Colors.black)
                : (_isDarkMode ? Colors.white70 : Colors.grey[600]),
          ),
          onPressed: () => _toggleTag(tag),
        ),
        title: Text(
          tag,
          style: TextStyle(
            fontFamily: 'Georgia',
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: _isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        onTap: () => _toggleTag(tag),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = widget.isDarkMode;
    final filteredQuotesCount = _getFilteredQuotesCount();
    final findButtonDisabled =
        _selectedTags.isNotEmpty && filteredQuotesCount == 0;

    return Scaffold(
      backgroundColor: _isDarkMode
          ? Colors.black
          : const Color.fromARGB(255, 240, 234, 225),
      appBar: AppBar(
        title: Text(
          'Browse Tags',
          style: TextStyle(
            color: _isDarkMode ? Colors.white : Colors.black,
            fontFamily: 'Georgia',
          ),
        ),
        backgroundColor: _isDarkMode
            ? Colors.black
            : const Color.fromARGB(255, 240, 234, 225),
        elevation: 0,
        iconTheme: IconThemeData(
          color: _isDarkMode ? Colors.white : Colors.black,
        ),
        actions: [
          if (_selectedTags.isNotEmpty)
            TextButton(
              onPressed: _clearAllTags,
              child: Text(
                'Clear All',
                style: TextStyle(
                  color: _isDarkMode ? Colors.white70 : Colors.black87,
                  fontFamily: 'Georgia',
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Header section with selected tags count
          if (_selectedTags.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: _isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: _isDarkMode
                      ? Colors.white.withOpacity(0.3)
                      : Colors.black.withOpacity(0.1),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '${_selectedTags.length} tag${_selectedTags.length == 1 ? '' : 's'} selected',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _isDarkMode ? Colors.white : Colors.black,
                      fontFamily: 'Georgia',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: _selectedTags.map((tag) {
                      return Chip(
                        label: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 12,
                            color: _isDarkMode ? Colors.white : Colors.black,
                            fontFamily: 'Georgia',
                          ),
                        ),
                        backgroundColor: _isDarkMode
                            ? Colors.white.withOpacity(0.2)
                            : Colors.black.withOpacity(0.1),
                        deleteIcon: Icon(
                          Icons.close,
                          size: 16,
                          color: _isDarkMode ? Colors.white : Colors.black,
                        ),
                        onDeleted: () => _toggleTag(tag),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Select tags to filter quotes. You can choose multiple tags to find quotes that contain all selected tags.',
              style: TextStyle(
                fontSize: 14,
                color: _isDarkMode ? Colors.white70 : Colors.black87,
                fontFamily: 'Georgia',
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),

          // Tags list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _allTags.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: _buildTagItem(_allTags[index]),
                );
              },
            ),
          ),

          // Find button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: findButtonDisabled ? null : _findQuotes,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isDarkMode
                    ? Colors.white.withOpacity(0.9)
                    : Colors.black.withOpacity(0.9),
                foregroundColor: _isDarkMode ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: Text(
                findButtonDisabled
                    ? 'Find Quotes (0)'
                    : (_selectedTags.isEmpty
                          ? 'Show All Quotes'
                          : 'Find Quotes ($filteredQuotesCount)'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Georgia',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getFilteredQuotesCount() {
    if (_selectedTags.isEmpty) return widget.allQuotes.length;

    return widget.allQuotes.where((quote) {
      return _selectedTags.every(
        (selectedTag) => quote.tags.contains(selectedTag),
      );
    }).length;
  }
}
