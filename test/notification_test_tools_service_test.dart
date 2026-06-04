import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/features/alerts/data/alert_service.dart';
import 'package:finarc/features/expenses/data/transaction_engine.dart';
import 'package:finarc/features/pending/data/pending_service.dart';
import 'package:finarc/features/pending/notifications/notification_fingerprint.dart';
import 'package:finarc/features/pending/notifications/notification_ingestion_service.dart';
import 'package:finarc/features/pending/notifications/notification_keyword_filter.dart';
import 'package:finarc/features/pending/notifications/notification_local_notifier.dart';
import 'package:finarc/features/pending/notifications/notification_test_tools_service.dart';
import 'package:finarc/features/pending/notifications/sms_fingerprint.dart';
import 'package:finarc/features/pending/notifications/sms_ingestion_service.dart';
import 'package:finarc/features/pending/notifications/sms_sender_filter.dart';
import 'package:finarc/features/pending/parsing/parsers/card_notification_parser.dart';
import 'package:finarc/features/pending/parsing/parsers/generic_bank_sms_parser.dart';
import 'package:finarc/features/pending/parsing/parsers/generic_fallback_parser.dart';
import 'package:finarc/features/pending/parsing/parsers/upi_notification_parser.dart';
import 'package:finarc/features/pending/parsing/pending_ingestion_service.dart';
import 'package:finarc/features/pending/parsing/transaction_parser_registry.dart';

class _FakeNotifier extends NotificationLocalNotifier {
  int alertsShown = 0;

  @override
  Future<void> showAlert({
    required String title,
    required String body,
    String route = '/alerts',
    String channelType = 'alerts',
  }) async {
    alertsShown += 1;
  }

  @override
  Future<void> showDetected({
    required String title,
    required String body,
    String route = '/pending',
    int? pendingId,
    bool showActions = true,
  }) async {}
}

void main() {
  late AppDatabase db;
  late NotificationTestToolsService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    final pendingService = PendingService(db, TransactionEngine(db));
    final parserRegistry = TransactionParserRegistry(
      parsers: [
        UpiNotificationParser(),
        CardNotificationParser(),
        GenericBankSmsParser(),
      ],
      fallbackParser: GenericFallbackParser(),
    );
    final pendingIngestion = PendingIngestionService(
      db,
      pendingService,
      parserRegistry,
    );
    final notifier = _FakeNotifier();

    final notificationIngestionService = NotificationIngestionService(
      database: db,
      pendingIngestionService: pendingIngestion,
      pendingService: pendingService,
      keywordFilter: NotificationKeywordFilter(),
      fingerprint: NotificationFingerprint(),
      localNotifier: notifier,
      isDetectionEnabled: () => true,
      shouldShowDetectionNotifications: () => true,
      appendDebug: (_) {},
    );
    final smsIngestionService = SmsIngestionService(
      database: db,
      pendingIngestionService: pendingIngestion,
      keywordFilter: NotificationKeywordFilter(),
      fingerprint: SmsFingerprint(),
      localNotifier: notifier,
      isSmsDetectionEnabled: () => true,
      isSmsPermissionGranted: () => true,
      shouldShowDetectionNotifications: () => true,
      appendDebug: (_) {},
      senderFilter: const SmsSenderFilter(),
    );

    service = NotificationTestToolsService(
      alertService: AlertService(db),
      notificationIngestionService: notificationIngestionService,
      smsIngestionService: smsIngestionService,
      localNotifier: notifier,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('create test alert creates alert row', () async {
    final id = await service.createTestAlert();
    expect(id, isNotNull);

    final alerts = await db.select(db.alerts).get();
    expect(alerts.length, 1);
    expect(alerts.first.alertType, 'info');
  });

  test('mock transaction notification creates pending transaction', () async {
    final ids = await service.mockTransactionNotification();
    expect(ids, isNotEmpty);

    final pending = await db.select(db.pendingTransactions).get();
    expect(pending.length, 1);
    expect(pending.first.sourceType, 'appNotification');
  });

  test('mock SMS transaction creates pending transaction', () async {
    final ids = await service.mockSmsTransaction();
    expect(ids, isNotEmpty);

    final pending = await db.select(db.pendingTransactions).get();
    expect(pending.length, 1);
    expect(pending.first.sourceType, 'sms');
  });

  test(
    'send test notification call does not crash with fake notifier',
    () async {
      await service.sendTestNotification();
      final notifier = service.localNotifier as _FakeNotifier;
      expect(notifier.alertsShown, 1);
    },
  );
}
