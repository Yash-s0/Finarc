import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/config/app_mode.dart';

class RealIngestionModeService {
  static const MethodChannel _channel = MethodChannel(
    'finarc/notification_control',
  );

  Future<bool> isAvailable() async {
    if (AppModeConfig.isSafeDebug) return false;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final available = await _channel.invokeMethod<bool>(
        'isRealIngestionAvailable',
      );
      return available ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
