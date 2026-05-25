import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/features/expenses/data/transaction_engine.dart';
import 'package:finarc/features/pending/data/pending_service.dart';
import 'package:finarc/features/pending/notifications/notification_fingerprint.dart';
import 'package:finarc/features/pending/notifications/notification_ingestion_service.dart';
import 'package:finarc/features/pending/notifications/notification_keyword_filter.dart';
import 'package:finarc/features/pending/notifications/notification_local_notifier.dart';
import 'package:finarc/features/pending/notifications/notification_payload.dart';
import 'package:finarc/features/pending/notifications/notification_providers.dart';
import 'package:finarc/features/pending/parsing/parsers/card_notification_parser.dart';
import 'package:finarc/features/pending/parsing/parsers/generic_bank_sms_parser.dart';
import 'package:finarc/features/pending/parsing/parsers/generic_fallback_parser.dart';
import 'package:finarc/features/pending/parsing/parsers/upi_notification_parser.dart';
import 'package:finarc/features/pending/parsing/pending_ingestion_service.dart';
import 'package:finarc/features/pending/parsing/transaction_parser_registry.dart';

class _FakeLocalNotifier extends NotificationLocalNotifier {
  int shownCount = 0;
  String? lastTitle;
  String? lastRoute;

  @override
  Future<void> showDetected({
    required String title,
    required String body,
    String route = '/pending',
    int? pendingId,
    bool showActions = true,
  }) async {
    shownCount += 1;
    lastTitle = title;
    lastRoute = route;
  }
}

void main() {
  group('notification keyword filter', () {
    test('accepts transaction-like text with keywords', () {
      final filter = NotificationKeywordFilter();
      final payload = NotificationPayload(
        packageName: 'com.random.app',
        sourceType: 'appNotification',
        receivedAt: DateTime(2026, 5, 24, 10, 0),
        title: 'Debit Alert',
        body: 'INR 1,499 spent at SWIGGY',
      );

      final result = filter.evaluate(payload);
      expect(result.accepted, isTrue);
    });

    test('ignores non-transaction social text', () {
      final filter = NotificationKeywordFilter();
      final payload = NotificationPayload(
        packageName: 'com.whatsapp',
        sourceType: 'appNotification',
        receivedAt: DateTime(2026, 5, 24, 10, 0),
        title: 'WhatsApp',
        body: 'new message from Ravi',
      );

      final result = filter.evaluate(payload);
      expect(result.accepted, isFalse);
      expect(result.reason, 'ignored-no-finance-keyword');
    });
  });

  group('notification fingerprint', () {
    test('duplicate suppression within window works', () {
      final fingerprint = NotificationFingerprint();
      final payload = NotificationPayload(
        packageName: 'com.phonepe.app',
        sourceType: 'appNotification',
        receivedAt: DateTime(2026, 5, 24, 10, 0, 0, 500),
        title: 'Paid ₹700',
        body: 'to Rahul via UPI',
      );

      final key = fingerprint.build(payload: payload);
      expect(
        fingerprint.isDuplicate(key, DateTime(2026, 5, 24, 10, 0, 0, 500)),
        isFalse,
      );
      expect(
        fingerprint.isDuplicate(key, DateTime(2026, 5, 24, 10, 1, 0, 500)),
        isTrue,
      );
      expect(
        fingerprint.isDuplicate(key, DateTime(2026, 5, 24, 10, 5, 0, 500)),
        isFalse,
      );
    });
  });

  group('notification payload mapping', () {
    test('map conversion preserves expected fields', () {
      final payload = NotificationPayload.fromMap({
        'packageName': 'com.phonepe.app',
        'appName': 'PhonePe',
        'title': 'Paid ₹700',
        'body': 'to Rahul',
        'bigText': 'UPI Ref 123',
        'subText': 'Savings A/c',
        'receivedAt': DateTime(2026, 5, 24, 10, 0).millisecondsSinceEpoch,
        'sourceType': 'appNotification',
        'isOngoing': false,
        'category': 'msg',
      });

      expect(payload.packageName, 'com.phonepe.app');
      expect(payload.appName, 'PhonePe');
      expect(payload.sourceType, 'appNotification');
      expect(payload.combinedText, contains('Paid ₹700'));
      expect(payload.combinedText, contains('UPI Ref 123'));
    });
  });

  group('notification ingestion service', () {
    late AppDatabase db;
    late NotificationIngestionService service;
    late _FakeLocalNotifier notifier;

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

      notifier = _FakeLocalNotifier();
      service = NotificationIngestionService(
        database: db,
        pendingIngestionService: pendingIngestion,
        keywordFilter: NotificationKeywordFilter(),
        fingerprint: NotificationFingerprint(),
        localNotifier: notifier,
        isDetectionEnabled: () => true,
        shouldShowDetectionNotifications: () => true,
        appendDebug: (_) {},
      );
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'creates pending transaction for transaction-like notification',
      () async {
        final ids = await service.processPayload(
          NotificationPayload(
            packageName: 'com.phonepe.app',
            sourceType: 'appNotification',
            receivedAt: DateTime(2026, 5, 24, 12, 0),
            title: 'Paid ₹250',
            body: 'to Zomato via UPI',
          ),
        );

        expect(ids.length, 1);
        final pending = await (db.select(
          db.pendingTransactions,
        )..where((t) => t.id.equals(ids.first))).getSingle();
        expect(pending.status, 'pending');
        expect(pending.merchant, 'Zomato');
        expect(notifier.shownCount, 1);
        expect(notifier.lastRoute, '/pending');
      },
    );

    test('ignores non-transaction notifications', () async {
      final ids = await service.processPayload(
        NotificationPayload(
          packageName: 'com.whatsapp',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 5, 24, 12, 0),
          title: 'Ravi',
          body: 'sent a photo',
        ),
      );

      expect(ids, isEmpty);
      expect(notifier.shownCount, 0);
    });

    test('suppresses duplicate notification ingestion', () async {
      final payload = NotificationPayload(
        packageName: 'com.phonepe.app',
        sourceType: 'appNotification',
        receivedAt: DateTime(2026, 5, 24, 12, 0),
        title: 'Paid ₹700',
        body: 'to Rahul Kumar via UPI',
      );

      final first = await service.processPayload(payload);
      final second = await service.processPayload(payload);

      expect(first, isNotEmpty);
      expect(second, isEmpty);

      final pendingRows = await db.select(db.pendingTransactions).get();
      expect(pendingRows.length, 1);
    });

    test('detection disabled prevents ingestion', () async {
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
      final localNotifier = _FakeLocalNotifier();
      final disabledService = NotificationIngestionService(
        database: db,
        pendingIngestionService: pendingIngestion,
        keywordFilter: NotificationKeywordFilter(),
        fingerprint: NotificationFingerprint(),
        localNotifier: localNotifier,
        isDetectionEnabled: () => false,
        shouldShowDetectionNotifications: () => true,
        appendDebug: (_) {},
      );

      final ids = await disabledService.processPayload(
        NotificationPayload(
          packageName: 'com.phonepe.app',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 5, 24, 12, 0),
          title: 'Paid ₹250',
          body: 'to Zomato via UPI',
        ),
      );

      expect(ids, isEmpty);
      expect(localNotifier.shownCount, 0);
      final pendingRows = await db.select(db.pendingTransactions).get();
      expect(pendingRows, isEmpty);
    });

    test(
      'showDetectionNotifications disabled skips local notification but still creates pending',
      () async {
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
        final localNotifier = _FakeLocalNotifier();
        final configuredService = NotificationIngestionService(
          database: db,
          pendingIngestionService: pendingIngestion,
          keywordFilter: NotificationKeywordFilter(),
          fingerprint: NotificationFingerprint(),
          localNotifier: localNotifier,
          isDetectionEnabled: () => true,
          shouldShowDetectionNotifications: () => false,
          appendDebug: (_) {},
        );

        final ids = await configuredService.processPayload(
          NotificationPayload(
            packageName: 'com.phonepe.app',
            sourceType: 'appNotification',
            receivedAt: DateTime(2026, 5, 24, 12, 0),
            title: 'Paid ₹250',
            body: 'to Zomato via UPI',
          ),
        );

        expect(ids.length, 1);
        expect(localNotifier.shownCount, 0);
        final pendingRows = await db.select(db.pendingTransactions).get();
        expect(pendingRows.length, 1);
      },
    );
  });

  group('notification route parsing', () {
    test('parse ignore action route', () {
      final action = parseNotificationRouteAction(
        '/pending?action=ignore&pendingId=12',
      );
      expect(action.type, 'ignore');
      expect(action.pendingId, 12);
    });

    test('parse confirm action route', () {
      final action = parseNotificationRouteAction(
        '/pending?action=confirm&pendingId=8',
      );
      expect(action.type, 'confirm');
      expect(action.pendingId, 8);
    });

    test('non-action route returns none', () {
      final action = parseNotificationRouteAction('/cards/1');
      expect(action.isNone, isTrue);
      expect(action.pendingId, isNull);
    });
  });
}
