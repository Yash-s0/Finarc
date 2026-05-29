import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../dashboard/data/dashboard_providers.dart';
import '../../expenses/presentation/transaction_detail_screen.dart';
import '../data/recoverables_service.dart';

class RecoverablesBreakdownScreen extends ConsumerWidget {
  const RecoverablesBreakdownScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recoverablesSnapshotProvider);

    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Recoverables Breakdown'),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              FinarcBalanceCard(
                label: 'Actionable Recoverable',
                value: inr(data.actionableRecoverables),
                subtitle:
                    'Card billed recoverables + bank/UPI + cash recoverables',
                statusLabel: data.actionableRecoverables > 0 ? 'Open' : 'Clear',
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: FinarcMetricCard(
                      title: 'Card Billed',
                      value: inr(data.cardBilledRecoverables),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: FinarcMetricCard(
                      title: 'Card Unbilled',
                      value: inr(data.cardUnbilledRecoverables),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: FinarcMetricCard(
                      title: 'Bank / UPI',
                      value: inr(data.bankUpiRecoverables),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: FinarcMetricCard(
                      title: 'Cash',
                      value: inr(data.cashRecoverables),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: FinarcMetricCard(
                      title: 'Recovered',
                      value: inr(data.settledRecoverables),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: FinarcMetricCard(
                      title: 'Total Outstanding',
                      value: inr(data.totalRecoverable),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              FinarcMetricCard(
                title: 'Split Receivables',
                value: inr(data.splitReceivables),
                onTap: () => context.push('/split'),
              ),
              const SizedBox(height: AppSpacing.md),
              _RecoverablesSection(
                title: 'Card Billed Recoverables',
                items: data.cardBilledItems,
                emptyText: 'No billed card recoverables',
              ),
              _RecoverablesSection(
                title: 'Card Unbilled Recoverables',
                items: data.cardUnbilledItems,
                emptyText: 'No unbilled card recoverables',
              ),
              _RecoverablesSection(
                title: 'Bank / UPI Recoverables',
                items: data.bankUpiItems,
                emptyText: 'No bank/UPI recoverables',
              ),
              _RecoverablesSection(
                title: 'Cash Recoverables',
                items: data.cashItems,
                emptyText: 'No cash recoverables',
              ),
              _RecoverablesSection(
                title: 'Recovered',
                items: data.recoveredItems,
                emptyText: 'No recovered entries yet',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RecoverablesSection extends ConsumerWidget {
  const _RecoverablesSection({
    required this.title,
    required this.items,
    required this.emptyText,
  });

  final String title;
  final List<RecoverableTransactionItem> items;
  final String emptyText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.sm),
        FinarcSectionHeader(title: title),
        const SizedBox(height: AppSpacing.xs),
        if (items.isEmpty)
          Text(emptyText, style: Theme.of(context).textTheme.bodySmall)
        else
          ...items.map(
            (item) => _RecoverableItemCard(
              item: item,
              onOpen: () => context.push('/expenses/transaction/${item.id}'),
              onRecovered: item.isRecovered
                  ? null
                  : () async {
                      await ref
                          .read(recoverablesServiceProvider)
                          .markRecovered(item.id);
                      ref.invalidate(recoverablesSnapshotProvider);
                      ref.invalidate(dashboardProvider);
                      ref.invalidate(transactionByIdProvider(item.id));
                    },
            ),
          ),
      ],
    );
  }
}

class _RecoverableItemCard extends StatelessWidget {
  const _RecoverableItemCard({
    required this.item,
    required this.onOpen,
    required this.onRecovered,
  });

  final RecoverableTransactionItem item;
  final VoidCallback onOpen;
  final VoidCallback? onRecovered;

  @override
  Widget build(BuildContext context) {
    return FinarcCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title),
                    const SizedBox(height: 2),
                    Text(
                      item.category,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                inr(item.openAmount),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FinarcStatusBadge(
                label: item.partyName,
                tone: FinarcStatusTone.info,
                compact: true,
              ),
              FinarcStatusBadge(
                label: item.isRecovered ? 'Recovered' : 'Open',
                tone: item.isRecovered
                    ? FinarcStatusTone.success
                    : FinarcStatusTone.warning,
                compact: true,
              ),
              FinarcStatusBadge(
                label: _sourceLabel(item.bucket),
                tone: FinarcStatusTone.info,
                compact: true,
              ),
              FinarcStatusBadge(
                label: 'Base ${inr(item.recoverableBaseAmount)}',
                tone: FinarcStatusTone.neutral,
                compact: true,
              ),
              if (item.recoveredAmount > 0)
                FinarcStatusBadge(
                  label: 'Recovered ${inr(item.recoveredAmount)}',
                  tone: FinarcStatusTone.success,
                  compact: true,
                ),
              FinarcStatusBadge(
                label: 'Cashback ${inr(item.cashbackAmount)}',
                tone: FinarcStatusTone.neutral,
                compact: true,
              ),
            ],
          ),
          if (item.partyPhone != null &&
              item.partyPhone!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              item.partyPhone!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recorded ${transactionDateLabel(item.transactionDate)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              if (onRecovered != null)
                TextButton(
                  onPressed: onRecovered,
                  child: const Text('Mark as Recovered'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _sourceLabel(String bucket) {
    switch (bucket) {
      case RecoverableBuckets.cardBilled:
        return 'Card billed';
      case RecoverableBuckets.cardUnbilled:
        return 'Card unbilled';
      case RecoverableBuckets.cash:
        return 'Cash';
      case RecoverableBuckets.recovered:
        return 'Recovered';
      case RecoverableBuckets.bankUpi:
      default:
        return 'Bank / UPI';
    }
  }
}
