import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'package:finarc/features/pending/notifications/notification_bridge.dart';
import 'package:finarc/features/pending/notifications/notification_payload.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('finarc/notification_control');

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('drains captured payloads before consuming launch route', () async {
    final calls = <String>[];
    final payloadProcessed = Completer<void>();
    final routes = <String>[];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          switch (call.method) {
            case 'isNotificationAccessEnabled':
              return true;
            case 'drainCapturedNotifications':
              return [
                {
                  'packageName': 'com.snapwork.hdfc',
                  'appName': 'HDFC Bank',
                  'title': 'Debit alert',
                  'body': 'INR 1,499 spent at SWIGGY',
                  'receivedAt': DateTime(
                    2026,
                    6,
                    23,
                    10,
                  ).millisecondsSinceEpoch,
                  'sourceType': 'appNotification',
                },
              ];
            case 'consumeLaunchRoute':
              expect(payloadProcessed.isCompleted, isTrue);
              return '/pending';
          }
          return null;
        });

    final bridge = NotificationBridge();
    await bridge.initialize(
      onPayload: (NotificationPayload payload) async {
        expect(payload.combinedText, contains('SWIGGY'));
        payloadProcessed.complete();
      },
      onRoute: (route) {
        routes.add(route);
      },
    );

    expect(
      calls,
      containsAllInOrder([
        'isNotificationAccessEnabled',
        'drainCapturedNotifications',
        'consumeLaunchRoute',
      ]),
    );
    expect(routes, ['/pending']);
    await bridge.dispose();
  });

  test('drains captured payloads again when app resumes', () async {
    final calls = <String>[];
    final payloads = <NotificationPayload>[];
    var drainCount = 0;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          switch (call.method) {
            case 'isNotificationAccessEnabled':
              return true;
            case 'drainCapturedNotifications':
              drainCount += 1;
              if (drainCount == 1) return [];
              return [
                {
                  'packageName': 'com.google.android.apps.messaging',
                  'appName': 'Messages',
                  'title': 'VA-ICICIT-S',
                  'body':
                      'INR 752.00 spent using ICICI Bank Card XX9000 on 25-Jun-26 on AMAZON PAY IN G. Avl Limit: INR 27,357.98.',
                  'receivedAt': DateTime(
                    2026,
                    6,
                    25,
                    16,
                    2,
                  ).millisecondsSinceEpoch,
                  'sourceType': 'appNotification',
                },
              ];
            case 'consumeLaunchRoute':
              return null;
          }
          return null;
        });

    final bridge = NotificationBridge();
    await bridge.initialize(
      onPayload: (payload) async {
        payloads.add(payload);
      },
      onRoute: (_) {},
    );

    bridge.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(
      calls.where((method) => method == 'drainCapturedNotifications').length,
      2,
    );
    expect(payloads, hasLength(1));
    expect(payloads.single.title, 'VA-ICICIT-S');
    expect(payloads.single.body, contains('INR 752.00 spent'));
    await bridge.dispose();
  });
}
