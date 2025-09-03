import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:quotes_app/services/analytics.dart';
import 'package:quotes_app/services/entitlements_service.dart';
import 'package:quotes_app/services/revenuecat_keys.dart';

enum PurchasePlan {
  monthly(r'$rc_monthly'),
  annual(r'$rc_annual');

  const PurchasePlan(this.id);
  final String id;
}

class PurchaseService {
  static final PurchaseService instance = PurchaseService._();
  PurchaseService._();

  Offerings? _offerings;

  /// No longer a mock
  bool get isMock => false;

  Future<void> configure({required String iosApiKey, String? appUserId}) async {
    // Android is deferred for now
    if (!Platform.isIOS) return;

    try {
      final config = PurchasesConfiguration(iosApiKey);
      await Purchases.configure(config);

      if (appUserId != null) {
        await logIn(appUserId);
      }

      Purchases.addCustomerInfoUpdateListener((customerInfo) async {
        final active =
            customerInfo.entitlements.all[rcEntitlementKey]?.isActive ?? false;
        await EntitlementsService.instance.setPro(
          active,
          since: active ? DateTime.now() : null,
        );
        Analytics.instance.logEvent('purchase.entitlement_changed', {
          'active': active,
        });
      });

      await syncEntitlementFromRC();
    } catch (e) {
      Analytics.instance.logEvent('purchase.configure_error', {
        'error': e.toString(),
      });
    }
  }

  Future<void> syncEntitlementFromRC() async {
    try {
      final info = await Purchases.getCustomerInfo();
      final active = info.entitlements.all[rcEntitlementKey]?.isActive ?? false;
      await EntitlementsService.instance.setPro(
        active,
        since: active ? DateTime.now() : null,
      );
      Analytics.instance.logEvent('purchase.entitlement_sync', {
        'active': active,
      });
    } catch (e) {
      Analytics.instance.logEvent('purchase.entitlement_sync_error', {
        'error': e.toString(),
      });
    }
  }

  Future<void> logIn(String appUserId) async {
    try {
      await Purchases.logIn(appUserId);
      await refreshOfferings();
    } catch (e) {
      Analytics.instance.logEvent('purchase.login_error', {
        'error': e.toString(),
      });
    }
  }

  Future<void> logOut() async {
    try {
      await Purchases.logOut();
      await refreshOfferings();
    } catch (e) {
      Analytics.instance.logEvent('purchase.logout_error', {
        'error': e.toString(),
      });
    }
  }

  /// Purchase a plan
  Future<bool> purchase(String planId) async {
    await Analytics.instance.logEvent('purchase.start', {'plan': planId});

    try {
      final packageToPurchase = _offerings?.current?.getPackage(planId);
      if (packageToPurchase == null) {
        throw Exception('Could not find package for plan $planId');
      }
      await Purchases.purchasePackage(packageToPurchase);
      await Analytics.instance.logEvent('purchase.success', {'plan': planId});
      return true;
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError) {
        Analytics.instance.logEvent('purchase.cancelled', {'plan': planId});
        return false;
      } else {
        await Analytics.instance.logEvent('purchase.error', {
          'plan': planId,
          'error': e.toString(),
        });
        rethrow;
      }
    } catch (e) {
      await Analytics.instance.logEvent('purchase.error', {
        'plan': planId,
        'error': e.toString(),
      });
      rethrow;
    }
  }

  /// Restore purchases
  Future<CustomerInfo> restore() async {
    await Analytics.instance.logEvent('purchase.restore_start');
    try {
      final customerInfo = await Purchases.restorePurchases();
      await Analytics.instance.logEvent('purchase.restore_success');
      return customerInfo;
    } catch (e) {
      await Analytics.instance.logEvent('purchase.restore_error', {
        'error': e.toString(),
      });
      rethrow;
    }
  }

  Future<void> refreshOfferings() async {
    try {
      _offerings = await Purchases.getOfferings();
    } catch (e) {
      Analytics.instance.logEvent('purchase.offerings_error', {
        'error': e.toString(),
      });
    }
  }

  Future<void> ensureOfferingsLoaded() async {
    if (_offerings == null) {
      await refreshOfferings();
    }
  }

  Package? _getPackageForPlan(PurchasePlan plan) {
    return _offerings?.current?.getPackage(plan.id);
  }

  /// Get display price for a plan
  String? getPlanPrice(PurchasePlan plan) {
    return _getPackageForPlan(plan)?.storeProduct.priceString;
  }

  /// Get per-month equivalent price for annual plan
  String? getAnnualPerMonthPrice() {
    final annualPackage = _getPackageForPlan(PurchasePlan.annual);
    if (annualPackage == null) return null;

    final product = annualPackage.storeProduct;
    final price = product.price;

    if (price <= 0) return null;

    final format = NumberFormat.simpleCurrency(name: product.currencyCode);
    return format.format(price / 12);
  }

  /// Get plan display name
  String getPlanDisplayName(PurchasePlan plan) {
    // This could also come from the package's storeProduct.title if needed
    switch (plan) {
      case PurchasePlan.monthly:
        return 'Monthly';
      case PurchasePlan.annual:
        return 'Annual';
    }
  }

  /// Returns a string like "Start with a 7 day free trial" or null if no trial.
  String? getTrialDescription(PurchasePlan plan) {
    final package = _getPackageForPlan(plan);
    final introPrice = package?.storeProduct.introductoryPrice;

    if (introPrice == null || introPrice.price > 0) return null;

    final units = introPrice.periodNumberOfUnits;
    if (units == 0) return null;

    var period = introPrice.periodUnit.name;
    if (units > 1) {
      period = '${period}s';
    }

    return 'Start with a $units $period free trial';
  }
}
