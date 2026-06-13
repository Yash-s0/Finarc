import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../data/loan_service.dart';
import '../data/loans_providers.dart';

class LoansDashboardScreen extends ConsumerWidget {
  const LoansDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loansDashboardProvider);

    return FinarcScaffold(
      appBar: FinarcAppBar(
        title: 'Loans & EMIs',
        actions: [
          IconButton(
            onPressed: () => context.push('/loans/add'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: state.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: const [
            FinarcLoadingSkeleton(height: 170),
            SizedBox(height: AppSpacing.sm),
            FinarcLoadingSkeleton(height: 110),
          ],
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(loansDashboardProvider);
            await ref.read(loansDashboardProvider.future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              FinarcBalanceCard(
                label: 'Total Loan Outstanding',
                value: inr(data.totalOutstanding),
                subtitle: 'Active liabilities from all open loans',
                statusLabel: data.totalOutstanding > 0
                    ? 'Track Closely'
                    : 'Clear',
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: FinarcMetricCard(
                      title: 'Monthly EMI',
                      value: inr(data.monthlyEmiBurden),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: FinarcMetricCard(
                      title: 'Debt Ratio',
                      value:
                          '${(data.debtRatio * 100).clamp(0, 999).toStringAsFixed(1)}%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              FinarcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FinarcSectionHeader(title: 'Upcoming EMIs'),
                    const SizedBox(height: AppSpacing.xs),
                    if (data.upcomingEmis.isEmpty)
                      FinarcEmptyState(
                        title: 'No upcoming EMIs',
                        subtitle:
                            'Add loans with EMI details to track due reminders.',
                        icon: Icons.event_available_outlined,
                      )
                    else
                      Column(
                        children: [
                          for (
                            var i = 0;
                            i < data.upcomingEmis.length;
                            i++
                          ) ...[
                            _EmiRow(schedule: data.upcomingEmis[i]),
                            if (i != data.upcomingEmis.length - 1)
                              const SizedBox(height: AppSpacing.xs),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FinarcSectionHeader(
                title: 'Active Loans',
                trailing: Text(
                  '${data.activeLoans.length}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              if (data.activeLoans.isEmpty)
                Column(
                  children: [
                    FinarcEmptyState(
                      title: 'No active loans',
                      subtitle:
                          'Add your first loan to monitor EMIs and debt ratio.',
                      icon: Icons.account_balance_outlined,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FinarcPrimaryButton(
                      onPressed: () => context.push('/loans/add'),
                      icon: Icons.add,
                      label: 'Add Loan',
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    for (var i = 0; i < data.activeLoans.length; i++) ...[
                      FinarcCard(
                        onTap: () =>
                            context.push('/loans/${data.activeLoans[i].id}'),
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.darkPrimarySoft,
                              child: const Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data.activeLoans[i].title),
                                  const SizedBox(height: 2),
                                  Text(
                                    data.activeLoans[i].lenderName,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  inr(data.activeLoans[i].currentOutstanding),
                                  style: AppTextStyles.amountStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    size: 16,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                FinarcStatusBadge(
                                  label: data.activeLoans[i].loanType
                                      .toUpperCase(),
                                  tone: FinarcStatusTone.neutral,
                                  compact: true,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (i != data.activeLoans.length - 1)
                        const SizedBox(height: AppSpacing.xs),
                    ],
                  ],
                ),
              const SizedBox(height: AppSpacing.sm),
              if (data.recentPayments.isNotEmpty) ...[
                const FinarcSectionHeader(title: 'Recent EMI Payments'),
                const SizedBox(height: AppSpacing.xs),
                FinarcCard(
                  child: Column(
                    children: [
                      for (var i = 0; i < data.recentPayments.length; i++) ...[
                        _PaymentRow(payment: data.recentPayments[i]),
                        if (i != data.recentPayments.length - 1)
                          const SizedBox(height: AppSpacing.xs),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmiRow extends StatelessWidget {
  const _EmiRow({required this.schedule});

  final EmiSchedule schedule;

  @override
  Widget build(BuildContext context) {
    final tone = switch (schedule.status) {
      'overdue' => FinarcStatusTone.error,
      'dueToday' => FinarcStatusTone.warning,
      'dueSoon' => FinarcStatusTone.warning,
      'partial' => FinarcStatusTone.warning,
      _ => FinarcStatusTone.info,
    };

    final dueLabel = switch (schedule.status) {
      'overdue' => '${schedule.daysUntilDue.abs()}d overdue',
      'dueToday' => 'Due today',
      'partial' => 'Partial',
      'dueSoon' => 'Due in ${schedule.daysUntilDue}d',
      _ => 'Upcoming',
    };

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                schedule.loan.title,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 2),
              Text(
                'Due ${schedule.nextDate.day}/${schedule.nextDate.month}/${schedule.nextDate.year}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Text(
          inr(schedule.remainingAmount),
          style: AppTextStyles.amountStyle(
            color: Theme.of(context).colorScheme.onSurface,
            size: 14,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        FinarcStatusBadge(label: dueLabel, tone: tone, compact: true),
      ],
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment});

  final LoanPayment payment;

  @override
  Widget build(BuildContext context) {
    return FinarcTransactionTile(
      title: 'Loan Payment',
      subtitle: 'EMI',
      meta: FinarcTransactionPresentation.meta(
        date: payment.paymentDate,
        source: FinarcTransactionPresentation.sourceLabel(
          payment.paymentSourceType ?? 'bank',
        ),
      ),
      amount: inr(payment.amount),
      amountColor: AppColors.darkSuccess,
      badges: const [FinarcTransactionPresentation.loanPaymentBadge],
      prefix: const CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.darkPrimarySoft,
        child: Icon(
          Icons.check_circle_outline,
          size: 16,
          color: AppColors.darkSuccess,
        ),
      ),
    );
  }
}
