import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/logging/app_log_service.dart';
import 'package:finarc/features/pending/notifications/notification_diagnostics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final logs = globalAppLogService;
  final service = NotificationDiagnosticsService(logs);

  setUp(() async {
    await logs.clearWhere((entry) => entry.category == 'notification_event');
  });

  test('aggregates notification counters and last event', () async {
    await logs.log(
      category: 'notification_event',
      message: 'ignored',
      meta: <String, Object?>{
        'source': 'appNotification',
        'package': 'com.phonepe.app',
        'title': 'PhonePe',
        'bodyPreview': 'message 1',
        'decision': 'ignored',
        'reason': 'ignored-no-finance-keyword',
        'parseResult': 'ignored-no-finance-keyword',
        'receivedAt': DateTime(2026, 5, 30, 10, 0).toIso8601String(),
      },
    );
    await logs.log(
      category: 'notification_event',
      message: 'pending-created',
      meta: <String, Object?>{
        'source': 'appNotification',
        'package': 'com.google.android.apps.nbu.paisa.user',
        'title': 'Google Pay',
        'bodyPreview': 'Paid ₹500',
        'decision': 'pending-created',
        'reason': 'success',
        'parseResult': 'parsed-pending-created',
        'confidenceLevel': 'HIGH',
        'localNotificationSent': true,
        'receivedAt': DateTime(2026, 5, 30, 10, 5).toIso8601String(),
      },
    );
    await logs.log(
      category: 'notification_event',
      message: 'duplicate',
      meta: <String, Object?>{
        'source': 'appNotification',
        'package': 'com.sbi.lotusintouch',
        'title': 'SBI',
        'bodyPreview': 'Duplicate',
        'decision': 'duplicate',
        'reason': 'duplicate-same-notification',
        'parseResult': 'duplicate-suppressed',
        'receivedAt': DateTime(2026, 5, 30, 10, 6).toIso8601String(),
      },
    );
    // SMS events should not affect notification-only diagnostics snapshot.
    await logs.log(
      category: 'notification_event',
      message: 'pending-created',
      meta: <String, Object?>{
        'source': 'sms',
        'package': 'JD-HDFCBK-S',
        'title': 'SMS',
        'bodyPreview': 'SMS event',
        'decision': 'pending-created',
        'reason': 'success',
      },
    );

    final snapshot = await service.loadSnapshot();
    expect(snapshot.received, 3);
    expect(snapshot.ignored, 1);
    expect(snapshot.parsed, 1);
    expect(snapshot.pendingCreated, 1);
    expect(snapshot.duplicatesBlocked, 1);
    expect(snapshot.localNotificationsSent, 1);
    expect(snapshot.lastEvent, isNotNull);
    expect(snapshot.lastEvent!.packageName, 'com.sbi.lotusintouch');
  });

  test('clear removes persisted notification events', () async {
    await logs.log(
      category: 'notification_event',
      message: 'ignored',
      meta: <String, Object?>{
        'source': 'appNotification',
        'package': 'com.phonepe.app',
        'title': 'PhonePe',
        'bodyPreview': 'test',
        'decision': 'ignored',
        'reason': 'ignored-no-finance-keyword',
      },
    );

    await service.clear();
    final snapshot = await service.loadSnapshot();
    expect(snapshot.received, 0);
    expect(snapshot.events, isEmpty);
  });
}
