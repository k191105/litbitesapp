import 'package:quotes_app/services/analytics.dart';
import 'package:quotes_app/services/entitlements_service.dart';

enum PurchasePlan {
  monthly('monthly'),
  annual('annual');

  const PurchasePlan(this.id);
  final String id;
}

class PurchaseService {
  static final PurchaseService instance = PurchaseService._();
  PurchaseService._();

  /// Always true for Phase 3 stub implementation
  bool get isMock => true;

  /// Purchase a plan - for Phase 3, this toggles Pro status
  Future<void> purchase(String plan) async {
    await Analytics.instance.logEvent('purchase.start', {'plan': plan});

    try {
      // Phase 3 stub: Always succeed and grant Pro
      await EntitlementsService.instance.setPro(
        true,
        since: DateTime.now().toUtc(),
      );

      await Analytics.instance.logEvent('purchase.success', {'plan': plan});
    } catch (e) {
      await Analytics.instance.logEvent('purchase.error', {
        'plan': plan,
        'error': e.toString(),
      });
      rethrow;
    }
  }

  /// Restore purchases - for Phase 3, this is mostly a no-op
  Future<void> restore() async {
    await Analytics.instance.logEvent('purchase.restore');

    // Phase 3 stub: Check if there's a dev flag or special condition
    // For now, this is essentially a no-op that shows feedback
    // In a real implementation, this would check with the store

    // Could add a dev flag here if needed:
    // if (kDebugMode || someDevFlag) {
    //   await EntitlementsService.instance.setPro(true, since: DateTime.now().toUtc());
    // }
  }

  /// Get display price for a plan (stub values for Phase 3)
  String getPlanPrice(PurchasePlan plan) {
    switch (plan) {
      case PurchasePlan.monthly:
        return '\$4.99';
      case PurchasePlan.annual:
        return '\$29.99';
    }
  }

  /// Get per-month equivalent price for annual plan
  String getAnnualPerMonthPrice() {
    return '\$2.50'; // $29.99 / 12 ≈ $2.50
  }

  /// Get plan display name
  String getPlanDisplayName(PurchasePlan plan) {
    switch (plan) {
      case PurchasePlan.monthly:
        return 'Monthly';
      case PurchasePlan.annual:
        return 'Annual';
    }
  }
}
