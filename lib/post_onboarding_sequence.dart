import 'package:flutter/material.dart';
import 'package:quotes_app/widgets/paywall.dart';
import 'dart:async';

class PostOnboardingSequence extends StatefulWidget {
  final VoidCallback onFinished;

  const PostOnboardingSequence({super.key, required this.onFinished});

  @override
  _PostOnboardingSequenceState createState() => _PostOnboardingSequenceState();
}

class _PostOnboardingSequenceState extends State<PostOnboardingSequence> {
  bool _isProcessing = true;
  int _currentStep =
      0; // 0: processing, 1: features, 2: paywall, 3: drawer guide

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
          _currentStep = 1;
        });
      }
    });
  }

  void _nextStep() {
    setState(() {
      _currentStep++;
    });
  }

  void _finish() {
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 240, 234, 225),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _buildCurrentStep(),
      ),
    );
  }

  Widget _buildCurrentStep() {
    if (_isProcessing) {
      return const ProcessingScreen();
    }

    switch (_currentStep) {
      case 1:
        return FeatureOverviewScreen(onFinished: _nextStep);
      case 2:
        return PaywallIntroScreen(onFinished: _nextStep);
      case 3:
        return DrawerGuideScreen(onFinished: _finish);
      default:
        return FeatureOverviewScreen(onFinished: _finish);
    }
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

class PaywallIntroScreen extends StatelessWidget {
  final VoidCallback onFinished;

  const PaywallIntroScreen({super.key, required this.onFinished});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Literature Bites is Free',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontFamily: 'EBGaramond',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'But it can be so much better.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'EBGaramond',
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 32),
          _buildProFeature(Icons.explore, 'Browse by Author & Period'),
          const SizedBox(height: 16),
          _buildProFeature(Icons.school, 'Unlimited Learn Sessions'),
          const SizedBox(height: 16),
          _buildProFeature(Icons.palette, 'Premium Themes & Fonts'),
          const SizedBox(height: 16),
          _buildProFeature(Icons.notifications, 'Custom Notifications'),
          const SizedBox(height: 48),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onFinished,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Continue Free',
                    style: TextStyle(fontFamily: 'EBGaramond', fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    // Show the full paywall
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const Paywall(contextKey: 'profile_upgrade'),
                      ),
                    );
                    // Continue regardless of paywall result
                    onFinished();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Upgrade Now',
                    style: TextStyle(
                      fontFamily: 'EBGaramond',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Colors.black54),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 16, fontFamily: 'EBGaramond'),
          ),
        ),
      ],
    );
  }
}

class DrawerGuideScreen extends StatelessWidget {
  final VoidCallback onFinished;

  const DrawerGuideScreen({super.key, required this.onFinished});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: Stack(
        children: [
          // Highlight the drawer area
          Positioned(
            top: 0,
            left: 0,
            bottom: 0,
            width: 80,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.menu, size: 32, color: Colors.black),
              ),
            ),
          ),

          // Guide text
          Positioned(
            top: MediaQuery.of(context).size.height * 0.2,
            left: 100,
            right: 32,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Access Your Dashboard',
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'EBGaramond',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tap the menu button to access Browse, Learn, Favorites, and other useful features.',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'EBGaramond',
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: onFinished,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Got it!',
                        style: TextStyle(
                          fontFamily: 'EBGaramond',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
