import '../../alerts/data/alert_service.dart';
import '../../alerts/data/alert_types.dart';
import 'notification_ingestion_service.dart';
import 'notification_local_notifier.dart';
import 'notification_payload.dart';
import 'sms_ingestion_service.dart';

class NotificationTestToolsService {
  const NotificationTestToolsService({
    required this.alertService,
    required this.notificationIngestionService,
    required this.smsIngestionService,
    required this.localNotifier,
  });

  final AlertService alertService;
  final NotificationIngestionService notificationIngestionService;
  final SmsIngestionService smsIngestionService;
  final NotificationLocalNotifier localNotifier;

  Future<void> sendTestNotification() {
    return localNotifier.showAlert(
      title: 'Finarc notifications are working',
      body:
          'You’ll receive reminders, alerts, and transaction confirmations here.',
      route: '/alerts',
      channelType: 'alerts',
    );
  }

  Future<int?> createTestAlert() async {
    final alert = await alertService.createAlert(
      CreateAlertInput(
        alertType: AlertType.info,
        title: 'Test alert',
        body: 'This alert was created locally for testing.',
        priority: AlertPriority.info,
        actionRoute: '/alerts',
        dedupeKey: 'manual_test_alert_${DateTime.now().millisecondsSinceEpoch}',
      ),
      dedupeWindow: Duration.zero,
    );
    return alert?.id;
  }

  Future<List<int>> mockTransactionNotification() {
    final payload = NotificationPayload(
      packageName: 'com.google.android.apps.nbu.paisa.user',
      appName: 'Google Pay',
      title: 'Payment successful',
      body: 'Paid ₹700 to Rahul Kumar via UPI. UPI Ref 123456789.',
      sourceType: 'appNotification',
      receivedAt: DateTime.now(),
    );
    return notificationIngestionService.processPayload(payload);
  }

  Future<List<int>> mockSmsTransaction() {
    final payload = NotificationPayload(
      packageName: 'android.sms',
      sender: 'JD-HDFCBK-S',
      title: 'JD-HDFCBK-S',
      body:
          'INR 1499 spent on your HDFC Bank Credit Card XX1234 at SWIGGY on 24-May. Avl limit INR 50000.',
      sourceType: 'sms',
      receivedAt: DateTime.now(),
    );
    return smsIngestionService.processSmsPayload(
      payload,
      bypassSenderFilter: true,
    );
  }
}
