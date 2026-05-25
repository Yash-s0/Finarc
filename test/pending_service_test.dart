import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/features/expenses/data/transaction_engine.dart';
import 'package:finarc/features/expenses/models/transaction_types.dart';
import 'package:finarc/features/pending/data/pending_service.dart';
import 'package:finarc/features/pending/models/pending_models.dart';

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
}
