import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NotificationPermissionService {
  static const MethodChannel _channel = MethodChannel(
    'finarc/notification_control',
  );

  Future<bool> isAccessEnabled() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final enabled = await _channel.invokeMethod<bool>(
        'isNotificationAccessEnabled',
      );
      return enabled ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> openAccessSettings() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>('openNotificationAccessSettings');
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }
}
