import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/features/dashboard/data/dashboard_providers.dart';
import 'package:finarc/features/dashboard/presentation/widgets/dashboard_sections.dart';
import 'package:finarc/shared/widgets/finarc/finarc_metric_card.dart';

void main() {
  const snapshot = DashboardSnapshot(
    netWorth: 0,
    bankBalance: 157893.18,
    cardDues: 17435,
    cardOutstanding: 0,
    cashInHand: 0,
    monthlySpends: 3879.59,
    pendingCount: 0,
    loansOutstanding: 80000,
    recoverableAmount: 15538,
    splitReceivableAmount: 0,
    splitPayableAmount: 0,
    recentTransactions: [],
    dueSoonBillsCount: 0,
    bankAccountCount: 1,
    cashWalletCount: 1,
    cardCount: 1,
    notificationDetectionEnabled: true,
    totalAssets: 0,
    totalLiabilities: 0,
    payableAmount: 0,
    debtRatio: 0,
    monthlyEmiBurden: 0,
    unreadAlertsCount: 0,
    latestImportantAlert: null,
  );

  testWidgets('metric grid stays two-column on normal phone width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: DashboardMetricGrid(data: snapshot),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cards = find.byType(FinarcMetricCard);
    expect(cards, findsNWidgets(6));

    final firstRect = tester.getRect(cards.at(0));
    final secondRect = tester.getRect(cards.at(1));
    final thirdRect = tester.getRect(cards.at(2));

    expect(secondRect.left, greaterThan(firstRect.left));
    expect((firstRect.top - secondRect.top).abs(), lessThan(1));
    expect(thirdRect.top, greaterThan(firstRect.bottom));
  });

  testWidgets('metric grid does not add automatic top scroll padding', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          padding: EdgeInsets.only(top: 32, bottom: 16),
        ),
        child: const MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 320,
                child: DashboardMetricGrid(data: snapshot),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cards = find.byType(FinarcMetricCard);
    final gridTop = tester.getTopLeft(find.byType(DashboardMetricGrid)).dy;
    final firstCardTop = tester.getTopLeft(cards.first).dy;

    expect(firstCardTop - gridTop, lessThanOrEqualTo(1));
  });

  testWidgets('metric cards preserve decimal amounts', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: DashboardMetricGrid(data: snapshot),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final values = tester
        .widgetList<FinarcMetricCard>(find.byType(FinarcMetricCard))
        .map((widget) => widget.value)
        .toList(growable: false);

    expect(values, contains('₹1,57,893.18'));
    expect(values, contains('₹17,435.00'));
    expect(values, contains('₹3,879.59'));
  });
}
