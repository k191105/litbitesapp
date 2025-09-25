import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:quotes_app/services/analytics.dart';
import 'package:quotes_app/services/entitlements_service.dart';
import 'package:quotes_app/services/revenuecat_keys.dart';
import 'package:quotes_app/services/time_provider.dart';

// TODO: TimeProvider refactor - DateTime.now() calls replaced with timeProvider.now()

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

  static const String _logPrefix = '[MembershipFlow]';

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
          since: active ? timeProvider.now() : null,
        );
        Analytics.instance.logEvent('purchase.entitlement_changed', {
          'active': active,
        });
        _log(
          'listener',
          'Customer info listener triggered',
          data: {
            'activeEntitlements': _activeEntitlementKeys(
              customerInfo,
            ).join(','),
            'proEntitlementActive': active,
          },
        );
      });

      await syncEntitlementFromRC();
    } catch (e) {
      Analytics.instance.logEvent('purchase.configure_error', {
        'error': e.toString(),
      });
      _log(
        'configure',
        'Failed to configure RevenueCat',
        data: {'error': e.toString()},
      );
    }
  }

  Future<CustomerInfo> syncEntitlementFromRC() async {
    final start = timeProvider.now();
    _log(
      'refresh',
      'Starting entitlement refresh',
      data: {
        'call': 'syncPurchases + getCustomerInfo',
        'startedAt': start.toIso8601String(),
      },
    );
    final wasPro = await EntitlementsService.instance.isPro();
    try {
      // Ensure purchases done outside the app (offer codes, subscription changes) are synced on iOS
      if (Platform.isIOS) {
        await Purchases.syncPurchases();
      }
      // Force a fresh fetch from RevenueCat (CustomerInfo is cached ~5 minutes)
      await Purchases.invalidateCustomerInfoCache();
      final info = await Purchases.getCustomerInfo();
      final active = info.entitlements.all[rcEntitlementKey]?.isActive ?? false;
      await EntitlementsService.instance.setPro(
        active,
        since: active ? timeProvider.now() : null,
      );
      Analytics.instance.logEvent('purchase.entitlement_sync', {
        'active': active,
      });
      return info;
    } catch (e) {
      final durationMs = timeProvider.now().difference(start).inMilliseconds;
      // Only log errors in debug mode to reduce noise
      if (e.toString().contains('ASDErrorDomain') ||
          e.toString().contains('StoreKit')) {
        // Handle App Store specific errors gracefully
        Analytics.instance.logEvent('purchase.store_error', {
          'error': e.toString(),
          'type': 'app_store_error',
        });
        _log(
          'refresh',
          'StoreKit-specific error during refresh',
          data: {'durationMs': durationMs, 'error': e.toString()},
        );
        return await Purchases.getCustomerInfo(); // Return cached data
      } else {
        Analytics.instance.logEvent('purchase.entitlement_sync_error', {
          'error': e.toString(),
        });
        _log(
          'refresh',
          'Entitlement refresh failed',
          data: {'durationMs': durationMs, 'error': e.toString()},
        );
        rethrow;
      }
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
    final start = timeProvider.now();
    _log(
      'purchase',
      'Starting purchasePackage',
      data: {
        'call': 'purchasePackage',
        'planId': planId,
        'startedAt': start.toIso8601String(),
      },
    );
    final wasPro = await EntitlementsService.instance.isPro();

    try {
      final packageToPurchase = _offerings?.current?.getPackage(planId);
      if (packageToPurchase == null) {
        _log('purchase', 'Package missing for plan', data: {'planId': planId});
        throw Exception('Could not find package for plan $planId');
      }
      final purchaseResult = await Purchases.purchasePackage(packageToPurchase);
      final info = purchaseResult.customerInfo;
      final isActive =
          info.entitlements.all[rcEntitlementKey]?.isActive ?? false;
      await EntitlementsService.instance.setPro(
        isActive,
        since: isActive ? timeProvider.now() : null,
      );
      await Analytics.instance.logEvent('purchase.success', {'plan': planId});
      final durationMs = timeProvider.now().difference(start).inMilliseconds;
      final activeEntitlements = _activeEntitlementKeys(info);
      final entitlementsChanged = wasPro != isActive;
      _log(
        'purchase',
        'Purchase completed',
        data: {
          'durationMs': durationMs,
          'planId': planId,
          'entitlementsChanged': entitlementsChanged,
          'proEntitlementActive': isActive,
          'activeEntitlements': activeEntitlements.join(','),
          'periodType':
              info.entitlements.all[rcEntitlementKey]?.periodType.name ??
              'none',
        },
      );

      if (!isActive) {
        _log(
          'purchase',
          'No active entitlement after purchase',
          data: {
            'planId': planId,
            'activeEntitlements': activeEntitlements.join(','),
          },
        );
      }
      return true;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        Analytics.instance.logEvent('purchase.cancelled', {'plan': planId});
        _log(
          'purchase',
          'Purchase cancelled by user',
          data: {
            'planId': planId,
            'durationMs': DateTime.now().difference(start).inMilliseconds,
          },
        );
        return false;
      } else if (errorCode ==
          PurchasesErrorCode.productNotAvailableForPurchaseError) {
        Analytics.instance.logEvent('purchase.product_unavailable', {
          'plan': planId,
        });
        _log(
          'purchase',
          'Product unavailable during purchase',
          data: {
            'planId': planId,
            'durationMs': DateTime.now().difference(start).inMilliseconds,
            'errorCode': errorCode.name,
          },
        );
        throw Exception('Product not available for purchase');
      } else if (errorCode == PurchasesErrorCode.paymentPendingError) {
        Analytics.instance.logEvent('purchase.payment_pending', {
          'plan': planId,
        });
        _log(
          'purchase',
          'Payment pending after purchase attempt',
          data: {
            'planId': planId,
            'durationMs': DateTime.now().difference(start).inMilliseconds,
          },
        );
        return false; // Don't rethrow for pending payments
      } else {
        Analytics.instance.logEvent('purchase.error', {
          'plan': planId,
          'error': e.toString(),
          'code': errorCode.toString(),
        });
        _log(
          'purchase',
          'Purchase failed with platform exception',
          data: {
            'planId': planId,
            'durationMs': DateTime.now().difference(start).inMilliseconds,
            'error': e.toString(),
            'code': errorCode.name,
          },
        );
        rethrow;
      }
    } catch (e) {
      // Handle network errors gracefully
      if (e.toString().contains('network') ||
          e.toString().contains('timeout')) {
        Analytics.instance.logEvent('purchase.network_error', {
          'plan': planId,
          'error': e.toString(),
        });
        _log(
          'purchase',
          'Network error during purchase',
          data: {
            'planId': planId,
            'durationMs': DateTime.now().difference(start).inMilliseconds,
            'error': e.toString(),
          },
        );
        throw Exception(
          'Network error. Please check your connection and try again.',
        );
      } else {
        Analytics.instance.logEvent('purchase.error', {
          'plan': planId,
          'error': e.toString(),
        });
        _log(
          'purchase',
          'Purchase failed',
          data: {
            'planId': planId,
            'durationMs': DateTime.now().difference(start).inMilliseconds,
            'error': e.toString(),
          },
        );
        rethrow;
      }
    }
  }

  /// Restore purchases
  Future<CustomerInfo> restore() async {
    await Analytics.instance.logEvent('purchase.restore_start');
    final start = timeProvider.now();
    _log(
      'restore',
      'Starting restorePurchases',
      data: {'call': 'restorePurchases', 'startedAt': start.toIso8601String()},
    );
    final wasPro = await EntitlementsService.instance.isPro();
    try {
      final customerInfo = await Purchases.restorePurchases();
      final isActive =
          customerInfo.entitlements.all[rcEntitlementKey]?.isActive ?? false;
      await EntitlementsService.instance.setPro(
        isActive,
        since: isActive ? timeProvider.now() : null,
      );
      await Analytics.instance.logEvent('purchase.restore_success');
      return customerInfo;
    } catch (e) {
      await Analytics.instance.logEvent('purchase.restore_error', {
        'error': e.toString(),
      });
      _log(
        'restore',
        'restorePurchases failed',
        data: {
          'durationMs': DateTime.now().difference(start).inMilliseconds,
          'error': e.toString(),
        },
      );
      rethrow;
    }
  }

  Future<void> refreshOfferings() async {
    try {
      _offerings = await Purchases.getOfferings();
      if (_offerings == null || _offerings?.current == null) {
        _log('offerings', 'Offerings fetched but current is null', data: {});
      } else {
        _log(
          'offerings',
          'Offerings refreshed',
          data: {
            'availablePackages':
                _offerings!.current?.availablePackages.length ?? 0,
          },
        );
      }
    } catch (e) {
      Analytics.instance.logEvent('purchase.offerings_error', {
        'error': e.toString(),
      });
      _log(
        'offerings',
        'Failed to refresh offerings',
        data: {'error': e.toString()},
      );
    }
  }

  Future<void> ensureOfferingsLoaded() async {
    if (_offerings == null) {
      await refreshOfferings();
      if (_offerings == null) {
        _log('offerings', 'Offerings still null after refresh', data: {});
      }
    }
  }

  bool get hasOfferingsLoaded => _offerings != null;

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

  void _log(String action, String message, {Map<String, dynamic>? data}) {
    final buffer = StringBuffer('$_logPrefix [$action] $message');
    if (data != null && data.isNotEmpty) {
      final formatted = data.entries
          .map((entry) => '${entry.key}=${entry.value}')
          .join(', ');
      buffer.write(' | $formatted');
    }
    final text = buffer.toString();
    if (kDebugMode) {
      debugPrint(text);
    } else {
      // ignore: avoid_print
      print(text);
    }
  }

  List<String> _activeEntitlementKeys(CustomerInfo info) {
    final active = info.entitlements.active;
    if (active.isEmpty) {
      return <String>[];
    }
    final keys = active.keys.toList();
    keys.sort();
    return keys;
  }
}
