import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/features/expenses/data/transaction_engine.dart';
import 'package:finarc/features/pending/data/pending_service.dart';
import 'package:finarc/features/pending/notifications/notification_burst_limiter.dart';
import 'package:finarc/features/pending/notifications/notification_fingerprint.dart';
import 'package:finarc/features/pending/notifications/notification_ingestion_service.dart';
import 'package:finarc/features/pending/notifications/notification_keyword_filter.dart';
import 'package:finarc/features/pending/notifications/notification_local_notifier.dart';
import 'package:finarc/features/pending/notifications/notification_log_sanitizer.dart';
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
  String? lastBody;
  String? lastRoute;
  int? lastPendingId;

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
    lastBody = body;
    lastRoute = route;
    lastPendingId = pendingId;
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

    test(
      'accepts transactional messaging app notification from bank sender',
      () {
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
        expect(result.reason, 'accepted-messaging-sms-notification');
        expect(result.senderFilterResult, 'allowed-transactional-sender');
      },
    );

    test('keeps truecaller mirrored SMS blocked', () {
      final filter = NotificationKeywordFilter();
      final payload = NotificationPayload(
        packageName: 'com.truecaller',
        appName: 'Truecaller',
        sourceType: 'appNotification',
        receivedAt: DateTime(2026, 5, 30, 10, 0),
        title: 'INR 628.00 spent using ICICI Bank Card on 13-Jun-26.',
        body:
            'INR 628.00 spent using ICICI Bank Card on 13-Jun-26. SMS from ICICI Bank',
      );

      final result = filter.evaluate(payload);
      expect(result.accepted, isFalse);
      expect(result.reason, 'ignored-package-not-allowlisted');
    });

    test('accepts non-catalog bank app notification via heuristic', () {
      final filter = NotificationKeywordFilter();
      final payload = NotificationPayload(
        packageName: 'com.kotak811.mobile',
        appName: 'Kotak811',
        sourceType: 'appNotification',
        receivedAt: DateTime(2026, 6, 13, 19, 5),
        title: '₹49.00 cashback received',
        body: '811 Super cashback credited to XX0754. Check out details.',
      );

      final result = filter.evaluate(payload);
      expect(result.accepted, isTrue);
      expect(result.reason, 'accepted-banking-app-heuristic');
      expect(result.amountCandidate, '₹49.00');
    });

    test('ignores finance notification without amount', () {
      final filter = NotificationKeywordFilter();
      final payload = NotificationPayload(
        packageName: 'com.snapwork.hdfc',
        sourceType: 'appNotification',
        receivedAt: DateTime(2026, 5, 30, 10, 0),
        title: 'HDFC Bank',
        body: 'Your card transaction was successful at SWIGGY',
      );

      final result = filter.evaluate(payload);
      expect(result.accepted, isFalse);
      expect(result.reason, 'ignored-no-amount');
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

  group('notification persistent logs', () {
    test('redacts notification text and amount hints from disk metadata', () {
      final meta = notificationDiskLogMeta(
        NotificationDebugEntry(
          receivedAt: DateTime(2026, 5, 24, 12, 0),
          packageName: 'com.bank.app',
          title: 'Bank alert',
          bodyPreview: 'INR 12,345 debited at SWIGGY from XX1234',
          decision: 'ignored',
          reason: 'promotional_offer_detected',
          amountCandidate: 'INR 12,345',
          blockedContext: 'gift card worth INR 12,345',
          sender: 'AD-BANK-S',
        ),
      );

      expect(meta['title'], '<redacted>');
      expect(meta['bodyPreview'], '<redacted>');
      expect(meta['amountCandidate'], '<redacted>');
      expect(meta['blockedContext'], '<redacted>');
      expect(meta['sender'], '<redacted>');
      expect(meta['hasAmountCandidate'], isTrue);
      expect(meta.values, isNot(contains('INR 12,345')));
      expect(meta.values, isNot(contains('AD-BANK-S')));
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

    test('map conversion includes expanded notification lines in bigText', () {
      final payload = NotificationPayload.fromMap({
        'packageName': 'com.snapwork.hdfc',
        'appName': 'HDFC Bank',
        'title': 'HDFC Bank',
        'body': '',
        'bigText':
            'A/C XX7788 debited by Rs. 1,250.00 at SWIGGY. Avl Bal Rs. 20,000.',
        'receivedAt': DateTime(2026, 6, 23, 10, 0).millisecondsSinceEpoch,
        'sourceType': 'appNotification',
      });

      expect(payload.combinedText, contains('debited by Rs. 1,250.00'));
      expect(payload.combinedText, contains('SWIGGY'));
    });
  });

  group('notification ingestion service', () {
    late AppDatabase db;
    late NotificationIngestionService service;
    late _FakeLocalNotifier notifier;
    late List<NotificationDebugEntry> debugEntries;
    const iciciBillText =
        'Pay Total Amount Due of Rs 17,027.10 or Minimum Amount Due of Rs 860.00 by 07-Jun-26 '
        'towards ICICI Bank Credit Card XX9000. Delay/Non-payment is reported to Credit Bureaus. Ignore if paid.';

    Future<int> createCard({
      required String bankName,
      required String last4,
      String nickname = 'Primary Card',
    }) {
      return db
          .into(db.creditCards)
          .insert(
            CreditCardsCompanion.insert(
              bankName: bankName,
              nickname: nickname,
              last4: last4,
              maskedNumber: 'XXXXXX$last4',
              creditLimit: 200000,
              billingDay: 1,
              dueDay: 7,
              currentOutstanding: const drift.Value(0.0),
            ),
          );
    }

    Future<int> createBank({
      required String bankName,
      String? accountName,
      String? last4,
    }) {
      return db
          .into(db.bankAccounts)
          .insert(
            BankAccountsCompanion.insert(
              bankName: bankName,
              accountName: accountName ?? '$bankName Savings',
              accountType: 'savings',
              last4: drift.Value(last4),
              currentBalance: const drift.Value(50000),
            ),
          );
    }

    Future<int> createBill({
      required int cardId,
      required double billedAmount,
      required DateTime dueDate,
      required String status,
      double paidAmount = 0,
    }) {
      return db
          .into(db.cardBills)
          .insert(
            CardBillsCompanion.insert(
              cardId: cardId,
              cycleStartDate: drift.Value(DateTime(2026, 5, 1)),
              cycleEndDate: drift.Value(DateTime(2026, 5, 31)),
              billingDate: drift.Value(DateTime(2026, 5, 31)),
              billedAmount: billedAmount,
              paidAmount: drift.Value(paidAmount),
              dueDate: drift.Value(dueDate),
              status: drift.Value(status),
            ),
          );
    }

    NotificationPayload iciciBillPayload({
      DateTime? receivedAt,
      String packageName = 'com.dreamplug.androidapp',
    }) {
      return NotificationPayload(
        packageName: packageName,
        sourceType: 'appNotification',
        receivedAt: receivedAt ?? DateTime(2026, 5, 31, 9, 20),
        title: 'CRED',
        body: iciciBillText,
      );
    }

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
        pendingService: pendingService,
        keywordFilter: NotificationKeywordFilter(),
        fingerprint: NotificationFingerprint(),
        localNotifier: notifier,
        isDetectionEnabled: () => true,
        areOptionalNotificationSourcesEnabled: () => true,
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

    test('rate limits a noisy notification package before parsing', () async {
      final pendingService = PendingService(db, TransactionEngine(db));
      final parserRegistry = TransactionParserRegistry(
        parsers: [
          UpiNotificationParser(),
          CardNotificationParser(),
          GenericBankSmsParser(),
        ],
        fallbackParser: GenericFallbackParser(),
      );
      final limitedService = NotificationIngestionService(
        database: db,
        pendingIngestionService: PendingIngestionService(
          db,
          pendingService,
          parserRegistry,
        ),
        pendingService: pendingService,
        keywordFilter: NotificationKeywordFilter(),
        fingerprint: NotificationFingerprint(),
        localNotifier: notifier,
        isDetectionEnabled: () => true,
        areOptionalNotificationSourcesEnabled: () => true,
        shouldShowDetectionNotifications: () => true,
        appendDebug: debugEntries.add,
        burstLimiter: NotificationBurstLimiter(
          maxEvents: 1,
          window: const Duration(minutes: 1),
        ),
      );

      final first = await limitedService.processPayload(
        NotificationPayload(
          packageName: 'com.phonepe.app',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 5, 24, 12, 0),
          title: 'Paid ₹250',
          body: 'to Zomato via UPI',
        ),
      );
      final second = await limitedService.processPayload(
        NotificationPayload(
          packageName: 'com.phonepe.app',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 5, 24, 12, 0, 30),
          title: 'Paid ₹399',
          body: 'to Swiggy via UPI',
        ),
      );

      expect(first.length, 1);
      expect(second, isEmpty);
      expect(debugEntries.last.decision, 'ignored');
      expect(debugEntries.last.reason, 'rate-limited-notification-burst');
      final rows = await db.select(db.pendingTransactions).get();
      expect(rows.length, 1);
    });

    test(
      'Amazon Pay notification suggests Amazon Pay wallet when available',
      () async {
        final walletId = await db
            .into(db.cashWallets)
            .insert(
              CashWalletsCompanion.insert(
                walletName: 'Amazon Pay',
                walletType: const drift.Value('amazonPay'),
                currentBalance: const drift.Value(1800),
              ),
            );

        final ids = await service.processPayload(
          NotificationPayload(
            packageName: 'com.amazon.mshop.android.shopping',
            sourceType: 'appNotification',
            receivedAt: DateTime(2026, 5, 24, 12, 0),
            title: 'Amazon Pay',
            body: 'Paid using Amazon Pay balance: Rs 250 at Swiggy',
          ),
        );

        expect(ids.length, 1);
        final pending = await (db.select(
          db.pendingTransactions,
        )..where((t) => t.id.equals(ids.first))).getSingle();
        expect(pending.paymentSourceTypeSuggestion, 'cash');
        expect(pending.paymentSourceIdSuggestion, walletId);
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

    test(
      'WhatsApp notifications are ignored without storing raw text',
      () async {
        final ids = await service.processPayload(
          NotificationPayload(
            packageName: 'com.whatsapp',
            sourceType: 'appNotification',
            receivedAt: DateTime(2026, 5, 24, 12, 0),
            title: 'Ravi',
            body: '₹12,000 sent yesterday',
          ),
        );

        expect(ids, isEmpty);
        expect(debugEntries, isEmpty);
        expect(await db.select(db.pendingTransactions).get(), isEmpty);
      },
    );

    test(
      'Telegram notifications are ignored without storing raw text',
      () async {
        final ids = await service.processPayload(
          NotificationPayload(
            packageName: 'org.telegram.messenger',
            sourceType: 'appNotification',
            receivedAt: DateTime(2026, 5, 24, 12, 5),
            title: 'Telegram',
            body: 'Paid ₹900 for dinner',
          ),
        );

        expect(ids, isEmpty);
        expect(debugEntries, isEmpty);
        expect(await db.select(db.pendingTransactions).get(), isEmpty);
      },
    );

    test(
      'Snapchat notifications are ignored without storing raw text',
      () async {
        final ids = await service.processPayload(
          NotificationPayload(
            packageName: 'com.snapchat.android',
            sourceType: 'appNotification',
            receivedAt: DateTime(2026, 5, 24, 12, 7),
            title: 'Snapchat',
            body: 'Swapnil Bhaiya sent you a Snap',
          ),
        );

        expect(ids, isEmpty);
        expect(debugEntries, isEmpty);
        expect(notifier.shownCount, 0);
        expect(await db.select(db.pendingTransactions).get(), isEmpty);
      },
    );

    test('social package with amount is still ignored', () async {
      final ids = await service.processPayload(
        NotificationPayload(
          packageName: 'com.instagram.android',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 5, 24, 12, 10),
          title: 'Instagram',
          body: 'Rahul sent ₹500 in chat',
        ),
      );

      expect(ids, isEmpty);
      expect(debugEntries, isEmpty);
      expect(await db.select(db.pendingTransactions).get(), isEmpty);
    });

    test('facebook messenger notification is ignored', () async {
      final ids = await service.processPayload(
        NotificationPayload(
          packageName: 'com.facebook.orca',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 5, 24, 12, 11),
          title: 'Messenger',
          body: 'Aman paid ₹500 in chat',
        ),
      );

      expect(ids, isEmpty);
      expect(debugEntries, isEmpty);
      expect(notifier.shownCount, 0);
      expect(await db.select(db.pendingTransactions).get(), isEmpty);
    });

    test('gmail notification is ignored', () async {
      final ids = await service.processPayload(
        NotificationPayload(
          packageName: 'com.google.android.gm',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 5, 24, 12, 12),
          title: 'Gmail',
          body: 'Statement due ₹4,500',
        ),
      );

      expect(ids, isEmpty);
      expect(debugEntries, isEmpty);
      expect(notifier.shownCount, 0);
      expect(await db.select(db.pendingTransactions).get(), isEmpty);
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

    test(
      'bank notification still creates pending when transaction-like',
      () async {
        final ids = await service.processPayload(
          NotificationPayload(
            packageName: 'com.snapwork.hdfc',
            sourceType: 'appNotification',
            receivedAt: DateTime(2026, 5, 31, 9, 12),
            title: 'HDFC Bank',
            body: 'INR 2,499 spent at SWIGGY on your card ending 1234',
          ),
        );

        expect(ids.length, 1);
        final pending = await (db.select(
          db.pendingTransactions,
        )..where((p) => p.id.equals(ids.first))).getSingle();
        expect(pending.merchant, 'Swiggy');
        expect(pending.sourceType, 'appNotification');
      },
    );

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

    test(
      'notification without amount is ignored for allowed finance app',
      () async {
        final ids = await service.processPayload(
          NotificationPayload(
            packageName: 'com.snapwork.hdfc',
            sourceType: 'appNotification',
            receivedAt: DateTime(2026, 5, 31, 9, 16),
            title: 'HDFC Bank',
            body: 'Your card was used at Myntra',
          ),
        );

        expect(ids, isEmpty);
        expect(debugEntries.last.reason, 'ignored-no-amount');
      },
    );

    test('ICICI bill due notification is classified and reconciled', () async {
      final cardId = await createCard(bankName: 'ICICI Bank', last4: '9000');
      await createBill(
        cardId: cardId,
        billedAmount: 17027.10,
        dueDate: DateTime(2026, 6, 7),
        status: 'billed',
      );
      final payload = iciciBillPayload();

      final parsed = service.cardBillDueNotificationService.parse(payload);
      expect(parsed, isNotNull);
      expect(parsed!.totalAmountDue, 17027.10);
      expect(parsed.minimumAmountDue, 860.00);
      expect(parsed.dueDate, DateTime(2026, 6, 7));
      expect(parsed.cardLast4, '9000');
      expect(parsed.issuer, 'ICICI');

      final ids = await service.processPayload(payload);
      expect(ids, isEmpty);
      expect(await db.select(db.pendingTransactions).get(), isEmpty);
      final alerts = await db.select(db.alerts).get();
      expect(alerts.length, 1);
      expect(alerts.first.alertType, 'cardDue');
      expect(alerts.first.title.toLowerCase(), contains('verified'));
      expect(debugEntries.last.reason, 'card-bill-due-verified');
    });

    test('card bill due with no matching card creates alert only', () async {
      final ids = await service.processPayload(iciciBillPayload());
      expect(ids, isEmpty);
      expect(await db.select(db.pendingTransactions).get(), isEmpty);

      final alerts = await db.select(db.alerts).get();
      expect(alerts.length, 1);
      expect(
        alerts.first.title,
        'Card bill detected but no matching card found',
      );
      expect(debugEntries.last.reason, 'card-bill-due-noMatchingCard');
    });

    test(
      'existing unpaid bill same amount verifies and updates due date',
      () async {
        final cardId = await createCard(bankName: 'ICICI Bank', last4: '9000');
        final billId = await createBill(
          cardId: cardId,
          billedAmount: 17027.10,
          dueDate: DateTime(2026, 6, 8),
          status: 'billed',
        );

        final ids = await service.processPayload(iciciBillPayload());
        expect(ids, isEmpty);
        expect(await db.select(db.pendingTransactions).get(), isEmpty);

        final bill = await (db.select(
          db.cardBills,
        )..where((b) => b.id.equals(billId))).getSingle();
        expect(bill.billedAmount, 17027.10);
        expect(bill.dueDate, DateTime(2026, 6, 7));
        expect(debugEntries.last.reason, 'card-bill-due-updatedDueDate');
      },
    );

    test(
      'existing unpaid bill mismatch creates warning and no overwrite',
      () async {
        final cardId = await createCard(bankName: 'ICICI Bank', last4: '9000');
        final billId = await createBill(
          cardId: cardId,
          billedAmount: 16000,
          dueDate: DateTime(2026, 6, 7),
          status: 'billed',
        );

        final ids = await service.processPayload(iciciBillPayload());
        expect(ids, isEmpty);
        expect(await db.select(db.pendingTransactions).get(), isEmpty);

        final bill = await (db.select(
          db.cardBills,
        )..where((b) => b.id.equals(billId))).getSingle();
        expect(bill.billedAmount, 16000);
        expect(bill.dueDate, DateTime(2026, 6, 7));

        final alerts = await db.select(db.alerts).get();
        expect(alerts.length, 1);
        expect(alerts.first.priority, 'warning');
        expect(alerts.first.title.toLowerCase(), contains('amount mismatch'));
        expect(debugEntries.last.reason, 'card-bill-due-mismatchAlert');
      },
    );

    test('already paid bill same amount creates info alert only', () async {
      final cardId = await createCard(bankName: 'ICICI Bank', last4: '9000');
      final billId = await createBill(
        cardId: cardId,
        billedAmount: 17027.10,
        dueDate: DateTime(2026, 6, 7),
        status: 'paid',
        paidAmount: 17027.10,
      );

      final ids = await service.processPayload(iciciBillPayload());
      expect(ids, isEmpty);
      expect(await db.select(db.pendingTransactions).get(), isEmpty);

      final bill = await (db.select(
        db.cardBills,
      )..where((b) => b.id.equals(billId))).getSingle();
      expect(bill.billedAmount, 17027.10);
      expect(bill.status, 'paid');

      final alerts = await db.select(db.alerts).get();
      expect(alerts.length, 1);
      expect(alerts.first.priority, 'info');
      expect(alerts.first.title, 'Paid bill notification matches your record');
      expect(debugEntries.last.reason, 'card-bill-due-paidBillVerified');
    });

    test(
      'already paid bill mismatch creates warning and does not reopen',
      () async {
        final cardId = await createCard(bankName: 'ICICI Bank', last4: '9000');
        final billId = await createBill(
          cardId: cardId,
          billedAmount: 18000,
          dueDate: DateTime(2026, 6, 7),
          status: 'paid',
          paidAmount: 18000,
        );

        final ids = await service.processPayload(iciciBillPayload());
        expect(ids, isEmpty);
        expect(await db.select(db.pendingTransactions).get(), isEmpty);

        final bill = await (db.select(
          db.cardBills,
        )..where((b) => b.id.equals(billId))).getSingle();
        expect(bill.billedAmount, 18000);
        expect(bill.status, 'paid');

        final alerts = await db.select(db.alerts).get();
        expect(alerts.length, 1);
        expect(alerts.first.priority, 'warning');
        expect(
          alerts.first.title,
          'Paid bill amount differs from notification',
        );
        expect(debugEntries.last.reason, 'card-bill-due-paidBillMismatch');
      },
    );

    test('duplicate bill due notification is deduped', () async {
      await createCard(bankName: 'ICICI Bank', last4: '9000');

      final first = await service.processPayload(iciciBillPayload());
      final second = await service.processPayload(
        iciciBillPayload(receivedAt: DateTime(2026, 5, 31, 9, 21)),
      );

      expect(first, isEmpty);
      expect(second, isEmpty);
      expect(await db.select(db.pendingTransactions).get(), isEmpty);

      final alerts = await db.select(db.alerts).get();
      expect(alerts.length, 1);
      expect(debugEntries.last.reason, 'card-bill-due-ignoredDuplicate');
    });

    test(
      'card bill due min due + total due uses total and creates alert only',
      () async {
        final cardId = await createCard(bankName: 'Axis Bank', last4: '1266');
        final payload = NotificationPayload(
          packageName: 'com.axis.mobile',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 6, 3, 9, 0),
          title: 'AXISBK',
          body:
              'Payment of Credit Card X1266 is due on 03/06/26. Min due Rs.200.00. Total Due Rs.8384.59. Pay before last date to avoid charges.',
        );

        final parsed = service.cardBillDueNotificationService.parse(payload);
        expect(parsed, isNotNull);
        expect(parsed!.cardLast4, '1266');
        expect(parsed.minimumAmountDue, 200);
        expect(parsed.totalAmountDue, 8384.59);

        final ids = await service.processPayload(payload);
        expect(ids, isEmpty);
        expect(await db.select(db.pendingTransactions).get(), isEmpty);

        final alerts = await db.select(db.alerts).get();
        expect(alerts, hasLength(1));
        expect(alerts.single.payload, contains('"minimumAmountDue":200.0'));
        expect(alerts.single.payload, contains('"totalAmountDue":8384.59'));
        expect(debugEntries.last.reason, contains('card-bill-due-'));

        final bills = await (db.select(
          db.cardBills,
        )..where((b) => b.cardId.equals(cardId))).get();
        expect(bills, isNotEmpty);
        expect(bills.single.billedAmount, 8384.59);
      },
    );

    test(
      'axis payment received towards credit card becomes card payment pending',
      () async {
        await createCard(bankName: 'Axis Bank', last4: '0374');
        final ids = await service.processPayload(
          NotificationPayload(
            packageName: 'com.axis.mobile',
            sourceType: 'appNotification',
            receivedAt: DateTime(2026, 5, 31, 11, 0),
            title: 'AXISBK',
            body:
                'Payment of INR 7736.04 has been received towards your Axis Bank Credit Card XX0374 on 31-05-26 - Axis Bank',
          ),
        );

        expect(ids, hasLength(1));
        final pending = await (db.select(
          db.pendingTransactions,
        )..where((p) => p.id.equals(ids.first))).getSingle();
        expect(pending.sourceType, 'cardPaymentNotification');
        expect(pending.categorySuggestion, 'Transfer');
        expect(pending.paymentSourceTypeSuggestion, 'bank');
        expect(pending.merchant, 'Axis Card XX0374');
        expect(pending.rawText, contains('[CARD_PAYMENT|'));
        expect(debugEntries.last.reason, 'card-payment-pendingCreated');
      },
    );

    test('bbps card payment receipt becomes card payment pending', () async {
      final cardId = await createCard(bankName: 'ICICI Bank', last4: '9000');
      final ids = await service.processPayload(
        NotificationPayload(
          packageName: 'com.amazon.mshop.android.shopping',
          appName: 'Amazon',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 6, 2, 9, 0),
          title: 'Amazon Pay ICICI Bank Credit Card',
          body: 'BBPS Payment Received of Rs. 1,489.01',
        ),
      );

      expect(ids, hasLength(1));
      final pending = await (db.select(
        db.pendingTransactions,
      )..where((p) => p.id.equals(ids.first))).getSingle();
      expect(pending.sourceType, 'cardPaymentNotification');
      expect(pending.amount, 1489.01);
      expect(pending.merchant, 'ICICI Card Payment');
      expect(pending.rawText, contains('destinationCardId=$cardId'));
      expect(pending.rawText, contains('kinds=destinationReceipt'));
    });

    test(
      'cred processed credit card payment does not become expense merchant',
      () async {
        await createCard(bankName: 'Axis Bank', last4: '0374');
        final ids = await service.processPayload(
          NotificationPayload(
            packageName: 'com.dreamplug.androidapp',
            sourceType: 'appNotification',
            receivedAt: DateTime(2026, 5, 31, 11, 1),
            title: 'CRED',
            body:
                'paid instantly to Axis Bank that was fast: payment of ₹7,736.04 on your Axis Bank credit card XXXX-0374 has been processed. tap to check your latest bank balance.',
          ),
        );

        expect(ids, hasLength(1));
        final pending = await (db.select(
          db.pendingTransactions,
        )..where((p) => p.id.equals(ids.first))).getSingle();
        expect(pending.sourceType, 'cardPaymentNotification');
        expect(pending.merchant, 'Axis Card XX0374');
        expect(
          pending.merchant.toLowerCase(),
          isNot(contains('that was fast')),
        );
        expect(pending.merchant.toLowerCase(), isNot(contains('check')));
        expect(pending.paymentSourceTypeSuggestion, 'bank');
      },
    );

    test(
      'kotak debit to cred club axisb becomes source-side card payment pending',
      () async {
        final bankId = await createBank(bankName: 'Kotak');
        final ids = await service.processPayload(
          NotificationPayload(
            packageName: 'com.msf.kbank.mobile',
            sourceType: 'appNotification',
            receivedAt: DateTime(2026, 5, 31, 10, 58),
            title: 'VM-KOTAKB-S',
            body:
                'Sent Rs.7730.04 from Kotak Bank AC XX0754 to cred.club@axisb on 31-05-26. UPI Ref 51718170827.',
          ),
        );

        expect(ids, hasLength(1));
        final pending = await (db.select(
          db.pendingTransactions,
        )..where((p) => p.id.equals(ids.first))).getSingle();
        expect(pending.sourceType, 'cardPaymentNotification');
        expect(pending.paymentSourceTypeSuggestion, 'bank');
        expect(pending.paymentSourceIdSuggestion, bankId);
        expect(pending.merchant, 'Axis Card Payment');
        expect(pending.rawText, contains('sourceAccountId=$bankId'));
        expect(pending.rawText, contains('transactionRef=51718170827'));
      },
    );

    test('multi-message card payment mapping keeps one logical pending', () async {
      final bankId = await createBank(bankName: 'Kotak');
      await createCard(bankName: 'Axis Bank', last4: '0374');

      final debitIds = await service.processPayload(
        NotificationPayload(
          packageName: 'com.msf.kbank.mobile',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 5, 31, 10, 58),
          title: 'VM-KOTAKB-S',
          body:
              'Sent Rs.7730.04 from Kotak Bank AC XX0754 to cred.club@axisb on 31-05-26. UPI Ref 51718170827.',
        ),
      );
      final receiptIds = await service.processPayload(
        NotificationPayload(
          packageName: 'com.axis.mobile',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 5, 31, 11, 0),
          title: 'AXISBK',
          body:
              'Payment of INR 7736.04 has been received towards your Axis Bank Credit Card XX0374 on 31-05-26 - Axis Bank',
        ),
      );
      final processedIds = await service.processPayload(
        NotificationPayload(
          packageName: 'com.dreamplug.androidapp',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 5, 31, 11, 1),
          title: 'CRED',
          body:
              'paid instantly to Axis Bank that was fast: payment of ₹7,736.04 on your Axis Bank credit card XXXX-0374 has been processed. tap to check your latest bank balance.',
        ),
      );

      expect(debitIds, hasLength(1));
      expect(receiptIds, isEmpty);
      expect(processedIds, isEmpty);

      final rows = await db.select(db.pendingTransactions).get();
      expect(rows, hasLength(1));
      expect(rows.single.sourceType, 'cardPaymentNotification');
      expect(rows.single.paymentSourceIdSuggestion, bankId);
      expect(rows.single.amount, 7736.04);
      expect(rows.single.merchant, 'Axis Card XX0374');
      expect(
        rows.single.rawText,
        contains('kinds=sourceDebit%2CdestinationReceipt%2CprocessorProcessed'),
      );
      expect(rows.single.rawText, contains('cred.club@axisb'));
      expect(
        rows.single.rawText,
        contains('received towards your Axis Bank Credit Card XX0374'),
      );
      expect(rows.single.rawText, contains('has been processed'));
    });

    test(
      'merged kotak cred debit updates local notification to destination card',
      () async {
        final bankId = await createBank(bankName: 'Kotak', last4: '0754');
        final cardId = await createCard(bankName: 'YES Bank', last4: '8731');

        final debitIds = await service.processPayload(
          NotificationPayload(
            packageName: 'com.msf.kbank.mobile',
            appName: 'Kotak811',
            sourceType: 'appNotification',
            receivedAt: DateTime(2026, 7, 1, 4, 29),
            title: '₹4,744.95 paid to Cred Club',
            body: 'Amount debited from XX0754. Check out details.',
          ),
        );
        final receiptIds = await service.processPayload(
          NotificationPayload(
            packageName: 'com.google.android.apps.messaging',
            appName: 'Messages',
            sourceType: 'appNotification',
            receivedAt: DateTime(2026, 7, 1, 4, 29, 20),
            title: 'AD-YESBNK-S',
            body:
                'Dear Cardmember, payment of Rs.4,744.95 is received towards your YES BANK Credit Card ending 8731. It will reflect in your Credit Card within 1-2 working days',
          ),
        );
        final processedIds = await service.processPayload(
          NotificationPayload(
            packageName: 'com.dreamplug.androidapp',
            appName: 'CRED',
            sourceType: 'appNotification',
            receivedAt: DateTime(2026, 7, 1, 4, 29, 40),
            title: 'CRED',
            body:
                'paid instantly to YES Bank that was fast: payment of ₹4,744.95 on your YES Bank credit card XXXX-8731 has been processed.',
          ),
        );

        expect(debitIds, hasLength(1));
        expect(receiptIds, isEmpty);
        expect(processedIds, isEmpty);

        final pending = await (db.select(
          db.pendingTransactions,
        )..where((p) => p.id.equals(debitIds.single))).getSingle();
        expect(pending.merchant, 'Yes Card XX8731');
        expect(pending.paymentSourceIdSuggestion, bankId);
        expect(pending.rawText, contains('destinationCardId=$cardId'));
        expect(
          pending.rawText,
          contains(
            'kinds=sourceDebit%2CdestinationReceipt%2CprocessorProcessed',
          ),
        );
        expect(notifier.lastPendingId, debitIds.single);
        expect(notifier.lastBody, contains('Yes Card XX8731'));
        expect(notifier.lastBody, isNot(contains('Axis Card Payment')));
      },
    );

    test(
      'normal card spend notification still creates pending expense',
      () async {
        await createCard(bankName: 'ICICI Bank', last4: '9000');
        final ids = await service.processPayload(
          NotificationPayload(
            packageName: 'com.dreamplug.androidapp',
            sourceType: 'appNotification',
            receivedAt: DateTime(2026, 5, 31, 10, 0),
            title: 'CRED',
            body: '₹500 spent on ICICI Credit Card XX9000 at Amazon',
          ),
        );

        expect(ids.length, 1);
        final pending = await (db.select(
          db.pendingTransactions,
        )..where((p) => p.id.equals(ids.first))).getSingle();
        expect(pending.amount, 500);
        expect(pending.paymentSourceTypeSuggestion, 'creditCard');
        expect(pending.merchant, 'Amazon');
        expect(await db.select(db.alerts).get(), isEmpty);
      },
    );

    test(
      'card refund notification creates refund pending instead of expense',
      () async {
        await createCard(bankName: 'ICICI Bank', last4: '9000');
        final ids = await service.processPayload(
          NotificationPayload(
            packageName: 'com.amazon.mshop.android.shopping',
            appName: 'Amazon',
            sourceType: 'appNotification',
            receivedAt: DateTime(2026, 6, 13, 10, 0),
            title: 'Amazon Pay ICICI Bank Credit Card',
            body: 'Refund of Rs.578.00 processed on your card ending 9000',
          ),
        );

        expect(ids, hasLength(1));
        final pending = await (db.select(
          db.pendingTransactions,
        )..where((p) => p.id.equals(ids.first))).getSingle();
        expect(pending.amount, 578);
        expect(pending.categorySuggestion, 'Refund');
        expect(pending.paymentSourceTypeSuggestion, 'creditCard');
        expect(pending.merchant, 'Amazon');
      },
    );

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
          packageName: 'com.msf.kbank.mobile',
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

    test('parses messages app transactional sender notifications', () async {
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

      expect(ids, hasLength(1));
      expect(debugEntries, isNotEmpty);
      final pending = await (db.select(
        db.pendingTransactions,
      )..where((p) => p.id.equals(ids.first))).getSingle();
      expect(pending.amount, 1);
      expect(pending.sourceType, 'sms');
      expect(pending.merchant.toLowerCase(), contains('yas21606'));
      expect(pending.merchant.toLowerCase(), contains('okaxis'));
    });

    test('parses ICICI card spend mirrored by Messages notification', () async {
      await createCard(bankName: 'ICICI Bank', last4: '9000');

      final ids = await service.processPayload(
        NotificationPayload(
          packageName: 'com.google.android.apps.messaging',
          appName: 'Messages',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 6, 25, 16, 2),
          title: 'VA-ICICIT-S',
          body:
              'INR 752.00 spent using ICICI Bank Card XX9000 on 25-Jun-26 on AMAZON PAY IN G. Avl Limit: INR 27,357.98. If not you, call 1800 2662/SMS BLOCK 9000 to 9215676766.',
        ),
      );

      expect(ids, hasLength(1));
      final pending = await (db.select(
        db.pendingTransactions,
      )..where((p) => p.id.equals(ids.first))).getSingle();
      expect(pending.amount, 752);
      expect(pending.paymentSourceTypeSuggestion, 'creditCard');
      expect(pending.paymentSourceIdSuggestion, isNotNull);
      expect(pending.merchant, 'Amazon');
      expect(pending.transactionDate, DateTime(2026, 6, 25, 16, 2));
      expect(debugEntries.last.reason, 'success');
    });

    test(
      'dedupes generic bank app receipt against detailed sms for same transaction',
      () async {
        final first = await service.processPayload(
          NotificationPayload(
            packageName: 'com.google.android.apps.messaging',
            sourceType: 'appNotification',
            receivedAt: DateTime(2026, 6, 13, 19, 19, 0),
            title: 'VM-KOTAKD-S',
            body:
                'Sent Rs.200.00 from XXXXX0754 to MANSI. on 13/06/2026. UPI ref no 615087788229.',
          ),
        );
        final duplicate = await service.processPayload(
          NotificationPayload(
            packageName: 'com.kotak811.mobile',
            appName: 'Kotak811',
            sourceType: 'appNotification',
            receivedAt: DateTime(2026, 6, 13, 19, 19, 20),
            title: '₹200.00 sent via UPI',
            body: 'Amount debited from XX0754. Check out details.',
          ),
        );

        expect(first, hasLength(1));
        expect(duplicate, isEmpty);
        expect(debugEntries.last.decision, 'duplicate');
        expect(
          debugEntries.last.reason,
          'generic_notification_duplicate_within_2m',
        );
        final rows = await db.select(db.pendingTransactions).get();
        expect(rows.length, 1);
      },
    );

    test('blocks OTP-style messages app notifications', () async {
      final ids = await service.processPayload(
        NotificationPayload(
          packageName: 'com.google.android.apps.messaging',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 5, 30, 12, 0),
          title: 'AD-ICICIO-T',
          body:
              '062773 is One-Time Password for INR 628.00 transaction towards AMAZON using ICICI Bank Credit Card XX9000. OTPs are SECRET. DO NOT disclose',
        ),
      );

      expect(ids, isEmpty);
      expect(debugEntries, isNotEmpty);
      expect(debugEntries.single.reason, 'ignored-otp-message');
      expect(await db.select(db.pendingTransactions).get(), isEmpty);
    });

    test(
      'parses cashback credit from non-catalog bank app notification',
      () async {
        final ids = await service.processPayload(
          NotificationPayload(
            packageName: 'com.kotak811.mobile',
            appName: 'Kotak811',
            sourceType: 'appNotification',
            receivedAt: DateTime(2026, 6, 13, 19, 5),
            title: '₹49.00 cashback received',
            body: '811 Super cashback credited to XX0754. Check out details.',
          ),
        );

        expect(ids, hasLength(1));
        final pending = await (db.select(
          db.pendingTransactions,
        )..where((p) => p.id.equals(ids.first))).getSingle();
        expect(pending.amount, 49);
        expect(pending.sourceType, 'appNotification');
        expect(pending.categorySuggestion, 'Refund');
      },
    );

    test('received upi notification is parsed as income transfer', () async {
      final ids = await service.processPayload(
        NotificationPayload(
          packageName: 'com.msf.kbank.mobile',
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
          packageName: 'com.msf.kbank.mobile',
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
          packageName: 'com.msf.kbank.mobile',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 5, 30, 12, 10),
          title: 'JX-KOTAKB-S',
          body:
              'Sent Rs.1.00 from Kotak Bank AC X0754 to yas21606-4@okaxis on 30-05-26. UPI Ref 615087788229.',
        ),
      );
      final duplicate = await service.processPayload(
        NotificationPayload(
          packageName: 'com.msf.kbank.mobile',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 5, 30, 12, 20),
          title: 'JX-KOTAKB-S',
          body:
              'Sent Rs.1.00 from Kotak Bank AC X0754 to yas21606-4@okaxis on 30-05-26. UPI Ref 615087788229. Not you?',
        ),
      );
      final secondUnique = await service.processPayload(
        NotificationPayload(
          packageName: 'com.msf.kbank.mobile',
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
          packageName: 'com.msf.kbank.mobile',
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
            packageName: 'com.msf.kbank.mobile',
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
      'suppresses same amount/person/type duplicate within 8 minutes',
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
          'near_duplicate_same_amount_counterparty_8m',
        );
        final rows = await db.select(db.pendingTransactions).get();
        expect(rows.length, 1);
      },
    );

    test('allows same amount/person/type after 30 minutes', () async {
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
          receivedAt: DateTime(2026, 5, 30, 14, 30, 0),
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
          packageName: 'com.msf.kbank.mobile',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 5, 30, 16, 0, 0),
          title: 'VM-KOTAKB-S',
          body:
              'Sent Rs.1.00 from Kotak Bank AC X0754 to yas21606-4@okaxis on 30-05-26. UPI Ref 615087788229.',
        ),
      );
      final duplicate = await service.processPayload(
        NotificationPayload(
          packageName: 'com.msf.kbank.mobile',
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
      'different UPI refs within 8 minutes are marked possible duplicate',
      () async {
        final first = await service.processPayload(
          NotificationPayload(
            packageName: 'com.msf.kbank.mobile',
            sourceType: 'appNotification',
            receivedAt: DateTime(2026, 5, 30, 17, 0, 0),
            title: 'VM-KOTAKB-S',
            body:
                'Sent Rs.1.00 from Kotak Bank AC X0754 to yas21606-4@okaxis on 30-05-26. UPI Ref 615087788229.',
          ),
        );
        final second = await service.processPayload(
          NotificationPayload(
            packageName: 'com.msf.kbank.mobile',
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
          'possible_duplicate_different_reference_within_8m',
        );
        final rows = await db.select(db.pendingTransactions).get();
        expect(rows.length, 2);
      },
    );

    test('source matching uses bank name and account last4', () async {
      final matchedBankId = await createBank(
        bankName: 'Kotak',
        accountName: 'Primary',
        last4: '0754',
      );
      await createBank(
        bankName: 'Kotak',
        accountName: 'Secondary',
        last4: '9988',
      );

      final ids = await service.processPayload(
        NotificationPayload(
          packageName: 'com.msf.kbank.mobile',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 5, 30, 12, 0),
          title: 'VM-KOTAKB-S',
          body:
              'Sent Rs.1.00 from Kotak Bank AC X0754 to yas21606-4@okaxis on 30-05-26. UPI Ref 123938960566.',
        ),
      );

      expect(ids, hasLength(1));
      final pending = await (db.select(
        db.pendingTransactions,
      )..where((p) => p.id.equals(ids.first))).getSingle();
      expect(pending.paymentSourceIdSuggestion, matchedBankId);
      expect(pending.rawText, contains('X0754'));
    });

    test('same amount and merchant hours apart are not duplicates', () async {
      final first = await service.processPayload(
        NotificationPayload(
          packageName: 'com.phonepe.app',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 5, 30, 10, 0, 0),
          title: 'PhonePe',
          body: 'Paid ₹500 to Swiggy via UPI',
        ),
      );
      final second = await service.processPayload(
        NotificationPayload(
          packageName: 'com.phonepe.app',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 5, 30, 15, 0, 0),
          title: 'PhonePe',
          body: 'Paid ₹500 to Swiggy via UPI',
        ),
      );

      expect(first.length, 1);
      expect(second.length, 1);
      final rows = await db.select(db.pendingTransactions).get();
      expect(rows.length, 2);
    });

    test('same amount different merchants are not duplicates', () async {
      final first = await service.processPayload(
        NotificationPayload(
          packageName: 'com.phonepe.app',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 5, 30, 18, 0, 0),
          title: 'PhonePe',
          body: 'Paid ₹187 to Zepto via UPI',
        ),
      );
      final second = await service.processPayload(
        NotificationPayload(
          packageName: 'com.phonepe.app',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 5, 30, 18, 2, 0),
          title: 'PhonePe',
          body: 'Paid ₹187 to Swiggy via UPI',
        ),
      );

      expect(first.length, 1);
      expect(second.length, 1);
      final rows = await db.select(db.pendingTransactions).get();
      expect(rows.length, 2);
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
        pendingService: pendingService,
        keywordFilter: NotificationKeywordFilter(),
        fingerprint: NotificationFingerprint(),
        localNotifier: localNotifier,
        isDetectionEnabled: () => false,
        areOptionalNotificationSourcesEnabled: () => true,
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
          pendingService: pendingService,
          keywordFilter: NotificationKeywordFilter(),
          fingerprint: NotificationFingerprint(),
          localNotifier: localNotifier,
          isDetectionEnabled: () => true,
          areOptionalNotificationSourcesEnabled: () => true,
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

    test('UPI/payment app notifications respect opt-in setting', () async {
      final optionalPendingService = PendingService(db, TransactionEngine(db));
      final optionalParserRegistry = TransactionParserRegistry(
        parsers: [
          UpiNotificationParser(),
          CardNotificationParser(),
          GenericBankSmsParser(),
        ],
        fallbackParser: GenericFallbackParser(),
      );
      final optionalPendingIngestion = PendingIngestionService(
        db,
        optionalPendingService,
        optionalParserRegistry,
      );
      final blockedEntries = <NotificationDebugEntry>[];
      final disabledOptionalService = NotificationIngestionService(
        database: db,
        pendingIngestionService: optionalPendingIngestion,
        pendingService: optionalPendingService,
        keywordFilter: NotificationKeywordFilter(),
        fingerprint: NotificationFingerprint(),
        localNotifier: _FakeLocalNotifier(),
        isDetectionEnabled: () => true,
        areOptionalNotificationSourcesEnabled: () => false,
        shouldShowDetectionNotifications: () => true,
        appendDebug: blockedEntries.add,
      );

      final disabledIds = await disabledOptionalService.processPayload(
        NotificationPayload(
          packageName: 'com.phonepe.app',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 5, 24, 12, 0),
          title: 'Paid ₹250',
          body: 'to Zomato via UPI',
        ),
      );
      expect(disabledIds, isEmpty);
      expect(blockedEntries, isEmpty);

      final enabledIds = await service.processPayload(
        NotificationPayload(
          packageName: 'com.phonepe.app',
          sourceType: 'appNotification',
          receivedAt: DateTime(2026, 5, 24, 12, 5),
          title: 'Paid ₹250',
          body: 'to Zomato via UPI',
        ),
      );
      expect(enabledIds.length, 1);
    });
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
