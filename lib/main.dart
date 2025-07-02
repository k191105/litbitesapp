import 'package:flutter/material.dart';
import 'quote_app.dart';

void main() {
  runApp(const QuotesMainApp());
}

class QuotesMainApp extends StatelessWidget {
  const QuotesMainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Literature Bites',
      home: const QuoteApp(),
    );
  }
}
