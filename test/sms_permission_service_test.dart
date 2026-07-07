import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/features/pending/notifications/sms_permission_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('finarc/notification_control');
  final calls = <String>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          switch (call.method) {
            case 'isSmsPermissionGranted':
              return true;
            case 'isReadSmsPermissionGranted':
              return true;
            case 'isReceiveSmsPermissionGranted':
              return false;
            case 'isSmsReceiverComponentAvailable':
              return true;
            case 'isSmsReceiverComponentEnabled':
              return true;
            case 'shouldShowSmsPermissionRationale':
              return false;
            case 'getSmsReceiverDiagnostics':
              return <String, dynamic>{
                'readSmsGranted': true,
                'receiveSmsGranted': false,
                'smsPermissionGranted': false,
                'receiverDeclared': true,
                'receiverEnabled': true,
                'lastReceivedAtMillis': 1716700000000,
                'lastSender': 'JD-HDFCBK-S',
                'lastCallbackSuccessAtMillis': 1716700001000,
                'lastError': null,
              };
            case 'previewRecentSms':
            case 'previewSmsRange':
              return <Map<String, Object?>>[
                {
                  'packageName': 'android.sms',
                  'appName': 'SMS',
                  'sender': 'CP-AXISBK-S',
                  'title': 'CP-AXISBK-S',
                  'body': 'Spent INR 33275.73 Axis Bank Card no. XX0374',
                  'receivedAt': 1783429500000,
                  'sourceType': 'sms',
                  'isOngoing': false,
                  'category': 'sms',
                },
              ];
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('permission and component methods bridge to method channel', () async {
    final service = SmsPermissionService();

    expect(await service.isPermissionGranted(), isTrue);
    expect(await service.isReadPermissionGranted(), isTrue);
    expect(await service.isReceivePermissionGranted(), isFalse);
    expect(await service.isReceiverComponentAvailable(), isTrue);
    expect(await service.isReceiverComponentEnabled(), isTrue);
    expect(await service.shouldShowPermissionRationale(), isFalse);

    expect(calls, contains('isSmsPermissionGranted'));
    expect(calls, contains('isReadSmsPermissionGranted'));
    expect(calls, contains('isReceiveSmsPermissionGranted'));
    expect(calls, contains('shouldShowSmsPermissionRationale'));
  });

  test('runtime diagnostics maps native payload correctly', () async {
    final service = SmsPermissionService();
    final diagnostics = await service.getRuntimeDiagnostics();

    expect(diagnostics.readSmsGranted, isTrue);
    expect(diagnostics.receiveSmsGranted, isFalse);
    expect(diagnostics.smsPermissionGranted, isFalse);
    expect(diagnostics.receiverDeclared, isTrue);
    expect(diagnostics.receiverEnabled, isTrue);
    expect(diagnostics.lastSender, 'JD-HDFCBK-S');
    expect(diagnostics.lastReceivedAt, isNotNull);
    expect(diagnostics.lastCallbackSuccessAt, isNotNull);
  });

  test('previewRecentSms maps native rows', () async {
    final service = SmsPermissionService();
    final rows = await service.previewRecentSms(60);

    expect(calls, contains('previewRecentSms'));
    expect(rows, hasLength(1));
    expect(rows.single.sender, 'CP-AXISBK-S');
    expect(rows.single.body, contains('33275.73'));
    expect(rows.single.toPayloadMap()['sourceType'], 'sms');
  });

  test('previewSmsRange maps native rows', () async {
    final service = SmsPermissionService();
    final rows = await service.previewSmsRange(
      from: DateTime(2026, 7, 1),
      to: DateTime(2026, 7, 7, 23, 59),
    );

    expect(calls, contains('previewSmsRange'));
    expect(rows, hasLength(1));
    expect(rows.single.sender, 'CP-AXISBK-S');
  });
}
