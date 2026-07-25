import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/core/database/database_providers.dart';
import 'package:finarc/features/cards/data/billing_service.dart';
import 'package:finarc/features/cards/presentation/card_detail_screen.dart';
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

  Future<int> createAmazonIciciCard() {
    return db
        .into(db.creditCards)
        .insert(
          CreditCardsCompanion.insert(
            bankName: 'ICICI Bank',
            nickname: 'Amazon Pay',
            last4: '1234',
            maskedNumber: '**** **** **** 1234',
            creditLimit: 100000,
            billingDay: 20,
            dueDay: 7,
          ),
        );
  }

  Future<void> addCardTxn(int cardId, DateTime date, double amount) {
    return TransactionEngine(db).addTransaction(
      AddTransactionInput(
        type: TransactionType.creditCard,
        amount: amount,
        title: 'Amazon',
        category: 'Groceries',
        transactionDate: date,
        paymentSourceType: PaymentSourceType.creditCard,
        paymentSourceId: cardId,
      ),
    );
  }

  testWidgets('current statement shows inclusive billing period', (
    tester,
  ) async {
    final cardId = await createAmazonIciciCard();
    await addCardTxn(cardId, DateTime(2026, 6, 20), 200);
    await addCardTxn(cardId, DateTime(2026, 7, 19), 300);
    await addCardTxn(cardId, DateTime(2026, 7, 20), 350);
    await addCardTxn(cardId, DateTime(2026, 7, 21), 400);

    await BillingService(
      db,
      now: () => DateTime(2026, 7, 20),
    ).generateBillForCard(cardId);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          seedProvider.overrideWith((ref) async {}),
        ],
        child: MaterialApp(home: CardDetailScreen(cardId: cardId)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Statement Date: 20/07/2026'), findsOneWidget);
    expect(
      find.text('Statement Period: 20/06/2026 - 19/07/2026'),
      findsOneWidget,
    );
    expect(find.text('Unbilled starts 20/07/2026'), findsOneWidget);
    expect(find.text('Due on 07/08/2026'), findsOneWidget);
  });
}
