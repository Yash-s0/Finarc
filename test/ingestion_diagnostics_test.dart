import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/features/pending/notifications/notification_ingestion_service.dart';
import 'package:finarc/features/pending/notifications/notification_providers.dart';

void main() {
  group('ingestion diagnostics', () {
    test('sms and notification counters update', () {
      final controller = IngestionDiagnosticsController();

      controller.append(
        NotificationDebugEntry(
          receivedAt: DateTime(2026, 5, 26, 10),
          packageName: 'JD-HDFCBK-S',
          title: 'SMS Sender',
          bodyPreview: 'INR 1499 spent at SWIGGY',
          decision: 'parsed',
          reason: 'allowed-transactional-sender',
          result: 'allowed-transactional-sender',
          sourceType: 'sms',
        ),
      );
      controller.append(
        NotificationDebugEntry(
          receivedAt: DateTime(2026, 5, 26, 10, 1),
          packageName: 'JD-HDFCBK-S',
          title: 'SMS Sender',
          bodyPreview: 'INR 1499 spent at SWIGGY',
          decision: 'pending-created',
          reason: 'success',
          result: 'parsed-pending-created',
          sourceType: 'sms',
        ),
      );
      controller.append(
        NotificationDebugEntry(
          receivedAt: DateTime(2026, 5, 26, 10, 2),
          packageName: 'BT-YESBNK-P',
          title: 'Promo',
          bodyPreview: 'promo',
          decision: 'ignored',
          reason: 'blocked-promotional-sender',
          result: 'blocked-promotional-sender',
          sourceType: 'sms',
        ),
      );
      controller.append(
        NotificationDebugEntry(
          receivedAt: DateTime(2026, 5, 26, 10, 3),
          packageName: 'com.phonepe.app',
          title: 'PhonePe',
          bodyPreview: 'Paid ₹700 to Rahul',
          decision: 'pending-created',
          reason: 'success',
          result: 'parsed-pending-created',
          sourceType: 'appNotification',
        ),
      );

      final state = controller.state;
      expect(state.smsReceived, 3);
      expect(state.smsAllowed, 1);
      expect(state.smsParsedPending, 1);
      expect(state.smsBlockedPromotional, 1);
      expect(state.notificationsReceived, 1);
      expect(state.notificationsParsedPending, 1);
    });

    test('clear resets diagnostics', () {
      final controller = IngestionDiagnosticsController();
      controller.append(
        NotificationDebugEntry(
          receivedAt: DateTime(2026, 5, 26, 10),
          packageName: 'com.phonepe.app',
          title: 'PhonePe',
          bodyPreview: 'Paid',
          decision: 'pending-created',
          reason: 'success',
          result: 'parsed-pending-created',
          sourceType: 'appNotification',
        ),
      );

      controller.clear();
      expect(controller.state.notificationsReceived, 0);
      expect(controller.state.lastNotificationResult, isNull);
    });
  });
}
