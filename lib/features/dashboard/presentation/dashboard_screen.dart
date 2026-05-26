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

            if (freshInstall) {
              return ListView(
                padding: _pagePadding(context),
                children: [DashboardFreshStartGate(data: data)],
              );
            }

            return ListView(
              padding: _pagePadding(context),
              children: [
                DashboardGreetingHeader(name: profile?.name),
                const SizedBox(height: AppSpacing.sm),
                FinarcCard(
                  onTap: () => context.push('/alerts'),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.darkPrimarySoft,
                        child: Icon(Icons.notifications_none_rounded, size: 18),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('View Alerts'),
                            const SizedBox(height: 2),
                            Text(
                              data.latestImportantAlert?.body ??
                                  'Open alerts center to review reminders and warnings.',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      FinarcStatusBadge(
                        label: data.unreadAlertsCount > 0
                            ? '${data.unreadAlertsCount} NEW'
                            : 'NO NEW',
                        tone: data.unreadAlertsCount > 0
                            ? FinarcStatusTone.warning
                            : FinarcStatusTone.neutral,
                        compact: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                NetWorthHeroCard(data: data),
                if (profile?.salaryCreditDay != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  FinarcCard(
                    child: Text(_salaryInsight(profile!.salaryCreditDay!)),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                DashboardMetricGrid(data: data),
                const SizedBox(height: AppSpacing.sm),
                FinarcCard(
                  onTap: () => context.push('/loans'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FinarcSectionHeader(
                        title: 'Liabilities',
                        trailing: FinarcStatusBadge(
                          label:
                              'Debt ratio ${(data.debtRatio * 100).toStringAsFixed(1)}%',
                          tone: data.debtRatio >= 0.6
                              ? FinarcStatusTone.error
                              : (data.debtRatio >= 0.3
                                    ? FinarcStatusTone.warning
                                    : FinarcStatusTone.success),
                          compact: true,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Liabilities',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  inr(data.totalLiabilities),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          if (data.monthlyEmiBurden > 0)
                            FinarcStatusBadge(
                              label: 'EMI ${inr(data.monthlyEmiBurden)}',
                              tone: FinarcStatusTone.info,
                              compact: true,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Tap to manage loans and EMI payments',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                PendingConfirmationsCard(pendingCount: data.pendingCount),
                if (data.pendingCount > 0)
                  const SizedBox(height: AppSpacing.xs),
                DueSoonCard(count: data.dueSoonBillsCount),
                if (data.dueSoonBillsCount > 0)
                  const SizedBox(height: AppSpacing.xs),
                if (data.splitReceivableAmount != 0 ||
                    data.splitPayableAmount != 0) ...[
                  FinarcCard(
                    onTap: () => context.push('/split'),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.darkPrimarySoft,
                          child: Icon(Icons.call_split_outlined, size: 18),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Split Balance'),
                              const SizedBox(height: 2),
                              Text(
                                'Owed ${inr(data.splitReceivableAmount)} • Owe ${inr(data.splitPayableAmount)}',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
                FinarcCard(
                  onTap: () => context.push('/accounts'),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.darkPrimarySoft,
                        child: Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Accounts Overview'),
                            const SizedBox(height: 2),
                            Text(
                              'Bank ${inr(data.bankBalance)} • Cash ${inr(data.cashInHand)}',
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.push('/accounts/transfer'),
                        icon: const Icon(Icons.swap_horiz),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                AnalyticsCtaCard(monthlySpends: data.monthlySpends),
                const SizedBox(height: AppSpacing.lg),
                RecentTransactionsSection(data: data),
              ],
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
