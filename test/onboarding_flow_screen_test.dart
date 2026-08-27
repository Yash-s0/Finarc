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
import 'package:finarc/features/pending/notifications/notification_providers.dart';

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
    List<Override> overrides = const [],
  }) async {
    final service = permissionService ?? _FakeNotificationPermissionService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingNotificationPermissionServiceProvider.overrideWithValue(
            service,
          ),
          notificationIngestionAvailableProvider.overrideWith(
            (ref) async => true,
          ),
          smsIngestionAvailableProvider.overrideWith((ref) async => true),
          ...overrides,
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
        GoRoute(
          path: '/expenses/add',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Add Expense'))),
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
          notificationIngestionAvailableProvider.overrideWith(
            (ref) async => true,
          ),
          smsIngestionAvailableProvider.overrideWith((ref) async => true),
        ],
        child: MaterialApp.router(theme: AppTheme.dark(), routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    return db;
  }

  Future<void> tapNext(WidgetTester tester) async {
    await tester.tap(find.text('Next').hitTestable());
    await tester.pumpAndSettle();
    if (find.text('Skip detection setup?').evaluate().isNotEmpty) {
      await tester.tap(find.text('Skip for now').hitTestable());
      await tester.pumpAndSettle();
    }
    if (find.text('Skip profile details?').evaluate().isNotEmpty) {
      await tester.tap(find.text('Continue empty').hitTestable());
      await tester.pumpAndSettle();
    }
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

    expect(find.text('Your data, your device'), findsOneWidget);
    expect(find.text('Stored locally'), findsOneWidget);
    expect(tester.takeException(), isNull);

    for (final title in [
      'Add your first account',
      'Detect transactions automatically',
      'Personalize your insights',
      "You're ready to go!",
    ]) {
      await tapNext(tester);
      expect(find.text(title), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('release onboarding exposes SMS setup CTA', (tester) async {
    AppModeConfig.debugOverride = AppMode.release;

    await pumpOnboarding(tester);

    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Detect transactions automatically'), findsOneWidget);
    expect(find.text('App notifications'), findsOneWidget);
    expect(find.text('Set up'), findsWidgets);
    expect(
      find.text('Detect payment notifications in the background.'),
      findsOneWidget,
    );
    expect(find.text('SMS setup unavailable in this build'), findsNothing);
  });

  testWidgets('optional detection skip explains it can be enabled later', (
    tester,
  ) async {
    await pumpOnboarding(tester);

    await tapNext(tester);
    await tapNext(tester);
    await tester.tap(find.text('Next').hitTestable());
    await tester.pumpAndSettle();

    expect(find.text('Skip detection setup?'), findsOneWidget);
    expect(
      find.text(
        'You can enable SMS or notification detection later from Profile. Manual entries still work.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Go back'));
    await tester.pumpAndSettle();
    expect(find.text('Detect transactions automatically'), findsOneWidget);
  });

  testWidgets('privacy tour popup opens and closes from onboarding', (
    tester,
  ) async {
    await pumpOnboarding(tester);

    await tester.tap(find.text('Stored locally'));
    await tester.pumpAndSettle();

    expect(find.text('How privacy works'), findsOneWidget);
    expect(find.text('Stored on this device'), findsOneWidget);
    expect(find.text('Pending before saved'), findsOneWidget);
    expect(find.text('Backups are manual'), findsOneWidget);

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    expect(find.text('How privacy works'), findsNothing);
  });

  testWidgets('empty profile prompt moves to summary and completes', (
    tester,
  ) async {
    final db = await pumpRoutedOnboarding(tester);

    await advanceToProfileStep(tester);
    expect(find.text('Personalize your insights'), findsOneWidget);

    await tapNext(tester);
    expect(find.text("You're ready to go!"), findsOneWidget);

    await tester.tap(find.text('Start using Finarc'));
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
    expect(find.text("You're ready to go!"), findsOneWidget);
    expect(find.text('Go to Dashboard'), findsNothing);
    expect(find.text('Add first expense'), findsOneWidget);
    expect(find.text('Skip setup'), findsNothing);

    await tester.tap(find.text('Start using Finarc'));
    await tester.pumpAndSettle();

    final row = await db.select(db.appSettings).getSingle();
    expect(row.hasCompletedOnboarding, true);
    expect(row.userName, isNull);
    expect(row.monthlySalary, isNull);
    expect(row.salaryCreditDay, isNull);
    expect(row.salaryCreditRule, isNull);
  });

  testWidgets('profile salary credit picker saves semantic last day', (
    tester,
  ) async {
    final db = await pumpRoutedOnboarding(tester);

    await advanceToProfileStep(tester);
    await tester.tap(find.text('Select day (1 - 31)'));
    await tester.pumpAndSettle();

    expect(find.text('Salary credit day'), findsWidgets);
    expect(find.text('First day of month'), findsOneWidget);
    expect(find.text('Last day of month'), findsOneWidget);
    expect(find.text('31'), findsOneWidget);

    await tester.tap(find.text('Last day of month'));
    await tester.pumpAndSettle();

    expect(find.text('Last day of month'), findsOneWidget);

    await tapNext(tester);
    expect(find.text("You're ready to go!"), findsOneWidget);

    await tester.tap(find.text('Start using Finarc'));
    await tester.pumpAndSettle();

    final row = await db.select(db.appSettings).getSingle();
    expect(row.salaryCreditDay, isNull);
    expect(row.salaryCreditRule, 'lastDayOfMonth');
  });

  testWidgets('profile keyboard next moves through optional fields', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpOnboarding(tester);
    await advanceToProfileStep(tester);

    await tester.tap(find.widgetWithText(TextFormField, 'e.g. Yash Sharma'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'e.g. Yash Sharma'),
      'Yash',
    );
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    tester.testTextInput.enterText('120000');
    await tester.pump();

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    final fieldValues = tester
        .widgetList<EditableText>(find.byType(EditableText))
        .map((field) => field.controller.text)
        .toList(growable: false);

    expect(fieldValues, containsAllInOrder(['Yash', '120000']));
    expect(find.text('Select day (1 - 31)'), findsOneWidget);
  });

  testWidgets('privacy points are visible without extra expansion cards', (
    tester,
  ) async {
    await pumpOnboarding(tester);

    expect(find.text('Stored locally'), findsOneWidget);
    expect(
      find.text('Detected items are reviewed before saving.'),
      findsOneWidget,
    );
    expect(
      find.text('Track your finances without an internet connection.'),
      findsOneWidget,
    );
  });

  testWidgets('privacy tour point stays tappable', (tester) async {
    await pumpOnboarding(tester);

    await tester.tap(find.text('Stored locally'));
    await tester.pumpAndSettle();

    expect(find.text('How privacy works'), findsOneWidget);
  });

  testWidgets('first step stays compact after removing extra cards', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpOnboarding(tester);

    expect(find.text('Stored locally'), findsOneWidget);
    expect(find.byType(Card), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('final onboarding action completes onboarding', (tester) async {
    final db = await pumpRoutedOnboarding(tester);

    for (var i = 0; i < 4; i++) {
      await tapNext(tester);
    }

    expect(find.text("You're ready to go!"), findsOneWidget);
    expect(find.text('Go to Dashboard'), findsNothing);
    expect(find.text('Add first expense'), findsOneWidget);
    expect(find.text('Skip setup'), findsNothing);
    await tester.tap(find.text('Start using Finarc'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    final row = await db.select(db.appSettings).getSingle();
    expect(row.hasCompletedOnboarding, true);
  });

  testWidgets('rapid final taps persist a single completed settings row', (
    tester,
  ) async {
    final db = await pumpRoutedOnboarding(tester);

    for (var i = 0; i < 4; i++) {
      await tapNext(tester);
    }

    await tester.tap(find.text('Start using Finarc'));
    await tester.tap(find.text('Start using Finarc'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    final rows = await db.select(db.appSettings).get();
    expect(rows, hasLength(1));
    expect(rows.single.hasCompletedOnboarding, true);
  });

  testWidgets('add first expense completes onboarding before routing', (
    tester,
  ) async {
    final db = await pumpRoutedOnboarding(tester);

    for (var i = 0; i < 4; i++) {
      await tapNext(tester);
    }

    await tester.tap(find.text('Add first expense'));
    await tester.tap(find.text('Add first expense'));
    await tester.pumpAndSettle();

    expect(find.text('Add Expense'), findsOneWidget);
    final row = await db.select(db.appSettings).getSingle();
    expect(row.hasCompletedOnboarding, true);
  });

  testWidgets('global skip setup confirms and completes empty setup', (
    tester,
  ) async {
    final db = await pumpRoutedOnboarding(tester);

    await tester.tap(find.text('Skip setup'));
    await tester.pumpAndSettle();
    expect(find.text('Skip setup?'), findsOneWidget);

    await tester.tap(find.text('Skip setup').last);
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    final row = await db.select(db.appSettings).getSingle();
    expect(row.hasCompletedOnboarding, true);
    expect(row.userName, isNull);
    expect(row.monthlySalary, isNull);
  });

  testWidgets('detection step reflects enabled permission state', (
    tester,
  ) async {
    await pumpOnboarding(
      tester,
      overrides: [
        notificationAccessStatusProvider.overrideWith((ref) async => true),
        smsPermissionStatusProvider.overrideWith((ref) async => true),
      ],
    );

    await tapNext(tester);
    await tapNext(tester);

    expect(find.text('Detect transactions automatically'), findsOneWidget);
    expect(find.text('Enabled'), findsWidgets);
    expect(find.text('Manage settings'), findsWidgets);
  });

  testWidgets('detection step disables unavailable setup actions', (
    tester,
  ) async {
    await pumpOnboarding(
      tester,
      overrides: [
        notificationIngestionAvailableProvider.overrideWith(
          (ref) async => false,
        ),
        smsIngestionAvailableProvider.overrideWith((ref) async => false),
        notificationAccessStatusProvider.overrideWith((ref) async => true),
        smsPermissionStatusProvider.overrideWith((ref) async => true),
      ],
    );

    await tapNext(tester);
    await tapNext(tester);

    expect(find.text('Unavailable'), findsWidgets);
    expect(find.text('Enabled'), findsNothing);
    final unavailableButtons = tester
        .widgetList<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Unavailable'),
        )
        .toList(growable: false);
    expect(unavailableButtons, hasLength(2));
    expect(
      unavailableButtons.every((button) => button.onPressed == null),
      true,
    );
  });

  testWidgets(
    'detection availability refreshes after returning from settings',
    (tester) async {
      var notificationAvailable = false;
      var smsAvailable = false;

      await pumpOnboarding(
        tester,
        overrides: [
          notificationIngestionAvailableProvider.overrideWith(
            (ref) async => notificationAvailable,
          ),
          smsIngestionAvailableProvider.overrideWith(
            (ref) async => smsAvailable,
          ),
          notificationAccessStatusProvider.overrideWith((ref) async => false),
          smsPermissionStatusProvider.overrideWith((ref) async => false),
        ],
      );

      await tapNext(tester);
      await tapNext(tester);
      expect(find.text('Unavailable'), findsWidgets);

      notificationAvailable = true;
      smsAvailable = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(find.text('Set up'), findsWidgets);
      expect(find.text('Unavailable'), findsNothing);
    },
  );

  testWidgets('large text onboarding stays overflow-free', (tester) async {
    tester.binding.platformDispatcher.textScaleFactorTestValue = 1.45;
    await tester.binding.setSurfaceSize(const Size(360, 700));
    addTearDown(() {
      tester.binding.platformDispatcher.clearTextScaleFactorTestValue();
      tester.binding.setSurfaceSize(null);
    });

    await pumpOnboarding(tester);

    for (var i = 0; i < 4; i++) {
      expect(tester.takeException(), isNull);
      await tapNext(tester);
    }
    expect(find.text("You're ready to go!"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid optional profile values block only until corrected', (
    tester,
  ) async {
    await pumpOnboarding(tester);
    await advanceToProfileStep(tester);

    await tester.enterText(find.widgetWithText(TextFormField, '₹ 0'), '-10');
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Monthly salary must be positive.'), findsOneWidget);
    expect(find.text('Personalize your insights'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, '₹ 0'), '');
    await tapNext(tester);
    expect(find.text("You're ready to go!"), findsOneWidget);
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
    expect(find.text('Allow notifications'), findsOneWidget);

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
    await tester.tap(find.text('Allow notifications'));
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
