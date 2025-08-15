import 'package:flutter/foundation.dart';

class Analytics {
  static final Analytics instance = Analytics._();

  Analytics._();

  Future<void> logEvent(String name, [Map<String, dynamic>? props]) async {
    // In a real app, this would send data to a service like Firebase or Amplitude.
    // For now, we'll just print to the console for debugging purposes.
    if (kDebugMode) {
      print('[Analytics] Event: $name, Properties: ${props ?? {}}');
    }
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
