import 'dart:math';
import 'package:quotes_app/quote.dart';

class RecommendationService {
  final List<Quote> allQuotes;
  final List<Quote> favoriteQuotes;
  final Map<String, int> likeCounts;
  final Map<String, int> viewCounts;
  final int totalViews;
  final Set<String> preferredAuthors;
  final Set<String> preferredTags;
  final int? sessionSeed;

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

  // A conservative weight for how much view proportion affects the penalty
  static const double _viewProportionWeight = 0.5;

  // Size of the pool for weighted random sampling
  static const int _reservoirSize = 150;

  // Pre-calculated normalization values
  final double _maxQuoteLength;
  final double _maxYear;
  final double _minYear;

  // Random number generator for session-specific recommendations
  final Random _random;

  RecommendationService({
    required this.allQuotes,
    required this.favoriteQuotes,
    required this.likeCounts,
    required this.viewCounts,
    required this.totalViews,
    this.preferredAuthors = const {},
    this.preferredTags = const {},
    this.sessionSeed,
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
           .toDouble(),
       _random = Random(sessionSeed);

  List<Quote> getRecommendations() {
    // Only provide recommendations if the user has favorited a meaningful number of quotes
    if (favoriteQuotes.length < 10) {
      return (List<Quote>.from(allQuotes)..shuffle(_random));
    }

    final favoriteQuoteIds = favoriteQuotes.map((q) => q.id).toSet();
    final recommendations = <Quote, double>{};

    for (final candidate in allQuotes) {
      double rawScore = 0.0;
      for (final favorite in favoriteQuotes) {
        // Use a logarithmic scale for the like multiplier for diminishing returns
        final likeMultiplier = log((likeCounts[favorite.id] ?? 1) + 1);
        rawScore += _calculateSimilarity(candidate, favorite) * likeMultiplier;
      }

      // Add a novelty bonus for non-favorited quotes to encourage discovery
      if (!favoriteQuoteIds.contains(candidate.id)) {
        rawScore += 1.0;
      }

      // Add a bonus for preferred authors from onboarding
      if (preferredAuthors.contains(candidate.authorName)) {
        rawScore *= 1.5; // Give a 50% boost
      }

      // Add a bonus for matching preferred tags
      final candidateTags = candidate.tags.toSet();
      final matchedTags = candidateTags.intersection(preferredTags).length;
      if (matchedTags > 0) {
        rawScore *= (1.0 + 0.2 * matchedTags); // 20% boost per matched tag
      }

      // 2. Exposure penalty: down-weight score based on view count
      final views = viewCounts[candidate.id] ?? 0;
      final viewProportion = totalViews > 0 ? views / totalViews : 0;
      final penalty =
          sqrt(1 + views) * (1 + _viewProportionWeight * viewProportion);
      final effectiveScore = rawScore / penalty;

      recommendations[candidate] = effectiveScore;
    }

    final sortedRecommendations = recommendations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 3. Top-K Reservoir: limit the pool to most relevant items
    final reservoir = sortedRecommendations.take(_reservoirSize).toList();

    // 4. Weighted Sampling: shuffle the reservoir based on score
    final weightedSample = _performWeightedSampling(reservoir);

    // Append the rest of the items, shuffled, for variety if user scrolls far
    final remainingQuotes =
        sortedRecommendations.skip(_reservoirSize).map((e) => e.key).toList()
          ..shuffle(_random);

    return weightedSample + remainingQuotes;
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

  // Performs weighted random sampling without replacement
  List<Quote> _performWeightedSampling(
    List<MapEntry<Quote, double>> reservoir,
  ) {
    final result = <Quote>[];
    final tempReservoir = List<MapEntry<Quote, double>>.from(reservoir);

    if (tempReservoir.isEmpty) {
      return result;
    }

    while (tempReservoir.isNotEmpty) {
      final totalWeight = tempReservoir.fold(
        0.0,
        (sum, item) => sum + item.value,
      );

      if (totalWeight <= 0) {
        // If remaining weights are zero, shuffle and add the rest
        tempReservoir.shuffle(_random);
        result.addAll(tempReservoir.map((e) => e.key));
        break;
      }

      final pick = _random.nextDouble() * totalWeight;
      var cumulativeWeight = 0.0;

      for (var i = 0; i < tempReservoir.length; i++) {
        cumulativeWeight += tempReservoir[i].value;
        if (pick <= cumulativeWeight) {
          final selected = tempReservoir.removeAt(i);
          result.add(selected.key);
          break; // Exit inner loop once item is picked
        }
      }
    }
    return result;
  }

  // Calculates similarity on a scale from 0 to 1 using a Gaussian-like curve
  double _normalizedGaussianSimilarity(double v1, double v2, double range) {
    if (range == 0) return 1.0;
    final diff = (v1 - v2).abs();
    // Use a simplified exponential decay function
    return exp(-pow(diff / (range * 0.5), 2));
  }
}
