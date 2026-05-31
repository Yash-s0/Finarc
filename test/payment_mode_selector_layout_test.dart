import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/theme/app_spacing.dart';
import 'package:finarc/shared/widgets/finarc/finarc_payment_selector.dart';

void main() {
  const modes = <FinarcPaymentModeOption>[
    FinarcPaymentModeOption(
      value: 'cash',
      label: 'Cash',
      icon: Icons.payments_rounded,
    ),
    FinarcPaymentModeOption(
      value: 'upi',
      label: 'UPI',
      icon: Icons.qr_code_scanner_rounded,
    ),
    FinarcPaymentModeOption(
      value: 'card',
      label: 'Card',
      icon: Icons.credit_card_rounded,
    ),
    FinarcPaymentModeOption(
      value: 'bank',
      label: 'Bank',
      icon: Icons.account_balance_rounded,
    ),
  ];

  Future<void> pumpSelector(
    WidgetTester tester, {
    required double width,
    List<FinarcPaymentModeOption> modeOptions = modes,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              key: const Key('host'),
              width: width,
              child: FinarcPaymentSelector(
                title: 'Payment Mode',
                selectedMode: 'cash',
                modes: modeOptions,
                onModeChanged: (_) {},
                sources: const [],
                selectedSourceId: null,
                onSourceChanged: (_) {},
                compactModeTiles: true,
                modeTestPrefix: 'layout-mode',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Rect rectForMode(WidgetTester tester, String value) {
    return tester.getRect(find.byKey(Key('layout-mode-$value')));
  }

  void expectRowFill(WidgetTester tester) {
    final host = tester.getRect(find.byKey(const Key('host')));
    final cash = rectForMode(tester, 'cash');
    final upi = rectForMode(tester, 'upi');
    final card = rectForMode(tester, 'card');
    final bank = rectForMode(tester, 'bank');

    expect(cash.left, closeTo(host.left, 0.1));
    expect(bank.right, closeTo(host.right, 0.1));
    expect(cash.width, closeTo(upi.width, 0.1));
    expect(upi.width, closeTo(card.width, 0.1));
    expect(card.width, closeTo(bank.width, 0.1));
    expect(upi.left - cash.right, closeTo(AppSpacing.xs, 0.1));
    expect(card.left - upi.right, closeTo(AppSpacing.xs, 0.1));
    expect(bank.left - card.right, closeTo(AppSpacing.xs, 0.1));
  }

  testWidgets('payment modes fill row width on 360dp', (tester) async {
    await pumpSelector(tester, width: 360);
    expectRowFill(tester);
  });

  testWidgets('payment modes fill row width on 393dp', (tester) async {
    await pumpSelector(tester, width: 393);
    expectRowFill(tester);
  });

  testWidgets('payment modes fill row width on 430dp', (tester) async {
    await pumpSelector(tester, width: 430);
    expectRowFill(tester);
  });

  testWidgets('equal card widths are preserved', (tester) async {
    await pumpSelector(tester, width: 393);
    final widths = [
      rectForMode(tester, 'cash').width,
      rectForMode(tester, 'upi').width,
      rectForMode(tester, 'card').width,
      rectForMode(tester, 'bank').width,
    ];
    for (var i = 1; i < widths.length; i++) {
      expect(widths[i], closeTo(widths[0], 0.1));
    }
  });

  testWidgets('wrapping works and keeps equal sizing when modes exceed four', (
    tester,
  ) async {
    const moreModes = <FinarcPaymentModeOption>[
      ...modes,
      FinarcPaymentModeOption(
        value: 'wallet',
        label: 'Wallet',
        icon: Icons.account_balance_wallet_rounded,
      ),
    ];

    await pumpSelector(tester, width: 360, modeOptions: moreModes);

    final first = rectForMode(tester, 'cash');
    final second = rectForMode(tester, 'upi');
    final third = rectForMode(tester, 'card');
    final fourth = rectForMode(tester, 'bank');
    final fifth = rectForMode(tester, 'wallet');

    expect(first.width, closeTo(second.width, 0.1));
    expect(second.width, closeTo(third.width, 0.1));
    expect(third.width, closeTo(fourth.width, 0.1));
    expect(fourth.width, closeTo(fifth.width, 0.1));
    expect(fifth.top, greaterThan(first.bottom));
  });
}
