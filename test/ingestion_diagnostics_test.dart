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
          preview: 'INR 1499 spent at SWIGGY',
          result: 'allowed-transactional-sender',
        ),
      );
      controller.append(
        NotificationDebugEntry(
          receivedAt: DateTime(2026, 5, 26, 10, 1),
          packageName: 'JD-HDFCBK-S',
          preview: 'INR 1499 spent at SWIGGY',
          result: 'parsed-pending-created',
        ),
      );
      controller.append(
        NotificationDebugEntry(
          receivedAt: DateTime(2026, 5, 26, 10, 2),
          packageName: 'BT-YESBNK-P',
          preview: 'promo',
          result: 'blocked-promotional-sender',
        ),
      );
      controller.append(
        NotificationDebugEntry(
          receivedAt: DateTime(2026, 5, 26, 10, 3),
          packageName: 'com.phonepe.app',
          preview: 'Paid ₹700 to Rahul',
          result: 'parsed-pending-created',
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
          preview: 'Paid',
          result: 'parsed-pending-created',
        ),
      );

      controller.clear();
      expect(controller.state.notificationsReceived, 0);
      expect(controller.state.lastNotificationResult, isNull);
    });
  });
}
