import 'package:flutter/material.dart';
import 'dart:async';
import 'package:quotes_app/quote.dart';
import 'package:quotes_app/models/period_catalog.dart';
import 'package:quotes_app/services/analytics.dart';
import 'package:quotes_app/theme/lb_theme_extension.dart';

class AuthorInfo {
  final String name;
  final int? birthYear;
  final int? deathYear;
  int quoteCount;
  bool isSelected;

  AuthorInfo({
    required this.name,
    this.birthYear,
    this.deathYear,
    required this.quoteCount,
    this.isSelected = true,
  });

  String get lifeSpan {
    if (birthYear != null && deathYear != null) {
      return '$birthYear–$deathYear';
    } else if (birthYear != null) {
      return '$birthYear–';
    } else if (deathYear != null) {
      return '–$deathYear';
    }
    return '';
  }
}

class BrowseByPeriodFilterPage extends StatefulWidget {
  final List<Quote> allQuotes;
  final String? initialPeriod;
  final int? initialStartYear;
  final int? initialEndYear;

  const BrowseByPeriodFilterPage({
    super.key,
    required this.allQuotes,
    this.initialPeriod,
    this.initialStartYear,
    this.initialEndYear,
  });

  @override
  State<BrowseByPeriodFilterPage> createState() =>
      _BrowseByPeriodFilterPageState();
}

class _BrowseByPeriodFilterPageState extends State<BrowseByPeriodFilterPage> {
  late int _startYear;
  late int _endYear;
  String? _selectedPeriod;
  List<AuthorInfo> _authors = [];
  bool _isSubmitting = false;
  Timer? _rangeDebounce;

  @override
  void initState() {
    super.initState();

    // Check for route arguments first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && mounted) {
        final selectedPeriod = args['selectedPeriod'] as String?;
        final startYear = args['startYear'] as int?;
        final endYear = args['endYear'] as int?;

        if (selectedPeriod != null && startYear != null && endYear != null) {
          setState(() {
            _startYear = startYear;
            _endYear = endYear;
            _selectedPeriod = selectedPeriod;
          });
          _updateAuthors();
          return;
        }
      }
    });

    // Initialize with provided values or defaults
    if (widget.initialPeriod != null) {
      final period = PeriodCatalog.getPeriodByName(widget.initialPeriod!);
      if (period != null) {
        _startYear = period.startYear;
        _endYear = period.endYear;
        _selectedPeriod = period.name;
      } else {
        _initializeDefaults();
      }
    } else if (widget.initialStartYear != null &&
        widget.initialEndYear != null) {
      _startYear = widget.initialStartYear!;
      _endYear = widget.initialEndYear!;
      _selectedPeriod = null;
    } else {
      _initializeDefaults();
    }

    _updateAuthors();
    Analytics.instance.logEvent('browse_period.opened');
  }

  void _initializeDefaults() {
    // Default to Modernism period
    final defaultPeriod = PeriodCatalog.getPeriodByName('Modernism')!;
    _startYear = defaultPeriod.startYear;
    _endYear = defaultPeriod.endYear;
    _selectedPeriod = defaultPeriod.name;
  }

  @override
  void dispose() {
    _rangeDebounce?.cancel();
    super.dispose();
  }

  void _updateAuthors() {
    final filteredQuotes = PeriodCatalog.getQuotesForRange(
      widget.allQuotes,
      _startYear,
      _endYear,
    );

    // Group authors by name and collect their info
    final authorMap = <String, AuthorInfo>{};

    for (final quote in filteredQuotes) {
      final authorName = quote.authorName;

      if (authorMap.containsKey(authorName)) {
        authorMap[authorName]!.quoteCount++;
      } else {
        authorMap[authorName] = AuthorInfo(
          name: authorName,
          birthYear: quote.authorBirth,
          deathYear: quote.authorDeath,
          quoteCount: 1,
          isSelected: true,
        );
      }
    }

    setState(() {
      _authors = authorMap.values.toList()
        ..sort((a, b) {
          // Sort by birth year if available, then by name
          if (a.birthYear != null && b.birthYear != null) {
            return a.birthYear!.compareTo(b.birthYear!);
          }
          return a.name.compareTo(b.name);
        });
    });
  }

  void _selectPeriod(String periodName) {
    final period = PeriodCatalog.getPeriodByName(periodName);
    if (period != null) {
      setState(() {
        _selectedPeriod = periodName;
        _startYear = period.startYear;
        _endYear = period.endYear;
      });
      _updateAuthors();
      Analytics.instance.logEvent('browse_period.select_preset', {
        'period': periodName,
      });
    }
  }

  void _setCustomRange(int startYear, int endYear) {
    setState(() {
      _startYear = startYear;
      _endYear = endYear;
      _selectedPeriod = null; // Clear preset selection for custom range
    });
    _updateAuthors();
    Analytics.instance.logEvent('browse_period.custom_range', {
      'start': startYear,
      'end': endYear,
    });
  }

  void _applyFilter() {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
    });
    final selectedAuthors = _authors
        .where((author) => author.isSelected)
        .map((author) => author.name)
        .toSet();

    Analytics.instance.logEvent('browse_period.filter_applied', {
      'start_year': _startYear,
      'end_year': _endYear,
      'selected_authors': selectedAuthors.length,
    });

    // Return the filter data (like browse by author/tags pattern)
    // Defer pop to next frame to avoid Navigator re-entrancy (_debugLocked)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop({
          'period_filter': {
            'period_name': _selectedPeriod ?? '$_startYear–$_endYear',
            'start_year': _startYear,
            'end_year': _endYear,
            'selected_authors': selectedAuthors,
          },
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lbTheme = Theme.of(context).extension<LBTheme>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Browse by Period',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontFamily: 'EBGaramond',
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
      ),
      body: Column(
        children: [
          // Header with subtitle
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select a period or set a custom year range',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).primaryColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_startYear–$_endYear',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),

          // Preset chips
          _buildPresetChips(),

          const SizedBox(height: 16),

          // Custom range slider
          _buildRangeSlider(lbTheme),

          const SizedBox(height: 24),

          // Authors section header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Authors (${_authors.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          for (var author in _authors) {
                            author.isSelected = true;
                          }
                        });
                      },
                      child: const Text('Select All'),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          for (var author in _authors) {
                            author.isSelected = false;
                          }
                        });
                      },
                      child: const Text('Unselect All'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Authors list
          Expanded(child: _buildAuthorsList()),
        ],
      ),

      // Go button
      bottomNavigationBar: _buildGoButton(lbTheme),
    );
  }

  Widget _buildPresetChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: PeriodCatalog.periods.map((period) {
          final isSelected = _selectedPeriod == period.name;

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(period.name),
              selected: isSelected,
              onSelected: (selected) => _selectPeriod(period.name),
              backgroundColor: Theme.of(context).cardColor,
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).primaryColor.withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).primaryColor.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRangeSlider(LBTheme? lbTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: lbTheme?.controlSurface ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: lbTheme?.controlBorder ?? Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Custom Year Range',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          RangeSlider(
            values: RangeValues(_startYear.toDouble(), _endYear.toDouble()),
            min: PeriodCatalog.minYear.toDouble(),
            max: PeriodCatalog.maxYear.toDouble(),
            divisions: (PeriodCatalog.maxYear - PeriodCatalog.minYear) ~/ 10,
            labels: RangeLabels(_startYear.toString(), _endYear.toString()),
            onChanged: (values) {
              _rangeDebounce?.cancel();
              _rangeDebounce = Timer(const Duration(milliseconds: 150), () {
                if (mounted) {
                  _setCustomRange(values.start.round(), values.end.round());
                }
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                PeriodCatalog.minYear.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).primaryColor.withOpacity(0.7),
                ),
              ),
              Text(
                PeriodCatalog.maxYear.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).primaryColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorsList() {
    if (_authors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 48,
              color: Theme.of(context).primaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No authors found for this period',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).primaryColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your date range',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).primaryColor.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _authors.length,
      itemBuilder: (context, index) {
        final author = _authors[index];

        return CheckboxListTile(
          value: author.isSelected,
          onChanged: (value) {
            setState(() {
              author.isSelected = value ?? false;
            });
          },
          title: Text(
            author.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).primaryColor,
            ),
          ),
          subtitle: Text(
            author.lifeSpan.isNotEmpty ? author.lifeSpan : 'Unknown dates',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).primaryColor.withOpacity(0.7),
            ),
          ),
          dense: true,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        );
      },
    );
  }

  Widget _buildGoButton(LBTheme? lbTheme) {
    final selectedCount = _authors.where((a) => a.isSelected).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lbTheme?.controlSurface ?? Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: lbTheme?.controlBorder ?? Colors.grey.shade300,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$selectedCount authors selected',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).primaryColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: selectedCount > 0 && !_isSubmitting
                    ? _applyFilter
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFF1976D2,
                  ), // Dark blue to match slider
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(
                    0xFF1976D2,
                  ).withOpacity(0.3),
                  disabledForegroundColor: Colors.white.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Go',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
