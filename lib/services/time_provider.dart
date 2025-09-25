import 'dart:async';
import 'package:flutter/widgets.dart';

/// Extension on BuildContext to easily access the current time
extension TimeProviderExtension on BuildContext {
  TimeProvider get timeProvider =>
      TimeProviderInheritedWidget.of(this)!.timeProvider;

  DateTime get now => timeProvider.now();
}

// Global time provider instance - must be initialized in main()
late final TimeProvider timeProvider;

/// InheritedWidget to propagate time changes down the widget tree
class TimeProviderInheritedWidget extends InheritedWidget {
  const TimeProviderInheritedWidget({
    super.key,
    required this.timeProvider,
    required super.child,
  });

  final TimeProvider timeProvider;

  static TimeProviderInheritedWidget? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<TimeProviderInheritedWidget>();
  }

  @override
  bool updateShouldNotify(TimeProviderInheritedWidget oldWidget) {
    return timeProvider != oldWidget.timeProvider;
  }
}

/// Abstract time provider interface
abstract class TimeProvider {
  DateTime now();
}

/// Real system time provider
class SystemTimeProvider implements TimeProvider {
  @override
  DateTime now() => DateTime.now();
}

/// Fake time provider for testing/debugging
class FakeTimeProvider implements TimeProvider {
  DateTime _current;
  Timer? _timer;
  final Duration _advanceInterval;
  final Duration _advanceAmount;
  final bool _autoAdvance;
  final StreamController<DateTime> _timeController =
      StreamController.broadcast();

  FakeTimeProvider({
    DateTime? initialTime,
    Duration? advanceInterval,
    Duration? advanceAmount,
    bool autoAdvance = true,
  }) : _current = initialTime ?? DateTime.now(),
       _advanceInterval = advanceInterval ?? const Duration(seconds: 30),
       _advanceAmount = advanceAmount ?? const Duration(days: 1),
       _autoAdvance = autoAdvance {
    if (_autoAdvance) {
      _startTimer();
    }
  }

  @override
  DateTime now() => _current;

  /// Stream of time changes for widgets to listen to
  Stream<DateTime> get timeStream => _timeController.stream;

  /// Advance time by the specified duration
  void advance(Duration duration) {
    _current = _current.add(duration);
    _timeController.add(_current);
  }

  /// Set time to a specific value
  void setTime(DateTime newTime) {
    _current = newTime;
    _timeController.add(_current);
  }

  /// Start the auto-advance timer
  void _startTimer() {
    if (_timer != null) {
      _timer!.cancel();
    }

    _timer = Timer.periodic(_advanceInterval, (_) {
      _current = _current.add(_advanceAmount);
      _timeController.add(_current);
    });
  }

  /// Stop the auto-advance timer
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Reset to current system time
  void reset() {
    _current = DateTime.now();
    _timeController.add(_current);
  }

  /// Dispose of the timer and controller
  void dispose() {
    stop();
    _timeController.close();
  }
}
