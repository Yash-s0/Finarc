import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/features/expenses/data/transaction_engine.dart';
import 'package:finarc/features/pending/data/pending_service.dart';
import 'package:finarc/features/pending/notifications/notification_keyword_filter.dart';
import 'package:finarc/features/pending/notifications/notification_local_notifier.dart';
import 'package:finarc/features/pending/notifications/notification_payload.dart';
import 'package:finarc/features/pending/notifications/notification_fingerprint.dart';
import 'package:finarc/features/pending/notifications/notification_ingestion_service.dart';
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
  int showCount = 0;

  @override
  Future<void> showDetected({
    required String title,
    required String body,
    String route = '/pending',
    int? pendingId,
    bool showActions = true,
  }) async {
    showCount += 1;
  }
}

void main() {
  group('sms keyword filter', () {
    test('accepts transaction SMS keyword set', () {
      final filter = NotificationKeywordFilter();
      final payload = NotificationPayload(
        packageName: 'android.sms',
        sourceType: 'sms',
        receivedAt: DateTime(2026, 5, 25, 9),
        sender: 'JD-HDFCBK-S',
        body: 'INR 1200 debited from your A/c. Avl Bal INR 5000',
      );
      final result = filter.evaluate(payload);
      expect(result.accepted, isTrue);
    });
  });

  group('sms sender filter', () {
    const filter = SmsSenderFilter();

    test('JD-PAYZAP-S allowed', () {
      expect(filter.evaluate('JD-PAYZAP-S').accepted, isTrue);
    });

    test('JD-HDFCBK-S allowed', () {
      expect(filter.evaluate('JD-HDFCBK-S').accepted, isTrue);
    });

    test('AD-INDUSB-T allowed', () {
      expect(filter.evaluate('AD-INDUSB-T').accepted, isTrue);
    });

    test('BT-YESBNK-P blocked', () {
      final result = filter.evaluate('BT-YESBNK-P');
      expect(result.accepted, isFalse);
      expect(result.reason, 'blocked-promotional-sender');
    });

    test('lowercase normalization works', () {
      expect(filter.evaluate('jd-hdfcbk-s').accepted, isTrue);
    });

    test('phone number sender blocked for auto-ingestion', () {
      final result = filter.evaluate('+919876543210');
      expect(result.accepted, isFalse);
      expect(result.reason, 'blocked-unknown-sender');
    });
  });

  group('sms fingerprint', () {
    test('suppresses duplicates', () {
      final fp = SmsFingerprint();
      final key = fp.build(
        sender: 'HDFCBK',
        body: 'INR 1200 debited from your account',
        receivedAt: DateTime(2026, 5, 25, 9, 0, 0, 100),
      );
      expect(fp.isDuplicate(key, DateTime(2026, 5, 25, 9, 0, 0, 100)), isFalse);
      expect(fp.isDuplicate(key, DateTime(2026, 5, 25, 9, 1, 0, 100)), isTrue);
    });
  });

  group('sms ingestion service', () {
    late AppDatabase db;
    late SmsIngestionService smsService;
    late PendingIngestionService pendingIngestion;
    late PendingService pendingService;
    late _FakeNotifier notifier;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      pendingService = PendingService(db, TransactionEngine(db));
      final registry = TransactionParserRegistry(
        parsers: [
          UpiNotificationParser(),
          CardNotificationParser(),
          GenericBankSmsParser(),
        ],
        fallbackParser: GenericFallbackParser(),
      );
      pendingIngestion = PendingIngestionService(db, pendingService, registry);
      notifier = _FakeNotifier();
      smsService = SmsIngestionService(
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
    });

    tearDown(() async {
      await db.close();
    });

    test('sms payload -> parser input conversion', () {
      final payload = NotificationPayload(
        packageName: 'android.sms',
        sourceType: 'sms',
        receivedAt: DateTime(2026, 5, 25, 10, 0),
        sender: 'AX-SBIUPI-S',
        body: 'Rs.700.00 debited from A/c for UPI payment to Rahul',
      );
      final input = smsService.toParserInput(payload);
      expect(input.sourceType, 'sms');
      expect(input.sender, 'AX-SBIUPI-S');
      expect(input.rawText, contains('Rs.700.00'));
    });

    test('smsDetectionEnabled false prevents ingestion', () async {
      final disabledService = SmsIngestionService(
        database: db,
        pendingIngestionService: pendingIngestion,
        keywordFilter: NotificationKeywordFilter(),
        fingerprint: SmsFingerprint(),
        localNotifier: notifier,
        isSmsDetectionEnabled: () => false,
        isSmsPermissionGranted: () => true,
        shouldShowDetectionNotifications: () => true,
        appendDebug: (_) {},
        senderFilter: const SmsSenderFilter(),
      );

      final ids = await disabledService.processSmsPayload(
        NotificationPayload(
          packageName: 'android.sms',
          sourceType: 'sms',
          receivedAt: DateTime(2026, 5, 25, 10),
          sender: 'JD-HDFCBK-S',
          body: 'INR 1499 spent at SWIGGY',
        ),
      );
      expect(ids, isEmpty);
    });

    test('SMS ingestion creates pending transaction', () async {
      final ids = await smsService.processSmsPayload(
        NotificationPayload(
          packageName: 'android.sms',
          sourceType: 'sms',
          receivedAt: DateTime(2026, 5, 25, 10),
          sender: 'JD-HDFCBK-S',
          body:
              'INR 1499 spent on your HDFC Bank Credit Card XX1234 at SWIGGY on 24-May.',
        ),
      );

      expect(ids.length, 1);
      final row = await (db.select(
        db.pendingTransactions,
      )..where((p) => p.id.equals(ids.first))).getSingle();
      expect(row.sourceType, 'sms');
      expect(row.rawText, contains('SWIGGY'));
      expect(notifier.showCount, 1);
    });

    test('ignored SMS content is not stored', () async {
      final ids = await smsService.processSmsPayload(
        NotificationPayload(
          packageName: 'android.sms',
          sourceType: 'sms',
          receivedAt: DateTime(2026, 5, 25, 10),
          sender: 'JD-HDFCBK-S',
          body: 'hey are we meeting tonight',
        ),
      );
      expect(ids, isEmpty);
      final rows = await db.select(db.pendingTransactions).get();
      expect(rows, isEmpty);
    });

  test('OTP SMS is ignored', () async {
      final ids = await smsService.processSmsPayload(
        NotificationPayload(
          packageName: 'android.sms',
          sourceType: 'sms',
          receivedAt: DateTime(2026, 5, 25, 10),
          sender: 'AD-ICICIO-T',
          body:
              '062773 is One-Time Password for INR 628.00 transaction towards AMAZON using ICICI Bank Credit Card XX9000. OTPs are SECRET. DO NOT disclose',
        ),
      );
      expect(ids, isEmpty);
      final rows = await db.select(db.pendingTransactions).get();
    expect(rows, isEmpty);
  });

  test('coupon offer SMS with credited upto wording is ignored', () async {
    final ids = await smsService.processSmsPayload(
      NotificationPayload(
        packageName: 'android.sms',
        sourceType: 'sms',
        receivedAt: DateTime(2026, 6, 16, 19, 19, 55),
        sender: 'AD-ONTIRA-S',
        body:
            'Your Tira account is credited Upto Rs.1000* off coupon - validity 6 hours Tira Tuesday deal is live!',
      ),
    );

    expect(ids, isEmpty);
    final rows = await db.select(db.pendingTransactions).get();
    expect(rows, isEmpty);
  });

    test('duplicate SMS suppression and backfill-style repeat', () async {
      final payload = NotificationPayload(
        packageName: 'android.sms',
        sourceType: 'sms',
        receivedAt: DateTime(2026, 5, 25, 10),
        sender: 'AX-SBIUPI-S',
        body:
            'Rs.700.00 debited from A/c XX7821 for UPI payment to Rahul Kumar. UPI Ref 123456789.',
      );
      final first = await smsService.processSmsPayload(payload);
      final second = await smsService.processSmsPayload(payload);
      expect(first.length, 1);
      expect(second, isEmpty);
      final rows = await db.select(db.pendingTransactions).get();
      expect(rows.length, 1);
    });

    test('backfill + receiver duplicate suppression', () async {
      final smsIds = await smsService.processSmsPayload(
        NotificationPayload(
          packageName: 'android.sms',
          sourceType: 'sms',
          receivedAt: DateTime(2026, 5, 25, 10),
          sender: 'JD-HDFCBK-S',
          body: 'INR 1499 spent at SWIGGY via card ending 1234',
        ),
      );
      expect(smsIds.length, 1);

      final duplicateViaBackfill = await smsService.processSmsPayload(
        NotificationPayload(
          packageName: 'android.sms',
          sourceType: 'sms',
          receivedAt: DateTime(2026, 5, 25, 10, 5),
          sender: 'JD-HDFCBK-S',
          body: 'INR 1499 spent at SWIGGY via card ending 1234',
        ),
      );
      expect(duplicateViaBackfill, isEmpty);

      final rows = await db.select(db.pendingTransactions).get();
      expect(rows.length, 1);
    });

    test('SMS + notification duplicate prevention where possible', () async {
      final smsIds = await smsService.processSmsPayload(
        NotificationPayload(
          packageName: 'android.sms',
          sourceType: 'sms',
          receivedAt: DateTime(2026, 5, 25, 10),
          sender: 'JD-HDFCBK-S',
          body: 'INR 1499 spent at SWIGGY via card ending 1234',
        ),
      );
      expect(smsIds.length, 1);

      final notificationService = NotificationIngestionService(
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
      final notificationIds = await notificationService.processPayload(
        NotificationPayload(
          packageName: 'com.bank.app',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 5, 25, 10, 1),
          title: 'Debit alert',
          body: 'INR 1499 spent at SWIGGY via card ending 1234',
        ),
      );
      expect(notificationIds, isEmpty);

      final rows = await db.select(db.pendingTransactions).get();
      expect(rows.length, 1);
    });

    test(
      'notification-first generic bank alert is deduped when detailed sms arrives next',
      () async {
        final notificationService = NotificationIngestionService(
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

        final notificationIds = await notificationService.processPayload(
          NotificationPayload(
            packageName: 'com.kotak811.mobile',
            appName: 'Kotak811',
            sourceType: 'appNotification',
            receivedAt: DateTime(2026, 6, 15, 14, 57, 51),
            title: '₹4,500.00 sent via UPI',
            body:
                '₹4,500.00 sent via UPI Amount debited from XX0754. Check out details. ₹4,500.00 sent via UPI Amount debited from XX0754. Check out details.',
          ),
        );
        expect(notificationIds, hasLength(1));

        final smsIds = await smsService.processSmsPayload(
          NotificationPayload(
            packageName: 'android.sms',
            sourceType: 'sms',
            receivedAt: DateTime(2026, 6, 15, 14, 57, 49),
            sender: 'VM-KOTAKB-S',
            body:
                'Sent Rs.4500.00 from Kotak Bank AC X0754 to Ary4n73 lbl on 15-06-26.UPI Ref 653228447453. Not you, https://kotak.com/KBANKT/Fraud',
          ),
          bypassSenderFilter: true,
        );

        expect(smsIds, isEmpty);
        final rows = await db.select(db.pendingTransactions).get();
        expect(rows.length, 1);
      },
    );

    test('phone-number sender ignored for auto ingestion', () async {
      final ids = await smsService.processSmsPayload(
        NotificationPayload(
          packageName: 'android.sms',
          sourceType: 'sms',
          receivedAt: DateTime(2026, 5, 25, 10),
          sender: '+919999999999',
          body: 'INR 1499 spent at SWIGGY',
        ),
      );
      expect(ids, isEmpty);
    });

    test('manual mock bypasses sender filter', () async {
      final ids = await smsService.processSmsPayload(
        NotificationPayload(
          packageName: 'android.sms',
          sourceType: 'sms',
          receivedAt: DateTime(2026, 5, 25, 10),
          sender: '+919999999999',
          body: 'INR 1499 spent at SWIGGY',
        ),
        bypassSenderFilter: true,
      );
      expect(ids, isNotEmpty);
    });
  });
}
