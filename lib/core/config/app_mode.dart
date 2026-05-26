import 'package:flutter/foundation.dart';

enum AppMode { safeDebug, personalDebug, release }

class AppModeConfig {
  static const String _mode = String.fromEnvironment(
    'APP_MODE',
    defaultValue: '',
  );

  static AppMode get current {
    if (kReleaseMode) return AppMode.release;
    switch (_mode.toLowerCase()) {
      case 'personaldebug':
      case 'personal_debug':
      case 'personal':
        return AppMode.personalDebug;
      case 'release':
        return AppMode.release;
      case 'safedebug':
      case 'safe_debug':
      case 'safe':
      default:
        return AppMode.safeDebug;
    }
  }

  static bool get isSafeDebug => current == AppMode.safeDebug;
  static bool get isPersonalDebug => current == AppMode.personalDebug;
  static bool get isRelease => current == AppMode.release;
  static bool get showModeBadge => !kReleaseMode;

  static String get label {
    switch (current) {
      case AppMode.safeDebug:
        return 'safeDebug';
      case AppMode.personalDebug:
        return 'personalDebug';
      case AppMode.release:
        return 'release';
    }
  }
}
