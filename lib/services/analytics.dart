import 'package:flutter/foundation.dart';

class Analytics {
  static final Analytics instance = Analytics._();

  Analytics._();

  Future<void> logEvent(String name, [Map<String, dynamic>? props]) async {
    // In production, this would send data to a service like Firebase or Amplitude.
    // For now, we'll only log critical events in release mode and all events in debug.
    final isProduction = const bool.fromEnvironment('dart.vm.product');

    // Always log critical events, but filter out noisy events in production
    final isCriticalEvent = _isCriticalEvent(name);

    if (kDebugMode || isProduction && isCriticalEvent) {
      // In production, you might want to use a proper logging service
      print('[Analytics] Event: $name, Properties: ${props ?? {}}');
    }
  }

  bool _isCriticalEvent(String eventName) {
    // Only log these critical events in production to reduce noise
    const criticalEvents = {
      'purchase.success',
      'purchase.error',
      'purchase.entitlement_changed',
      'purchase.store_error',
      'streak.milestone_shown',
      'learn.srs_cap_reached',
    };
    return criticalEvents.contains(eventName);
  }

  // Learn Hub Events
  static const String learnGuidedOpened = 'learn.guided_opened';
  static const String learnGuidedStarted = 'learn.guided_started';
  static const String learnGuidedAnswer = 'learn.guided_answer';
  static const String learnGuidedFinished = 'learn.guided_finished';
  static const String learnSrsOpened = 'learn.srs_opened';
  static const String learnSrsStarted = 'learn.srs_started';
  static const String learnSrsGraded = 'learn.srs_graded';
  static const String learnSrsFinished = 'learn.srs_finished';
  static const String learnSrsCapReached = 'learn.srs_cap_reached';
  static const String learnAddToSrs = 'learn.add_to_srs';
  static const String learnPaywallPrompt = 'learn.paywall_prompt';

  // Notification Events
  static const String notifSettingsOpened = 'notif.settings_opened';
  static const String notifEditOpened = 'notif.edit_opened';
  static const String notifCountChanged = 'notif.count_changed';
  static const String notifTimesChanged = 'notif.times_changed';
  static const String notifWeekdaysChanged = 'notif.weekdays_changed';
  static const String notifSourceChanged = 'notif.source_changed';
  static const String notifScheduledTotal = 'notif.scheduled_total';
  static const String notifDelivered = 'notif.delivered';
  static const String notifTapped = 'notif.tapped';
}
