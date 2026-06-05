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
    if (loanId <= 0) {
      return FinarcScaffold(
        appBar: const FinarcAppBar(title: 'Loan Detail'),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const FinarcEmptyState(
              title: 'Invalid loan route',
              subtitle: 'This loan link is invalid.',
              icon: Icons.error_outline,
            ),
            const SizedBox(height: AppSpacing.sm),
            FinarcPrimaryButton(
              onPressed: () => context.go('/loans'),
              icon: Icons.arrow_back_rounded,
              label: 'Back to Loans',
            ),
          ],
        ),
      );
    }

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
        error: (e, _) => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const FinarcEmptyState(
              title: 'Loan not found',
              subtitle: 'This loan may have been deleted after reset.',
              icon: Icons.account_balance_wallet_outlined,
            ),
            const SizedBox(height: AppSpacing.sm),
            FinarcPrimaryButton(
              onPressed: () => context.go('/loans'),
              icon: Icons.arrow_back_rounded,
              label: 'Back to Loans',
            ),
          ],
        ),
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
                    if (data.loan.lenderType != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        _lenderTypeLabel(data.loan.lenderType!),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
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
                    const SizedBox(height: AppSpacing.xs),
                    _kv(
                      context,
                      'Due amount',
                      inr(
                        data.overdueEmi?.remainingAmount ??
                            data.nextEmi?.remainingAmount ??
                            0,
                      ),
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
                        FinarcTransactionTile(
                          title: data.loan.title,
                          subtitle: 'EMI payment',
                          meta: FinarcTransactionPresentation.meta(
                            date: data.payments[i].paymentDate,
                            source: FinarcTransactionPresentation.sourceLabel(
                              data.payments[i].paymentSourceType ?? 'bank',
                            ),
                          ),
                          amount: inr(data.payments[i].amount),
                          amountColor: AppColors.darkSuccess,
                          badges: const [
                            FinarcTransactionPresentation.loanPaymentBadge,
                          ],
                          prefix: const CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.darkPrimarySoft,
                            child: Icon(
                              Icons.check_circle_outline,
                              size: 16,
                              color: AppColors.darkSuccess,
                            ),
                          ),
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
                          meta: FinarcTransactionPresentation.meta(
                            date: data.relatedTransactions[i].transactionDate,
                            source: FinarcTransactionPresentation.sourceLabel(
                              data.relatedTransactions[i].paymentSourceType,
                            ),
                          ),
                          badges: [
                            if (data.relatedTransactions[i].type == 'loanEmi')
                              FinarcTransactionPresentation.emiBadge,
                            if (data.relatedTransactions[i].cashbackAmount > 0)
                              FinarcTransactionPresentation.cashbackBadge,
                          ],
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
    if (schedule.status == 'overdue') {
      return '${schedule.daysUntilDue.abs()} day(s) overdue';
    }
    if (schedule.status == 'dueToday') {
      return 'Due today';
    }
    if (schedule.status == 'partial') {
      return '${inr(schedule.remainingAmount)} remaining';
    }
    return 'Due in ${schedule.daysUntilDue} day(s)';
  }

  static String _lenderTypeLabel(String type) {
    switch (type) {
      case LoanLenderType.company:
        return 'Company';
      case LoanLenderType.bankNbfc:
        return 'Bank / NBFC';
      case LoanLenderType.person:
        return 'Person';
      default:
        return 'Other';
    }
  }
}
