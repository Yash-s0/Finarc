import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../onboarding/data/onboarding_providers.dart';
import '../../profile/data/profile_settings_providers.dart';
import '../data/dashboard_providers.dart';
import 'widgets/dashboard_sections.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  EdgeInsets _pagePadding(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.md + topInset,
      AppSpacing.md,
      AppSpacing.md,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.watch(onboardingCompletedProvider);
    final profile = ref.watch(userProfileSettingsProvider).valueOrNull;
    return onboardingState.when(
      loading: () => ListView(
        padding: _pagePadding(context),
        children: const [
          FinarcLoadingSkeleton(height: 36, width: 180),
          SizedBox(height: AppSpacing.md),
          FinarcLoadingSkeleton(height: 144),
        ],
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (completed) {
        if (!completed) {
          return ListView(
            padding: _pagePadding(context),
            children: [
              Text(
                'Welcome to Finarc',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Complete setup to start tracking finances. Old values are hidden until setup is complete.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              const FinarcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FinarcSectionHeader(title: 'Fresh Start'),
                    SizedBox(height: AppSpacing.sm),
                    Text('Onboarding is pending.'),
                    SizedBox(height: AppSpacing.xxs),
                    Text('No financial metrics are shown in this state.'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FinarcPrimaryButton(
                onPressed: () => context.go('/onboarding'),
                icon: Icons.flag_outlined,
                label: 'Continue Setup',
              ),
            ],
          );
        }

        final state = ref.watch(dashboardProvider);
        return state.when(
          loading: () => ListView(
            padding: _pagePadding(context),
            children: const [
              FinarcLoadingSkeleton(height: 36, width: 180),
              SizedBox(height: AppSpacing.xs),
              FinarcLoadingSkeleton(height: 16, width: 240),
              SizedBox(height: AppSpacing.md),
              FinarcLoadingSkeleton(height: 156),
              SizedBox(height: AppSpacing.md),
              FinarcLoadingSkeleton(height: 100),
            ],
          ),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (data) {
            final freshInstall =
                data.bankAccountCount == 0 &&
                data.cashWalletCount == 0 &&
                data.cardCount == 0 &&
                data.loansOutstanding == 0 &&
                data.recentTransactions.isEmpty;
            final salaryCreditDay = profile?.salaryCreditDay;

            if (freshInstall) {
              return RefreshIndicator(
                onRefresh: () => ref.read(dashboardRefreshActionsProvider)(),
                child: ListView(
                  padding: _pagePadding(context),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [DashboardFreshStartGate(data: data)],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => ref.read(dashboardRefreshActionsProvider)(),
              child: ListView(
                padding: _pagePadding(context),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  DashboardGreetingHeader(
                    name: profile?.name,
                    unreadAlertsCount: data.unreadAlertsCount,
                    onAlertsTap: () => context.push('/alerts'),
                    onSettingsTap: () => context.push('/profile'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  NetWorthHeroCard(data: data),
                  if (salaryCreditDay != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    FinarcCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.event_available_rounded,
                            color: AppColors.darkMint,
                            size: 14,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              _salaryInsight(salaryCreditDay),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  DashboardMetricGrid(data: data),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      if (data.pendingCount > 0)
                        Expanded(
                          child: PendingConfirmationsCard(
                            pendingCount: data.pendingCount,
                          ),
                        ),
                      if (data.pendingCount > 0 && data.dueSoonBillsCount > 0)
                        const SizedBox(width: AppSpacing.xs),
                      if (data.dueSoonBillsCount > 0)
                        Expanded(
                          child: DueSoonCard(count: data.dueSoonBillsCount),
                        ),
                    ],
                  ),
                  if (data.pendingCount > 0 || data.dueSoonBillsCount > 0)
                    const SizedBox(height: AppSpacing.sm),
                  FinarcCard(
                    onTap: () => context.push('/accounts'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.darkPrimarySoft,
                          child: Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 14,
                            color: AppColors.darkBlue,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            'Bank ${inr(data.bankBalance)} • Cash ${inr(data.cashInHand)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, size: 16),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  RecentTransactionsSection(data: data),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _salaryInsight(int salaryCreditDay) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var expected = DateTime(now.year, now.month, salaryCreditDay);
    if (salaryCreditDay > 28) {
      final monthEnd = DateTime(now.year, now.month + 1, 0).day;
      expected = DateTime(
        now.year,
        now.month,
        salaryCreditDay.clamp(1, monthEnd),
      );
    }
    if (expected.isBefore(today)) {
      final nextMonthEnd = DateTime(now.year, now.month + 2, 0).day;
      expected = DateTime(
        now.year,
        now.month + 1,
        salaryCreditDay.clamp(1, nextMonthEnd),
      );
    }
    final days = expected.difference(today).inDays;
    if (days <= 0) return 'Salary expected today';
    if (days == 1) return 'Salary expected in 1 day';
    return 'Salary expected in $days days';
  }
}
