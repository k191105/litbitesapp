import 'package:flutter/material.dart';
import 'package:quotes_app/quote_app.dart';
import 'package:quotes_app/services/notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await NotificationService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Literature Bites',
      navigatorKey: NotificationService.navigatorKey,
      theme: ThemeData(primarySwatch: Colors.blue),
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
