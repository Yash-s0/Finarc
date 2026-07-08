import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/features/expenses/data/transaction_engine.dart';
import 'package:finarc/features/pending/data/pending_service.dart';
import 'package:finarc/features/pending/notifications/notification_keyword_filter.dart';
import 'package:finarc/features/pending/notifications/notification_payload.dart';
import 'package:finarc/features/pending/notifications/sms_permission_service.dart';
import 'package:finarc/features/pending/notifications/sms_recovery_service.dart';
import 'package:finarc/features/pending/notifications/sms_sender_filter.dart';
import 'package:finarc/features/pending/parsing/parsers/card_notification_parser.dart';
import 'package:finarc/features/pending/parsing/parsers/generic_bank_sms_parser.dart';
import 'package:finarc/features/pending/parsing/parsers/generic_fallback_parser.dart';
import 'package:finarc/features/pending/parsing/parsers/upi_notification_parser.dart';
import 'package:finarc/features/pending/parsing/pending_ingestion_service.dart';
import 'package:finarc/features/pending/parsing/transaction_parser_registry.dart';

void main() {
  group('SMS recovery service', () {
    late AppDatabase db;
    late SmsRecoveryService recoveryService;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      final transactionEngine = TransactionEngine(db);
      final pendingService = PendingService(db, transactionEngine);
      final registry = TransactionParserRegistry(
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
        registry,
      );
      await db
          .into(db.creditCards)
          .insert(
            CreditCardsCompanion.insert(
              bankName: 'Axis Bank',
              nickname: 'Axis',
              last4: '0374',
              maskedNumber: '**** **** **** 0374',
              creditLimit: 200000,
              billingDay: 15,
              dueDay: 5,
              currentOutstanding: const Value(0),
            ),
          );
      await db
          .into(db.creditCards)
          .insert(
            CreditCardsCompanion.insert(
              bankName: 'Yes Bank',
              nickname: 'Yes',
              last4: '8731',
              maskedNumber: '**** **** **** 8731',
              creditLimit: 100000,
              billingDay: 15,
              dueDay: 5,
              currentOutstanding: const Value(0),
            ),
          );
      recoveryService = SmsRecoveryService(
        db,
        SmsPermissionService(),
        pendingIngestion,
        transactionEngine,
        NotificationKeywordFilter(),
        const SmsSenderFilter(),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('classifies a generic card spend SMS as importable', () async {
      final preview = await recoveryService.classifyPayload(
        NotificationPayload(
          packageName: 'android.sms',
          sourceType: 'sms',
          receivedAt: DateTime(2026, 7, 7, 13, 4, 46),
          sender: 'CP-AXISBK-S',
          title: 'CP-AXISBK-S',
          body:
              'Spent INR 33275.73\nAxis Bank Card no. XX0374\n07-07-26 13:04:46 IST\nTRAVELPORTAL\nAvl Limit: INR 114844.17',
        ),
      );

      expect(preview.status, SmsBackfillPreviewStatus.importable);
      expect(preview.amount, 33275.73);
      expect(preview.merchant, isNotNull);
      expect(preview.reason, 'Ready to import');
    });

    test('keeps bill due and available-limit-only messages out', () async {
      final billDue = await recoveryService.classifyPayload(
        NotificationPayload(
          packageName: 'android.sms',
          sourceType: 'sms',
          receivedAt: DateTime(2026, 7, 6, 17, 19),
          sender: 'AX-YESBNK-S',
          title: 'AX-YESBNK-S',
          body:
              'URGENT: Bill Overdue! Credit card bill of ₹4,126.95 for Yes Bank card - 8731 was due on 4th Jul. Pay now with ₹0 fees & avoid penalties. Ignore if already paid!',
        ),
      );
      final limitOnly = await recoveryService.classifyPayload(
        NotificationPayload(
          packageName: 'android.sms',
          sourceType: 'sms',
          receivedAt: DateTime(2026, 7, 6, 11, 43),
          sender: 'AX-YESBNK-S',
          title: 'AX-YESBNK-S',
          body:
              'YES BANK Card X8731 Avl Lmt INR 58,970.70. SMS BLKCC 8731 to 9840909000 if not you',
        ),
      );

      expect(billDue.status, SmsBackfillPreviewStatus.ignored);
      expect(billDue.reason, 'non-expense-card-message');
      expect(limitOnly.status, SmsBackfillPreviewStatus.ignored);
      expect(limitOnly.reason, 'non-expense-card-message');
    });

    test(
      'adds selected preview as a confirmed transaction without pending',
      () async {
        final payload = NotificationPayload(
          packageName: 'android.sms',
          sourceType: 'sms',
          receivedAt: DateTime(2026, 7, 7, 13, 8, 48),
          sender: 'AX-YESBNK-S',
          title: 'AX-YESBNK-S',
          body:
              'INR 20,929.19 spent on YES BANK Card X8731 @UPI_HOTELBOOKING PAYMENTS IN 07-07-2026 01:08:48 pm. Avl Lmt INR 35,645.51. SMS BLKCC 8731 to 9840909000 if not you',
        );
        final preview = await recoveryService.classifyPayload(payload);

        final result = await recoveryService.importPreviews([preview]);
        final pending = await db.select(db.pendingTransactions).get();
        final transactions = await db.select(db.transactions).get();
        final sourceEvents = await db.select(db.transactionSourceEvents).get();

        expect(preview.status, SmsBackfillPreviewStatus.importable);
        expect(result.importedCount, 1);
        expect(result.duplicateOrSkippedCount, 0);
        expect(pending, isEmpty);
        expect(transactions, hasLength(1));
        expect(transactions.single.amount, 20929.19);
        expect(transactions.single.detectedSourceType, 'smsRecovery');
        expect(sourceEvents, hasLength(1));
        expect(sourceEvents.single.transactionId, transactions.single.id);
        expect(sourceEvents.single.sourceFingerprint, preview.id);
        expect(sourceEvents.single.status, 'imported');

        final duplicatePreview = await recoveryService.classifyPayload(payload);
        final duplicateResult = await recoveryService.importPreviews([
          duplicatePreview,
        ]);
        final transactionsAfterDuplicate = await db
            .select(db.transactions)
            .get();
        final sourceEventsAfterDuplicate = await db
            .select(db.transactionSourceEvents)
            .get();

        expect(
          duplicatePreview.status,
          SmsBackfillPreviewStatus.duplicateLikely,
        );
        expect(duplicateResult.importedCount, 0);
        expect(duplicateResult.duplicateOrSkippedCount, 1);
        expect(transactionsAfterDuplicate, hasLength(1));
        expect(sourceEventsAfterDuplicate, hasLength(1));
      },
    );

    test('attaches duplicate SMS proof to an existing transaction', () async {
      final payload = NotificationPayload(
        packageName: 'android.sms',
        sourceType: 'sms',
        receivedAt: DateTime(2026, 7, 7, 13, 4, 46),
        sender: 'CP-AXISBK-S',
        title: 'CP-AXISBK-S',
        body:
            'Spent INR 33275.73\nAxis Bank Card no. XX0374\n07-07-26 13:04:46 IST\nTRAVELPORTAL\nAvl Limit: INR 114844.17',
      );
      final preview = await recoveryService.classifyPayload(payload);
      final existingTransactionId = await TransactionEngine(db).addTransaction(
        AddTransactionInput(
          type: 'creditCard',
          amount: preview.amount!,
          title: preview.merchant!,
          category: preview.category ?? 'Travel',
          transactionDate: preview.transactionDate!,
          paymentSourceType: preview.paymentSourceType!,
          paymentSourceId: preview.paymentSourceId,
          detectedSourceType: 'manual',
          transactionImpactType: 'historicalNoBalance',
        ),
      );

      final duplicatePreview = await recoveryService.classifyPayload(payload);
      final result = await recoveryService.importPreviews([duplicatePreview]);
      final transactions = await db.select(db.transactions).get();
      final sourceEvents = await db.select(db.transactionSourceEvents).get();

      expect(duplicatePreview.status, SmsBackfillPreviewStatus.duplicateLikely);
      expect(result.importedCount, 0);
      expect(result.duplicateOrSkippedCount, 1);
      expect(result.previews.single.reason, contains('proof attached'));
      expect(transactions, hasLength(1));
      expect(sourceEvents, hasLength(1));
      expect(sourceEvents.single.transactionId, existingTransactionId);
      expect(sourceEvents.single.status, 'duplicateAttached');
    });
  });
}
