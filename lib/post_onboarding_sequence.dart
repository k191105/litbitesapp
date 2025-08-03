import 'package:flutter/material.dart';
import 'dart:async';

class PostOnboardingSequence extends StatefulWidget {
  final VoidCallback onFinished;

  const PostOnboardingSequence({super.key, required this.onFinished});

  @override
  _PostOnboardingSequenceState createState() => _PostOnboardingSequenceState();
}

class _PostOnboardingSequenceState extends State<PostOnboardingSequence> {
  bool _isProcessing = true;

  @override
  void initState() {
    super.initState();
    _startProcessing();
  }

  void _startProcessing() {
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 240, 234, 225),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _isProcessing
            ? const ProcessingScreen()
            : FeatureOverviewScreen(onFinished: widget.onFinished),
      ),
    );
  }
}

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});

  @override
  _ProcessingScreenState createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Synthesizing your results...',
            style: TextStyle(
              fontSize: 22,
              fontFamily: 'EBGaramond',
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48.0),
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: _animation.value,
                  backgroundColor: Colors.black.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FeatureOverviewScreen extends StatelessWidget {
  final VoidCallback onFinished;

  const FeatureOverviewScreen({super.key, required this.onFinished});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 2),
          const Text(
            'You\'re all set!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontFamily: 'EBGaramond',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildFeatureDescription(
            Icons.favorite_border,
            'Favorite quotes to build your collection and improve recommendations.',
          ),
          const SizedBox(height: 16),
          _buildFeatureDescription(
            Icons.explore_outlined,
            'Browse quotes by author, tags, or historical periods.',
          ),
          const SizedBox(height: 16),
          _buildFeatureDescription(
            Icons.school_outlined,
            'Learn your favorite quotes with our smart flashcard system.',
          ),
          const Spacer(flex: 3),
          ElevatedButton(
            onPressed: onFinished,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: const Text(
              'Start Exploring',
              style: TextStyle(
                fontFamily: 'EBGaramond',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureDescription(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 28, color: Colors.black54),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                fontFamily: 'EBGaramond',
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
