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
}
