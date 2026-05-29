import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../data/split_providers.dart';

class SplitScreen extends ConsumerWidget {
  const SplitScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(splitDashboardProvider);
    return FinarcScaffold(
      appBar: FinarcAppBar(
        title: 'Split',
        actions: [
          IconButton(
            onPressed: () => context.push('/split/groups/add'),
            icon: const Icon(Icons.group_add_outlined),
          ),
        ],
      ),
      body: state.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: const [
            FinarcLoadingSkeleton(height: 140),
            SizedBox(height: AppSpacing.sm),
            FinarcLoadingSkeleton(height: 120),
          ],
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          final net = data.receivable - data.payable;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              FinarcBalanceCard(
                label: 'Net Split Balance',
                value: inr(net),
                subtitle:
                    'Owed ${inr(data.receivable)} • Owe ${inr(data.payable)}',
                statusLabel: net >= 0 ? 'Net receivable' : 'Net payable',
              ),
              const SizedBox(height: AppSpacing.sm),
              FinarcPrimaryButton(
                onPressed: () => context.push('/split/groups/add'),
                icon: Icons.group_add_outlined,
                label: 'Create Group',
              ),
              if (data.groups.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                FinarcSecondaryButton(
                  onPressed: () => context.push(
                    '/split/groups/${data.groups.first.id}/add-expense',
                  ),
                  icon: Icons.add_card_rounded,
                  label: 'Quick Add Split Expense',
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              const FinarcSectionHeader(title: 'Active Groups'),
              const SizedBox(height: AppSpacing.xs),
              if (data.groups.isEmpty)
                const FinarcEmptyState(
                  title: 'No groups yet',
                  subtitle:
                      'Create a group and start tracking shared expenses.',
                )
              else
                ...data.groups.map((group) {
                  final net = data.groupNetById[group.id] ?? 0;
                  final memberCount = data.groupMemberCountById[group.id] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: FinarcCard(
                      onTap: () => context.push('/split/groups/${group.id}'),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.darkPrimarySoft,
                            child: Icon(Icons.group_outlined, size: 18),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(group.name),
                                const SizedBox(height: 2),
                                Text(
                                  '${group.description ?? 'Shared expenses'} • $memberCount members',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(inr(net)),
                              const SizedBox(height: 4),
                              FinarcStatusBadge(
                                label: net > 0
                                    ? 'OWED'
                                    : net < 0
                                    ? 'OWE'
                                    : 'SETTLED',
                                tone: net > 0
                                    ? FinarcStatusTone.success
                                    : net < 0
                                    ? FinarcStatusTone.warning
                                    : FinarcStatusTone.neutral,
                                compact: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: AppSpacing.md),
              const FinarcSectionHeader(title: 'Recent Activity'),
              const SizedBox(height: AppSpacing.xs),
              if (data.recentExpenses.isEmpty && data.recentSettlements.isEmpty)
                const FinarcEmptyState(
                  title: 'No split activity',
                  subtitle: 'Expenses and settlements will appear here.',
                )
              else ...[
                ...data.recentExpenses
                    .take(6)
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: FinarcTransactionTile(
                          title: e.title,
                          subtitle: e.category,
                          meta:
                              'Group #${e.groupId} • ${e.splitType.toUpperCase()} • ${transactionDateLabel(e.expenseDate)}',
                          amount: inr(e.totalAmount),
                          amountColor: AppColors.darkError,
                        ),
                      ),
                    ),
                ...data.recentSettlements
                    .take(6)
                    .map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: FinarcTransactionTile(
                          title: 'Settlement',
                          subtitle:
                              'Member ${s.fromMemberId} → ${s.toMemberId}',
                          meta:
                              'Group #${s.groupId} • ${transactionDateLabel(s.settlementDate)}',
                          amount: inr(s.amount),
                          amountColor: AppColors.darkSuccess,
                        ),
                      ),
                    ),
              ],
            ],
          );
        },
      ),
    );
  }
}
