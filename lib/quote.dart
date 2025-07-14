class Quote {
  final String id;
  final String text;
  final String authorName;
  final int? authorBirth;
  final int? authorDeath;
  final String? source;
  final String? work;
  final int? year;
  final List<String> themes;
  final List<String> tags;
  final String? context;
  final String? notes;
  final String status;
  final String? interpretation;
  final String? sourceBlurb;
  final String? tone;
  final String? period;
  final double? sentimentScore;
  final int? intensity;
  final int? author_score;

  Quote({
    required this.id,
    required this.text,
    required this.authorName,
    this.authorBirth,
    this.authorDeath,
    this.source,
    this.work,
    this.year,
    required this.themes,
    required this.tags,
    this.context,
    this.notes,
    required this.status,
    this.interpretation,
    this.sourceBlurb,
    this.tone,
    this.period,
    this.sentimentScore,
    this.intensity,
    this.author_score,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    final gptData = json['gpt'] as Map<String, dynamic>?;

    return Quote(
      id: json['id'],
      text: json['text'],
      authorName: json['author']['name'],
      authorBirth: json['author']['birth'],
      authorDeath: json['author']['death'],
      source: json['source'],
      work: json['work'],
      year: json['year'],
      themes: List<String>.from(json['themes'] ?? []),
      tags: List<String>.from(gptData?['tags'] ?? json['tags'] ?? []),
      context: json['context'],
      notes: json['notes'],
      status: json['status'],
      interpretation: gptData?['interpretation'],
      sourceBlurb: gptData?['source_blurb'],
      tone: gptData?['tone']?['label'],
      period: gptData?['period'],
      sentimentScore: (gptData?['sentiment_score'] as num?)?.toDouble(),
      intensity: (gptData?['tone']?['intensity'] as num?)?.toInt(),
      author_score: json['author_score'],
    );
  }

  // Helper method to get formatted author info
  String get authorInfo {
    String result = authorName;
    if (authorBirth != null) {
      result += ' (';
      result += authorBirth.toString();
      if (authorDeath != null) {
        result += '–${authorDeath}';
      } else {
        result += '–';
      }
      result += ')';
    }
    return result;
  }

  // Helper method to get source info for display
  String get displaySource {
    if (source != null && source!.isNotEmpty) {
      return source!;
    } else if (work != null && work!.isNotEmpty) {
      if (year != null) {
        return '$work ($year)';
      } else {
        return work!;
      }
    } else if (year != null) {
      return year.toString();
    }
    return '';
  }
}
