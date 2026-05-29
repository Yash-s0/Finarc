import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/features/dashboard/data/dashboard_providers.dart';
import 'package:finarc/features/dashboard/presentation/dashboard_screen.dart';
import 'package:finarc/features/onboarding/data/onboarding_providers.dart';
import 'package:finarc/features/profile/data/profile_settings_service.dart';
import 'package:finarc/features/profile/data/profile_settings_providers.dart';

void main() {
  DashboardSnapshot buildSnapshot() {
    return DashboardSnapshot(
      netWorth: 0,
      bankBalance: 1000,
      cardDues: 200,
      cardOutstanding: 400,
      cashInHand: 300,
      monthlySpends: 400,
      pendingCount: 1,
      loansOutstanding: 500,
      recoverableAmount: 600,
      splitReceivableAmount: 0,
      splitPayableAmount: 0,
      recentTransactions: const <Transaction>[],
      dueSoonBillsCount: 1,
      bankAccountCount: 1,
      cashWalletCount: 0,
      cardCount: 1,
      notificationDetectionEnabled: true,
      totalAssets: 1000,
      totalLiabilities: 700,
      payableAmount: 0,
      debtRatio: 0.7,
      monthlyEmiBurden: 0,
      unreadAlertsCount: 2,
      latestImportantAlert: null,
    );
  }

  testWidgets('dashboard pull to refresh triggers aggregate refresh', (
    tester,
  ) async {
    var refreshCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingCompletedProvider.overrideWith((ref) async => true),
          userProfileSettingsProvider.overrideWith(
            (ref) async => const UserProfileSettings(name: 'Yash'),
          ),
          dashboardProvider.overrideWith((ref) async => buildSnapshot()),
          dashboardRefreshActionsProvider.overrideWith(
            (ref) => () async {
              refreshCount += 1;
            },
          ),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).first, const Offset(0, 320));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(refreshCount, 1);
  });
}
