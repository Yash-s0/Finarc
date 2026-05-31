import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/features/dashboard/presentation/widgets/dashboard_sections.dart';

void main() {
  Future<void> pumpHeader(
    WidgetTester tester, {
    required DateTime now,
    String? name,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardGreetingHeader(
            name: name,
            unreadAlertsCount: 0,
            now: now,
          ),
        ),
      ),
    );
  }

  testWidgets('morning greeting is shown from 05:00 to 11:59', (tester) async {
    await pumpHeader(tester, now: DateTime(2026, 6, 1, 8, 30), name: 'yash');
    expect(find.text('Good morning,'), findsOneWidget);
    expect(find.text('Yash 👋'), findsOneWidget);
  });

  testWidgets('afternoon greeting is shown from 12:00 to 16:59', (
    tester,
  ) async {
    await pumpHeader(tester, now: DateTime(2026, 6, 1, 14, 0), name: 'yash');
    expect(find.text('Good afternoon,'), findsOneWidget);
    expect(find.text('Yash 👋'), findsOneWidget);
  });

  testWidgets('evening greeting is shown from 17:00 to 20:59', (tester) async {
    await pumpHeader(tester, now: DateTime(2026, 6, 1, 19, 15), name: 'yash');
    expect(find.text('Good evening,'), findsOneWidget);
    expect(find.text('Yash 👋'), findsOneWidget);
  });

  testWidgets('night greeting is shown from 21:00 to 04:59', (tester) async {
    await pumpHeader(tester, now: DateTime(2026, 6, 1, 23, 45), name: 'yash');
    expect(find.text('Good night,'), findsOneWidget);
    expect(find.text('Yash 👋'), findsOneWidget);
  });

  testWidgets('fallback greeting uses Welcome when name is unavailable', (
    tester,
  ) async {
    await pumpHeader(tester, now: DateTime(2026, 6, 1, 8, 30), name: '   ');
    expect(find.text('Good morning,'), findsOneWidget);
    expect(find.text('Welcome 👋'), findsOneWidget);
  });

  testWidgets('name is trimmed and capitalized and not duplicated in line 1', (
    tester,
  ) async {
    await pumpHeader(
      tester,
      now: DateTime(2026, 6, 1, 8, 30),
      name: '   yash   sharma ',
    );
    expect(find.text('Good morning,'), findsOneWidget);
    expect(find.text('Yash Sharma 👋'), findsOneWidget);
    expect(find.textContaining('Good morning, Yash'), findsNothing);
  });
}
