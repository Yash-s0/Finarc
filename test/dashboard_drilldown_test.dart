import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/features/dashboard/data/dashboard_providers.dart';
import 'package:finarc/features/dashboard/presentation/widgets/dashboard_sections.dart';

void main() {
  DashboardSnapshot buildSnapshot() {
    return DashboardSnapshot(
      netWorth: 0,
      bankBalance: 1000,
      cardDues: 200,
      cardOutstanding: 200,
      cashInHand: 300,
      monthlySpends: 400,
      pendingCount: 0,
      loansOutstanding: 500,
      recoverableAmount: 600,
      splitReceivableAmount: 0,
      splitPayableAmount: 0,
      recentTransactions: <Transaction>[],
      dueSoonBillsCount: 0,
      bankAccountCount: 1,
      cashWalletCount: 1,
      cardCount: 1,
      notificationDetectionEnabled: true,
      totalAssets: 1000,
      totalLiabilities: 700,
      payableAmount: 0,
      debtRatio: 0.7,
      monthlyEmiBurden: 0,
      unreadAlertsCount: 0,
      latestImportantAlert: null,
    );
  }

  testWidgets('dashboard metric cards open drilldown routes', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              Scaffold(body: DashboardMetricGrid(data: buildSnapshot())),
        ),
        GoRoute(
          path: '/accounts',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('accounts-page'))),
        ),
        GoRoute(
          path: '/cards',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('cards-page'))),
        ),
        GoRoute(
          path: '/analytics',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('analytics-page'))),
        ),
        GoRoute(
          path: '/loans',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('loans-page'))),
        ),
        GoRoute(
          path: '/recoverables',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('recoverables-page'))),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Recoverable Amount'));
    await tester.pumpAndSettle();
    expect(find.text('recoverables-page'), findsOneWidget);

    router.go('/');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Monthly Spends'));
    await tester.pumpAndSettle();
    expect(find.text('analytics-page'), findsOneWidget);
  });
}
