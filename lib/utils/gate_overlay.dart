import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:quotes_app/widgets/pro_badge.dart';

class GateOverlay extends StatelessWidget {
  final Widget child;
  final bool allowed;
  final VoidCallback onBlocked;
  final bool showProBadge;
  final double blurSigma;

  const GateOverlay({
    super.key,
    required this.child,
    required this.allowed,
    required this.onBlocked,
    this.showProBadge = true,
    this.blurSigma = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    if (allowed) {
      return child;
    }

    return Stack(
      children: [
        // Original content with blur
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: child,
            ),
          ),
        ),

        // Tap detector for paywall
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onBlocked,
              borderRadius: BorderRadius.circular(12),
              child: Container(),
            ),
          ),
        ),

        // PRO badge
        if (showProBadge) Positioned(top: 8, right: 8, child: const ProBadge()),
      ],
    );
  }
}
