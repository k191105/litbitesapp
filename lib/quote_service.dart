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
      final List<dynamic> jsonData = json.decode(jsonString);

      _cachedQuotes = jsonData.map((json) => Quote.fromJson(json)).toList();
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
