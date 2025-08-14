import 'package:flutter/material.dart';

class RewardIsland extends StatefulWidget {
  final String featureKey;
  final VoidCallback onDismiss;

  const RewardIsland({
    super.key,
    required this.featureKey,
    required this.onDismiss,
  });

  @override
  State<RewardIsland> createState() => _RewardIslandState();
}

class _RewardIslandState extends State<RewardIsland>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Card(
        margin: const EdgeInsets.all(8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.star, color: Colors.amber),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'You\'ve unlocked a Pro feature for 7 days: You can now ${widget.featureKey.replaceAll('_', ' ')}!',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onDismiss,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
