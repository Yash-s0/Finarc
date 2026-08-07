import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/core/database/database_providers.dart';
import 'package:finarc/features/expenses/models/transaction_types.dart';
import 'package:finarc/features/expenses/presentation/transaction_detail_screen.dart';

void main() {
  late AppDatabase db;
  late int bankId;
  late int cardId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    bankId = await db
        .into(db.bankAccounts)
        .insert(
          BankAccountsCompanion.insert(
            bankName: 'Kotak',
            accountName: 'Kotak 811',
            accountType: 'savings',
            currentBalance: const Value(100000),
          ),
        );
    cardId = await db
        .into(db.creditCards)
        .insert(
          CreditCardsCompanion.insert(
            bankName: 'ICICI Bank',
            nickname: 'Amazon Pay',
            last4: '9000',
            maskedNumber: '**** **** **** 9000',
            creditLimit: 60000,
            billingDay: 20,
            dueDay: 7,
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  Widget wrap(int transactionId) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        seedProvider.overrideWith((ref) async {}),
      ],
      child: MaterialApp(
        home: TransactionDetailScreen(transactionId: transactionId),
      ),
    );
  }

  Future<int> addTransaction({
    required String type,
    required String title,
    required String sourceType,
    required int sourceId,
    String? transferGroupId,
  }) {
    return db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            type: type,
            amount: 21408,
            title: title,
            category: type == TransactionType.income ? 'Salary' : 'Transfer',
            transactionDate: DateTime(2026, 7, 30, 13, 53, 34),
            paymentSourceType: sourceType,
            paymentSourceId: sourceId,
            transferGroupId: Value(transferGroupId),
          ),
        );
  }

  testWidgets('linked card payment clearly labels transfer out', (
    tester,
  ) async {
    final id = await addTransaction(
      type: TransactionType.cardPayment,
      title: 'Card Bill Payment Out',
      sourceType: PaymentSourceType.bank,
      sourceId: bankId,
      transferGroupId: 'cardpay_1',
    );

    await tester.pumpWidget(wrap(id));
    await tester.pumpAndSettle();

    expect(find.text('TRANSFER OUT'), findsOneWidget);
    expect(find.text('Paid from Bank'), findsOneWidget);
    expect(find.textContaining('matching transfer-in entry'), findsOneWidget);
  });

  testWidgets('linked card payment clearly labels transfer in', (tester) async {
    final id = await addTransaction(
      type: TransactionType.cardPayment,
      title: 'Card Bill Payment In',
      sourceType: PaymentSourceType.creditCard,
      sourceId: cardId,
      transferGroupId: 'cardpay_1',
    );

    await tester.pumpWidget(wrap(id));
    await tester.pumpAndSettle();

    expect(find.text('TRANSFER IN'), findsOneWidget);
    expect(find.text('Applied to Card'), findsOneWidget);
    expect(find.textContaining('matching transfer-out entry'), findsOneWidget);
  });

  testWidgets('ordinary income and expense have explicit type labels', (
    tester,
  ) async {
    final incomeId = await addTransaction(
      type: TransactionType.income,
      title: 'Salary',
      sourceType: PaymentSourceType.bank,
      sourceId: bankId,
    );
    final expenseId = await addTransaction(
      type: TransactionType.bank,
      title: 'Groceries',
      sourceType: PaymentSourceType.bank,
      sourceId: bankId,
    );

    await tester.pumpWidget(wrap(incomeId));
    await tester.pumpAndSettle();
    expect(find.text('INCOME'), findsOneWidget);

    await tester.pumpWidget(wrap(expenseId));
    await tester.pumpAndSettle();
    expect(find.text('EXPENSE'), findsOneWidget);
  });
}
