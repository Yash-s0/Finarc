import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/features/dashboard/presentation/widgets/dashboard_sections.dart';
import 'package:finarc/shared/widgets/finarc/finarc_card.dart';

void main() {
  test('due soon label uses proper singular and plural copy', () {
    expect(dashboardDueSoonLabel(0), '0 card bills due soon');
    expect(dashboardDueSoonLabel(1), '1 card bill due soon');
    expect(dashboardDueSoonLabel(2), '2 card bills due soon');
  });

  testWidgets('alerts stack vertically on narrow widths', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: DashboardAlertsSection(
              pendingCount: 3,
              dueSoonBillsCount: 1,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cards = tester.widgetList<FinarcCard>(find.byType(FinarcCard));
    expect(cards.length, 2);

    final cardsFinder = find.byType(FinarcCard);
    final firstRect = tester.getRect(cardsFinder.at(0));
    final secondRect = tester.getRect(cardsFinder.at(1));
    expect(firstRect.left, closeTo(secondRect.left, 0.1));
    expect(secondRect.top, greaterThan(firstRect.bottom));
    expect(find.text('1 card bill due soon'), findsOneWidget);
  });

  testWidgets('alerts stay side by side on wider widths', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            child: DashboardAlertsSection(
              pendingCount: 3,
              dueSoonBillsCount: 1,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cardsFinder = find.byType(FinarcCard);
    expect(tester.widgetList<FinarcCard>(cardsFinder).length, 2);
    final firstRect = tester.getRect(cardsFinder.at(0));
    final secondRect = tester.getRect(cardsFinder.at(1));
    expect(secondRect.left, greaterThan(firstRect.left));
  });
}
