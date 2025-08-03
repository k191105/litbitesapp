import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class StreakIsland extends StatefulWidget {
  final String streakMessage;
  final List<Map<String, dynamic>> weeklyView;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final bool isDarkMode;

  const StreakIsland({
    super.key,
    required this.streakMessage,
    required this.weeklyView,
    this.onTap,
    this.onDismiss,
    this.isDarkMode = false,
  });

  @override
  State<StreakIsland> createState() => _StreakIslandState();
}

class _StreakIslandState extends State<StreakIsland>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _flameController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _flameController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    // Add listener to detect when dismiss animation completes
    _slideController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        widget.onDismiss?.call();
      }
    });

    // Start animations
    _slideController.forward();

    // Auto-hide after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _slideController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _flameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: widget.isDarkMode
                ? const Color(0xFF2A2A2A)
                : const Color(0xFFF8F6F0),
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: widget.isDarkMode
                  ? Colors.grey.withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Streak message
              Text(
                widget.streakMessage,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? Colors.white : Colors.black,
                  fontFamily: 'EBGaramond',
                ),
              ),
              const SizedBox(height: 12),

              // Weekly view
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: widget.weeklyView.map((day) {
                  return _buildDayIndicator(day);
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayIndicator(Map<String, dynamic> day) {
    final isCompleted = day['isCompleted'] as bool;
    final isToday = day['isToday'] as bool;
    final dayName = day['day'] as String;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Day name
        Text(
          dayName,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            color: isToday
                ? (widget.isDarkMode
                      ? Colors.orange.shade300
                      : Colors.orange.shade700)
                : (widget.isDarkMode
                      ? Colors.grey.shade400
                      : Colors.grey.shade600),
            fontFamily: 'EBGaramond',
          ),
        ),
        const SizedBox(height: 4),

        // Day indicator
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? Colors.orange.shade200
                : (widget.isDarkMode
                      ? Colors.grey.shade700
                      : Colors.grey.shade300),
            border: Border.all(
              color: isToday
                  ? (widget.isDarkMode
                        ? Colors.orange.shade300
                        : Colors.orange.shade700)
                  : Colors.transparent,
              width: isToday ? 2 : 0,
            ),
          ),
          child: isCompleted
              ? Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    child: Lottie.asset(
                      'assets/animations/flame.json',
                      controller: _flameController,
                      onLoaded: (composition) {
                        _flameController.duration = composition.duration;
                        _flameController.repeat();
                      },
                      fit: BoxFit.contain,
                    ),
                  ),
                )
              : Container(),
        ),
      ],
    );
  }
}
