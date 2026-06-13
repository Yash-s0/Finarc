import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../data/split_providers.dart';
import '../data/split_service.dart';

class SplitGroupDetailScreen extends ConsumerWidget {
  const SplitGroupDetailScreen({super.key, required this.groupId});

  final int groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (groupId <= 0) {
      return FinarcScaffold(
        appBar: const FinarcAppBar(title: 'Group'),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            FinarcEmptyState(
              title: 'Invalid split group route',
              subtitle: 'This group link is invalid.',
              icon: Icons.error_outline,
            ),
            const SizedBox(height: AppSpacing.sm),
            FinarcPrimaryButton(
              onPressed: () => context.go('/split'),
              icon: Icons.arrow_back_rounded,
              label: 'Back to Split',
            ),
          ],
        ),
      );
    }

    final state = ref.watch(splitGroupDetailProvider(groupId));

    return FinarcScaffold(
      appBar: FinarcAppBar(
        title: 'Group',
        actions: [
          IconButton(
            onPressed: () => _showAddMemberDialog(context, ref),
            icon: const Icon(Icons.person_add_alt_1_rounded),
          ),
        ],
      ),
      body: state.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: const [
            FinarcLoadingSkeleton(height: 144),
            SizedBox(height: AppSpacing.sm),
            FinarcLoadingSkeleton(height: 200),
          ],
        ),
        error: (e, _) => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            FinarcEmptyState(
              title: 'Split group not found',
              subtitle: 'This group may have been archived or deleted.',
              icon: Icons.group_off_outlined,
            ),
            const SizedBox(height: AppSpacing.sm),
            FinarcPrimaryButton(
              onPressed: () => context.go('/split'),
              icon: Icons.arrow_back_rounded,
              label: 'Back to Split',
            ),
          ],
        ),
        data: (data) {
          final yourBalance = data.memberBalances
              .where((m) => m.member.isCurrentUser)
              .fold<double>(0, (sum, b) => sum + b.net);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(splitGroupDetailProvider(groupId));
              await ref.read(splitGroupDetailProvider(groupId).future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text(
                  data.group.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  data.group.description ?? 'Shared expenses',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                FinarcBalanceCard(
                  label: 'Your Group Balance',
                  value: inr(yourBalance),
                  subtitle: yourBalance >= 0
                      ? 'You are owed in this group.'
                      : 'You owe in this group.',
                  statusLabel: yourBalance >= 0 ? 'Receivable' : 'Payable',
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: FinarcSecondaryButton(
                        onPressed: () =>
                            context.push('/split/groups/$groupId/add-expense'),
                        icon: Icons.add,
                        label: 'Add Expense',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: FinarcSecondaryButton(
                        onPressed: () =>
                            context.push('/split/groups/$groupId/settle'),
                        icon: Icons.swap_horiz_rounded,
                        label: 'Settle Up',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const FinarcSectionHeader(title: 'Member Balances'),
                const SizedBox(height: AppSpacing.xs),
                if (data.memberBalances.isEmpty)
                  FinarcEmptyState(
                    title: 'No members',
                    subtitle: 'Add members to start splitting expenses.',
                  )
                else
                  ...data.memberBalances.map((balance) {
                    final net = balance.net;
                    final tone = net > 0
                        ? FinarcStatusTone.success
                        : net < 0
                        ? FinarcStatusTone.warning
                        : FinarcStatusTone.neutral;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: FinarcCard(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: balance.member.isCurrentUser
                                  ? AppColors.darkPrimarySoft
                                  : AppColors.darkSurfaceHigh,
                              child: Text(
                                (balance.member.name.isEmpty
                                        ? '?'
                                        : balance.member.name.substring(0, 1))
                                    .toUpperCase(),
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(balance.member.name),
                                  const SizedBox(height: 2),
                                  Text(
                                    balance.member.contact ??
                                        (balance.member.isCurrentUser
                                            ? 'Current user'
                                            : 'Member'),
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
                                  inr(net),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: net < 0
                                            ? AppColors.darkError
                                            : AppColors.darkSuccess,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                FinarcStatusBadge(
                                  label: net > 0
                                      ? 'OWED'
                                      : net < 0
                                      ? 'OWES'
                                      : 'SETTLED',
                                  tone: tone,
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
                FinarcSectionHeader(
                  title: 'Simplified Balances',
                  trailing: TextButton(
                    onPressed: () =>
                        context.push('/split/groups/$groupId/balances'),
                    child: const Text('View all'),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                if (data.simplifiedTransfers.isEmpty)
                  const FinarcCard(
                    child: Text('All settled. No transfers required.'),
                  )
                else
                  ...data.simplifiedTransfers.take(3).map((xfer) {
                    final fromName = _memberNameById(data, xfer.fromMemberId);
                    final toName = _memberNameById(data, xfer.toMemberId);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: FinarcCard(
                        child: Row(
                          children: [
                            Expanded(child: Text(fromName)),
                            const Icon(Icons.arrow_forward_rounded, size: 16),
                            Expanded(
                              child: Text(toName, textAlign: TextAlign.end),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              inr(xfer.amount),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: AppSpacing.md),
                const FinarcSectionHeader(title: 'Recent Group Expenses'),
                const SizedBox(height: AppSpacing.xs),
                const FinarcCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Split expense edit/delete is under development.'),
                      SizedBox(height: 4),
                      Text(
                        'You can add new expenses normally. Safe financial edit/delete will be available soon.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                if (data.expenses.isEmpty)
                  FinarcEmptyState(
                    title: 'No group expenses',
                    subtitle: 'Add a split expense to start tracking balances.',
                  )
                else
                  ...data.expenses.map((expense) {
                    final payer = _memberNameById(data, expense.paidByMemberId);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: FinarcTransactionTile(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(SplitService.splitEditSoonMessage),
                            ),
                          );
                        },
                        title: expense.title,
                        subtitle: expense.category,
                        meta: FinarcTransactionPresentation.meta(
                          date: expense.expenseDate,
                          source: 'Paid by $payer',
                        ),
                        amount: inr(expense.totalAmount),
                        amountColor: AppColors.darkError,
                        badges: [
                          FinarcStatusBadge(
                            label: expense.splitType.toUpperCase(),
                            tone: FinarcStatusTone.info,
                            compact: true,
                          ),
                          const FinarcStatusBadge(
                            label: 'Edit/Delete soon',
                            tone: FinarcStatusTone.warning,
                            compact: true,
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: AppSpacing.md),
                const FinarcSectionHeader(title: 'Settlement History'),
                const SizedBox(height: AppSpacing.xs),
                if (data.settlements.isEmpty)
                  const FinarcCard(child: Text('No settlements yet.'))
                else
                  ...data.settlements.take(8).map((settlement) {
                    final fromName = _memberNameById(
                      data,
                      settlement.fromMemberId,
                    );
                    final toName = _memberNameById(data, settlement.toMemberId);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: FinarcTransactionTile(
                        title: 'Settlement',
                        subtitle: '$fromName → $toName',
                        meta: FinarcTransactionPresentation.meta(
                          date: settlement.settlementDate,
                          source: 'Split',
                        ),
                        amount: inr(settlement.amount),
                        amountColor: AppColors.darkSuccess,
                        badges: const [
                          FinarcStatusBadge(
                            label: 'Settled',
                            tone: FinarcStatusTone.success,
                            compact: true,
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _memberNameById(SplitGroupDetail data, int id) {
    for (final member in data.members) {
      if (member.id == id) return member.name;
    }
    return 'Member #$id';
  }

  Future<void> _showAddMemberDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final contactController = TextEditingController();

    final shouldAdd = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: contactController,
                decoration: const InputDecoration(
                  labelText: 'Phone / Email (optional)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (shouldAdd != true) return;
    final name = nameController.text.trim();
    if (name.isEmpty) return;

    await ref
        .read(splitActionsProvider)
        .addMember(
          groupId,
          name: name,
          contact: contactController.text.trim().isEmpty
              ? null
              : contactController.text.trim(),
        );
  }
}
