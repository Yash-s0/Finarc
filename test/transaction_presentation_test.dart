import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/shared/widgets/finarc/finarc_status_badge.dart';
import 'package:finarc/shared/widgets/finarc/finarc_transaction_presentation.dart';
import 'package:finarc/shared/widgets/finarc/finarc_transaction_tile.dart';

void main() {
  testWidgets('billed and unbilled badges render with consistent labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              FinarcTransactionPresentation.billedBadge(billed: true),
              FinarcTransactionPresentation.billedBadge(billed: false),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Billed'), findsOneWidget);
    expect(find.text('Unbilled'), findsOneWidget);
  });

  testWidgets('recoverable status badges render unpaid partial recovered', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              FinarcTransactionPresentation.recoverableStatusBadge('unpaid'),
              FinarcTransactionPresentation.recoverableStatusBadge('partial'),
              FinarcTransactionPresentation.recoverableStatusBadge('recovered'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Unpaid'), findsOneWidget);
    expect(find.text('Partial'), findsOneWidget);
    expect(find.text('Recovered'), findsOneWidget);
  });

  testWidgets('pending status badges render pending ignored duplicate', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              FinarcTransactionPresentation.pendingStatusBadge('pending'),
              FinarcTransactionPresentation.pendingStatusBadge('ignored'),
              FinarcTransactionPresentation.pendingStatusBadge('duplicate'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Ignored'), findsOneWidget);
    expect(find.text('Duplicate'), findsOneWidget);
  });

  testWidgets('transaction tile renders date-source meta and badges', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FinarcTransactionTile(
            title: 'Swiggy',
            subtitle: 'Food',
            date: DateTime(2026, 5, 28, 19, 42),
            source: 'Card',
            amount: '₹450',
            badges: const [
              FinarcStatusBadge(
                label: 'Cashback',
                tone: FinarcStatusTone.success,
                compact: true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Swiggy'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.textContaining('Card'), findsOneWidget);
    expect(find.text('₹450'), findsOneWidget);
    expect(find.text('Cashback'), findsOneWidget);
  });
}
