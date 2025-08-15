import 'package:flutter/material.dart';
import 'package:quotes_app/models/notification_prefs.dart';
import 'package:quotes_app/services/analytics.dart';
import 'package:quotes_app/services/notification_service.dart';
import 'package:quotes_app/theme/lb_theme_extension.dart';
import 'package:quotes_app/quote.dart';
import 'package:quotes_app/browse_by_author.dart';
import 'package:quotes_app/browse.dart';

class NotificationEditorSheet extends StatefulWidget {
  final NotificationPrefs initialPrefs;
  final List<Quote> allQuotes;
  final List<Quote> favoriteQuotes;
  final Map<String, int> viewCounts;

  const NotificationEditorSheet({
    super.key,
    required this.initialPrefs,
    required this.allQuotes,
    required this.favoriteQuotes,
    required this.viewCounts,
  });

  @override
  State<NotificationEditorSheet> createState() =>
      _NotificationEditorSheetState();
}

class _NotificationEditorSheetState extends State<NotificationEditorSheet> {
  late NotificationPrefs _prefs;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _prefs = widget.initialPrefs;
    Analytics.instance.logEvent(Analytics.notifEditOpened);
  }

  @override
  Widget build(BuildContext context) {
    final lbTheme = Theme.of(context).extension<LBTheme>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildTimesSection(lbTheme),
                const SizedBox(height: 24),
                _buildWeekdaysSection(lbTheme),
                const SizedBox(height: 24),
                _buildSourceSection(lbTheme),
                const SizedBox(height: 80), // Space for footer
              ],
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Notification Settings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimesSection(LBTheme? lbTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Times per Day',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose 1-6 times when you\'d like to receive quotes',
          style: TextStyle(
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 16),

        // Count stepper
        Row(
          children: [
            IconButton(
              onPressed: _prefs.times.length > 1 ? _decreaseTimeCount : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text(
              '${_prefs.times.length}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            IconButton(
              onPressed: _prefs.times.length < 6 ? _increaseTimeCount : null,
              icon: const Icon(Icons.add_circle_outline),
            ),
            const SizedBox(width: 16),
            Text(
              '${_prefs.times.length} time${_prefs.times.length == 1 ? '' : 's'} per day',
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Time pickers
        ...List.generate(_prefs.times.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildTimePicker(index, lbTheme),
          );
        }),
      ],
    );
  }

  Widget _buildTimePicker(int index, LBTheme? lbTheme) {
    final time = _prefs.times[index];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: lbTheme?.controlSurface ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: lbTheme?.controlBorder ?? Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        children: [
          Icon(_getIconForTime(time), color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: () => _editTime(index),
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  IconData _getIconForTime(TimeOfDay time) {
    if (time.hour < 6) return Icons.bedtime;
    if (time.hour < 12) return Icons.wb_sunny;
    if (time.hour < 18) return Icons.wb_sunny_outlined;
    return Icons.nights_stay;
  }

  Widget _buildWeekdaysSection(LBTheme? lbTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Days of Week',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Select which days you want to receive notifications',
          style: TextStyle(
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 16),

        Wrap(
          spacing: 8,
          children: List.generate(7, (index) {
            final weekday = index + 1; // 1=Monday, 7=Sunday
            final isSelected = _prefs.weekdays.contains(weekday);
            final dayName = _getDayName(weekday);

            return FilterChip(
              label: Text(dayName),
              selected: isSelected,
              onSelected: (selected) => _toggleWeekday(weekday),
              backgroundColor: lbTheme?.controlSurface,
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              checkmarkColor: Theme.of(context).primaryColor,
            );
          }),
        ),
      ],
    );
  }

  String _getDayName(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[weekday - 1];
  }

  Widget _buildSourceSection(LBTheme? lbTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quote Sources',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Filter quotes by authors or tags',
          style: TextStyle(
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 16),

        // Authors
        _buildSourceSubsection(
          'Authors',
          _prefs.authors.isNotEmpty
              ? '${_prefs.authors.length} selected'
              : 'All authors',
          () => _editAuthors(),
          lbTheme,
        ),

        const SizedBox(height: 12),

        // Tags
        _buildSourceSubsection(
          'Tags',
          _prefs.tags.isNotEmpty
              ? '${_prefs.tags.length} selected'
              : 'All tags',
          () => _editTags(),
          lbTheme,
        ),

        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSourceSubsection(
    String title,
    String subtitle,
    VoidCallback onTap,
    LBTheme? lbTheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: lbTheme?.controlSurface ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: lbTheme?.controlBorder ?? Theme.of(context).dividerColor,
        ),
      ),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _savePreferences,
              child: _isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }

  void _increaseTimeCount() {
    if (_prefs.times.length >= 6) return;

    setState(() {
      final newTimes = List<TimeOfDay>.from(_prefs.times);
      // Add a new time 2 hours after the last one, wrapping around if needed
      final lastTime = newTimes.last;
      final newHour = (lastTime.hour + 2) % 24;
      newTimes.add(TimeOfDay(hour: newHour, minute: lastTime.minute));
      newTimes.sort((a, b) => a.hour.compareTo(b.hour));

      _prefs = _prefs.copyWith(times: newTimes);
    });

    Analytics.instance.logEvent(Analytics.notifCountChanged, {
      'count': _prefs.times.length,
    });
  }

  void _decreaseTimeCount() {
    if (_prefs.times.length <= 1) return;

    setState(() {
      final newTimes = List<TimeOfDay>.from(_prefs.times);
      newTimes.removeLast();

      _prefs = _prefs.copyWith(times: newTimes);
    });

    Analytics.instance.logEvent(Analytics.notifCountChanged, {
      'count': _prefs.times.length,
    });
  }

  void _editTime(int index) async {
    final currentTime = _prefs.times[index];
    final newTime = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );

    if (newTime != null && newTime != currentTime) {
      setState(() {
        final newTimes = List<TimeOfDay>.from(_prefs.times);
        newTimes[index] = newTime;
        newTimes.sort((a, b) => a.hour.compareTo(b.hour));

        _prefs = _prefs.copyWith(times: newTimes);
      });

      Analytics.instance.logEvent(Analytics.notifTimesChanged, {
        'times': _prefs.times.map((t) => '${t.hour}:${t.minute}').toList(),
      });
    }
  }

  void _toggleWeekday(int weekday) {
    setState(() {
      final newWeekdays = Set<int>.from(_prefs.weekdays);
      if (newWeekdays.contains(weekday)) {
        // Don't allow removing all weekdays
        if (newWeekdays.length > 1) {
          newWeekdays.remove(weekday);
        }
      } else {
        newWeekdays.add(weekday);
      }

      _prefs = _prefs.copyWith(weekdays: newWeekdays);
    });

    Analytics.instance.logEvent(Analytics.notifWeekdaysChanged, {
      'days': _prefs.weekdays.length,
    });
  }

  void _editAuthors() async {
    final result = await Navigator.push<Set<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => BrowseByAuthorPage(
          allQuotes: widget.allQuotes,
          initialSelectedAuthors: _prefs.authors,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _prefs = _prefs.copyWith(authors: result);
      });

      Analytics.instance.logEvent(Analytics.notifSourceChanged, {
        'authors_n': result.length,
        'tags_n': _prefs.tags.length,
      });
    }
  }

  void _editTags() async {
    final result = await Navigator.push<Set<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => BrowsePage(
          allQuotes: widget.allQuotes,
          initialSelectedTags: _prefs.tags,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _prefs = _prefs.copyWith(tags: result);
      });

      Analytics.instance.logEvent(Analytics.notifSourceChanged, {
        'authors_n': _prefs.authors.length,
        'tags_n': result.length,
      });
    }
  }

  void _savePreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Save preferences
      await NotificationService.saveNotificationPrefs(_prefs);

      // Sync notifications with new preferences
      await NotificationService.syncWithPrefs(
        _prefs,
        DateTime.now(),
        feed: widget.allQuotes,
        favoriteQuotes: widget.favoriteQuotes,
      );

      if (mounted) {
        Navigator.of(context).pop(_prefs);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification preferences saved!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preferences: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
