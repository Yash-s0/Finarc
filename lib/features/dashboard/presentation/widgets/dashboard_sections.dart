import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../data/dashboard_providers.dart';

class DashboardGreetingHeader extends StatelessWidget {
  const DashboardGreetingHeader({
    super.key,
    required this.name,
    required this.unreadAlertsCount,
    this.onAlertsTap,
    this.onSettingsTap,
  });

  final String? name;
  final int unreadAlertsCount;
  final VoidCallback? onAlertsTap;
  final VoidCallback? onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final trimmed = name?.trim();
    final hasName = trimmed != null && trimmed.isNotEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasName ? 'Good morning, $trimmed' : 'Good morning',
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                hasName ? '$trimmed 👋' : 'Welcome 👋',
                style: Theme.of(context).textTheme.headlineSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _headerAction(
          context,
          icon: Icons.notifications_none_rounded,
          onTap: onAlertsTap,
          badge: unreadAlertsCount > 0 ? unreadAlertsCount.toString() : null,
        ),
        const SizedBox(width: AppSpacing.xs),
        _headerAction(context, icon: Icons.tune_rounded, onTap: onSettingsTap),
      ],
    );
  }

  Widget _headerAction(
    BuildContext context, {
    required IconData icon,
    VoidCallback? onTap,
    String? badge,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceHigh,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Icon(
              icon,
              size: 17,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        if (badge != null)
          Positioned(
            right: -3,
            top: -3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.darkError,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badge,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  letterSpacing: 0,
                ),
              ),
            ),
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
        subtitle:
            'Assets ${inr(data.totalAssets)} • Liabilities ${inr(data.totalLiabilities)}',
        trendLabel: 'Monthly spends ${inr(data.monthlySpends)}',
        statusLabel: data.netWorth >= 0 ? 'On track' : 'Needs attention',
        isHero: true,
        leading: const CircleAvatar(
          radius: 13,
          backgroundColor: AppColors.darkPrimarySoft,
          child: Icon(
            Icons.insights_rounded,
            size: 14,
            color: AppColors.darkAccent,
          ),
        ),
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
      childAspectRatio: 1.9,
      crossAxisSpacing: AppSpacing.xs,
      mainAxisSpacing: AppSpacing.xs,
      children: [
        FinarcMetricCard(
          title: 'Bank Balance',
          value: inr(data.bankBalance),
          icon: Icons.account_balance_rounded,
          iconColor: AppColors.darkMint,
          iconBackgroundColor: AppColors.darkMint.withValues(alpha: 0.14),
          onTap: () => context.push('/accounts'),
        ),
        FinarcMetricCard(
          title: 'Card Dues',
          value: inr(data.cardDues),
          icon: Icons.credit_card_rounded,
          iconColor: AppColors.darkError,
          iconBackgroundColor: AppColors.darkError.withValues(alpha: 0.14),
          onTap: () => context.push('/cards'),
        ),
        FinarcMetricCard(
          title: 'Cash In Hand',
          value: inr(data.cashInHand),
          icon: Icons.wallet_rounded,
          iconColor: AppColors.darkWarning,
          iconBackgroundColor: AppColors.darkWarning.withValues(alpha: 0.14),
          onTap: () => context.push('/accounts'),
        ),
        FinarcMetricCard(
          title: 'Loans',
          value: inr(data.loansOutstanding),
          icon: Icons.account_balance_wallet_outlined,
          iconColor: AppColors.darkOrange,
          iconBackgroundColor: AppColors.darkOrange.withValues(alpha: 0.14),
          onTap: () => context.push('/loans'),
        ),
        FinarcMetricCard(
          title: 'Recoverable Amount',
          value: inr(data.recoverableAmount),
          icon: Icons.call_received_rounded,
          iconColor: AppColors.darkBlue,
          iconBackgroundColor: AppColors.darkBlue.withValues(alpha: 0.14),
          onTap: () => context.push('/recoverables'),
        ),
        FinarcMetricCard(
          title: 'Monthly Spends',
          value: inr(data.monthlySpends),
          icon: Icons.calendar_month_rounded,
          iconColor: AppColors.darkPink,
          iconBackgroundColor: AppColors.darkPink.withValues(alpha: 0.14),
          onTap: () => context.push('/analytics'),
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
    final items = data.recentTransactions;
    return FinarcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FinarcSectionHeader(
            title: 'Recent Transactions',
            trailing: TextButton(
              onPressed: () => context.push('/expenses'),
              child: const Text('See all'),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: 320,
            child: items.isEmpty
                ? const FinarcEmptyState(
                    title: 'No transactions yet',
                    subtitle: 'Add your first expense from quick actions.',
                  )
                : Scrollbar(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.xs),
                      itemBuilder: (context, index) {
                        final t = items[index];
                        final isIncome =
                            t.type == 'income' || t.type == 'refund';
                        final tone = isIncome
                            ? FinarcStatusTone.success
                            : (t.paymentSourceType == 'creditCard'
                                  ? FinarcStatusTone.warning
                                  : FinarcStatusTone.info);
                        return FinarcTransactionTile(
                          title: t.title,
                          subtitle: t.category,
                          meta: transactionDateLabel(t.transactionDate),
                          prefix: CircleAvatar(
                            radius: 15,
                            backgroundColor: _avatarColor(t.category),
                            child: Icon(
                              _categoryIcon(t.category),
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                          amount: '${isIncome ? '+' : '-'}${inr(t.amount)}',
                          amountColor: isIncome
                              ? AppColors.darkSuccess
                              : AppColors.darkError,
                          statusLabel: isIncome
                              ? 'Income'
                              : (t.paymentSourceType == 'creditCard'
                                    ? 'Unbilled'
                                    : 'Spent'),
                          statusTone: tone,
                          compact: true,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  static Color _avatarColor(String category) {
    final key = category.trim().toLowerCase();
    if (key.contains('food')) return AppColors.darkOrange;
    if (key.contains('travel')) return AppColors.darkBlue;
    if (key.contains('bill')) return AppColors.darkAccent;
    if (key.contains('shop')) return AppColors.darkPink;
    return AppColors.darkMint;
  }

  static IconData _categoryIcon(String category) {
    final key = category.trim().toLowerCase();
    if (key.contains('food')) return Icons.restaurant_rounded;
    if (key.contains('travel')) return Icons.flight_takeoff_rounded;
    if (key.contains('bill')) return Icons.receipt_long_rounded;
    if (key.contains('shop')) return Icons.shopping_bag_rounded;
    return Icons.paid_rounded;
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
