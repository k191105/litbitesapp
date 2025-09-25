import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quotes_app/quote_app.dart';
import 'package:quotes_app/services/debug_hooks.dart';
import 'package:quotes_app/services/entitlements_service.dart';
import 'package:quotes_app/services/notification_service.dart';
import 'package:quotes_app/services/purchase_service.dart';
import 'package:quotes_app/services/revenuecat_keys.dart';
import 'package:quotes_app/services/theme_controller.dart';
import 'package:quotes_app/services/time_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize global time provider
  timeProvider = kDebugMode
      ? FakeTimeProvider(
          initialTime: DateTime.now(),
          advanceInterval: const Duration(seconds: 30),
          advanceAmount: const Duration(days: 1),
          autoAdvance: true,
        )
      : SystemTimeProvider();

  NotificationService.initTimezones();
  await NotificationService.init();
  await ThemeController.instance.init();
  // Don't await this, let it configure in the background
  PurchaseService.instance.configure(iosApiKey: rcAppleApiKey);
  runApp(const MyApp());

  // Handle notification that launched the app after first frame
  WidgetsBinding.instance.addPostFrameCallback((_) {
    NotificationService.handleInitialNotification();
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  StreamSubscription<DateTime>? _timeSub;
  @override
  void initState() {
    super.initState();
    ThemeController.instance.addListener(_onThemeChanged);
    WidgetsBinding.instance.addObserver(this);
    if (kDebugMode && timeProvider is FakeTimeProvider) {
      _timeSub = (timeProvider as FakeTimeProvider).timeStream.listen((
        _,
      ) async {
        if (!mounted) return;
        setState(() {});
        // Also run new-day pipelines on auto-advance ticks
        final fn = DebugHooks.onAdvanceDay;
        if (fn != null) await fn();
      });
    }
  }

  @override
  void dispose() {
    ThemeController.instance.removeListener(_onThemeChanged);
    WidgetsBinding.instance.removeObserver(this);
    _timeSub?.cancel();
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Only sync if user has active subscriptions to avoid unnecessary network calls
      PurchaseService.instance.syncEntitlementFromRC().catchError((_) {
        // Silently handle sync errors on resume
      });
    }
  }

  /// Manually advance time (for debug mode testing)
  void advanceTime(Duration duration) {
    if (kDebugMode && timeProvider is FakeTimeProvider) {
      (timeProvider as FakeTimeProvider).advance(duration);
      setState(() {});
      // Run app's new-day pipelines (streak, notifications, overlays)
      // via a debug hook exposed by the app layer
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final fn = DebugHooks.onAdvanceDay;
        if (fn != null) await fn();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Literature Bites',
      navigatorKey: NotificationService.navigatorKey,
      theme: ThemeController.instance.themeData,
      home: TimeProviderInheritedWidget(
        timeProvider: timeProvider,
        child: Stack(
          children: [
            const QuoteApp(),
            // if (kDebugMode) _buildDebugTimeControls(),
          ],
        ),
      ),
      onGenerateRoute: (settings) {
        if (settings.name == '/quote') {
          final quoteId = settings.arguments as String?;
          return MaterialPageRoute(
            builder: (context) {
              return TimeProviderInheritedWidget(
                timeProvider: timeProvider,
                child: QuoteApp(quoteId: quoteId),
              );
            },
          );
        }
        return null;
      },
    );
  }

  /// Debug-only time controls for testing
  Widget _buildDebugTimeControls() {
    return Positioned(
      bottom: 100,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            onPressed: () async {
              final isPro = await EntitlementsService.instance.isPro();
              await EntitlementsService.instance.setPro(!isPro);
              if (mounted) setState(() {});
            },
            backgroundColor: Colors.teal.withOpacity(0.9),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.workspace_premium),
            label: const Text('Toggle Pro'),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            onPressed: () => advanceTime(const Duration(days: 1)),
            backgroundColor: Colors.orange.withOpacity(0.8),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.fast_forward),
            label: const Text('+1 Day'),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            onPressed: () => advanceTime(const Duration(days: 7)),
            backgroundColor: Colors.purple.withOpacity(0.8),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.skip_next),
            label: const Text('+1 Week'),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            onPressed: () => advanceTime(const Duration(days: 30)),
            backgroundColor: Colors.blue.withOpacity(0.8),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.double_arrow),
            label: const Text('+30 Days'),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fake:  ${timeProvider.now().toString().substring(0, 19)}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'Real:  ${DateTime.now().toString().substring(0, 19)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
