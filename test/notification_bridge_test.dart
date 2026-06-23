import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
