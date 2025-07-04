import 'package:flutter/material.dart';
import 'package:quotes_app/period_quotes_page.dart';
import 'package:quotes_app/quote.dart';

class BrowseByPeriodPage extends StatefulWidget {
  final List<Quote> allQuotes;
  final bool isDarkMode;

  const BrowseByPeriodPage({
    super.key,
    required this.allQuotes,
    required this.isDarkMode,
  });

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
      backgroundColor: widget.isDarkMode
          ? Colors.black
          : const Color.fromARGB(255, 240, 234, 225),
      appBar: AppBar(
        title: Text(
          'Browse by Period',
          style: TextStyle(
            fontFamily: 'Georgia',
            color: widget.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: widget.isDarkMode
            ? Colors.black
            : const Color.fromARGB(255, 240, 234, 225),
        elevation: 0,
        iconTheme: IconThemeData(
          color: widget.isDarkMode ? Colors.white : Colors.black,
        ),
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
                color: widget.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            subtitle: Text(
              '$quoteCount quote${quoteCount > 1 ? 's' : ''}',
              style: TextStyle(
                fontFamily: 'Georgia',
                color: widget.isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PeriodQuotesPage(
                    periodName: period,
                    quotes: _quotesByPeriod[period]!,
                    isDarkMode: widget.isDarkMode,
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
