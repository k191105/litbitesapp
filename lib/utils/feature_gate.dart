import 'package:flutter/material.dart';
import '../services/entitlements_service.dart';
import '../services/purchase_service.dart';
import '../widgets/paywall.dart';

Future<void> requireFeature(
  BuildContext ctx,
  String featureKey, {
  required VoidCallback onAllowed,
  required VoidCallback onBlocked,
}) async {
  final isAllowed = await EntitlementsService.instance.isFeatureActive(
    featureKey,
  );

  if (isAllowed) {
    onAllowed();
  } else {
    onBlocked();
  }
}

/// Opens the paywall with the specified context
Future<bool?> openPaywall({
  required BuildContext context,
  required String contextKey,
  PurchasePlan initialPlan = PurchasePlan.annual,
}) async {
  return await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return FractionallySizedBox(
        heightFactor: 0.9,
        child: Paywall(contextKey: contextKey, initialPlan: initialPlan),
      );
    },
  );
}
