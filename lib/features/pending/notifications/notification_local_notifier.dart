import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NotificationLocalNotifier {
  static const MethodChannel _channel = MethodChannel(
    'finarc/notification_control',
  );

  Future<void> showDetected({
    required String title,
    required String body,
    String route = '/pending',
    int? pendingId,
    bool showActions = true,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>('showDetectionNotification', {
        'title': title,
        'body': body,
        'route': route,
        'pendingId': pendingId,
        'showActions': showActions,
      });
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  Future<void> showReminder({
    required String title,
    required String body,
    String route = '/pending',
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>('showReminderNotification', {
        'title': title,
        'body': body,
        'route': route,
      });
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  Future<void> showAlert({
    required String title,
    required String body,
    String route = '/alerts',
    String channelType = 'alerts',
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>('showAlertNotification', {
        'title': title,
        'body': body,
        'route': route,
        'channelType': channelType,
      });
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  Future<void> scheduleReminder({
    required int reminderId,
    required DateTime triggerAt,
    required String title,
    required String body,
    required String route,
    bool repeatDaily = false,
    bool repeatWeekly = false,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>('scheduleReminderNotification', {
        'reminderId': reminderId,
        'triggerAtMillis': triggerAt.millisecondsSinceEpoch,
        'title': title,
        'body': body,
        'route': route,
        'repeatDaily': repeatDaily,
        'repeatWeekly': repeatWeekly,
      });
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  Future<void> cancelReminder(int reminderId) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>('cancelReminderNotification', {
        'reminderId': reminderId,
      });
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }
}
