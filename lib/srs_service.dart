import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class QuoteLearningData {
  final String quoteId;
  DateTime lastReviewed;
  int interval; // in days

  QuoteLearningData({
    required this.quoteId,
    required this.lastReviewed,
    this.interval = 1,
  });

  factory QuoteLearningData.fromJson(Map<String, dynamic> json) {
    return QuoteLearningData(
      quoteId: json['quoteId'],
      lastReviewed: DateTime.parse(json['lastReviewed']),
      interval: json['interval'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quoteId': quoteId,
      'lastReviewed': lastReviewed.toIso8601String(),
      'interval': interval,
    };
  }
}

class SRSService {
  static const _key = 'srsLearningData';

  Future<Map<String, QuoteLearningData>> getLearningData() async {
    return await _getLearningData();
  }

  Future<Map<String, QuoteLearningData>> _getLearningData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) {
      return {};
    }
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    return jsonMap.map(
      (key, value) => MapEntry(key, QuoteLearningData.fromJson(value)),
    );
  }

  Future<void> _saveLearningData(Map<String, QuoteLearningData> data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(
      data.map((key, value) => MapEntry(key, value.toJson())),
    );
    await prefs.setString(_key, jsonString);
  }

  Future<void> addQuote(String quoteId) async {
    final data = await _getLearningData();
    if (!data.containsKey(quoteId)) {
      data[quoteId] = QuoteLearningData(
        quoteId: quoteId,
        lastReviewed: DateTime.now(),
      );
      await _saveLearningData(data);
    }
  }

  Future<void> removeQuote(String quoteId) async {
    final data = await _getLearningData();
    if (data.containsKey(quoteId)) {
      data.remove(quoteId);
      await _saveLearningData(data);
    }
  }

  Future<void> updateQuote(String quoteId, bool isCorrect) async {
    final data = await _getLearningData();
    final quoteData = data[quoteId];
    if (quoteData != null) {
      quoteData.lastReviewed = DateTime.now();
      if (isCorrect) {
        // Simple doubling interval for correct answers
        quoteData.interval = (quoteData.interval * 2).clamp(1, 365);
      } else {
        // Reset interval for incorrect answers
        quoteData.interval = 1;
      }
      data[quoteId] = quoteData;
      await _saveLearningData(data);
    }
  }
}
