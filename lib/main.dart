import 'package:flutter/material.dart';
import 'package:quotes_app/quote_app.dart';
import 'package:quotes_app/services/notification_service.dart';
import 'package:quotes_app/services/theme_controller.dart';
import 'package:timezone/data/latest_all.dart' as tz;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await NotificationService.init();
  await ThemeController.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    ThemeController.instance.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeController.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
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
