import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../data/dashboard_providers.dart';

class NetWorthBreakdownScreen extends ConsumerWidget {
  const NetWorthBreakdownScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);

    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Net Worth Breakdown'),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              FinarcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FinarcSectionHeader(title: 'Formula'),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Net Worth = Assets - Liabilities',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${inr(data.totalAssets)} - ${inr(data.totalLiabilities)} = ${inr(data.netWorth)}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ExpansionTile(
                title: const Text('Assets'),
                initiallyExpanded: true,
                childrenPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                children: [
                  _row('Bank balances', inr(data.bankBalance)),
                  _row('Cash', inr(data.cashInHand)),
                  _row(
                    'Recoverable (All)',
                    inr(
                      data.totalAssets -
                          (data.bankBalance +
                              data.cashInHand +
                              data.splitReceivableAmount),
                    ),
                  ),
                  _row('Split receivables', inr(data.splitReceivableAmount)),
                  const Divider(),
                  _row('Total assets', inr(data.totalAssets)),
                ],
              ),
              ExpansionTile(
                title: const Text('Liabilities'),
                initiallyExpanded: true,
                childrenPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                children: [
                  _row('Total Card Outstanding', inr(data.cardOutstanding)),
                  _row('Loans outstanding', inr(data.loansOutstanding)),
                  _row('Split payables', inr(data.splitPayableAmount)),
                  const Divider(),
                  _row('Total liabilities', inr(data.totalLiabilities)),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              FinarcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FinarcSectionHeader(title: 'Additional Insights'),
                    const SizedBox(height: AppSpacing.xs),
                    _row(
                      'Liquid assets',
                      inr(data.bankBalance + data.cashInHand),
                    ),
                    _row(
                      'Debt ratio',
                      '${(data.debtRatio * 100).toStringAsFixed(1)}%',
                    ),
                    _row('Monthly EMI burden', inr(data.monthlyEmiBurden)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value),
        ],
      ),
    );
  }
}
