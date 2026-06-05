import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/features/dashboard/data/dashboard_providers.dart';
import 'package:finarc/features/dashboard/presentation/widgets/dashboard_sections.dart';
import 'package:finarc/shared/widgets/finarc/finarc_transaction_tile.dart';

void main() {
  testWidgets('recent transactions section is bounded and scrollable', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    for (var i = 0; i < 5; i += 1) {
      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              type: 'bank',
              amount: 100 + i * 10,
              title: 'Txn $i',
              category: 'Food',
              transactionDate: DateTime(2026, 5, 24 - i),
              paymentSourceType: 'bank',
              paymentSourceId: 1,
            ),
          );
    }

    final txns = await db.select(db.transactions).get();
    final snapshot = DashboardSnapshot(
      netWorth: 0,
      bankBalance: 0,
      cardDues: 0,
      cardOutstanding: 0,
      cashInHand: 0,
      monthlySpends: 0,
      pendingCount: 0,
      loansOutstanding: 0,
      recoverableAmount: 0,
      splitReceivableAmount: 0,
      splitPayableAmount: 0,
      recentTransactions: txns,
      dueSoonBillsCount: 0,
      bankAccountCount: 0,
      cashWalletCount: 0,
      cardCount: 0,
      notificationDetectionEnabled: true,
      totalAssets: 0,
      totalLiabilities: 0,
      payableAmount: 0,
      debtRatio: 0,
      monthlyEmiBurden: 0,
      unreadAlertsCount: 0,
      latestImportantAlert: null,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RecentTransactionsSection(data: snapshot),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Scrollbar), findsOneWidget);
    expect(
      tester
          .widgetList<SizedBox>(find.byType(SizedBox))
          .any((box) => box.height == 320),
      isTrue,
    );
  });

  testWidgets('recent transactions list does not add automatic top padding', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            type: 'creditCard',
            amount: 400,
            title: 'amazon',
            category: 'Groceries',
            transactionDate: DateTime(2026, 5, 29),
            paymentSourceType: 'creditCard',
            paymentSourceId: 1,
          ),
        );

    final txns = await db.select(db.transactions).get();
    final snapshot = DashboardSnapshot(
      netWorth: 0,
      bankBalance: 0,
      cardDues: 0,
      cardOutstanding: 0,
      cashInHand: 0,
      monthlySpends: 0,
      pendingCount: 0,
      loansOutstanding: 0,
      recoverableAmount: 0,
      splitReceivableAmount: 0,
      splitPayableAmount: 0,
      recentTransactions: txns,
      dueSoonBillsCount: 0,
      bankAccountCount: 0,
      cashWalletCount: 0,
      cardCount: 0,
      notificationDetectionEnabled: true,
      totalAssets: 0,
      totalLiabilities: 0,
      payableAmount: 0,
      debtRatio: 0,
      monthlyEmiBurden: 0,
      unreadAlertsCount: 0,
      latestImportantAlert: null,
    );

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          padding: EdgeInsets.only(top: 32, bottom: 16),
        ),
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RecentTransactionsSection(data: snapshot),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final listTop = tester.getTopLeft(find.byType(ListView)).dy;
    final tileTop = tester.getTopLeft(find.byType(FinarcTransactionTile)).dy;

    expect(tileTop - listTop, lessThanOrEqualTo(1));
  });

  testWidgets('recent transactions section does not reserve max height for empty state', (
    tester,
  ) async {
    final snapshot = const DashboardSnapshot(
      netWorth: 0,
      bankBalance: 0,
      cardDues: 0,
      cardOutstanding: 0,
      cashInHand: 0,
      monthlySpends: 0,
      pendingCount: 0,
      loansOutstanding: 0,
      recoverableAmount: 0,
      splitReceivableAmount: 0,
      splitPayableAmount: 0,
      recentTransactions: [],
      dueSoonBillsCount: 0,
      bankAccountCount: 0,
      cashWalletCount: 0,
      cardCount: 0,
      notificationDetectionEnabled: true,
      totalAssets: 0,
      totalLiabilities: 0,
      payableAmount: 0,
      debtRatio: 0,
      monthlyEmiBurden: 0,
      unreadAlertsCount: 0,
      latestImportantAlert: null,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RecentTransactionsSection(data: snapshot),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No transactions yet'), findsOneWidget);
    expect(
      tester
          .widgetList<SizedBox>(find.byType(SizedBox))
          .any((box) => box.height == 164),
      isTrue,
    );
    expect(
      tester
          .widgetList<SizedBox>(find.byType(SizedBox))
          .any((box) => box.height == 320),
      isFalse,
    );
  });
}
