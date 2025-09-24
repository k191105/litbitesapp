import 'package:flutter/material.dart';
import 'package:quotes_app/quote_app.dart';
import 'package:quotes_app/services/notification_service.dart';
import 'package:quotes_app/services/purchase_service.dart';
import 'package:quotes_app/services/revenuecat_keys.dart';
import 'package:quotes_app/services/theme_controller.dart';
import 'package:timezone/data/latest_all.dart' as tz;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await NotificationService.init();
  await ThemeController.instance.init();
  await PurchaseService.instance.configure(iosApiKey: rcAppleApiKey);
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
  @override
  void initState() {
    super.initState();
    ThemeController.instance.addListener(_onThemeChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    ThemeController.instance.removeListener(_onThemeChanged);
    WidgetsBinding.instance.removeObserver(this);
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Literature Bites',
      navigatorKey: NotificationService.navigatorKey,
      theme: ThemeController.instance.themeData,
      home: const QuoteApp(),
      onGenerateRoute: (settings) {
        if (settings.name == '/quote') {
          final quoteId = settings.arguments as String?;
          return MaterialPageRoute(
            builder: (context) {
              return QuoteApp(quoteId: quoteId);
            },
          );
        }
        return null;
      },
    );
  }
}
