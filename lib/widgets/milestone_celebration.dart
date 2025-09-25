import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SimpleCelebrationOverlay extends StatefulWidget {
  final String animationType; // 'confetti'
  final VoidCallback onComplete;

  const SimpleCelebrationOverlay({
    super.key,
    required this.animationType,
    required this.onComplete,
  });

  @override
  State<SimpleCelebrationOverlay> createState() =>
      _SimpleCelebrationOverlayState();
}

class _SimpleCelebrationOverlayState extends State<SimpleCelebrationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Let the animation controller run for a long time to allow natural completion
    _controller = AnimationController(
      duration: const Duration(
        milliseconds: 10000,
      ), // Long duration, let Lottie control timing
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _controller.forward();

    // Auto-complete after natural duration + fade
    Future.delayed(const Duration(milliseconds: 4000), () {
      if (mounted) {
        _fadeController.forward().then((_) {
          if (mounted) {
            widget.onComplete();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  String get _animationPath {
    return 'assets/animations/confetti.json';
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: Lottie.asset(
                  _animationPath,
                  controller: _controller,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  repeat: false,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
