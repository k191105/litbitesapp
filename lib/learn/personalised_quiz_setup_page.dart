import 'package:flutter/material.dart';
import 'package:quotes_app/quote.dart';

class PersonalisedQuizConfig {
  final int length;
  final Set<String> quoteIds;

  PersonalisedQuizConfig({required this.length, required this.quoteIds});
}

class PersonalisedQuizSetupPage extends StatefulWidget {
  final List<Quote> favoriteQuotes;

  const PersonalisedQuizSetupPage({super.key, required this.favoriteQuotes});

  @override
  State<PersonalisedQuizSetupPage> createState() =>
      _PersonalisedQuizSetupPageState();
}

class _PersonalisedQuizSetupPageState extends State<PersonalisedQuizSetupPage> {
  int _length = 10;
  final Set<String> _selectedQuoteIds = {};
  final Set<String> _selectedTags = {};
  final Set<String> _selectedPeriods = {};

  @override
  void initState() {
    super.initState();
    _preselectQuotes();
  }

  void _preselectQuotes() {
    final filteredQuotes = _getFilteredQuotes();
    filteredQuotes.shuffle();
    setState(() {
      _selectedQuoteIds.clear();
      _selectedQuoteIds.addAll(filteredQuotes.take(_length).map((q) => q.id));
    });
  }

  List<Quote> _getFilteredQuotes() {
    return widget.favoriteQuotes.where((quote) {
      final tagMatch =
          _selectedTags.isEmpty ||
          quote.tags.any((tag) => _selectedTags.contains(tag));
      final periodMatch =
          _selectedPeriods.isEmpty || _selectedPeriods.contains(quote.period);
      return tagMatch && periodMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configure Quiz'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12.0),
        children: [
          _buildLengthSelector(),
          const SizedBox(height: 12),
          _buildFilterSection(
            title: 'Filter by Tag',
            chips: [
              'Any',
              ...widget.favoriteQuotes.expand((q) => q.tags).toSet(),
            ],
            selectedValues: _selectedTags,
            onSelected: (value) {
              setState(() {
                if (value == 'Any') {
                  _selectedTags.clear();
                } else {
                  if (_selectedTags.contains(value)) {
                    _selectedTags.remove(value);
                  } else {
                    _selectedTags.add(value);
                  }
                }
              });
              _preselectQuotes();
            },
          ),
          const SizedBox(height: 8),
          _buildFilterSection(
            title: 'Filter by Period',
            chips: [
              'Any',
              'Enlightenment',
              'Romanticism',
              'Victorian',
              'Modernism',
              'Contemporary',
            ],
            selectedValues: _selectedPeriods,
            onSelected: (value) {
              setState(() {
                if (value == 'Any') {
                  _selectedPeriods.clear();
                } else {
                  if (_selectedPeriods.contains(value)) {
                    _selectedPeriods.remove(value);
                  } else {
                    _selectedPeriods.add(value);
                  }
                }
              });
              _preselectQuotes();
            },
          ),
          const SizedBox(height: 12),
          _buildQuoteSelector(),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            final config = PersonalisedQuizConfig(
              length: _selectedQuoteIds.length,
              quoteIds: _selectedQuoteIds,
            );
            Navigator.of(context).pop(config);
          },
          child: const Text('Start Quiz'),
        ),
      ),
    );
  }

  Widget _buildLengthSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Length', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          children:
              [5, 10, 20].map((length) {
                bool canSelect = widget.favoriteQuotes.length >= length;
                return ChoiceChip(
                  label: Text('$length Questions'),
                  selected: _length == length,
                  onSelected: canSelect
                      ? (selected) {
                          if (selected) {
                            setState(() => _length = length);
                            _preselectQuotes();
                          }
                        }
                      : null,
                );
              }).toList()..add(
                ChoiceChip(
                  label: const Text('Custom'),
                  selected: ![5, 10, 20].contains(_selectedQuoteIds.length),
                  onSelected: (selected) {},
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildFilterSection({
    required String title,
    required List<String> chips,
    required Set<String> selectedValues,
    required ValueChanged<String> onSelected,
  }) {
    return ExpansionTile(
      title: Text(title),
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(
            spacing: 8.0,
            children: chips.map((value) {
              final bool isAny = value == 'Any';
              final bool isSelected = isAny
                  ? selectedValues.isEmpty
                  : selectedValues.contains(value);
              return FilterChip(
                label: Text(value),
                selected: isSelected,
                onSelected: (selected) {
                  onSelected(value);
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildQuoteSelector() {
    final selectedQuotes = widget.favoriteQuotes
        .where((q) => _selectedQuoteIds.contains(q.id))
        .toList();
    final unselectedQuotes = widget.favoriteQuotes
        .where((q) => !_selectedQuoteIds.contains(q.id))
        .toList();

    return Column(
      children: [
        ExpansionTile(
          title: Text('Selected Quotes (${selectedQuotes.length})'),
          initiallyExpanded: true,
          children: selectedQuotes
              .map((quote) => _buildQuoteTile(quote))
              .toList(),
        ),
        ExpansionTile(
          title: const Text('Add from Favorites'),
          children: unselectedQuotes
              .map((quote) => _buildQuoteTile(quote))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildQuoteTile(Quote quote) {
    return CheckboxListTile(
      title: Text(quote.text, maxLines: 2),
      value: _selectedQuoteIds.contains(quote.id),
      onChanged: (value) {
        setState(() {
          if (value ?? false) {
            _selectedQuoteIds.add(quote.id);
          } else {
            _selectedQuoteIds.remove(quote.id);
          }
        });
      },
    );
  }
}
