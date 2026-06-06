import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/core/database/database_providers.dart';
import 'package:finarc/features/expenses/presentation/expenses_screen.dart';
import 'package:finarc/shared/widgets/finarc/finarc_transaction_tile.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    for (final row in [
      TransactionsCompanion.insert(
        type: 'expense',
        amount: 120,
        title: 'Groceries',
        category: 'Food',
        transactionDate: DateTime(2026, 6, 1),
        paymentSourceType: 'bank',
        paymentSourceId: 1,
      ),
      TransactionsCompanion.insert(
        type: 'income',
        amount: 5000,
        title: 'Salary',
        category: 'Income',
        transactionDate: DateTime(2026, 6, 2),
        paymentSourceType: 'bank',
        paymentSourceId: 1,
      ),
      TransactionsCompanion.insert(
        type: 'expense',
        amount: 250,
        title: 'Fuel',
        category: 'Travel',
        transactionDate: DateTime(2026, 6, 3),
        paymentSourceType: 'creditCard',
        paymentSourceId: 1,
      ),
      TransactionsCompanion.insert(
        type: 'expense',
        amount: 80,
        title: 'UPI Tea',
        category: 'Food',
        transactionDate: DateTime(2026, 6, 4),
        paymentSourceType: 'upi',
        paymentSourceId: 1,
      ),
    ]) {
      await db.into(db.transactions).insert(row);
    }
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: ExpensesScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> selectQuickFilter(WidgetTester tester, String label) async {
    await tester.tap(find.byKey(const Key('expenses-quick-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  testWidgets('quick filter dropdown contains required options', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('expenses-quick-filter')));
    await tester.pumpAndSettle();

    expect(find.text('All').last, findsOneWidget);
    expect(find.text('Expenses'), findsWidgets);
    expect(find.text('Income'), findsWidgets);
    expect(find.text('Card'), findsWidgets);
    expect(find.text('UPI'), findsWidgets);
  });

  testWidgets('selecting dropdown filters updates the list', (tester) async {
    await pumpScreen(tester);

    await selectQuickFilter(tester, 'Income');
    expect(find.text('Salary'), findsOneWidget);
    expect(find.text('Groceries'), findsNothing);

    await selectQuickFilter(tester, 'Card');
    expect(find.text('Fuel'), findsOneWidget);
    expect(find.text('Salary'), findsNothing);
  });

  testWidgets('reset stays hidden by default and clears active filters', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.byKey(const Key('expenses-reset-filters')), findsNothing);

    await selectQuickFilter(tester, 'UPI');
    expect(find.byKey(const Key('expenses-reset-filters')), findsOneWidget);
    expect(find.text('UPI Tea'), findsOneWidget);
    expect(find.text('Fuel'), findsNothing);
    expect(find.byType(FinarcTransactionTile), findsOneWidget);

    await tester.tap(find.byKey(const Key('expenses-reset-filters')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('expenses-reset-filters')), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Fuel'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Fuel'), findsOneWidget);
  });

  testWidgets('empty filtered state shows only one Add Expense CTA', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'does-not-match');
    await tester.pumpAndSettle();

    expect(find.text('No transactions yet'), findsOneWidget);
    expect(find.text('Add Expense'), findsOneWidget);
    expect(find.text('Enable Notification Detection'), findsOneWidget);
  });
}
