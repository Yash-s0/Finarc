import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/config/app_mode.dart';

class RealIngestionModeService {
  static const MethodChannel _channel = MethodChannel(
    'finarc/notification_control',
  );

  Future<bool> isNotificationIngestionAvailable() async {
    if (AppModeConfig.isSafeDebug) return false;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final available = await _channel.invokeMethod<bool>(
        'isNotificationIngestionAvailable',
      );
      return available ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> isSmsIngestionAvailable() async {
    if (!AppModeConfig.isPersonalDebug) return false;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final available = await _channel.invokeMethod<bool>(
        'isSmsIngestionAvailable',
      );
      return available ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> isAvailable() async {
    final notificationAvailable = await isNotificationIngestionAvailable();
    final smsAvailable = await isSmsIngestionAvailable();
    return notificationAvailable || smsAvailable;
  }
}
