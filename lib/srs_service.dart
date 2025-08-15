import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quotes_app/services/entitlements_service.dart';

class SrsItem {
  final String quoteId;
  int reps;
  int lapses;
  double ease;
  int interval;
  DateTime due;
  String lastResult;

  SrsItem({
    required this.quoteId,
    this.reps = 0,
    this.lapses = 0,
    this.ease = 2.5,
    this.interval = 0,
    required this.due,
    this.lastResult = 'new',
  });

  Map<String, dynamic> toJson() => {
    'quoteId': quoteId,
    'reps': reps,
    'lapses': lapses,
    'ease': ease,
    'interval': interval,
    'due': due.toIso8601String(),
    'lastResult': lastResult,
  };

  factory SrsItem.fromJson(Map<String, dynamic> json) => SrsItem(
    quoteId: json['quoteId'],
    reps: json['reps'],
    lapses: json['lapses'],
    ease: json['ease'],
    interval: json['interval'],
    due: DateTime.parse(json['due']),
    lastResult: json['lastResult'],
  );
}

class SRSService {
  static const _srsKey = 'srs_data';
  Map<String, SrsItem> _srsItems = {};

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_srsKey);
    if (jsonString != null) {
      final decoded = json.decode(jsonString) as Map<String, dynamic>;
      if (decoded['version'] == 1) {
        final items = decoded['items'] as Map<String, dynamic>;
        _srsItems = items.map(
          (key, value) => MapEntry(key, SrsItem.fromJson(value)),
        );
      }
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode({
      'version': 1,
      'items': _srsItems.map((key, value) => MapEntry(key, value.toJson())),
    });
    await prefs.setString(_srsKey, jsonString);
  }

  Future<int> dueCount(DateTime today) async {
    await _load();
    return _srsItems.values.where((item) => !item.due.isAfter(today)).length;
  }

  Future<List<String>> loadDue(DateTime today) async {
    await _load();
    final items = _srsItems.values
        .where((item) => !item.due.isAfter(today))
        .toList();
    items.sort((a, b) => b.lapses.compareTo(a.lapses));
    return items.map((item) => item.quoteId).toList();
  }

  Future<List<String>> getStruggledQuotes() async {
    await _load();
    return _srsItems.values
        .where((item) => item.lapses > 0)
        .map((item) => item.quoteId)
        .toList();
  }

  Future<int> getLearnedQuotesCount() async {
    await _load();
    return _srsItems.values
        .where((item) => item.reps >= 3 && item.lapses == 0)
        .length;
  }

  Future<void> grade(
    String quoteId, {
    required bool correct,
    required DateTime today,
  }) async {
    await _load();
    final item = _srsItems[quoteId];
    if (item != null) {
      if (correct) {
        item.reps++;
      } else {
        item.lapses++;
        item.reps = 0; // Reset reps on failure
      }
      // This is a placeholder. A real implementation would use SM-2 logic.
      _srsItems[quoteId] = item;
      await _save();
    }
  }

  Future<void> addQuote(String quoteId) async {
    await _load();
    _srsItems[quoteId] = SrsItem(quoteId: quoteId, due: DateTime.now());
    await _save();
  }

  Future<void> addMany(Set<String> quoteIds) async {
    await _load();
    for (final quoteId in quoteIds) {
      _srsItems[quoteId] = SrsItem(quoteId: quoteId, due: DateTime.now());
    }
    await _save();
  }

  Future<void> removeQuote(String quoteId) async {
    await _load();
    _srsItems.remove(quoteId);
    await _save();
  }

  Future<int> dailyCap() async {
    final isPro = await EntitlementsService.instance.isPro();
    final hasSrsPass = await EntitlementsService.instance.isFeatureActive(
      'srs_unlimited',
    );
    return (isPro || hasSrsPass) ? 10000 : 20;
  }

  Future<bool> canReviewMore(DateTime today) async {
    // This is a placeholder. A real implementation would track daily reviews.
    return true;
  }
}
