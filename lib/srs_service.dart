import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quotes_app/services/entitlements_service.dart';
import 'package:quotes_app/services/time_provider.dart';

// TODO: TimeProvider refactor - DateTime.now() calls replaced with timeProvider.now()

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
    reps: json['reps'] ?? 0,
    lapses: json['lapses'] ?? 0,
    ease: json['ease'] ?? 2.5,
    interval: json['interval'] ?? 0,
    due: DateTime.parse(json['due']),
    lastResult: json['lastResult'] ?? 'new',
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
    items.sort((a, b) => a.due.compareTo(b.due));
    return items.map((item) => item.quoteId).toList();
  }

  Future<List<String>> getStruggledQuotes() async {
    await _load();
    return _srsItems.values
        .where((item) => item.lastResult == 'incorrect')
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
    final item = _srsItems[quoteId] ?? SrsItem(quoteId: quoteId, due: today);

    if (correct) {
      item.reps++;
      if (item.reps == 1) {
        item.interval = 1;
      } else if (item.reps == 2) {
        item.interval = 6;
      } else {
        item.interval = (item.interval * item.ease).round();
      }
      item.lastResult = 'correct';
    } else {
      item.lapses++;
      item.interval = 0;
      item.reps = 0;
      item.lastResult = 'incorrect';
    }

    item.ease = max(
      1.3,
      item.ease +
          0.1 -
          (5 - (correct ? 5 : 1)) * (0.08 + (5 - (correct ? 5 : 1)) * 0.02),
    );
    item.due = today.add(Duration(days: item.interval));
    _srsItems[quoteId] = item;
    await _save();
  }

  Future<void> addQuote(String quoteId) async {
    await _load();
    _srsItems[quoteId] = SrsItem(quoteId: quoteId, due: timeProvider.now());
    await _save();
  }

  Future<void> addMany(Set<String> quoteIds) async {
    await _load();
    for (final quoteId in quoteIds) {
      _srsItems[quoteId] = SrsItem(quoteId: quoteId, due: timeProvider.now());
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
