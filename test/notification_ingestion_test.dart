import 'package:drift/drift.dart' as drift;
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
    test(
      'accepts allowlisted provider notification with transaction keywords',
      () {
        final filter = NotificationKeywordFilter();
        final payload = NotificationPayload(
          packageName: 'com.phonepe.app',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 5, 24, 10, 0),
          title: 'Debit Alert',
          body: 'INR 1,499 spent at SWIGGY',
        );

        final result = filter.evaluate(payload);
        expect(result.accepted, isTrue);
      },
    );

    test('ignores package not in allowlist', () {
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
      expect(result.reason, 'ignored-package-not-allowlisted');
    });

    test('accepts messaging app notification from transactional sender', () {
      final filter = NotificationKeywordFilter();
      final payload = NotificationPayload(
        packageName: 'com.google.android.apps.messaging',
        sourceType: 'appNotification',
        receivedAt: DateTime(2026, 5, 30, 10, 0),
        title: 'AD-INDUSB-S',
        body: 'A/C *XX5661 credited by Rs 1.00 from test@okaxis. RRN:123456.',
      );

      final result = filter.evaluate(payload);
      expect(result.accepted, isTrue);
      expect(result.reason, 'accepted-messages-transactional-sender');
      expect(result.senderFilterResult, 'allowed-transactional-sender');
    });

    test('blocks messaging app notification from promotional sender', () {
      final filter = NotificationKeywordFilter();
      final payload = NotificationPayload(
        packageName: 'com.google.android.apps.messaging',
        sourceType: 'appNotification',
        receivedAt: DateTime(2026, 5, 30, 10, 0),
        title: 'CP-RZRPAY-P',
        body: 'Offer just for you! cashback if you pay now',
      );

      final result = filter.evaluate(payload);
      expect(result.accepted, isFalse);
      expect(result.reason, 'blocked-promotional-sender');
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
    late List<NotificationDebugEntry> debugEntries;

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
      debugEntries = [];
      service = NotificationIngestionService(
        database: db,
        pendingIngestionService: pendingIngestion,
        keywordFilter: NotificationKeywordFilter(),
        fingerprint: NotificationFingerprint(),
        localNotifier: notifier,
        isDetectionEnabled: () => true,
        shouldShowDetectionNotifications: () => true,
        appendDebug: (entry) => debugEntries.add(entry),
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
        expect(notifier.lastTitle, 'Transaction detected');
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

    test('CRED promo gift card notification is ignored', () async {
      final ids = await service.processPayload(
        NotificationPayload(
          packageName: 'com.dreamplug.androidapp',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 5, 31, 9, 0),
          title: 'CRED',
          body:
              'your Myntra wishlist. at 6% off. with a gift card worth ₹2,500. tap to claim before it’s gone.',
        ),
      );

      expect(ids, isEmpty);
      expect(debugEntries.last.decision, 'ignored');
      expect(debugEntries.last.reason, 'promotional_offer_detected');
      expect(debugEntries.last.amountCandidate, isNotNull);
      expect(debugEntries.last.blockedContext, contains('gift card'));
    });

    test('promo amount voucher notification is ignored', () async {
      final ids = await service.processPayload(
        NotificationPayload(
          packageName: 'com.dreamplug.androidapp',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 5, 31, 9, 5),
          title: 'CRED',
          body: 'Get flat ₹500 cashback voucher on shopping',
        ),
      );

      expect(ids, isEmpty);
      expect(debugEntries.last.decision, 'ignored');
      expect(debugEntries.last.reason, 'promotional_offer_detected');
    });

    test('discount sale notification with amount is ignored', () async {
      final ids = await service.processPayload(
        NotificationPayload(
          packageName: 'com.amazon.mshop.android.shopping',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 5, 31, 9, 10),
          title: 'Amazon',
          body: 'Amazon sale 40% off, deals worth ₹2,000',
        ),
      );

      expect(ids, isEmpty);
      expect(debugEntries.last.decision, 'ignored');
      expect(debugEntries.last.reason, 'promotional_offer_detected');
    });

    test('real CRED card transaction still creates pending', () async {
      final ids = await service.processPayload(
        NotificationPayload(
          packageName: 'com.dreamplug.androidapp',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 5, 31, 9, 15),
          title: 'CRED',
          body:
              '₹2,500 spent on your HDFC Bank Credit Card ending 1234 at Myntra',
        ),
      );

      expect(ids.length, 1);
      final pending = await (db.select(
        db.pendingTransactions,
      )..where((p) => p.id.equals(ids.first))).getSingle();
      expect(pending.paymentSourceTypeSuggestion, 'creditCard');
      expect(pending.merchant, 'Myntra');
    });

    test('card bill due notification does not create spend pending', () async {
      final ids = await service.processPayload(
        NotificationPayload(
          packageName: 'com.dreamplug.androidapp',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 5, 31, 9, 20),
          title: 'CRED',
          body: 'Your credit card bill of ₹12,500 is due tomorrow',
        ),
      );

      expect(ids, isEmpty);
      expect(
        debugEntries.last.reason,
        anyOf('confidence-low', 'parser-no-candidate'),
      );
    });

    test('real UPI sent notification still creates pending', () async {
      final ids = await service.processPayload(
        NotificationPayload(
          packageName: 'com.phonepe.app',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 5, 31, 9, 25),
          title: 'PhonePe',
          body: 'Paid ₹700 to Rahul via UPI',
        ),
      );

      expect(ids.length, 1);
      final pending = await (db.select(
        db.pendingTransactions,
      )..where((p) => p.id.equals(ids.first))).getSingle();
      expect(pending.amount, 700);
      expect(pending.merchant, 'Rahul');
    });

    test('real salary credited notification creates income pending', () async {
      final ids = await service.processPayload(
        NotificationPayload(
          packageName: 'com.google.android.apps.messaging',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 5, 31, 9, 30),
          title: 'CP-RZRPAY-S',
          body: 'Salary of Rs 59,700 credited from Stackera',
        ),
      );

      expect(ids.length, 1);
      final pending = await (db.select(
        db.pendingTransactions,
      )..where((p) => p.id.equals(ids.first))).getSingle();
      expect(pending.amount, 59700);
      expect(pending.categorySuggestion, 'Income');
    });

    test(
      'creates pending transactions from messages app transactional sender',
      () async {
        final ids = await service.processPayload(
          NotificationPayload(
            packageName: 'com.google.android.apps.messaging',
            sourceType: 'appNotification',
            receivedAt: DateTime(2026, 5, 30, 12, 0),
            title: 'VM-KOTAKB-S',
            body:
                'Sent Rs.1.00 from Kotak Bank AC X0754 to yas21606-4@okaxis on 30-05-26.UPI Ref 123938960566.',
          ),
        );

        expect(ids.length, 1);
        final pending = await (db.select(
          db.pendingTransactions,
        )..where((p) => p.id.equals(ids.first))).getSingle();
        expect(pending.sourceType, 'appNotification');
        expect(pending.merchant.toLowerCase(), contains('yas21606'));
        expect(pending.merchant.toLowerCase(), contains('okaxis'));
        expect(pending.categorySuggestion, 'Transfer');
      },
    );

    test('received upi notification is parsed as income transfer', () async {
      final ids = await service.processPayload(
        NotificationPayload(
          packageName: 'com.google.android.apps.messaging',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 5, 30, 12, 2),
          title: 'VM-KOTAKB-S',
          body:
              'Received Rs.1.00 in your Kotak Bank AC X0754 from yas21606-4@okaxis on 30-05-26. UPI Ref:651638004295.',
        ),
      );

      expect(ids.length, 1);
      final pending = await (db.select(
        db.pendingTransactions,
      )..where((p) => p.id.equals(ids.first))).getSingle();
      expect(pending.amount, 1);
      expect(pending.categorySuggestion, 'Transfer');
      expect(pending.paymentSourceTypeSuggestion, 'bank');
      expect(pending.merchant.toLowerCase(), contains('yas21606'));
      expect(pending.merchant.toLowerCase(), contains('okaxis'));
    });

    test('parses two RRN entries from one messages notification', () async {
      final ids = await service.processPayload(
        NotificationPayload(
          packageName: 'com.google.android.apps.messaging',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 5, 30, 12, 5),
          title: 'AD-INDUSB-S',
          body:
              'A/C *XX5661 credited by Rs 1.00 from yas21606-3@okaxis. RRN:615087788229. '
              'A/C *XX5661 credited by Rs 1.00 from yas21606-3@okhdfcbank. RRN:123938960566.',
        ),
      );

      expect(ids.length, 2);
      final rows = await (db.select(
        db.pendingTransactions,
      )..orderBy([(t) => drift.OrderingTerm.asc(t.id)])).get();
      expect(rows.length, 2);
      expect(rows[0].rawText, contains('615087788229'));
      expect(rows[1].rawText, contains('123938960566'));
    });

    test('suppresses duplicate RRN and allows different RRN', () async {
      final first = await service.processPayload(
        NotificationPayload(
          packageName: 'com.google.android.apps.messaging',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 5, 30, 12, 10),
          title: 'JX-KOTAKB-S',
          body:
              'Sent Rs.1.00 from Kotak Bank AC X0754 to yas21606-4@okaxis on 30-05-26. UPI Ref 615087788229.',
        ),
      );
      final duplicate = await service.processPayload(
        NotificationPayload(
          packageName: 'com.google.android.apps.messaging',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 5, 30, 12, 20),
          title: 'JX-KOTAKB-S',
          body:
              'Sent Rs.1.00 from Kotak Bank AC X0754 to yas21606-4@okaxis on 30-05-26. UPI Ref 615087788229. Not you?',
        ),
      );
      final secondUnique = await service.processPayload(
        NotificationPayload(
          packageName: 'com.google.android.apps.messaging',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 5, 30, 12, 30),
          title: 'VM-KOTAKB-S',
          body:
              'Sent Rs.1.00 from Kotak Bank AC X0754 to yas21606-4@okaxis on 30-05-26. UPI Ref 123938960566.',
        ),
      );

      expect(first.length, 1);
      expect(duplicate, isEmpty);
      expect(secondUnique.length, 1);
      final rows = await db.select(db.pendingTransactions).get();
      expect(rows.length, 2);
    });

    test('duplicate repeated body with same UPI ref creates one pending', () async {
      final ids = await service.processPayload(
        NotificationPayload(
          packageName: 'com.google.android.apps.messaging',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 5, 30, 12, 35),
          title: 'VM-KOTAKB-S',
          body:
              'Received Rs.1.00 in your Kotak Bank AC X0754 from yas21606-4@okaxis on 30-05-26. UPI Ref:651638004295. '
              'Received Rs.1.00 in your Kotak Bank AC X0754 from yas21606-4@okaxis on 30-05-26. UPI Ref:651638004295.',
        ),
      );

      expect(ids.length, 1);
      final rows = await db.select(db.pendingTransactions).get();
      expect(rows.length, 1);
      expect(rows.first.rawText, contains('651638004295'));
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

    test(
      'uses notification receivedAt time when parsed text has no explicit time',
      () async {
        final receivedAt = DateTime(2026, 5, 30, 21, 17, 42);
        final ids = await service.processPayload(
          NotificationPayload(
            packageName: 'com.phonepe.app',
            sourceType: 'appNotification',
            receivedAt: receivedAt,
            title: 'PhonePe',
            body: 'Paid ₹250 to Zomato via UPI',
          ),
        );

        expect(ids.length, 1);
        final pending = await (db.select(
          db.pendingTransactions,
        )..where((p) => p.id.equals(ids.first))).getSingle();
        expect(pending.transactionDate, receivedAt);
      },
    );

    test(
      'combines parsed date with receivedAt time when time is missing',
      () async {
        final receivedAt = DateTime(2026, 5, 30, 21, 17, 42);
        final ids = await service.processPayload(
          NotificationPayload(
            packageName: 'com.google.android.apps.messaging',
            sourceType: 'appNotification',
            receivedAt: receivedAt,
            title: 'VM-KOTAKB-S',
            body:
                'Sent Rs.1.00 from Kotak Bank AC X0754 to yas21606-4@okaxis on 30-05-26. UPI Ref 123938960566.',
          ),
        );

        expect(ids.length, 1);
        final pending = await (db.select(
          db.pendingTransactions,
        )..where((p) => p.id.equals(ids.first))).getSingle();
        expect(pending.transactionDate, DateTime(2026, 5, 30, 21, 17, 42));
      },
    );

    test(
      'suppresses same amount/person/type duplicate within 40 seconds',
      () async {
        final first = await service.processPayload(
          NotificationPayload(
            packageName: 'com.phonepe.app',
            sourceType: 'appNotification',
            receivedAt: DateTime(2026, 5, 30, 13, 0, 0),
            title: 'PhonePe',
            body: 'Paid ₹700 to Rahul via UPI',
          ),
        );
        final second = await service.processPayload(
          NotificationPayload(
            packageName: 'com.phonepe.app',
            sourceType: 'appNotification',
            receivedAt: DateTime(2026, 5, 30, 13, 0, 30),
            title: 'PhonePe',
            body: 'Sent ₹700 to Rahul via UPI',
          ),
        );

        expect(first.length, 1);
        expect(second, isEmpty);
        expect(debugEntries.last.decision, 'duplicate');
        expect(
          debugEntries.last.reason,
          'near_duplicate_same_amount_counterparty_40s',
        );
        final rows = await db.select(db.pendingTransactions).get();
        expect(rows.length, 1);
      },
    );

    test('allows same amount/person/type after 45 seconds', () async {
      final first = await service.processPayload(
        NotificationPayload(
          packageName: 'com.phonepe.app',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 5, 30, 14, 0, 0),
          title: 'PhonePe',
          body: 'Paid ₹700 to Rahul via UPI',
        ),
      );
      final second = await service.processPayload(
        NotificationPayload(
          packageName: 'com.phonepe.app',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 5, 30, 14, 0, 45),
          title: 'PhonePe',
          body: 'Sent ₹700 to Rahul via UPI from account',
        ),
      );

      expect(first.length, 1);
      expect(second.length, 1);
      final rows = await db.select(db.pendingTransactions).get();
      expect(rows.length, 2);
    });

    test(
      'does not dedupe income and expense with same amount/person',
      () async {
        final expense = await service.processPayload(
          NotificationPayload(
            packageName: 'com.phonepe.app',
            sourceType: 'appNotification',
            receivedAt: DateTime(2026, 5, 30, 15, 0, 0),
            title: 'PhonePe',
            body: 'Paid ₹500 to Rahul via UPI',
          ),
        );
        final income = await service.processPayload(
          NotificationPayload(
            packageName: 'com.phonepe.app',
            sourceType: 'appNotification',
            receivedAt: DateTime(2026, 5, 30, 15, 0, 20),
            title: 'PhonePe',
            body: 'Received ₹500 from Rahul via UPI',
          ),
        );

        expect(expense.length, 1);
        expect(income.length, 1);
        final rows = await db.select(db.pendingTransactions).get();
        expect(rows.length, 2);
      },
    );

    test('same UPI reference dedupes even outside 40 second window', () async {
      final first = await service.processPayload(
        NotificationPayload(
          packageName: 'com.google.android.apps.messaging',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 5, 30, 16, 0, 0),
          title: 'VM-KOTAKB-S',
          body:
              'Sent Rs.1.00 from Kotak Bank AC X0754 to yas21606-4@okaxis on 30-05-26. UPI Ref 615087788229.',
        ),
      );
      final duplicate = await service.processPayload(
        NotificationPayload(
          packageName: 'com.google.android.apps.messaging',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 5, 30, 16, 2, 0),
          title: 'VM-KOTAKB-S',
          body:
              'Sent Rs.1.00 from Kotak Bank AC X0754 to yas21606-4@okaxis on 30-05-26. UPI Ref 615087788229.',
        ),
      );

      expect(first.length, 1);
      expect(duplicate, isEmpty);
      expect(debugEntries.last.reason, 'duplicate-ref');
      final rows = await db.select(db.pendingTransactions).get();
      expect(rows.length, 1);
    });

    test(
      'different UPI refs within 40 seconds are marked possible duplicate',
      () async {
        final first = await service.processPayload(
          NotificationPayload(
            packageName: 'com.google.android.apps.messaging',
            sourceType: 'appNotification',
            receivedAt: DateTime(2026, 5, 30, 17, 0, 0),
            title: 'VM-KOTAKB-S',
            body:
                'Sent Rs.1.00 from Kotak Bank AC X0754 to yas21606-4@okaxis on 30-05-26. UPI Ref 615087788229.',
          ),
        );
        final second = await service.processPayload(
          NotificationPayload(
            packageName: 'com.google.android.apps.messaging',
            sourceType: 'appNotification',
            receivedAt: DateTime(2026, 5, 30, 17, 0, 20),
            title: 'VM-KOTAKB-S',
            body:
                'Sent Rs.1.00 from Kotak Bank AC X0754 to yas21606-4@okaxis on 30-05-26. UPI Ref 123938960566.',
          ),
        );

        expect(first.length, 1);
        expect(second.length, 1);
        expect(debugEntries.last.decision, 'pending-created');
        expect(
          debugEntries.last.possibleDuplicateReason,
          'possible_duplicate_different_reference_within_40s',
        );
        final rows = await db.select(db.pendingTransactions).get();
        expect(rows.length, 2);
      },
    );

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
