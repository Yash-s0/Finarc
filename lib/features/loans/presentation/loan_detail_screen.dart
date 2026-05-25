import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../data/loan_service.dart';
import '../data/loans_providers.dart';

class LoanDetailScreen extends ConsumerWidget {
  const LoanDetailScreen({super.key, required this.loanId});

  final int loanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loanDetailProvider(loanId));

    return FinarcScaffold(
      appBar: FinarcAppBar(
        title: 'Loan Detail',
        actions: [
          IconButton(
            onPressed: () => context.push('/loans/$loanId/edit'),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: state.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: const [
            FinarcLoadingSkeleton(height: 180),
            SizedBox(height: AppSpacing.sm),
            FinarcLoadingSkeleton(height: 120),
          ],
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          final utilization = data.loan.principalAmount <= 0
              ? 0.0
              : (data.loan.currentOutstanding / data.loan.principalAmount)
                    .clamp(0, 1)
                    .toDouble();

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              FinarcCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data.loan.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        FinarcStatusBadge(
                          label: data.loan.loanType.toUpperCase(),
                          tone: FinarcStatusTone.neutral,
                          compact: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      data.loan.lenderName,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      inr(data.loan.currentOutstanding),
                      style: AppTextStyles.amountStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 34,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Current outstanding',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    LinearProgressIndicator(
                      value: utilization,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Principal ${inr(data.loan.principalAmount)} • ${(utilization * 100).toStringAsFixed(1)}% remaining',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FinarcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FinarcSectionHeader(title: 'EMI Snapshot'),
                    const SizedBox(height: AppSpacing.xs),
                    _kv(context, 'EMI Amount', inr(data.loan.emiAmount ?? 0)),
                    const SizedBox(height: AppSpacing.xs),
                    _kv(context, 'EMI Day', '${data.loan.emiDay ?? '-'}'),
                    const SizedBox(height: AppSpacing.xs),
                    _kv(
                      context,
                      'Next EMI',
                      data.nextEmi == null
                          ? (data.overdueEmi == null
                                ? '-'
                                : _dueText(data.overdueEmi!))
                          : _dueText(data.nextEmi!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: FinarcPrimaryButton(
                      onPressed: () => context.push('/loans/$loanId/pay'),
                      icon: Icons.payments_outlined,
                      label: 'Pay EMI',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: FinarcSecondaryButton(
                      onPressed: data.loan.currentOutstanding <= 0
                          ? () async {
                              await ref
                                  .read(loanActionsProvider)
                                  .closeLoan(loanId);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Loan closed')),
                                );
                              }
                            }
                          : null,
                      icon: Icons.task_alt,
                      label: 'Close Loan',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const FinarcSectionHeader(title: 'Payment History'),
              const SizedBox(height: AppSpacing.xs),
              if (data.payments.isEmpty)
                const FinarcEmptyState(
                  title: 'No EMI history',
                  subtitle: 'EMI payments will appear here once recorded.',
                  icon: Icons.history,
                )
              else
                FinarcCard(
                  child: Column(
                    children: [
                      for (var i = 0; i < data.payments.length; i++) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 16,
                              color: AppColors.darkSuccess,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                '${data.payments[i].paymentDate.day}/${data.payments[i].paymentDate.month}/${data.payments[i].paymentDate.year}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            Text(
                              inr(data.payments[i].amount),
                              style: AppTextStyles.amountStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                size: 14,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        if (i != data.payments.length - 1)
                          const SizedBox(height: AppSpacing.xs),
                      ],
                    ],
                  ),
                ),
              if (data.relatedTransactions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                const FinarcSectionHeader(title: 'Linked Transactions'),
                const SizedBox(height: AppSpacing.xs),
                FinarcCard(
                  child: Column(
                    children: [
                      for (
                        var i = 0;
                        i < data.relatedTransactions.length;
                        i++
                      ) ...[
                        FinarcTransactionTile(
                          title: data.relatedTransactions[i].title,
                          subtitle: data.relatedTransactions[i].category,
                          amount: '-${inr(data.relatedTransactions[i].amount)}',
                          amountColor: AppColors.darkError,
                          meta:
                              '${data.relatedTransactions[i].paymentSourceType.toUpperCase()} • ${data.relatedTransactions[i].transactionDate.day}/${data.relatedTransactions[i].transactionDate.month}',
                        ),
                        if (i != data.relatedTransactions.length - 1)
                          const SizedBox(height: AppSpacing.xs),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  static Widget _kv(BuildContext context, String key, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(key, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(
          value,
          style: AppTextStyles.amountStyle(
            color: Theme.of(context).colorScheme.onSurface,
            size: 14,
            weight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  static String _dueText(EmiSchedule schedule) {
    if (schedule.daysUntilDue < 0) {
      return '${schedule.daysUntilDue.abs()} day(s) overdue';
    }
    if (schedule.daysUntilDue == 0) {
      return 'Due today';
    }
    return 'Due in ${schedule.daysUntilDue} day(s)';
  }
}
