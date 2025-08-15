import 'package:flutter/material.dart';

class NotificationPrefs {
  final List<TimeOfDay> times; // sorted, unique, local time
  final Set<String> authors; // optional; empty = no author filter
  final Set<String> tags; // optional; empty = no tag filter
  final int? startYear; // optional
  final int? endYear; // optional
  final Set<int> weekdays; // 1=Mon … 7=Sun; default all 7
  final int dailyCap; // guards double scheduling; default times.length
  final int lookbackDays; // de-duplicate within N days; default 14
  final int version; // schema version

  const NotificationPrefs({
    required this.times,
    this.authors = const {},
    this.tags = const {},
    this.startYear,
    this.endYear,
    this.weekdays = const {1, 2, 3, 4, 5, 6, 7},
    this.dailyCap = 2,
    this.lookbackDays = 14,
    this.version = 1,
  });

  /// Default free tier preferences: 2 times per day, no filters
  static NotificationPrefs defaultFree() {
    return const NotificationPrefs(
      times: [
        TimeOfDay(hour: 9, minute: 0), // 09:00
        TimeOfDay(hour: 20, minute: 0), // 20:00
      ],
      dailyCap: 2,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'times': times
          .map(
            (t) =>
                '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
          )
          .toList(),
      'authors': authors.toList(),
      'tags': tags.toList(),
      'startYear': startYear,
      'endYear': endYear,
      'weekdays': weekdays.toList(),
      'dailyCap': dailyCap,
      'lookbackDays': lookbackDays,
      'version': version,
    };
  }

  static NotificationPrefs fromJson(Map<String, dynamic> json) {
    final timeStrings = List<String>.from(json['times'] ?? []);
    final times = timeStrings.map((timeStr) {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }).toList();

    return NotificationPrefs(
      times: times,
      authors: Set<String>.from(json['authors'] ?? []),
      tags: Set<String>.from(json['tags'] ?? []),
      startYear: json['startYear'],
      endYear: json['endYear'],
      weekdays: Set<int>.from(json['weekdays'] ?? [1, 2, 3, 4, 5, 6, 7]),
      dailyCap: json['dailyCap'] ?? 2,
      lookbackDays: json['lookbackDays'] ?? 14,
      version: json['version'] ?? 1,
    );
  }

  NotificationPrefs copyWith({
    List<TimeOfDay>? times,
    Set<String>? authors,
    Set<String>? tags,
    int? startYear,
    int? endYear,
    Set<int>? weekdays,
    int? dailyCap,
    int? lookbackDays,
    int? version,
  }) {
    return NotificationPrefs(
      times: times ?? this.times,
      authors: authors ?? this.authors,
      tags: tags ?? this.tags,
      startYear: startYear ?? this.startYear,
      endYear: endYear ?? this.endYear,
      weekdays: weekdays ?? this.weekdays,
      dailyCap: dailyCap ?? this.dailyCap,
      lookbackDays: lookbackDays ?? this.lookbackDays,
      version: version ?? this.version,
    );
  }

  /// Check if this is effectively the default free configuration
  bool get isDefaultFree {
    return times.length == 2 &&
        times.contains(const TimeOfDay(hour: 9, minute: 0)) &&
        times.contains(const TimeOfDay(hour: 20, minute: 0)) &&
        authors.isEmpty &&
        tags.isEmpty &&
        startYear == null &&
        endYear == null &&
        weekdays.length == 7;
  }

  /// Get a human-readable description of the schedule
  String get scheduleDescription {
    if (times.isEmpty) return 'No reminders';
    if (times.length == 1) return '1/day';
    return '${times.length}/day';
  }

  /// Get formatted times string for display
  String get timesDisplay {
    if (times.isEmpty) return 'None';
    return times
        .map(
          (t) =>
              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
        )
        .join(' • ');
  }

  /// Check if notifications should be sent on a specific weekday
  bool isActiveOnWeekday(int weekday) {
    return weekdays.contains(weekday);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NotificationPrefs) return false;

    return _listEquals(times, other.times) &&
        _setEquals(authors, other.authors) &&
        _setEquals(tags, other.tags) &&
        startYear == other.startYear &&
        endYear == other.endYear &&
        _setEquals(weekdays, other.weekdays) &&
        dailyCap == other.dailyCap &&
        lookbackDays == other.lookbackDays &&
        version == other.version;
  }

  @override
  int get hashCode {
    return Object.hash(
      Object.hashAll(times),
      Object.hashAll(authors),
      Object.hashAll(tags),
      startYear,
      endYear,
      Object.hashAll(weekdays),
      dailyCap,
      lookbackDays,
      version,
    );
  }

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _setEquals<T>(Set<T> a, Set<T> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }
}
