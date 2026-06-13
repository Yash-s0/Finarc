import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/core/database/database_providers.dart';
import 'package:finarc/features/cards/presentation/cards_overview_screen.dart';
import 'package:finarc/features/dashboard/presentation/dashboard_screen.dart';
import 'package:finarc/features/expenses/presentation/expenses_screen.dart';
import 'package:finarc/features/split/presentation/split_screen.dart';
import 'package:finarc/shared/widgets/finarc/finarc_empty_state.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpScreen(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('dashboard shows onboarding gate when onboarding is incomplete', (
    tester,
  ) async {
    await pumpScreen(tester, const DashboardScreen());
    expect(find.text('Welcome to Finarc'), findsOneWidget);
    expect(find.text('Continue Setup'), findsOneWidget);
    expect(find.text('Net Worth'), findsNothing);
  });

  testWidgets('dashboard does not show numbers when onboarding incomplete', (
    tester,
  ) async {
    await db
        .into(db.bankAccounts)
        .insert(
          BankAccountsCompanion.insert(
            bankName: 'Legacy',
            accountName: 'Old Account',
            accountType: 'savings',
            currentBalance: const Value(50000),
          ),
        );
    await db
        .into(db.creditCards)
        .insert(
          CreditCardsCompanion.insert(
            bankName: 'Legacy Card',
            nickname: 'Old',
            last4: '1234',
            maskedNumber: '**** **** **** 1234',
            creditLimit: 100000,
            billingDay: 5,
            dueDay: 20,
            currentOutstanding: const Value(25000),
          ),
        );
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            type: 'creditCard',
            amount: 10,
            title: 'Legacy txn',
            category: 'General',
            transactionDate: DateTime.now(),
            paymentSourceType: 'creditCard',
            paymentSourceId: 1,
          ),
        );

    await db
        .into(db.appSettings)
        .insert(
          AppSettingsCompanion.insert(
            isDarkMode: const Value(true),
            hasCompletedOnboarding: const Value(false),
          ),
        );

    await pumpScreen(tester, const DashboardScreen());
    expect(find.text('Continue Setup'), findsOneWidget);
    expect(find.text('Net Worth'), findsNothing);
    expect(find.textContaining('₹'), findsNothing);
  });

  testWidgets('cards empty state works', (tester) async {
    await pumpScreen(tester, const CardsOverviewScreen());
    expect(find.text('No cards added yet'), findsOneWidget);
    expect(find.text('Add Card'), findsOneWidget);
  });

  testWidgets('expenses empty state works', (tester) async {
    await pumpScreen(tester, const ExpensesScreen());
    expect(find.text('No transactions yet'), findsOneWidget);
    expect(find.text('Add Expense'), findsOneWidget);
  });

  testWidgets('split empty state works', (tester) async {
    await pumpScreen(tester, const SplitScreen());
    expect(find.text('No groups yet'), findsOneWidget);
    expect(find.text('Create Group'), findsOneWidget);
  });

  testWidgets('finarc empty state renders primary and secondary actions', (
    tester,
  ) async {
    var primaryTapped = 0;
    var secondaryTapped = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FinarcEmptyState(
            title: 'Nothing here',
            subtitle: 'Add an item to continue.',
            actionLabel: 'Primary',
            secondaryActionLabel: 'Secondary',
            onAction: () => primaryTapped += 1,
            onSecondaryAction: () => secondaryTapped += 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Primary'), findsOneWidget);
    expect(find.text('Secondary'), findsOneWidget);

    await tester.tap(find.text('Primary'));
    await tester.tap(find.text('Secondary'));
    await tester.pumpAndSettle();

    expect(primaryTapped, 1);
    expect(secondaryTapped, 1);
  });
}
