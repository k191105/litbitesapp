import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quotes_app/services/analytics.dart';

class EntitlementsService {
  static final EntitlementsService instance = EntitlementsService._();
  Completer<void>? _writeLock;

  static const _entitlementsKey = 'entitlements';
  static const _isProKey = 'isPro';
  static const _proSinceKey = 'proSince';
  static const _featurePassesKey = 'featurePasses';

  // Feature Keys
  static const String browseTags = 'browse_tags';
  static const String browseAuthor = 'browse_author';
  static const String browsePeriod = 'browse_period';
  static const String premiumThemes = 'premium_themes';
  static const String premiumFonts = 'premium_fonts';
  static const String premiumShareStyles = 'premium_share_styles';
  static const String srsUnlimited = 'srs_unlimited';
  static const String learnTrainer = 'learn_trainer';

  EntitlementsService._();

  Future<Map<String, dynamic>> _loadEntitlements() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_entitlementsKey);
    if (jsonString != null) {
      try {
        final loaded = json.decode(jsonString) as Map<String, dynamic>;
        // Basic validation
        if (loaded.containsKey(_isProKey) &&
            loaded.containsKey(_featurePassesKey)) {
          return loaded;
        }
      } catch (e) {
        // Corrupt data, fall back to default
      }
    }
    // Default entitlements
    return {
      _isProKey: false,
      _proSinceKey: null,
      _featurePassesKey: <String, String>{},
    };
  }

  Future<void> _saveEntitlements(Map<String, dynamic> entitlements) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_entitlementsKey, json.encode(entitlements));
  }

  Future<void> _mutex(Future<void> Function() criticalSection) async {
    while (_writeLock != null) {
      await _writeLock!.future;
    }
    _writeLock = Completer();
    try {
      await criticalSection();
    } finally {
      _writeLock!.complete();
      _writeLock = null;
    }
  }

  Future<bool> isPro() async {
    final entitlements = await _loadEntitlements();
    return entitlements['isPro'] as bool;
  }

  /// Helper for Pro-only features that don't have Feature Passes
  Future<bool> isProOnlyFeature(String key) async {
    return await isPro();
  }

  Future<void> clearExpiredPasses() async {
    final entitlements = await _loadEntitlements();
    final passes = Map<String, String>.from(
      entitlements[_featurePassesKey] as Map,
    );
    final now = DateTime.now().toUtc();

    final futures = <Future<void>>[];
    passes.removeWhere((key, value) {
      final expiry = DateTime.tryParse(value)?.toUtc();
      final isExpired = expiry == null || !expiry.isAfter(now);
      if (isExpired) {
        futures.add(
          Analytics.instance.logEvent('entitlement.feature_pass_expired', {
            'feature': key,
          }),
        );
      }
      return isExpired;
    });

    await Future.wait(futures);

    entitlements[_featurePassesKey] = passes;
    await _saveEntitlements(entitlements);
  }

  Future<Map<String, DateTime>> getFeaturePasses() async {
    await clearExpiredPasses();
    final entitlements = await _loadEntitlements();
    final passes = Map<String, String>.from(
      entitlements[_featurePassesKey] as Map,
    );
    return passes.map((key, value) => MapEntry(key, DateTime.parse(value)));
  }

  Future<void> grantFeaturePass(
    String featureKey,
    Duration duration, {
    String source = 'unknown',
  }) async {
    await _mutex(() async {
      await clearExpiredPasses();
      final entitlements = await _loadEntitlements();
      final passes = Map<String, String>.from(
        entitlements[_featurePassesKey] as Map,
      );
      final now = DateTime.now().toUtc();

      final currentExpiryStr = passes[featureKey];
      DateTime newExpiry;
      if (currentExpiryStr != null) {
        final currentExpiry = DateTime.parse(currentExpiryStr).toUtc();
        if (currentExpiry.isAfter(now)) {
          // Extend existing pass
          newExpiry = currentExpiry.add(duration);
        } else {
          // Grant new pass as old one expired
          newExpiry = now.add(duration);
        }
      } else {
        // Grant new pass
        newExpiry = now.add(duration);
      }

      passes[featureKey] = newExpiry.toIso8601String();
      entitlements[_featurePassesKey] = passes;
      await _saveEntitlements(entitlements);
      await Analytics.instance.logEvent('entitlement.feature_pass_granted', {
        'feature': featureKey,
        'source': source,
        'expiresAt': newExpiry.toIso8601String(),
      });
    });
  }

  Future<bool> isFeatureActive(String featureKey) async {
    if (await isPro()) {
      return true;
    }

    final passes = await getFeaturePasses();
    return passes.containsKey(featureKey);
  }

  Future<Duration?> timeRemaining(String featureKey) async {
    if (await isPro()) return null; // Pro has infinite duration

    final passes = await getFeaturePasses();
    final expiry = passes[featureKey];

    if (expiry == null) return null;

    final remaining = expiry.difference(DateTime.now().toUtc());
    return remaining.isNegative ? null : remaining;
  }

  Future<List<String>> activeFeatureKeys() async {
    final passes = await getFeaturePasses();
    return passes.keys.toList();
  }

  // Helper for dev panel
  Future<void> revokeFeaturePass(String featureKey) async {
    await _mutex(() async {
      final entitlements = await _loadEntitlements();
      final passes = Map<String, String>.from(
        entitlements[_featurePassesKey] as Map,
      );
      passes.remove(featureKey);
      entitlements[_featurePassesKey] = passes;
      await _saveEntitlements(entitlements);
    });
  }

  // Helper for dev panel and purchase service
  Future<void> setPro(bool isPro, {DateTime? since}) async {
    await _mutex(() async {
      final entitlements = await _loadEntitlements();
      entitlements[_isProKey] = isPro;
      entitlements[_proSinceKey] = isPro
          ? (since ?? DateTime.now().toUtc()).toIso8601String()
          : null;
      await _saveEntitlements(entitlements);
    });
  }

  // Helper for dev panel
  Future<void> clearAllPasses() async {
    await _mutex(() async {
      final entitlements = await _loadEntitlements();
      entitlements[_featurePassesKey] = <String, String>{};
      await _saveEntitlements(entitlements);
    });
  }
}
