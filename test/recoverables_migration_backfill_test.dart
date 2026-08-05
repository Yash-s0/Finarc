import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('backfill normalizes legacy recoverable statuses and amounts', () async {
    final now = DateTime(2026, 5, 24);

    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            type: 'bank',
            amount: 500,
            title: 'Legacy settled',
            category: 'Food',
            transactionDate: now,
            paymentSourceType: 'bank',
            paymentSourceId: 1,
            cashbackAmount: const Value(50),
            isForOthers: const Value(true),
            recoverableAmount: const Value(300),
            recoverableStatus: const Value('settled'),
          ),
        );
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            type: 'bank',
            amount: 500,
            title: 'Legacy partial',
            category: 'Food',
            transactionDate: now,
            paymentSourceType: 'bank',
            paymentSourceId: 1,
            cashbackAmount: const Value(50),
            isForOthers: const Value(true),
            recoverableAmount: const Value(220),
            recoverableStatus: const Value('partial'),
          ),
        );
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            type: 'bank',
            amount: 500,
            title: 'Legacy unknown',
            category: 'Food',
            transactionDate: now,
            paymentSourceType: 'bank',
            paymentSourceId: 1,
            cashbackAmount: const Value(50),
            isForOthers: const Value(true),
            recoverableStatus: const Value('unknown'),
          ),
        );
    await db
        .into(db.pendingTransactions)
        .insert(
          PendingTransactionsCompanion.insert(
            amount: 400,
            merchant: 'Pending legacy',
            categorySuggestion: 'Food',
            paymentSourceTypeSuggestion: 'bank',
            detectedAt: now,
            transactionDate: now,
            sourceType: 'sms',
            rawText: 'legacy',
            confidenceScore: 0.9,
            isForOthers: const Value(true),
            cashbackAmount: const Value(20),
            recoverableAmount: const Value(180),
          ),
        );

    await db.normalizeRecoverableDataBackfill();

    final txns = await db.select(db.transactions).get();
    final byTitle = {for (final t in txns) t.title: t};

    final settled = byTitle['Legacy settled']!;
    expect(settled.recoverableBaseAmount, closeTo(300, 0.01));
    expect(settled.recoveredAmount, closeTo(300, 0.01));
    expect(settled.recoverableAmount, closeTo(0, 0.01));
    expect(settled.recoverableStatus, 'recovered');

    final partial = byTitle['Legacy partial']!;
    expect(partial.recoverableBaseAmount, closeTo(220, 0.01));
    expect(partial.recoveredAmount, closeTo(0, 0.01));
    expect(partial.recoverableAmount, closeTo(220, 0.01));
    expect(partial.recoverableStatus, 'unpaid');

    final unknown = byTitle['Legacy unknown']!;
    expect(unknown.recoverableBaseAmount, closeTo(450, 0.01));
    expect(unknown.recoveredAmount, closeTo(0, 0.01));
    expect(unknown.recoverableAmount, closeTo(450, 0.01));
    expect(unknown.recoverableStatus, 'unpaid');

    final pending = await db.select(db.pendingTransactions).getSingle();
    expect(pending.recoverableBaseAmount, closeTo(180, 0.01));
    expect(pending.recoveredAmount, closeTo(0, 0.01));
    expect(pending.recoverableAmount, closeTo(180, 0.01));
  });

  test('repair marks legacy mirrored autopay pending rows as duplicates', () async {
    final cardSpendId = await db
        .into(db.pendingTransactions)
        .insert(
          PendingTransactionsCompanion.insert(
            amount: 899,
            merchant: 'Upa Apple India Privat',
            categorySuggestion: 'Others',
            paymentSourceTypeSuggestion: 'creditCard',
            detectedAt: DateTime(2026, 7, 27, 14, 19, 48),
            transactionDate: DateTime(2026, 7, 27, 14, 19, 48),
            sourceType: 'sms',
            rawText:
                'INR 899.00 spent on YES BANK Card X8731 @UPA_APPLE INDIA PRIVAT 27-07-2026 02:19:48 pm. Avl Lmt INR 45,338.05. SMS BLKCC 8731 to 9840909000 if not you',
            confidenceScore: 0.95,
          ),
        );
    final debitSmsId = await db
        .into(db.pendingTransactions)
        .insert(
          PendingTransactionsCompanion.insert(
            amount: 899,
            merchant: '27 07 2026 Towards Apple India Private Limited',
            categorySuggestion: 'Transfer',
            paymentSourceTypeSuggestion: 'bank',
            detectedAt: DateTime(2026, 7, 27, 14, 19, 58),
            transactionDate: DateTime(2026, 7, 27, 14, 19, 58),
            sourceType: 'sms',
            rawText:
                'JD-YESBAK-S Your RuPay Credit Card has been successfully debited with Rs.899.00 on 27/07/2026 towards Apple India Private Limited UPI AutoPay, 1acc1dde7ac648cabe4e3a029571c4e7@yescred.-Yes Bank Your RuPay Credit Card has been successfully debited with Rs.899.00 on 27/07/2026 towards Apple India Private Limited UPI AutoPay, 1acc1dde7ac648cabe4e3a029571c4e7@yescred.-Yes Bank',
            confidenceScore: 0.95,
          ),
        );
    final appAlertId = await db
        .into(db.pendingTransactions)
        .insert(
          PendingTransactionsCompanion.insert(
            amount: 899,
            merchant: 'Your',
            categorySuggestion: 'Transfer',
            paymentSourceTypeSuggestion: 'upi',
            detectedAt: DateTime(2026, 7, 27, 14, 19, 49),
            transactionDate: DateTime(2026, 7, 27, 14, 19, 49),
            sourceType: 'appNotification',
            rawText:
                'update on your UPI autopay payment UPI autopay of ₹899 for Apple India Private Limited has been debited successfully. tap for more details. update on your UPI autopay payment UPI autopay of ₹899 for Apple India Private Limited has been debited successfully. tap for more details.',
            confidenceScore: 0.77,
          ),
        );

    final repaired = await db.repairMirroredAutopayPendingDuplicates();

    expect(repaired, 2);
    final rows = await db.select(db.pendingTransactions).get();
    final byId = {for (final row in rows) row.id: row};
    expect(byId[cardSpendId]!.status, 'pending');
    expect(byId[debitSmsId]!.status, 'duplicate');
    expect(byId[debitSmsId]!.duplicateOfTransactionId, cardSpendId);
    expect(byId[appAlertId]!.status, 'duplicate');
    expect(byId[appAlertId]!.duplicateOfTransactionId, cardSpendId);

    final secondRun = await db.repairMirroredAutopayPendingDuplicates();
    expect(secondRun, 0);
  });

  test(
    'repair ignores promo pending and reverses confirmed promo income',
    () async {
      final bankId = await db
          .into(db.bankAccounts)
          .insert(
            BankAccountsCompanion.insert(
              bankName: 'Kotak',
              accountName: 'Main',
              accountType: 'savings',
              currentBalance: const Value(10500),
            ),
          );
      final raw =
          'Salary credited? Time to use it smartly! Start your SIP with Kotak811 App from just ₹500. T&C apply';
      final at = DateTime(2026, 8, 1, 11, 1, 32);
      final pendingId = await db
          .into(db.pendingTransactions)
          .insert(
            PendingTransactionsCompanion.insert(
              amount: 500,
              merchant: 'Just',
              categorySuggestion: 'Income',
              paymentSourceTypeSuggestion: 'bank',
              paymentSourceIdSuggestion: Value(bankId),
              detectedAt: at,
              transactionDate: at,
              sourceType: 'appNotification',
              rawText: raw,
              confidenceScore: 0.77,
              status: const Value('confirmed'),
            ),
          );
      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              type: 'income',
              amount: 500,
              title: 'Just',
              category: 'Income',
              transactionDate: at,
              paymentSourceType: 'bank',
              paymentSourceId: bankId,
            ),
          );

      final repaired = await db.repairPromoAndSweepArtifacts();

      expect(repaired, 2);
      final pending = await (db.select(
        db.pendingTransactions,
      )..where((p) => p.id.equals(pendingId))).getSingle();
      final txns = await db.select(db.transactions).get();
      final bank = await (db.select(
        db.bankAccounts,
      )..where((b) => b.id.equals(bankId))).getSingle();
      expect(pending.status, 'ignored');
      expect(txns, isEmpty);
      expect(bank.currentBalance, closeTo(10000, 0.01));
    },
  );

  test('repair converts confirmed sweep to balance-neutral transfer', () async {
    final bankId = await db
        .into(db.bankAccounts)
        .insert(
          BankAccountsCompanion.insert(
            bankName: 'Kotak',
            accountName: 'Main',
            accountType: 'savings',
            currentBalance: const Value(25000),
          ),
        );
    final raw =
        'ActivMoney sweep out ₹15,000.00 credited to ActivMoney. Check out details.';
    final at = DateTime(2026, 7, 31, 22, 34, 18);
    await db
        .into(db.pendingTransactions)
        .insert(
          PendingTransactionsCompanion.insert(
            amount: 15000,
            merchant: 'Activmoney',
            categorySuggestion: 'Transfer',
            paymentSourceTypeSuggestion: 'bank',
            paymentSourceIdSuggestion: Value(bankId),
            detectedAt: at,
            transactionDate: at,
            sourceType: 'appNotification',
            rawText: raw,
            confidenceScore: 0.77,
            status: const Value('confirmed'),
          ),
        );
    final txnId = await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            type: 'income',
            amount: 15000,
            title: 'Activmoney',
            category: 'Transfer',
            transactionDate: at,
            paymentSourceType: 'bank',
            paymentSourceId: bankId,
          ),
        );

    final repaired = await db.repairPromoAndSweepArtifacts();

    expect(repaired, 1);
    final txn = await (db.select(
      db.transactions,
    )..where((t) => t.id.equals(txnId))).getSingle();
    final bank = await (db.select(
      db.bankAccounts,
    )..where((b) => b.id.equals(bankId))).getSingle();
    expect(txn.type, 'transfer');
    expect(txn.title, 'ActivMoney');
    expect(txn.transactionImpactType, 'historicalNoBalance');
    expect(bank.currentBalance, closeTo(10000, 0.01));
  });

  test('repair reopens recovered unbilled card recoverables', () async {
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            type: 'creditCard',
            amount: 1500,
            title: 'Amazon',
            category: 'Groceries',
            transactionDate: DateTime(2026, 7, 20),
            paymentSourceType: 'creditCard',
            paymentSourceId: 1,
            cashbackAmount: const Value(275),
            isForOthers: const Value(true),
            recoverableBaseAmount: const Value(1225),
            recoverableAmount: const Value(0),
            recoveredAmount: const Value(1225),
            recoverableStatus: const Value('recovered'),
          ),
        );

    final repaired = await db.repairUnbilledCardRecoveries();

    expect(repaired, 1);
    final txn = await db.select(db.transactions).getSingle();
    expect(txn.recoverableAmount, closeTo(1225, 0.01));
    expect(txn.recoveredAmount, closeTo(0, 0.01));
    expect(txn.recoverableStatus, 'unpaid');
    expect(txn.recoveredAt, null);
  });

  test('repair recalculates stale opening bill due', () async {
    final cardId = await db
        .into(db.creditCards)
        .insert(
          CreditCardsCompanion.insert(
            bankName: 'ICICI',
            nickname: 'Amazon Pay',
            last4: '9000',
            maskedNumber: '**** **** **** 9000',
            creditLimit: 60000,
            billingDay: 20,
            dueDay: 7,
            currentOutstanding: const Value(19609),
          ),
        );
    final openingId = await db
        .into(db.cardBills)
        .insert(
          CardBillsCompanion.insert(
            cardId: cardId,
            cycleStartDate: Value(DateTime(2026, 8, 1)),
            cycleEndDate: Value(DateTime(2026, 8, 1)),
            billingDate: Value(DateTime(2026, 8, 1)),
            dueDate: Value(DateTime(2026, 8, 7)),
            billedAmount: 1000,
            status: const Value('opening'),
          ),
        );
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            type: 'creditCard',
            amount: 1500,
            title: 'Amazon',
            category: 'Groceries',
            transactionDate: DateTime(2026, 7, 20),
            paymentSourceType: 'creditCard',
            paymentSourceId: cardId,
          ),
        );

    final repaired = await db.repairStaleOpeningBills();

    expect(repaired, 1);
    final opening = await (db.select(
      db.cardBills,
    )..where((b) => b.id.equals(openingId))).getSingle();
    expect(opening.billedAmount, closeTo(18109, 0.01));
  });
}
