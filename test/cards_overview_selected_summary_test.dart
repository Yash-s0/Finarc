import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/core/database/database_providers.dart';
import 'package:finarc/features/cards/data/billing_service.dart';
import 'package:finarc/features/cards/presentation/cards_overview_screen.dart';
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
    required String bankName,
    required String nickname,
    required String last4,
    required int dueDay,
  }) {
    return db
        .into(db.creditCards)
        .insert(
          CreditCardsCompanion.insert(
            bankName: bankName,
            nickname: nickname,
            last4: last4,
            maskedNumber: '**** **** **** $last4',
            creditLimit: 10000,
            billingDay: 20,
            dueDay: dueDay,
            currentOutstanding: const Value(0),
          ),
        );
  }

  Future<void> addCardTxn(int cardId, DateTime date, double amount) {
    return TransactionEngine(db).addTransaction(
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

  testWidgets('selected card summary metrics update after swipe', (
    tester,
  ) async {
    final primaryCardId = await createCard(
      bankName: 'ICICI',
      nickname: 'Amazon',
      last4: '9000',
      dueDay: 7,
    );
    await createCard(
      bankName: 'IndusInd',
      nickname: 'Rupay',
      last4: '1616',
      dueDay: 10,
    );

    await addCardTxn(primaryCardId, DateTime(2026, 5, 19), 1000);
    await addCardTxn(primaryCardId, DateTime(2026, 5, 21), 600);
    await BillingService(
      db,
      now: () => DateTime(2026, 6, 5),
    ).generateBillForCard(primaryCardId);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          seedProvider.overrideWith((ref) async {}),
        ],
        child: const MaterialApp(home: Scaffold(body: CardsOverviewScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('₹600.00'), findsOneWidget);
    expect(find.text('16.0%'), findsOneWidget);
    expect(find.text('₹1,000.00'), findsAtLeastNWidgets(1));

    await tester.drag(find.byType(PageView), const Offset(-320, 0));
    await tester.pumpAndSettle();

    expect(find.text('₹600.00'), findsNothing);
    expect(find.text('16.0%'), findsNothing);
    expect(find.text('0.0%'), findsOneWidget);
    expect(find.text('No active billed statement'), findsOneWidget);
  });

  testWidgets('unbilled-only cards do not show a pay now action', (
    tester,
  ) async {
    await createCard(
      bankName: 'Axis',
      nickname: 'Neo',
      last4: '1111',
      dueDay: 7,
    );

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          seedProvider.overrideWith((ref) async {}),
        ],
        child: const MaterialApp(home: Scaffold(body: CardsOverviewScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pay Now'), findsNothing);
    expect(find.text('No Bill'), findsOneWidget);
  });
}
