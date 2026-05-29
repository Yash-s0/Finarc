import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/features/cards/data/billing_service.dart';
import 'package:finarc/features/expenses/data/transaction_engine.dart';
import 'package:finarc/features/expenses/models/transaction_types.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> createCard({
    int billingDay = 10,
    int dueDay = 20,
    double outstanding = 0,
  }) async {
    return db
        .into(db.creditCards)
        .insert(
          CreditCardsCompanion.insert(
            bankName: 'Test Bank',
            nickname: 'Primary',
            last4: '1234',
            maskedNumber: '**** **** **** 1234',
            creditLimit: 100000,
            billingDay: billingDay,
            dueDay: dueDay,
            currentOutstanding: Value(outstanding),
          ),
        );
  }

  Future<void> addCardTxn(int cardId, DateTime date, double amount) async {
    await TransactionEngine(db).addTransaction(
      AddTransactionInput(
        type: TransactionType.creditCard,
        amount: amount,
        title: 'Card txn',
        category: 'Food',
        transactionDate: date,
        paymentSourceType: PaymentSourceType.creditCard,
        paymentSourceId: cardId,
      ),
    );
  }

  test('billing cycle includes cutoff day and excludes next day', () async {
    final cardId = await createCard(billingDay: 20, dueDay: 7);
    await addCardTxn(cardId, DateTime(2026, 5, 19), 1200);
    await addCardTxn(cardId, DateTime(2026, 5, 20), 800);
    await addCardTxn(cardId, DateTime(2026, 5, 21), 600);

    final service = BillingService(db, now: () => DateTime(2026, 5, 25));
    final bill = await service.generateBillForCard(cardId);
    final unbilled = await service.getUnbilledTransactions(cardId);
    final snapshot = await service.getCardBillingSnapshotById(cardId);

    expect(bill, isNotNull);
    expect(bill!.billingDate, DateTime(2026, 5, 20));
    expect(bill.cycleStartDate, DateTime(2026, 4, 21));
    expect(bill.cycleEndDate, DateTime(2026, 5, 20));
    expect(bill.dueDate, DateTime(2026, 6, 7));
    expect(bill.billedAmount, 2000);

    expect(unbilled, hasLength(1));
    expect(unbilled.single.transactionDate, DateTime(2026, 5, 21));

    expect(snapshot.billedDue, 2000);
    expect(snapshot.unbilledSpends, 600);
    expect(snapshot.totalOutstanding, 2600);
  });

  test(
    'late old transaction is attached to existing unpaid bill cycle',
    () async {
      final cardId = await createCard(billingDay: 20, dueDay: 7);
      await addCardTxn(cardId, DateTime(2026, 5, 19), 1000);

      final service = BillingService(db, now: () => DateTime(2026, 5, 25));
      final initial = await service.generateBillForCard(cardId);
      expect(initial, isNotNull);
      expect(initial!.billedAmount, 1000);

      await addCardTxn(cardId, DateTime(2026, 5, 18), 400);

      final updated = await (db.select(
        db.cardBills,
      )..where((b) => b.id.equals(initial.id))).getSingle();
      expect(updated.status, isNot('needsReview'));
      expect(updated.billedAmount, 1400);

      final txns = await service.getBilledTransactions(cardId, initial.id);
      expect(txns, hasLength(2));
    },
  );

  test(
    'paid bill is marked needsReview when later transaction affects cycle',
    () async {
      final bankId = await db
          .into(db.bankAccounts)
          .insert(
            BankAccountsCompanion.insert(
              bankName: 'Bank',
              accountName: 'Main',
              accountType: 'savings',
              currentBalance: const Value(10000),
            ),
          );
      final cardId = await createCard(billingDay: 20, dueDay: 7);
      await addCardTxn(cardId, DateTime(2026, 5, 19), 1000);

      final service = BillingService(db, now: () => DateTime(2026, 5, 25));
      final bill = await service.generateBillForCard(cardId);
      expect(bill, isNotNull);

      await service.markBillAsPaid(bill!.id, bankId, 1000);

      await addCardTxn(cardId, DateTime(2026, 5, 18), 300);

      final reviewed = await (db.select(
        db.cardBills,
      )..where((b) => b.id.equals(bill.id))).getSingle();
      expect(reviewed.status, 'needsReview');
      expect(reviewed.billedAmount, 1000);
      expect(reviewed.paidAmount, 1000);

      final unbilled = await service.getUnbilledTransactions(cardId);
      expect(unbilled.any((t) => t.amount == 300), isTrue);
    },
  );

  test('no duplicate bill rows are created for same cycle', () async {
    final cardId = await createCard(billingDay: 20, dueDay: 7);
    await addCardTxn(cardId, DateTime(2026, 5, 19), 1000);

    final service = BillingService(db, now: () => DateTime(2026, 5, 25));
    final first = await service.generateBillForCard(cardId);
    final second = await service.generateBillForCard(cardId);

    expect(first, isNotNull);
    expect(second, isNotNull);
    expect(first!.id, second!.id);

    await addCardTxn(cardId, DateTime(2026, 5, 18), 200);
    final third = await service.generateBillForCard(cardId);
    expect(third!.id, first.id);

    final bills =
        await (db.select(db.cardBills)..where(
              (b) =>
                  b.cardId.equals(cardId) &
                  b.billingDate.equals(DateTime(2026, 5, 20)),
            ))
            .get();
    expect(bills, hasLength(1));
  });

  test(
    'synthetic opening bill preserves legacy outstanding in billed due',
    () async {
      final cardId = await createCard(
        billingDay: 20,
        dueDay: 7,
        outstanding: 30000,
      );

      final service = BillingService(db, now: () => DateTime(2026, 5, 25));
      final snapshot = await service.getCardBillingSnapshotById(cardId);

      final openingBills =
          await (db.select(db.cardBills)..where(
                (b) => b.cardId.equals(cardId) & b.status.equals('opening'),
              ))
              .get();

      expect(openingBills, hasLength(1));
      expect(snapshot.billedDue, 30000);
      expect(snapshot.unbilledSpends, 0);
      expect(snapshot.totalOutstanding, 30000);
      expect(snapshot.availableLimit, 70000);
    },
  );
}
