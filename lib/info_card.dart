import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final String message;
  final List<Widget> actions;
  final Color? color;

  const InfoCard({
    super.key,
    required this.title,
    required this.message,
    this.actions = const [],
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color ?? Theme.of(context).cardColor,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.black.withOpacity(0.6),
              size: 40,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'EBGaramond',
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'EBGaramond',
                fontSize: 18,
                height: 1.5,
              ),
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: actions
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: e,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class GradientOutlinedButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Gradient gradient;
  final double strokeWidth;
  final double borderRadius;
  final Color? backgroundColor;

  const GradientOutlinedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.strokeWidth = 1.5,
    this.borderRadius = 30.0,
    this.gradient = const LinearGradient(
      colors: [Colors.purpleAccent, Colors.blueAccent],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onPressed,
          child: Container(
            margin: EdgeInsets.all(strokeWidth),
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 12.0,
            ),
            decoration: BoxDecoration(
              color:
                  backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(borderRadius - strokeWidth),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
