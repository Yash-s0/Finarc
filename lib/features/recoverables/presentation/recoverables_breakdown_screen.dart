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
    final byPerson = <String, List<RecoverableTransactionItem>>{};
    for (final item in items) {
      byPerson.putIfAbsent(item.partyName, () => []).add(item);
    }
    final groups = byPerson.entries.toList()
      ..sort((a, b) {
        final aRemaining = a.value.fold<double>(
          0,
          (sum, item) => sum + item.remainingRecoverableAmount,
        );
        final bRemaining = b.value.fold<double>(
          0,
          (sum, item) => sum + item.remainingRecoverableAmount,
        );
        return bRemaining.compareTo(aRemaining);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.sm),
        FinarcSectionHeader(title: title),
        const SizedBox(height: AppSpacing.xs),
        if (items.isEmpty)
          FinarcEmptyState(
            title: 'No entries',
            subtitle: emptyText,
            icon: Icons.receipt_long_outlined,
          )
        else
          ...groups.map(
            (group) => _RecoverablePersonGroupCard(
              personName: group.key,
              items: group.value,
              onOpenItem: (item) =>
                  context.push('/expenses/transaction/${item.id}'),
              onRecoveredItem: (item) async {
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

class _RecoverablePersonGroupCard extends StatelessWidget {
  const _RecoverablePersonGroupCard({
    required this.personName,
    required this.items,
    required this.onOpenItem,
    required this.onRecoveredItem,
  });

  final String personName;
  final List<RecoverableTransactionItem> items;
  final void Function(RecoverableTransactionItem item) onOpenItem;
  final Future<void> Function(RecoverableTransactionItem item) onRecoveredItem;

  @override
  Widget build(BuildContext context) {
    final sorted = [...items]
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    final baseTotal = sorted.fold<double>(
      0,
      (sum, item) => sum + item.recoverableBaseAmount,
    );
    final recoveredTotal = sorted.fold<double>(
      0,
      (sum, item) => sum + item.recoveredAmount,
    );
    final remainingTotal = sorted.fold<double>(
      0,
      (sum, item) => sum + item.remainingRecoverableAmount,
    );

    return FinarcCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(personName),
                    const SizedBox(height: 2),
                    Text(
                      'Base ${inr(baseTotal)} • Recovered ${inr(recoveredTotal)} • Remaining ${inr(remainingTotal)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ...sorted.map((item) {
            final isCardBucket =
                item.bucket == RecoverableBuckets.cardBilled ||
                item.bucket == RecoverableBuckets.cardUnbilled;
            return Column(
              children: [
                FinarcTransactionTile(
                  onTap: () => onOpenItem(item),
                  title: item.title,
                  subtitle: item.category,
                  meta: FinarcTransactionPresentation.meta(
                    date: item.transactionDate,
                    source: _sourceLabel(item.bucket),
                  ),
                  amount: inr(item.remainingRecoverableAmount),
                  amountMeta: 'Remaining',
                  badges: [
                    if (isCardBucket)
                      FinarcTransactionPresentation.billedBadge(
                        billed: item.bucket == RecoverableBuckets.cardBilled,
                      ),
                    FinarcTransactionPresentation.recoverableStatusBadge(
                      item.status,
                    ),
                    FinarcStatusBadge(
                      label: 'Base ${inr(item.recoverableBaseAmount)}',
                      tone: FinarcStatusTone.neutral,
                      compact: true,
                    ),
                    FinarcStatusBadge(
                      label: 'Recovered ${inr(item.recoveredAmount)}',
                      tone: item.recoveredAmount > 0
                          ? FinarcStatusTone.success
                          : FinarcStatusTone.neutral,
                      compact: true,
                    ),
                  ],
                ),
                if (!item.isRecovered)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        onRecoveredItem(item);
                      },
                      child: const Text('Mark as Recovered'),
                    ),
                  ),
                const Divider(height: AppSpacing.sm),
              ],
            );
          }),
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
