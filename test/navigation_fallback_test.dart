import 'package:finarc/features/accounts/presentation/account_detail_screen.dart';
import 'package:finarc/features/cards/presentation/bill_detail_screen.dart';
import 'package:finarc/features/cards/presentation/card_detail_screen.dart';
import 'package:finarc/features/split/presentation/split_group_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return ProviderScope(child: MaterialApp(home: child));
}

void main() {
  testWidgets('card detail invalid route fallback renders', (tester) async {
    await tester.pumpWidget(_wrap(const CardDetailScreen(cardId: 0)));

    expect(find.text('Invalid card route'), findsOneWidget);
    expect(find.text('Back to Cards'), findsOneWidget);
  });

  testWidgets('bill detail invalid route fallback renders', (tester) async {
    await tester.pumpWidget(
      _wrap(const BillDetailScreen(cardId: 0, billId: 0)),
    );

    expect(find.text('Invalid bill route'), findsOneWidget);
    expect(find.text('Back to Cards'), findsOneWidget);
  });

  testWidgets('account detail invalid route fallback renders', (tester) async {
    await tester.pumpWidget(
      _wrap(const AccountDetailScreen(type: 'bank', id: 0)),
    );

    expect(find.text('Invalid account route'), findsOneWidget);
    expect(find.text('Back to Accounts'), findsOneWidget);
  });

  testWidgets('split group invalid route fallback renders', (tester) async {
    await tester.pumpWidget(_wrap(const SplitGroupDetailScreen(groupId: 0)));

    expect(find.text('Invalid split group route'), findsOneWidget);
    expect(find.text('Back to Split'), findsOneWidget);
  });
}
