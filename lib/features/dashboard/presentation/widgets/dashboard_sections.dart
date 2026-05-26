import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../data/dashboard_providers.dart';

class DashboardGreetingHeader extends StatelessWidget {
  const DashboardGreetingHeader({super.key, required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final trimmed = name?.trim();
    final hasName = trimmed != null && trimmed.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasName ? 'Hello, $trimmed' : 'Welcome',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Track money confidently, offline.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class NetWorthHeroCard extends StatelessWidget {
  const NetWorthHeroCard({super.key, required this.data});

  final DashboardSnapshot data;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/dashboard/net-worth-breakdown'),
      child: FinarcBalanceCard(
        label: 'Net Worth',
        value: inr(data.netWorth),
        subtitle: 'Liquid + recoverable - dues/loans',
        statusLabel: data.netWorth >= 0 ? 'Healthy' : 'Attention',
      ),
    );
  }
}

class SetupProgressCard extends StatelessWidget {
  const SetupProgressCard({super.key, required this.data});

  final DashboardSnapshot data;

  @override
  Widget build(BuildContext context) {
    return FinarcCard(
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
          _progressRow(context, 'Credit card added', done: data.cardCount > 0),
          const SizedBox(height: AppSpacing.xs),
          _progressRow(
            context,
            'Notification detection enabled',
            done: data.notificationDetectionEnabled,
          ),
        ],
      ),
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

class DashboardMetricGrid extends StatelessWidget {
  const DashboardMetricGrid({super.key, required this.data});

  final DashboardSnapshot data;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.75,
      crossAxisSpacing: AppSpacing.xs,
      mainAxisSpacing: AppSpacing.xs,
      children: [
        FinarcMetricCard(title: 'Bank Balance', value: inr(data.bankBalance)),
        FinarcMetricCard(title: 'Card Dues', value: inr(data.cardDues)),
        FinarcMetricCard(title: 'Cash In Hand', value: inr(data.cashInHand)),
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
    );
  }
}

class PendingConfirmationsCard extends StatelessWidget {
  const PendingConfirmationsCard({super.key, required this.pendingCount});

  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    if (pendingCount <= 0) return const SizedBox.shrink();
    return FinarcCard(
      onTap: () => context.push('/pending'),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.darkPrimarySoft,
            child: Icon(Icons.notification_important_outlined, size: 18),
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
            label: '$pendingCount',
            tone: FinarcStatusTone.warning,
          ),
        ],
      ),
    );
  }
}

class DueSoonCard extends StatelessWidget {
  const DueSoonCard({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return FinarcCard(
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
              '$count card bill(s) due soon',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const FinarcStatusBadge(label: 'DUE', tone: FinarcStatusTone.warning),
        ],
      ),
    );
  }
}

class RecentTransactionsSection extends StatelessWidget {
  const RecentTransactionsSection({super.key, required this.data});

  final DashboardSnapshot data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
  }
}

class AnalyticsCtaCard extends StatelessWidget {
  const AnalyticsCtaCard({super.key, required this.monthlySpends});

  final double monthlySpends;

  @override
  Widget build(BuildContext context) {
    return FinarcCard(
      onTap: () => context.push('/analytics'),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.darkPrimarySoft,
            child: Icon(Icons.insights_outlined, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('View Reports'),
                const SizedBox(height: 2),
                Text(
                  'Monthly spend ${inr(monthlySpends)} • Open analytics dashboard',
                ),
              ],
            ),
          ),
          FinarcStatusBadge(
            label: monthlySpends > 0 ? 'TREND' : 'NEW',
            tone: monthlySpends > 0
                ? FinarcStatusTone.info
                : FinarcStatusTone.neutral,
            compact: true,
          ),
        ],
      ),
    );
  }
}

class DashboardFreshStartGate extends StatelessWidget {
  const DashboardFreshStartGate({super.key, required this.data});

  final DashboardSnapshot data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        SetupProgressCard(data: data),
        const SizedBox(height: AppSpacing.sm),
        FinarcCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FinarcSectionHeader(title: 'Next Best Actions'),
              const SizedBox(height: AppSpacing.sm),
              FinarcPrimaryButton(
                onPressed: () => context.push('/accounts/add?type=bank'),
                icon: Icons.account_balance_outlined,
                label: 'Add Bank Account',
              ),
              const SizedBox(height: AppSpacing.xs),
              FinarcSecondaryButton(
                onPressed: () => context.push('/accounts/add?type=cash'),
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
}
