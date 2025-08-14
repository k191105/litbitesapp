import 'package:flutter/material.dart';
import 'package:quotes_app/quote.dart';

class PeriodQuotesPage extends StatelessWidget {
  final String periodName;
  final List<Quote> quotes;

  const PeriodQuotesPage({
    super.key,
    required this.periodName,
    required this.quotes,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          periodName,
          style: TextStyle(
            fontFamily: 'Georgia',
            color: Theme.of(context).primaryColor,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
      ),
      body: ListView.builder(
        itemCount: quotes.length,
        itemBuilder: (context, index) {
          final quote = quotes[index];
          return Card(
            color: Theme.of(context).cardColor,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '"${quote.text}"',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '— ${quote.authorInfo}',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 14,
                        color: Theme.of(context).primaryColor.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
