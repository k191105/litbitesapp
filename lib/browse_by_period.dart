import 'package:flutter/material.dart';
import 'package:quotes_app/period_quotes_page.dart';
import 'package:quotes_app/quote.dart';

class BrowseByPeriodPage extends StatefulWidget {
  final List<Quote> allQuotes;

  const BrowseByPeriodPage({super.key, required this.allQuotes});

  @override
  State<BrowseByPeriodPage> createState() => _BrowseByPeriodPageState();
}

class _BrowseByPeriodPageState extends State<BrowseByPeriodPage> {
  late Map<String, List<Quote>> _quotesByPeriod;
  List<String> _periods = [];

  @override
  void initState() {
    super.initState();
    _groupQuotesByPeriod();
  }

  void _groupQuotesByPeriod() {
    final Map<String, List<Quote>> periodMap = {};
    for (final quote in widget.allQuotes) {
      if (quote.period != null && quote.period!.isNotEmpty) {
        if (periodMap.containsKey(quote.period)) {
          periodMap[quote.period!]!.add(quote);
        } else {
          periodMap[quote.period!] = [quote];
        }
      }
    }
    _quotesByPeriod = periodMap;
    _periods = periodMap.keys.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Browse by Period',
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
        itemCount: _periods.length,
        itemBuilder: (context, index) {
          final period = _periods[index];
          final quoteCount = _quotesByPeriod[period]!.length;
          return ListTile(
            title: Text(
              period,
              style: TextStyle(
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
            subtitle: Text(
              '$quoteCount quote${quoteCount > 1 ? 's' : ''}',
              style: TextStyle(
                fontFamily: 'Georgia',
                color: Theme.of(context).primaryColor.withOpacity(0.7),
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PeriodQuotesPage(
                    periodName: period,
                    quotes: _quotesByPeriod[period]!,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
