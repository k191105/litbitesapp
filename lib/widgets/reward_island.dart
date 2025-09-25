import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class RewardIsland extends StatefulWidget {
  final String featureKey;
  final String featureName;
  final VoidCallback? onDismiss;
  final VoidCallback? onTry;

  const RewardIsland({
    super.key,
    required this.featureKey,
    required this.featureName,
    this.onDismiss,
    this.onTry,
  });

  @override
  State<RewardIsland> createState() => _RewardIslandState();
}

class _RewardIslandState extends State<RewardIsland>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    _slideController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        widget.onDismiss?.call();
      }
    });

    _slideController.forward();

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _slideController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/animations/confetti.json',
                  width: 40,
                  height: 40,
                  repeat: false,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Reward Unlocked!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'You\'ve unlocked a 5-day pass for:\n${widget.featureName}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.center,
              child: OutlinedButton(
                onPressed: widget.onTry,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Theme.of(context).primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text('Try Now'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
