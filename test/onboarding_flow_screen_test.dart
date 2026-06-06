import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/config/app_mode.dart';
import 'package:finarc/features/onboarding/presentation/onboarding_flow_screen.dart';

void main() {
  tearDown(() {
    AppModeConfig.debugOverride = null;
  });

  Future<void> pumpOnboarding(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: OnboardingFlowScreen())),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('onboarding stays overflow-free on a small viewport', (
    tester,
  ) async {
    AppModeConfig.debugOverride = AppMode.safeDebug;
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpOnboarding(tester);

    expect(find.text('Welcome to Finarc'), findsOneWidget);
    expect(find.text('Expenses'), findsOneWidget);
    expect(tester.takeException(), isNull);

    for (final title in [
      'Privacy-first by design',
      'Set up your first account',
      'Optional detection setup',
      'Your name',
    ]) {
      await tester.drag(find.byType(PageView), const Offset(-360, 0));
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('release onboarding does not expose SMS setup CTA', (
    tester,
  ) async {
    AppModeConfig.debugOverride = AppMode.release;

    await pumpOnboarding(tester);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Optional detection setup'), findsOneWidget);
    expect(find.text('Notification Setup'), findsOneWidget);
    expect(find.text('SMS Setup'), findsNothing);
    expect(find.text('SMS setup unavailable in this build'), findsOneWidget);
  });
}
