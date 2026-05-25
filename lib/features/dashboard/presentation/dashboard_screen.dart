import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../onboarding/data/onboarding_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../data/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.watch(onboardingCompletedProvider);
    return onboardingState.when(
      loading: () => ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
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
            padding: const EdgeInsets.all(AppSpacing.md),
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
            padding: const EdgeInsets.all(AppSpacing.md),
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
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  Text(
                    'Welcome to Finarc',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Start by adding your first bank account or credit card.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FinarcCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FinarcSectionHeader(title: 'Setup Progress'),
                        const SizedBox(height: AppSpacing.sm),
                        _progressRow(
                          context,
                          'Bank account added',
                          done: data.bankAccountCount > 0,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _progressRow(
                          context,
                          'Cash wallet added',
                          done: data.cashWalletCount > 0,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _progressRow(
                          context,
                          'Credit card added',
                          done: data.cardCount > 0,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _progressRow(
                          context,
                          'Notification detection enabled',
                          done: data.notificationDetectionEnabled,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FinarcCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FinarcSectionHeader(title: 'Next Best Actions'),
                        const SizedBox(height: AppSpacing.sm),
                        FinarcPrimaryButton(
                          onPressed: () =>
                              context.push('/accounts/add?type=bank'),
                          icon: Icons.account_balance_outlined,
                          label: 'Add Bank Account',
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        FinarcSecondaryButton(
                          onPressed: () =>
                              context.push('/accounts/add?type=cash'),
                          icon: Icons.account_balance_wallet_outlined,
                          label: 'Add Cash Wallet',
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        FinarcSecondaryButton(
                          onPressed: () => context.push('/cards/add'),
                          icon: Icons.credit_card_outlined,
                          label: 'Add Card',
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        FinarcSecondaryButton(
                          onPressed: () => context.push('/expenses/add'),
                          icon: Icons.add_circle_outline,
                          label: 'Add Expense',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const FinarcCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.darkPrimarySoft,
                          child: Icon(Icons.offline_bolt_rounded, size: 18),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Offline-first and local-only. No cloud sync. Data stays on this device.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text(
                  'Hello, Yash',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Track money confidently, offline.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                FinarcBalanceCard(
                  label: 'Net Worth',
                  value: inr(data.netWorth),
                  subtitle: 'Liquid + recoverable - dues/loans',
                  statusLabel: data.netWorth >= 0 ? 'Healthy' : 'Attention',
                ),
                const SizedBox(height: AppSpacing.md),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.75,
                  crossAxisSpacing: AppSpacing.xs,
                  mainAxisSpacing: AppSpacing.xs,
                  children: [
                    FinarcMetricCard(
                      title: 'Bank Balance',
                      value: inr(data.bankBalance),
                    ),
                    FinarcMetricCard(
                      title: 'Card Dues',
                      value: inr(data.cardDues),
                    ),
                    FinarcMetricCard(
                      title: 'Cash In Hand',
                      value: inr(data.cashInHand),
                    ),
                    FinarcMetricCard(
                      title: 'Monthly Spends',
                      value: inr(data.monthlySpends),
                    ),
                    FinarcMetricCard(
                      title: 'Loans Outstanding',
                      value: inr(data.loansOutstanding),
                    ),
                    FinarcMetricCard(
                      title: 'Recoverable Amount',
                      value: inr(data.recoverableAmount),
                    ),
                  ],
                ),
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
                if (data.pendingCount > 0) ...[
                  FinarcCard(
                    onTap: () => context.push('/pending'),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.darkPrimarySoft,
                          child: Icon(
                            Icons.notification_important_outlined,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pending Confirmations'),
                              SizedBox(height: 2),
                              Text(
                                'Detected spends waiting for your confirmation',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        FinarcStatusBadge(
                          label: '${data.pendingCount}',
                          tone: FinarcStatusTone.warning,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
                if (data.dueSoonBillsCount > 0) ...[
                  FinarcCard(
                    onTap: () => context.push('/cards'),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.darkPrimarySoft,
                          child: Icon(Icons.event_busy_outlined, size: 18),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            '${data.dueSoonBillsCount} card bill(s) due soon',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        const FinarcStatusBadge(
                          label: 'DUE',
                          tone: FinarcStatusTone.warning,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
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
                const SizedBox(height: AppSpacing.lg),
                const FinarcSectionHeader(title: 'Recent Transactions'),
                const SizedBox(height: AppSpacing.xs),
                if (data.recentTransactions.isEmpty)
                  const FinarcEmptyState(
                    title: 'No transactions yet',
                    subtitle: 'Add your first expense from quick actions.',
                  )
                else
                  ...data.recentTransactions.map(
                    (t) => FinarcTransactionTile(
                      title: t.title,
                      subtitle: t.category,
                      prefix: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.darkPrimarySoft,
                        child: Text(
                          t.category[0].toUpperCase(),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                      amount:
                          '${t.type == 'income' || t.type == 'refund' ? '+' : '-'}${inr(t.amount)}',
                      amountColor: t.type == 'income' || t.type == 'refund'
                          ? AppColors.darkSuccess
                          : AppColors.darkError,
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  static Widget _progressRow(
    BuildContext context,
    String label, {
    required bool done,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        FinarcStatusBadge(
          label: done ? 'YES' : 'NO',
          tone: done ? FinarcStatusTone.success : FinarcStatusTone.neutral,
          compact: true,
        ),
      ],
    );
  }
}
