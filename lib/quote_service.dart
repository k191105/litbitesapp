import 'dart:convert';
import 'package:flutter/services.dart';
import 'quote.dart';

class QuoteService {
  static List<Quote>? _cachedQuotes;

  static Future<List<Quote>> loadQuotes() async {
    if (_cachedQuotes != null) {
      return _cachedQuotes!;
    }

    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/quotes.json',
      );
      final dynamic decoded = json.decode(jsonString);

      if (decoded is! List) {
        throw FormatException(
          'Top-level JSON must be a List, got ${decoded.runtimeType}',
        );
      }

      final List<dynamic> parsed = decoded;
      final List<Quote> result = [];

      for (var i = 0; i < parsed.length; i++) {
        final entry = parsed[i];
        try {
          if (entry is Map<String, dynamic>) {
            result.add(Quote.fromJson(entry));
          } else if (entry is Map) {
            // Handle Map<dynamic, dynamic> by creating a typed map
            result.add(Quote.fromJson(Map<String, dynamic>.from(entry)));
          } else {
            // Non-object element — warn and skip
            print(
              'Skipping element at index $i: expected object, got ${entry.runtimeType}',
            );
          }
        } catch (e) {
          final id = (entry is Map) ? entry['id'] : null;
          print(
            'Failed to parse quote at index $i${id != null ? " (id: $id)" : ""}: $e',
          );
          // Uncomment to see stack trace if needed
          // print(st);
          continue; // keep current behavior: bail out so you notice the bad item
        }
      }

      _cachedQuotes = result;
      return _cachedQuotes!;
    } catch (e) {
      print('Error loading quotes: $e');
      return [];
    }
  }

  static List<Quote> searchQuotes(List<Quote> quotes, String query) {
    if (query.isEmpty) return quotes;

    final lowercaseQuery = query.toLowerCase();
    return quotes.where((quote) {
      return quote.text.toLowerCase().contains(lowercaseQuery) ||
          quote.authorName.toLowerCase().contains(lowercaseQuery) ||
          quote.themes.any(
            (theme) => theme.toLowerCase().contains(lowercaseQuery),
          ) ||
          quote.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  static List<Quote> filterByAuthor(List<Quote> quotes, String author) {
    return quotes
        .where(
          (quote) => quote.authorName.toLowerCase() == author.toLowerCase(),
        )
        .toList();
  }

  static List<Quote> filterByTheme(List<Quote> quotes, String theme) {
    return quotes
        .where(
          (quote) =>
              quote.themes.any((t) => t.toLowerCase() == theme.toLowerCase()),
        )
        .toList();
  }

  static List<Quote> filterByTag(List<Quote> quotes, String tag) {
    return quotes
        .where(
          (quote) =>
              quote.tags.any((t) => t.toLowerCase() == tag.toLowerCase()),
        )
        .toList();
  }
}
