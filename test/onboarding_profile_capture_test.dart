import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/config/app_info_provider.dart';
import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/core/database/database_providers.dart';
import 'package:finarc/features/dashboard/data/dashboard_providers.dart';
import 'package:finarc/features/dashboard/presentation/dashboard_screen.dart';
import 'package:finarc/features/dashboard/presentation/widgets/dashboard_sections.dart';
import 'package:finarc/features/onboarding/data/onboarding_providers.dart';
import 'package:finarc/features/onboarding/data/onboarding_service.dart';
import 'package:finarc/features/pending/notifications/notification_providers.dart';
import 'package:finarc/features/profile/data/profile_settings_service.dart';
import 'package:finarc/features/profile/data/profile_settings_providers.dart';
import 'package:finarc/features/profile/presentation/profile_screen.dart';
import 'package:finarc/features/profile/presentation/profile_screen_safe.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('onboarding saves name', () async {
    final service = OnboardingService(db);

    await service.setCompleted(true, userName: 'Yash');

    final row = await db.select(db.appSettings).getSingle();
    expect(row.hasCompletedOnboarding, true);
    expect(row.userName, 'Yash');
  });

  test('onboarding saves salary/company/day', () async {
    final service = OnboardingService(db);

    await service.setCompleted(
      true,
      userName: 'Yash',
      monthlySalary: 78000,
      salaryCreditDay: 7,
      companyName: 'Finarc Labs',
    );

    final row = await db.select(db.appSettings).getSingle();
    expect(row.monthlySalary, 78000);
    expect(row.salaryCreditDay, 7);
    expect(row.companyName, 'Finarc Labs');
  });

  test('skip optional fields works in onboarding', () async {
    final service = OnboardingService(db);

    await service.setCompleted(true, userName: 'Yash');

    final row = await db.select(db.appSettings).getSingle();
    expect(row.userName, 'Yash');
    expect(row.monthlySalary, isNull);
    expect(row.salaryCreditDay, isNull);
    expect(row.companyName, isNull);
  });

  test('onboarding blocks invalid salary day', () async {
    final service = OnboardingService(db);

    expect(
      () => service.setCompleted(true, userName: 'Yash', salaryCreditDay: 40),
      throwsArgumentError,
    );
  });

  test('onboarding blocks non-positive salary', () async {
    final service = OnboardingService(db);

    expect(
      () => service.setCompleted(true, userName: 'Yash', monthlySalary: 0),
      throwsArgumentError,
    );
  });

  test('onboarding keeps single settings row and removes duplicates', () async {
    final service = OnboardingService(db);

    await db
        .into(db.appSettings)
        .insert(
          AppSettingsCompanion.insert(
            isDarkMode: const Value(true),
            hasCompletedOnboarding: const Value(false),
          ),
        );
    await db
        .into(db.appSettings)
        .insert(
          AppSettingsCompanion.insert(
            isDarkMode: const Value(false),
            hasCompletedOnboarding: const Value(false),
          ),
        );

    await service.setCompleted(true, userName: 'Yash Sharma');

    final rows = await db.select(db.appSettings).get();
    expect(rows.length, 1);
    expect(rows.first.userName, 'Yash Sharma');
  });

  test('profile edit updates name', () async {
    final service = ProfileSettingsService(db);

    await service.save(const UserProfileSettings(name: 'Alex'));
    await service.save(const UserProfileSettings(name: 'Alex Sharma'));

    final loaded = await service.load();
    expect(loaded.name, 'Alex Sharma');
  });

  test('invalid salary day is blocked in profile save', () async {
    final service = ProfileSettingsService(db);

    expect(
      () => service.save(
        const UserProfileSettings(name: 'Alex', salaryCreditDay: 40),
      ),
      throwsArgumentError,
    );
  });

  test(
    'profile save keeps single settings row and removes duplicates',
    () async {
      final service = ProfileSettingsService(db);

      await db
          .into(db.appSettings)
          .insert(
            AppSettingsCompanion.insert(
              isDarkMode: const Value(true),
              hasCompletedOnboarding: const Value(false),
            ),
          );
      await db
          .into(db.appSettings)
          .insert(
            AppSettingsCompanion.insert(
              isDarkMode: const Value(false),
              hasCompletedOnboarding: const Value(false),
            ),
          );

      await service.save(
        const UserProfileSettings(
          name: 'Alex',
          monthlySalary: 50000,
          salaryCreditDay: 10,
          companyName: 'Acme',
        ),
      );

      final rows = await db.select(db.appSettings).get();
      expect(rows.length, 1);
      expect(rows.first.userName, 'Alex');
    },
  );

  testWidgets('dashboard greeting uses saved name', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardGreetingHeader(
            name: 'Yash',
            unreadAlertsCount: 0,
            now: DateTime(2026, 5, 31, 8, 30),
          ),
        ),
      ),
    );

    expect(find.text('Good morning,'), findsOneWidget);
    expect(find.text('Yash 👋'), findsOneWidget);
    expect(find.textContaining('Good morning, Yash'), findsNothing);
  });

  testWidgets('profile section is visible at top of profile screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          onboardingCompletedProvider.overrideWith((ref) async => true),
          userProfileSettingsProvider.overrideWith(
            (ref) async => const UserProfileSettings(
              name: 'Yash',
              monthlySalary: 50000,
              salaryCreditDay: 7,
              companyName: 'Finarc Labs',
            ),
          ),
          appVersionProvider.overrideWith((ref) async => '1.0.0'),
          notificationAccessStatusProvider.overrideWith((ref) async => true),
          smsPermissionStatusProvider.overrideWith((ref) async => false),
          notificationIngestionAvailableProvider.overrideWith(
            (ref) async => true,
          ),
          smsIngestionAvailableProvider.overrideWith((ref) async => false),
          postNotificationsPermissionProvider.overrideWith((ref) async => true),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Profile & Salary'), findsOneWidget);
    expect(find.text('App Runtime'), findsNothing);
  });

  testWidgets('edit salary updates dashboard salary insight visibility', (
    tester,
  ) async {
    final settings = ProfileSettingsService(db);
    await OnboardingService(db).setCompleted(true, userName: 'Yash');

    DashboardSnapshot buildSnapshot() {
      return const DashboardSnapshot(
        netWorth: 0,
        bankBalance: 1000,
        cardDues: 0,
        cardOutstanding: 0,
        cashInHand: 0,
        monthlySpends: 0,
        pendingCount: 0,
        loansOutstanding: 0,
        recoverableAmount: 0,
        splitReceivableAmount: 0,
        splitPayableAmount: 0,
        recentTransactions: <Transaction>[],
        dueSoonBillsCount: 0,
        bankAccountCount: 1,
        cashWalletCount: 0,
        cardCount: 0,
        notificationDetectionEnabled: true,
        totalAssets: 0,
        totalLiabilities: 0,
        payableAmount: 0,
        debtRatio: 0,
        monthlyEmiBurden: 0,
        unreadAlertsCount: 0,
        latestImportantAlert: null,
      );
    }

    await settings.save(const UserProfileSettings(name: 'Yash'));

    Future<void> pumpDashboard(Key scopeKey) async {
      await tester.pumpWidget(
        ProviderScope(
          key: scopeKey,
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            onboardingCompletedProvider.overrideWith((ref) async => true),
            dashboardProvider.overrideWith((ref) async => buildSnapshot()),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpDashboard(const ValueKey('without-salary-day'));
    expect(find.textContaining('Salary expected'), findsNothing);

    await settings.save(
      const UserProfileSettings(name: 'Yash', salaryCreditDay: 12),
    );
    await pumpDashboard(const ValueKey('with-salary-day'));
    expect(find.textContaining('Salary expected'), findsOneWidget);
  });

  testWidgets(
    'existing onboarded user with missing fields sees profile card placeholders',
    (tester) async {
      await OnboardingService(db).setCompleted(true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            appVersionProvider.overrideWith((ref) async => '1.0.0'),
          ],
          child: const MaterialApp(home: ProfileScreenSafe()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Profile & Salary'), findsOneWidget);
      expect(find.text('Name: Add your name'), findsOneWidget);
      expect(find.text('Company: Add company'), findsOneWidget);
      expect(find.text('Monthly salary: Add salary'), findsOneWidget);
      expect(find.text('Salary credit day: Add salary day'), findsOneWidget);
    },
  );

  testWidgets('profile edit from safe screen saves and updates card', (
    tester,
  ) async {
    await OnboardingService(db).setCompleted(true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          appVersionProvider.overrideWith((ref) async => '1.0.0'),
        ],
        child: const MaterialApp(home: ProfileScreenSafe()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Asha');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Monthly Salary'),
      '75000',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Salary Credit Day'),
      '7',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Company Name'),
      'Acme Corp',
    );
    await tester.tap(find.text('Save Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Name: Asha'), findsOneWidget);
    expect(find.text('Company: Acme Corp'), findsOneWidget);
    expect(find.text('Monthly salary: ₹75,000.00'), findsOneWidget);
    expect(find.text('Salary credit day: 7'), findsOneWidget);
  });

  testWidgets('clearing name falls back dashboard greeting to Welcome', (
    tester,
  ) async {
    final settings = ProfileSettingsService(db);
    await OnboardingService(db).setCompleted(true, userName: 'Yash');
    await settings.save(const UserProfileSettings(name: 'Yash'));
    await settings.save(const UserProfileSettings(name: ''));

    DashboardSnapshot buildSnapshot() {
      return const DashboardSnapshot(
        netWorth: 0,
        bankBalance: 1000,
        cardDues: 0,
        cardOutstanding: 0,
        cashInHand: 0,
        monthlySpends: 0,
        pendingCount: 0,
        loansOutstanding: 0,
        recoverableAmount: 0,
        splitReceivableAmount: 0,
        splitPayableAmount: 0,
        recentTransactions: <Transaction>[],
        dueSoonBillsCount: 0,
        bankAccountCount: 1,
        cashWalletCount: 0,
        cardCount: 0,
        notificationDetectionEnabled: true,
        totalAssets: 0,
        totalLiabilities: 0,
        payableAmount: 0,
        debtRatio: 0,
        monthlyEmiBurden: 0,
        unreadAlertsCount: 0,
        latestImportantAlert: null,
      );
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          onboardingCompletedProvider.overrideWith((ref) async => true),
          dashboardProvider.overrideWith((ref) async => buildSnapshot()),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            const <String>{
              'Good morning,',
              'Good afternoon,',
              'Good evening,',
              'Good night,',
            }.contains(widget.data),
      ),
      findsOneWidget,
    );
    expect(find.text('Welcome 👋'), findsOneWidget);
    expect(find.textContaining('Good morning, Yash'), findsNothing);
  });
}
