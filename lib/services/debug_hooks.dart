class DebugHooks {
  /// Called in debug when advancing the simulated day so app can run
  /// its normal "new day" pipelines (streak, notifications, etc.).
  static Future<void> Function()? onAdvanceDay;
}
