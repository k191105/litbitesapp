import 'package:flutter/material.dart';

class ActiveFiltersBar extends StatelessWidget {
  final Set<String> selectedTags;
  final Set<String> selectedAuthors;
  final Map<String, dynamic>? periodFilter;
  final bool isFavoritesMode;
  final VoidCallback onClear;

  const ActiveFiltersBar({
    super.key,
    required this.selectedTags,
    required this.selectedAuthors,
    this.periodFilter,
    required this.isFavoritesMode,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      if (isFavoritesMode) 'Favorites',
      ...selectedTags,
      ...selectedAuthors,
      if (periodFilter != null)
        '${periodFilter!['start_year']}-${periodFilter!['end_year']}',
    ];

    if (filters.isEmpty) {
      return Container();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Theme.of(context).bottomAppBarTheme.color?.withOpacity(0.8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 8.0,
                children: filters.map((filter) {
                  return Chip(
                    label: Text(filter),
                    backgroundColor: Theme.of(
                      context,
                    ).chipTheme.backgroundColor,
                  );
                }).toList(),
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.clear), onPressed: onClear),
        ],
      ),
    );
  }
}
