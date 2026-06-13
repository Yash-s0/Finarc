import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../data/analytics_models.dart';
import '../data/analytics_providers.dart';
import 'widgets/analytics_charts.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(analyticsPeriodProvider);
    final customRange = ref.watch(analyticsCustomRangeProvider);
    final state = ref.watch(analyticsSnapshotProvider);

    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Reports & Analytics'),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(analyticsSnapshotProvider);
          await ref.read(analyticsSnapshotProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              'Track trends from your local data only.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AnalyticsPeriod.values
                  .map((item) {
                    final isSelected = period == item;
                    return FinarcActionChip(
                      label: analyticsPeriodLabel(item),
                      selected: isSelected,
                      onTap: () async {
                        if (item == AnalyticsPeriod.custom) {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020, 1, 1),
                            lastDate: DateTime(2100, 12, 31),
                            initialDateRange: customRange,
                          );
                          if (picked == null) return;
                          ref
                                  .read(analyticsCustomRangeProvider.notifier)
                                  .state =
                              picked;
                        }
                        ref.read(analyticsPeriodProvider.notifier).state = item;
                      },
                    );
                  })
                  .toList(growable: false),
            ),
            const SizedBox(height: AppSpacing.sm),
            state.when(
              loading: () => const Column(
                children: [
                  FinarcLoadingSkeletonGroup(items: 3, itemHeight: 156),
                ],
              ),
              error: (e, _) => FinarcEmptyState(
                title: 'Unable to load analytics',
                subtitle: '$e',
                icon: Icons.error_outline,
              ),
              data: (data) {
                if (!data.hasAnyData) {
                  return FinarcEmptyState(
                    title: 'Not enough data for reports',
                    subtitle:
                        'Add transactions, cards or loans to unlock analytics trends.',
                    icon: Icons.insights_outlined,
                  );
                }

                return Column(
                  children: [
                    _overviewSection(context, data),
                    const SizedBox(height: AppSpacing.sm),
                    _spendingSection(context, data),
                    const SizedBox(height: AppSpacing.sm),
                    _incomeSection(context, data),
                    const SizedBox(height: AppSpacing.sm),
                    _cardsSection(context, data),
                    const SizedBox(height: AppSpacing.sm),
                    _loansSection(context, data),
                    const SizedBox(height: AppSpacing.sm),
                    _splitSection(context, data),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _overviewSection(BuildContext context, AnalyticsSnapshot data) {
    final monthPoints = data.monthlyTrend
        .map((x) => TrendPoint(label: x.label, value: x.spend))
        .toList(growable: false);

    return FinarcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FinarcSectionHeader(
            title: 'Overview • ${data.range.label}',
            trailing: FinarcStatusBadge(
              label: 'Local Only',
              tone: FinarcStatusTone.info,
              compact: true,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _metric(
                  context,
                  'Spending',
                  inr(data.spending.totalSpending),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _metric(context, 'Income', inr(data.income.totalIncome)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: _metric(
                  context,
                  'Loan Burden',
                  inr(data.loans.monthlyEmiBurden),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _metric(
                  context,
                  'Split Net',
                  inr(data.splits.totalRecoverable - data.splits.totalPayable),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Spending Trend', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          FinarcLineChart(points: monthPoints, color: AppColors.darkAccent),
        ],
      ),
    );
  }

  Widget _spendingSection(BuildContext context, AnalyticsSnapshot data) {
    final spending = data.spending;
    return FinarcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FinarcSectionHeader(title: 'Spending Analytics'),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _metric(
                  context,
                  'Total Spending',
                  inr(spending.totalSpending),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _metric(
                  context,
                  'Avg Daily',
                  inr(spending.avgDailySpend),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: _metric(
                  context,
                  'Highest Category',
                  spending.highestCategory?.name ?? '-',
                  valueIsAmount: false,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _metric(
                  context,
                  'Highest Merchant',
                  spending.highestMerchant?.name ?? '-',
                  valueIsAmount: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FinarcDonutChart(
                items: spending.categoryBreakdown
                    .take(6)
                    .toList(growable: false),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top Categories',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ...spending.topCategories
                        .take(4)
                        .map(
                          (c) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    c.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(inr(c.amount)),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Top Merchants', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          FinarcBarChart(
            items: spending.topMerchants,
            color: AppColors.darkSuccess,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Payment Mode Split',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          FinarcBarChart(
            items: spending.paymentModeSplit,
            color: AppColors.darkAccent,
          ),
          if (spending.recurringMerchants.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Recurring Merchants',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            ...spending.recurringMerchants
                .take(4)
                .map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${m.name} • ${m.count} txns • ${inr(m.amount)}',
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Widget _incomeSection(BuildContext context, AnalyticsSnapshot data) {
    final income = data.income;
    return FinarcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FinarcSectionHeader(title: 'Income vs Expenses'),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _metric(context, 'Income', inr(income.totalIncome)),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _metric(context, 'Expenses', inr(income.totalExpense)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          _metric(
            context,
            'Net Flow',
            inr(income.netFlow),
            valueColor: income.netFlow >= 0
                ? AppColors.darkSuccess
                : AppColors.darkError,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Income Trend', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          FinarcLineChart(
            points: income.incomeTrend,
            color: AppColors.darkSuccess,
          ),
        ],
      ),
    );
  }

  Widget _cardsSection(BuildContext context, AnalyticsSnapshot data) {
    final cards = data.cards;
    return FinarcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FinarcSectionHeader(title: 'Card Analytics'),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _metric(
                  context,
                  'Utilization',
                  '${(cards.totalUtilization * 100).toStringAsFixed(1)}%',
                  valueIsAmount: false,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _metric(
                  context,
                  'Highest Spend Card',
                  cards.highestSpendCard == null
                      ? '-'
                      : '${cards.highestSpendCard!.cardName} • ${cards.highestSpendCard!.last4}',
                  valueIsAmount: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: _metric(
                  context,
                  'Billed',
                  inr(cards.billSummary.billedTotal),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _metric(
                  context,
                  'Pending',
                  inr(cards.billSummary.pendingTotal),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              FinarcStatusBadge(
                label: 'Paid bills ${cards.billSummary.paidCount}',
                tone: FinarcStatusTone.success,
                compact: true,
              ),
              const SizedBox(width: AppSpacing.xs),
              FinarcStatusBadge(
                label: 'Due soon ${cards.billSummary.dueSoonCount}',
                tone: FinarcStatusTone.warning,
                compact: true,
              ),
              const SizedBox(width: AppSpacing.xs),
              FinarcStatusBadge(
                label: 'Overdue ${cards.billSummary.overdueCount}',
                tone: FinarcStatusTone.error,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Card Usage Split',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          FinarcBarChart(
            items: cards.usageSplit
                .map(
                  (c) => NamedAmount(
                    name: '${c.cardName} • ${c.last4}',
                    amount: c.amount,
                  ),
                )
                .toList(growable: false),
            color: AppColors.darkAccent,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Monthly Billed Trend',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          FinarcLineChart(
            points: cards.billedTrend,
            color: AppColors.darkWarning,
          ),
        ],
      ),
    );
  }

  Widget _loansSection(BuildContext context, AnalyticsSnapshot data) {
    final loans = data.loans;
    return FinarcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FinarcSectionHeader(title: 'Loan Analytics'),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _metric(
                  context,
                  'Liabilities',
                  inr(loans.totalOutstanding),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _metric(
                  context,
                  'EMI Burden',
                  inr(loans.monthlyEmiBurden),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: _metric(
                  context,
                  'Active vs Closed',
                  '${loans.activeCount} / ${loans.closedCount}',
                  valueIsAmount: false,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _metric(
                  context,
                  'Upcoming EMI',
                  '${loans.upcomingEmiCount} • ${inr(loans.upcomingEmiTotal)}',
                  valueIsAmount: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('EMI Trend', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          FinarcLineChart(points: loans.emiTrend, color: AppColors.darkError),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Debt Ratio Trend',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          FinarcLineChart(
            points: loans.debtRatioTrend,
            color: AppColors.darkWarning,
          ),
        ],
      ),
    );
  }

  Widget _splitSection(BuildContext context, AnalyticsSnapshot data) {
    final split = data.splits;
    return FinarcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FinarcSectionHeader(title: 'Split Analytics'),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _metric(
                  context,
                  'Recoverable',
                  inr(split.totalRecoverable),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _metric(context, 'Payable', inr(split.totalPayable)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          _metric(
            context,
            'Settlement Progress',
            '${(split.settlementProgress * 100).toStringAsFixed(1)}%',
            valueIsAmount: false,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (split.owesYou.isNotEmpty) ...[
            Text(
              'Who Owes You Most',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            ...split.owesYou
                .take(3)
                .map(
                  (x) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('${x.name} • ${inr(x.amount)}'),
                  ),
                ),
            const SizedBox(height: AppSpacing.xs),
          ],
          if (split.youOwe.isNotEmpty) ...[
            Text(
              'Who You Owe Most',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            ...split.youOwe
                .take(3)
                .map(
                  (x) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('${x.name} • ${inr(x.amount)}'),
                  ),
                ),
            const SizedBox(height: AppSpacing.xs),
          ],
          if (split.groupBalances.isNotEmpty) ...[
            Text(
              'Group Balances',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            FinarcBarChart(
              items: split.groupBalances
                  .map((g) => NamedAmount(name: g.name, amount: g.amount.abs()))
                  .toList(growable: false),
              color: AppColors.darkAccent,
            ),
          ],
        ],
      ),
    );
  }

  Widget _metric(
    BuildContext context,
    String label,
    String value, {
    bool valueIsAmount = true,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(
          value,
          style:
              (valueIsAmount
                      ? Theme.of(context).textTheme.titleMedium
                      : Theme.of(context).textTheme.titleSmall)
                  ?.copyWith(color: valueColor),
        ),
      ],
    );
  }
}
