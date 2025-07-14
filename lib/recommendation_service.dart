import 'dart:math';
import 'package:quotes_app/quote.dart';

class RecommendationService {
  final List<Quote> allQuotes;
  final List<Quote> favoriteQuotes;
  final Map<String, int> likeCounts;
  final Set<String> preferredAuthors;
  final Set<String> preferredTags;

  // Feature weights can be tuned to adjust recommendation quality
  static const Map<String, double> _featureWeights = {
    'author': 3.0,
    'tags': 1.5,
    'period': 1.0,
    'year': 1.0,
    'sentiment': 1.5,
    'tone_label': 2.5,
    'tone_intensity': 2.0,
    'length': 2.0,
  };

  // Pre-calculated normalization values
  final double _maxQuoteLength;
  final double _maxYear;
  final double _minYear;

  RecommendationService({
    required this.allQuotes,
    required this.favoriteQuotes,
    required this.likeCounts,
    this.preferredAuthors = const {},
    this.preferredTags = const {},
  }) : _maxQuoteLength = allQuotes
           .map((q) => q.text.length)
           .reduce((a, b) => a > b ? a : b)
           .toDouble(),
       _maxYear = allQuotes
           .where((q) => q.year != null)
           .map((q) => q.year!)
           .reduce((a, b) => a > b ? a : b)
           .toDouble(),
       _minYear = allQuotes
           .where((q) => q.year != null)
           .map((q) => q.year!)
           .reduce((a, b) => a < b ? a : b)
           .toDouble();

  List<Quote> getRecommendations() {
    // Only provide recommendations if the user has favorited a meaningful number of quotes
    if (favoriteQuotes.length < 10) {
      return (List<Quote>.from(allQuotes)..shuffle());
    }

    final favoriteQuoteIds = favoriteQuotes.map((q) => q.id).toSet();
    final recommendations = <Quote, double>{};

    for (final candidate in allQuotes) {
      double score = 0.0;
      for (final favorite in favoriteQuotes) {
        // Use a logarithmic scale for the like multiplier for diminishing returns
        final likeMultiplier = log((likeCounts[favorite.id] ?? 1) + 1);
        score += _calculateSimilarity(candidate, favorite) * likeMultiplier;
      }

      // Add a novelty bonus for non-favorited quotes to encourage discovery
      if (!favoriteQuoteIds.contains(candidate.id)) {
        score += 1.0;
      }

      // Add a bonus for preferred authors from onboarding
      if (preferredAuthors.contains(candidate.authorName)) {
        score *= 1.5; // Give a 50% boost
      }

      // Add a bonus for matching preferred tags
      final candidateTags = candidate.tags.toSet();
      final matchedTags = candidateTags.intersection(preferredTags).length;
      if (matchedTags > 0) {
        score *= (1.0 + 0.2 * matchedTags); // 20% boost per matched tag
      }

      recommendations[candidate] = score;
    }

    final sortedRecommendations = recommendations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedRecommendations.map((entry) => entry.key).toList();
  }

  double _calculateSimilarity(Quote a, Quote b) {
    double totalSimilarity = 0;

    // Author
    if (a.authorName == b.authorName) {
      totalSimilarity += 1.0 * _featureWeights['author']!;
    }

    // Tags (Jaccard Similarity)
    final tagsA = a.tags.toSet();
    final tagsB = b.tags.toSet();
    final intersection = tagsA.intersection(tagsB).length;
    final union = tagsA.union(tagsB).length;
    if (union > 0) {
      totalSimilarity += (intersection / union) * _featureWeights['tags']!;
    }

    // Period
    if (a.period != null && a.period == b.period) {
      totalSimilarity += 1.0 * _featureWeights['period']!;
    }

    // Year
    if (a.year != null && b.year != null) {
      totalSimilarity +=
          _normalizedGaussianSimilarity(
            a.year!.toDouble(),
            b.year!.toDouble(),
            _maxYear - _minYear,
          ) *
          _featureWeights['year']!;
    }

    // Sentiment
    if (a.sentimentScore != null && b.sentimentScore != null) {
      totalSimilarity +=
          _normalizedGaussianSimilarity(
            a.sentimentScore!,
            b.sentimentScore!,
            2.0,
          ) *
          _featureWeights['sentiment']!; // Range is -1 to 1, so 2.0
    }

    // Tone Label
    if (a.tone != null && a.tone == b.tone) {
      totalSimilarity += 1.0 * _featureWeights['tone_label']!;
    }

    // Tone Intensity
    if (a.intensity != null && b.intensity != null) {
      totalSimilarity +=
          _normalizedGaussianSimilarity(
            a.intensity!.toDouble(),
            b.intensity!.toDouble(),
            100.0,
          ) *
          _featureWeights['tone_intensity']!; // Range is 0-100
    }

    // Quote Length
    totalSimilarity +=
        _normalizedGaussianSimilarity(
          a.text.length.toDouble(),
          b.text.length.toDouble(),
          _maxQuoteLength,
        ) *
        _featureWeights['length']!;

    return totalSimilarity;
  }

  // Calculates similarity on a scale from 0 to 1 using a Gaussian-like curve
  double _normalizedGaussianSimilarity(double v1, double v2, double range) {
    if (range == 0) return 1.0;
    final diff = (v1 - v2).abs();
    // Use a simplified exponential decay function
    return exp(-pow(diff / (range * 0.5), 2));
  }
}
