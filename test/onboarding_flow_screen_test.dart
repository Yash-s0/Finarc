import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:finarc/core/config/app_mode.dart';
import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/core/database/database_providers.dart';
import 'package:finarc/core/theme/app_colors.dart';
import 'package:finarc/core/theme/app_theme.dart';
import 'package:finarc/features/onboarding/presentation/onboarding_flow_screen.dart';
import 'package:finarc/features/pending/notifications/notification_permission_service.dart';

class _FakeNotificationPermissionService extends NotificationPermissionService {
  _FakeNotificationPermissionService({this.isGranted = true});

  bool isGranted;
  bool permissionRequestResult = true;
  int requestCount = 0;

  @override
  Future<bool> isPostNotificationsGranted() async => isGranted;

  @override
  Future<bool> requestPostNotificationsPermission() async {
    requestCount += 1;
    isGranted = permissionRequestResult;
    return permissionRequestResult;
  }
}

void main() {
  tearDown(() {
    AppModeConfig.debugOverride = null;
  });

  Future<void> pumpOnboarding(
    WidgetTester tester, {
    _FakeNotificationPermissionService? permissionService,
  }) async {
    final service = permissionService ?? _FakeNotificationPermissionService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingNotificationPermissionServiceProvider.overrideWithValue(
            service,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const OnboardingFlowScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<AppDatabase> pumpRoutedOnboarding(
    WidgetTester tester, {
    _FakeNotificationPermissionService? permissionService,
  }) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final service = permissionService ?? _FakeNotificationPermissionService();

    final router = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingFlowScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Home'))),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          onboardingNotificationPermissionServiceProvider.overrideWithValue(
            service,
          ),
        ],
        child: MaterialApp.router(theme: AppTheme.dark(), routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    return db;
  }

  Future<void> tapNext(WidgetTester tester) async {
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
  }

  Future<void> advanceToProfileStep(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tapNext(tester);
    }
  }

  testWidgets('onboarding stays overflow-free on a small viewport', (
    tester,
  ) async {
    AppModeConfig.debugOverride = AppMode.safeDebug;
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpOnboarding(tester);

    expect(find.text('Welcome to Finarc'), findsOneWidget);
    expect(find.text('Privacy-first'), findsOneWidget);
    expect(tester.takeException(), isNull);

    for (final title in [
      'Set up your first account',
      'Optional detection setup',
      'Tell us about you',
      'You’re ready to track smarter',
    ]) {
      await tapNext(tester);
      expect(find.text(title), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('release onboarding does not expose SMS setup CTA', (
    tester,
  ) async {
    AppModeConfig.debugOverride = AppMode.release;

    await pumpOnboarding(tester);

    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Optional detection setup'), findsOneWidget);
    expect(find.text('Notification Setup'), findsOneWidget);
    expect(find.text('SMS Setup'), findsNothing);
    expect(find.text('SMS setup unavailable in this build'), findsOneWidget);
  });

  testWidgets('skip name moves to summary and completes with empty profile', (
    tester,
  ) async {
    final db = await pumpRoutedOnboarding(tester);

    await advanceToProfileStep(tester);
    expect(find.text('Tell us about you'), findsOneWidget);

    await tester.tap(find.text('Skip name for now'));
    await tester.pumpAndSettle();
    expect(find.text('You’re ready to track smarter'), findsOneWidget);

    await tester.tap(find.text('Finish Setup'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);

    final row = await db.select(db.appSettings).getSingle();
    expect(row.hasCompletedOnboarding, true);
    expect(row.userName, isNull);
    expect(row.monthlySalary, isNull);
  });

  testWidgets('onboarding can complete without name or salary', (tester) async {
    final db = await pumpRoutedOnboarding(tester);

    await advanceToProfileStep(tester);
    await tapNext(tester);
    expect(find.text('You’re ready to track smarter'), findsOneWidget);

    await tester.tap(find.text('Finish Setup'));
    await tester.pumpAndSettle();

    final row = await db.select(db.appSettings).getSingle();
    expect(row.hasCompletedOnboarding, true);
    expect(row.userName, isNull);
    expect(row.monthlySalary, isNull);
    expect(row.salaryCreditDay, isNull);
  });

  testWidgets('expandable feature tile opens and shows details', (
    tester,
  ) async {
    await pumpOnboarding(tester);

    const detail =
        'Your data stays on your device, no account is required, and there is no cloud sync in v1.';
    expect(find.text(detail), findsNothing);

    await tester.tap(find.text('Privacy-first'));
    await tester.pumpAndSettle();

    expect(find.text(detail), findsOneWidget);
  });

  testWidgets('expandable feature tile collapses cleanly', (tester) async {
    await pumpOnboarding(tester);

    const detail =
        'Your data stays on your device, no account is required, and there is no cloud sync in v1.';

    await tester.tap(find.text('Privacy-first'));
    await tester.pumpAndSettle();
    expect(find.text(detail), findsOneWidget);

    await tester.tap(find.text('Privacy-first'));
    await tester.pumpAndSettle();
    expect(find.text(detail), findsNothing);
  });

  testWidgets('opening another feature tile collapses the first', (
    tester,
  ) async {
    await pumpOnboarding(tester);

    const privacyDetail =
        'Your data stays on your device, no account is required, and there is no cloud sync in v1.';
    const offlineDetail =
        'The app is built around local storage. Notification detection is optional, and detected transactions require confirmation before entering your ledger.';

    await tester.tap(find.text('Privacy-first'));
    await tester.pumpAndSettle();
    expect(find.text(privacyDetail), findsOneWidget);

    await tester.tap(find.text('Offline-first'));
    await tester.pumpAndSettle();
    expect(find.text(privacyDetail), findsNothing);
    expect(find.text(offlineDetail), findsOneWidget);
  });

  testWidgets('final onboarding action completes onboarding', (tester) async {
    final db = await pumpRoutedOnboarding(tester);

    for (var i = 0; i < 4; i++) {
      await tapNext(tester);
    }

    expect(find.text('You’re ready to track smarter'), findsOneWidget);
    await tester.tap(find.text('Finish Setup'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    final row = await db.select(db.appSettings).getSingle();
    expect(row.hasCompletedOnboarding, true);
  });

  testWidgets('onboarding prompts for app notifications and allows skip', (
    tester,
  ) async {
    final permissionService = _FakeNotificationPermissionService(
      isGranted: false,
    );

    await pumpOnboarding(tester, permissionService: permissionService);

    expect(find.text('Allow Finarc notifications?'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);
    expect(find.text('Allow'), findsOneWidget);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(find.text('Allow Finarc notifications?'), findsNothing);
    expect(permissionService.requestCount, 0);
  });

  testWidgets('onboarding can request app notification permission', (
    tester,
  ) async {
    final permissionService = _FakeNotificationPermissionService(
      isGranted: false,
    );

    await pumpOnboarding(tester, permissionService: permissionService);
    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();

    expect(permissionService.requestCount, 1);
  });

  testWidgets('light theme onboarding hero uses light gradient tokens', (
    tester,
  ) async {
    AppModeConfig.debugOverride = AppMode.safeDebug;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const OnboardingFlowScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final heroDecorations = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((widget) => widget.decoration)
        .whereType<BoxDecoration>()
        .where((decoration) => decoration.gradient is LinearGradient);

    expect(
      heroDecorations.any((decoration) {
        final gradient = decoration.gradient! as LinearGradient;
        return gradient.colors.contains(AppColors.lightHeroGradientStart) &&
            gradient.colors.contains(AppColors.lightHeroGradientEnd);
      }),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
}
