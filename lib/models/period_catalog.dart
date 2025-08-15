import 'package:quotes_app/quote.dart';

class PeriodRange {
  final String name;
  final int startYear;
  final int endYear;
  final String? description;

  const PeriodRange({
    required this.name,
    required this.startYear,
    required this.endYear,
    this.description,
  });

  bool containsYear(int year) {
    return year >= startYear && year <= endYear;
  }

  String get displayRange => '$startYear–$endYear';
}

class PeriodCatalog {
  static const List<PeriodRange> periods = [
    PeriodRange(
      name: 'Enlightenment',
      startYear: 1680,
      endYear: 1800,
      description: 'Age of Reason and scientific revolution',
    ),
    PeriodRange(
      name: 'Romanticism',
      startYear: 1780,
      endYear: 1850,
      description: 'Emotion, nature, and individualism',
    ),
    PeriodRange(
      name: 'Victorian',
      startYear: 1837,
      endYear: 1901,
      description: 'British cultural dominance and moral values',
    ),
    PeriodRange(
      name: 'Modernism',
      startYear: 1900,
      endYear: 1945,
      description: 'Experimental forms and breaking tradition',
    ),
    PeriodRange(
      name: 'Postmodern',
      startYear: 1945,
      endYear: 1990,
      description: 'Questioning truth and embracing plurality',
    ),
    PeriodRange(
      name: 'Contemporary',
      startYear: 1990,
      endYear: 2024,
      description: 'Digital age and global interconnectedness',
    ),
  ];

  static const int minYear = 1600;
  static const int maxYear = 2024;

  /// Infer period from year if not explicitly set
  static String? inferPeriodFromYear(int? year) {
    if (year == null) return null;

    for (final period in periods) {
      if (period.containsYear(year)) {
        return period.name;
      }
    }

    // Handle edge cases for very old or very new works
    if (year < minYear) return 'Pre-Enlightenment';
    if (year > maxYear) return 'Future';

    return null;
  }

  /// Get period range by name
  static PeriodRange? getPeriodByName(String name) {
    try {
      return periods.firstWhere(
        (p) => p.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get quotes count for a period range
  static int getQuoteCountForRange(
    List<Quote> quotes,
    int startYear,
    int endYear,
  ) {
    return quotes.where((quote) {
      final year = quote.year;
      if (year != null) {
        return year >= startYear && year <= endYear;
      }
      // Check if quote has explicit period that matches our range
      final quotePeriod = quote.period;
      if (quotePeriod != null) {
        final periodRange = getPeriodByName(quotePeriod);
        if (periodRange != null) {
          // Check if periods overlap
          return !(periodRange.endYear < startYear ||
              periodRange.startYear > endYear);
        }
      }
      return false;
    }).length;
  }

  /// Get quotes for a specific period range
  static List<Quote> getQuotesForRange(
    List<Quote> quotes,
    int startYear,
    int endYear,
  ) {
    return quotes.where((quote) {
      final year = quote.year;
      if (year != null) {
        return year >= startYear && year <= endYear;
      }
      // Check if quote has explicit period that matches our range
      final quotePeriod = quote.period;
      if (quotePeriod != null) {
        final periodRange = getPeriodByName(quotePeriod);
        if (periodRange != null) {
          // Check if periods overlap
          return !(periodRange.endYear < startYear ||
              periodRange.startYear > endYear);
        }
      }
      return false;
    }).toList();
  }
}
