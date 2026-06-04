import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/features/expenses/data/transaction_engine.dart';
import 'package:finarc/features/expenses/models/transaction_types.dart';
import 'package:finarc/features/pending/data/pending_service.dart';
import 'package:finarc/features/pending/models/pending_models.dart';
import 'package:finarc/features/pending/notifications/card_payment_pending_codec.dart';

void main() {
  late AppDatabase db;
  late PendingService service;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final engine = TransactionEngine(db);
    service = PendingService(db, engine);

    await db
        .into(db.bankAccounts)
        .insert(
          BankAccountsCompanion.insert(
            bankName: 'Test Bank',
            accountName: 'Main',
            accountType: 'savings',
            currentBalance: const Value(10000),
          ),
        );
    await db
        .into(db.cashWallets)
        .insert(
          CashWalletsCompanion.insert(
            walletName: 'Cash',
            currentBalance: const Value(3000),
          ),
        );
    await db
        .into(db.creditCards)
        .insert(
          CreditCardsCompanion.insert(
            bankName: 'Bank',
            nickname: 'Card',
            last4: '1234',
            maskedNumber: '**** **** **** 1234',
            creditLimit: 50000,
            billingDay: 10,
            dueDay: 20,
            currentOutstanding: const Value(1000),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  test('create + get pending transactions', () async {
    await service.createPendingTransaction(
      amount: 1499,
      merchant: 'Swiggy',
      categorySuggestion: 'Food',
      paymentSourceTypeSuggestion: PaymentSourceType.creditCard,
      paymentSourceIdSuggestion: 1,
      transactionDate: DateTime.now(),
      sourceType: 'sms',
      rawText: 'sample',
      confidenceScore: 0.94,
    );

    final list = await service.getPendingTransactions();
    expect(list.length, 1);
    expect(list.first.merchant, 'Swiggy');
  });

  test(
    'confirm pending creates real transaction and marks pending confirmed',
    () async {
      final pendingId = await service.createPendingTransaction(
        amount: 700,
        merchant: 'Rahul',
        categorySuggestion: 'Transfer',
        paymentSourceTypeSuggestion: PaymentSourceType.upi,
        paymentSourceIdSuggestion: 1,
        transactionDate: DateTime.now(),
        sourceType: 'upiNotification',
        rawText: 'upi',
        confidenceScore: 0.8,
      );

      await service.confirmPendingTransaction(
        pendingId,
        PendingEditData(
          amount: 700,
          merchant: 'Rahul',
          category: 'Transfer',
          paymentSourceType: PaymentSourceType.upi,
          paymentSourceId: 1,
          transactionDate: DateTime.now(),
        ),
      );

      final txnCount = await db.select(db.transactions).get();
      final pending = await (db.select(
        db.pendingTransactions,
      )..where((p) => p.id.equals(pendingId))).getSingle();

      expect(txnCount.length, 1);
      expect(pending.status, 'confirmed');
    },
  );

  test('confirm received pending creates income transaction', () async {
    final pendingId = await service.createPendingTransaction(
      amount: 1,
      merchant: 'Yas21606 4 Okaxis',
      categorySuggestion: 'Transfer',
      paymentSourceTypeSuggestion: PaymentSourceType.bank,
      paymentSourceIdSuggestion: 1,
      transactionDate: DateTime(2026, 5, 30, 12, 0),
      sourceType: 'appNotification',
      rawText:
          'Received Rs.1.00 in your Kotak Bank AC X0754 from yas21606-4@okaxis on 30-05-26. UPI Ref:651638004295.',
      confidenceScore: 0.92,
    );

    await service.confirmPendingTransaction(
      pendingId,
      PendingEditData(
        amount: 1,
        merchant: 'Yas21606 4 Okaxis',
        category: 'Transfer',
        paymentSourceType: PaymentSourceType.bank,
        paymentSourceId: 1,
        transactionDate: DateTime(2026, 5, 30, 12, 0),
      ),
    );

    final txn = await (db.select(
      db.transactions,
    )..where((t) => t.id.isBiggerThanValue(0))).getSingle();
    final bank = await (db.select(
      db.bankAccounts,
    )..where((b) => b.id.equals(1))).getSingle();

    expect(txn.type, TransactionType.income);
    expect(txn.amount, 1);
    expect(txn.paymentSourceType, PaymentSourceType.bank);
    expect(bank.currentBalance, closeTo(10001, 0.001));
  });

  test('ignore pending changes status', () async {
    final id = await service.createPendingTransaction(
      amount: 99,
      merchant: 'Test',
      categorySuggestion: 'Misc',
      paymentSourceTypeSuggestion: PaymentSourceType.cash,
      paymentSourceIdSuggestion: 1,
      transactionDate: DateTime.now(),
      sourceType: 'manualImport',
      rawText: 'x',
      confidenceScore: 0.5,
    );

    await service.ignorePendingTransaction(id);
    final p = await (db.select(
      db.pendingTransactions,
    )..where((q) => q.id.equals(id))).getSingle();
    expect(p.status, 'ignored');
  });

  test('detect duplicate finds matching transaction', () async {
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            type: TransactionType.creditCard,
            amount: 1500,
            title: 'Amazon',
            category: 'Shopping',
            transactionDate: DateTime.now(),
            paymentSourceType: PaymentSourceType.creditCard,
            paymentSourceId: 1,
          ),
        );

    final id = await service.createPendingTransaction(
      amount: 1500,
      merchant: 'Amazon',
      categorySuggestion: 'Shopping',
      paymentSourceTypeSuggestion: PaymentSourceType.creditCard,
      paymentSourceIdSuggestion: 1,
      transactionDate: DateTime.now(),
      sourceType: 'appNotification',
      rawText: 'x',
      confidenceScore: 0.8,
    );

    final pending = await (db.select(
      db.pendingTransactions,
    )..where((p) => p.id.equals(id))).getSingle();
    final duplicate = await service.detectPossibleDuplicate(pending);
    expect(duplicate, isNotNull);
  });

  test(
    'confirm card payment pending settles bill and records cardPayment',
    () async {
      await db
          .into(db.cardBills)
          .insert(
            CardBillsCompanion.insert(
              cardId: 1,
              cycleStartDate: Value(DateTime(2026, 5, 1)),
              cycleEndDate: Value(DateTime(2026, 5, 31)),
              billingDate: Value(DateTime(2026, 5, 31)),
              dueDate: Value(DateTime(2026, 6, 20)),
              billedAmount: 1000,
              paidAmount: const Value(0),
              status: const Value('billed'),
            ),
          );

      final pendingId = await service.createPendingTransaction(
        amount: 1000,
        merchant: 'Bank Card XX1234',
        categorySuggestion: 'Transfer',
        paymentSourceTypeSuggestion: PaymentSourceType.bank,
        paymentSourceIdSuggestion: 1,
        transactionDate: DateTime(2026, 6, 4, 9, 0),
        sourceType: 'cardPaymentNotification',
        rawText: CardPaymentPendingCodec.wrap(
          rawText:
              'Payment of INR 1000 has been received towards your Bank Credit Card XX1234 on 04-06-26.',
          data: const CardPaymentPendingData(
            issuer: 'Bank',
            cardLast4: '1234',
            destinationCardId: 1,
            sourceTypeSuggestion: PaymentSourceType.bank,
            kinds: ['destinationReceipt'],
          ),
        ),
        confidenceScore: 0.98,
      );

      await service.confirmPendingTransaction(
        pendingId,
        PendingEditData(
          amount: 1000,
          merchant: 'Bank Card XX1234',
          category: 'Transfer',
          paymentSourceType: PaymentSourceType.bank,
          paymentSourceId: 1,
          transactionDate: DateTime(2026, 6, 4, 9, 0),
        ),
      );

      final pending = await (db.select(
        db.pendingTransactions,
      )..where((p) => p.id.equals(pendingId))).getSingle();
      final bank = await (db.select(
        db.bankAccounts,
      )..where((b) => b.id.equals(1))).getSingle();
      final card = await (db.select(
        db.creditCards,
      )..where((c) => c.id.equals(1))).getSingle();
      final cardPayments = await (db.select(
        db.transactions,
      )..where((t) => t.type.equals(TransactionType.cardPayment))).get();

      expect(pending.status, 'confirmed');
      expect(bank.currentBalance, closeTo(9000, 0.001));
      expect(card.currentOutstanding, closeTo(0, 0.001));
      expect(cardPayments, hasLength(1));
      expect(cardPayments.single.amount, 1000);
    },
  );

  test(
    'pending for-others confirmation computes recoverable base and keeps full card charge',
    () async {
      final pendingId = await service.createPendingTransaction(
        amount: 900,
        merchant: 'Team Dinner',
        categorySuggestion: 'Food',
        paymentSourceTypeSuggestion: PaymentSourceType.creditCard,
        paymentSourceIdSuggestion: 1,
        transactionDate: DateTime.now(),
        sourceType: 'sms',
        rawText: 'Rs 900 spent',
        confidenceScore: 0.9,
      );

      await service.confirmPendingTransaction(
        pendingId,
        PendingEditData(
          amount: 900,
          merchant: 'Team Dinner',
          category: 'Food',
          paymentSourceType: PaymentSourceType.creditCard,
          paymentSourceId: 1,
          transactionDate: DateTime.now(),
          cashbackAmount: 100,
          isForOthers: true,
          recoveredAmount: 200,
          recoverablePartyName: 'Rahul',
        ),
      );

      final txn = await (db.select(
        db.transactions,
      )..where((t) => t.title.equals('Team Dinner'))).getSingle();
      expect(txn.recoverableBaseAmount, closeTo(800, 0.01));
      expect(txn.recoveredAmount, closeTo(200, 0.01));
      expect(txn.recoverableAmount, closeTo(600, 0.01));
      expect(txn.recoverablePartyName, 'Rahul');

      final card = await (db.select(
        db.creditCards,
      )..where((c) => c.id.equals(1))).getSingle();
      expect(card.currentOutstanding, closeTo(1900, 0.01));
    },
  );

  test('pending for-others confirmation requires party name', () async {
    final pendingId = await service.createPendingTransaction(
      amount: 500,
      merchant: 'Shared ride',
      categorySuggestion: 'Travel',
      paymentSourceTypeSuggestion: PaymentSourceType.bank,
      paymentSourceIdSuggestion: 1,
      transactionDate: DateTime.now(),
      sourceType: 'sms',
      rawText: 'Rs 500',
      confidenceScore: 0.7,
    );

    expect(
      () => service.confirmPendingTransaction(
        pendingId,
        PendingEditData(
          amount: 500,
          merchant: 'Shared ride',
          category: 'Travel',
          paymentSourceType: PaymentSourceType.bank,
          paymentSourceId: 1,
          transactionDate: DateTime.now(),
          isForOthers: true,
          recoverablePartyName: '',
        ),
      ),
      throwsArgumentError,
    );
  });

  test(
    'income confirmation without destination account throws actionable validation error',
    () async {
      final pendingId = await service.createPendingTransaction(
        amount: 1,
        merchant: 'Yas21606 4 Okaxis',
        categorySuggestion: 'Transfer',
        paymentSourceTypeSuggestion: PaymentSourceType.bank,
        paymentSourceIdSuggestion: null,
        transactionDate: DateTime(2026, 5, 30, 12, 0),
        sourceType: 'appNotification',
        rawText:
            'Received Rs.1.00 in your Kotak Bank AC X0754 from yas21606-4@okaxis on 30-05-26. UPI Ref:651638004295.',
        confidenceScore: 0.92,
      );

      try {
        await service.confirmPendingTransaction(
          pendingId,
          PendingEditData(
            amount: 1,
            merchant: 'Yas21606 4 Okaxis',
            category: 'Transfer',
            paymentSourceType: PaymentSourceType.bank,
            paymentSourceId: null,
            transactionDate: DateTime(2026, 5, 30, 12, 0),
          ),
        );
        fail('Expected PendingConfirmationException');
      } on PendingConfirmationException catch (error) {
        expect(error.reason, 'missing-destination-account');
        expect(
          error.userMessage,
          'Select destination account to confirm this income.',
        );
        expect(error.detectedType, TransactionType.income);
      }
    },
  );
}
