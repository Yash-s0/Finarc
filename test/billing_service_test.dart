import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/features/cards/data/billing_service.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> createCard() async {
    return db
        .into(db.creditCards)
        .insert(
          CreditCardsCompanion.insert(
            bankName: 'Test Bank',
            nickname: 'Primary',
            last4: '1234',
            maskedNumber: '**** **** **** 1234',
            creditLimit: 100000,
            billingDay: 10,
            dueDay: 20,
            currentOutstanding: const Value(30000),
          ),
        );
  }

  test('transaction before billing date goes into billed cycle', () async {
    final cardId = await createCard();
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            title: 'Cycle expense',
            category: 'Food',
            amount: 1000,
            type: 'creditCard',
            transactionDate: DateTime(2026, 5, 9),
            paymentSourceType: 'creditCard',
            paymentSourceId: cardId,
          ),
        );

    final service = BillingService(db, now: () => DateTime(2026, 5, 15));
    final bill = await service.generateBillForCard(cardId);

    expect(bill, isNotNull);
    expect(bill!.billedAmount, 1000);

    final billedTxns = await service.getBilledTransactions(cardId, bill.id);
    expect(billedTxns.length, 1);
  });

  test('transaction after billing date stays unbilled', () async {
    final cardId = await createCard();
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            title: 'Post bill expense',
            category: 'Travel',
            amount: 2500,
            type: 'creditCard',
            transactionDate: DateTime(2026, 5, 12),
            paymentSourceType: 'creditCard',
            paymentSourceId: cardId,
          ),
        );

    final service = BillingService(db, now: () => DateTime(2026, 5, 15));
    final bill = await service.generateBillForCard(cardId);

    expect(bill, isNotNull);
    expect(bill!.billedAmount, 0);
    final unbilled = await service.getUnbilledTransactions(cardId);
    expect(unbilled.length, 1);
  });

  test('bill amount freezes after generation', () async {
    final cardId = await createCard();
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            title: 'Included expense',
            category: 'Food',
            amount: 1000,
            type: 'creditCard',
            transactionDate: DateTime(2026, 5, 9),
            paymentSourceType: 'creditCard',
            paymentSourceId: cardId,
          ),
        );

    final service = BillingService(db, now: () => DateTime(2026, 5, 15));
    final bill = await service.generateBillForCard(cardId);

    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            title: 'Late inserted old-date expense',
            category: 'Food',
            amount: 500,
            type: 'creditCard',
            transactionDate: DateTime(2026, 5, 8),
            paymentSourceType: 'creditCard',
            paymentSourceId: cardId,
          ),
        );

    final again = await service.generateBillForCard(cardId);

    expect(again!.id, bill!.id);
    expect(again.billedAmount, 1000);
  });
}
