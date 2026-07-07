import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/config/app_mode.dart';
import 'package:finarc/features/pending/notifications/real_ingestion_mode_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('finarc/notification_control');
  final calls = <String>[];

  setUp(() {
    calls.clear();
    AppModeConfig.debugOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          switch (call.method) {
            case 'isNotificationIngestionAvailable':
              return true;
            case 'isSmsIngestionAvailable':
              return true;
            default:
              return false;
          }
        });
  });

  tearDown(() {
    AppModeConfig.debugOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('safeDebug mode disables notification and SMS ingestion', () async {
    AppModeConfig.debugOverride = AppMode.safeDebug;
    final service = RealIngestionModeService();

    expect(await service.isNotificationIngestionAvailable(), isFalse);
    expect(await service.isSmsIngestionAvailable(), isFalse);
    expect(await service.isAvailable(), isFalse);
    expect(calls, isEmpty);
  });

  test(
    'release mode enables notification and SMS ingestion when native bridge is available',
    () async {
      AppModeConfig.debugOverride = AppMode.release;
      final service = RealIngestionModeService();

      expect(await service.isNotificationIngestionAvailable(), isTrue);
      expect(await service.isSmsIngestionAvailable(), isTrue);
      expect(await service.isAvailable(), isTrue);
      expect(calls, contains('isNotificationIngestionAvailable'));
      expect(calls, contains('isSmsIngestionAvailable'));
    },
  );

  test('personalDebug mode enables notification and SMS ingestion', () async {
    AppModeConfig.debugOverride = AppMode.personalDebug;
    final service = RealIngestionModeService();

    expect(await service.isNotificationIngestionAvailable(), isTrue);
    expect(await service.isSmsIngestionAvailable(), isTrue);
    expect(await service.isAvailable(), isTrue);
    expect(calls, contains('isNotificationIngestionAvailable'));
    expect(calls, contains('isSmsIngestionAvailable'));
  });
}
