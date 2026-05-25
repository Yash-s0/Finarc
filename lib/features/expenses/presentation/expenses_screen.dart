import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../data/expenses_providers.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(expenseListProvider);

    return FinarcScaffold(
      appBar: FinarcAppBar(
        title: 'Expenses',
        actions: [
          IconButton(
            onPressed: () => context.push('/expenses/add'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: state.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: const [
            FinarcLoadingSkeleton(height: 110),
            SizedBox(height: AppSpacing.sm),
            FinarcLoadingSkeleton(height: 84),
            SizedBox(height: AppSpacing.xs),
            FinarcLoadingSkeleton(height: 84),
          ],
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (txns) {
          final grouped = <String, List<dynamic>>{};
          for (final txn in txns) {
            final key =
                '${txn.transactionDate.year}-${txn.transactionDate.month.toString().padLeft(2, '0')}-${txn.transactionDate.day.toString().padLeft(2, '0')}';
            grouped.putIfAbsent(key, () => []).add(txn);
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(
                'Transaction command center',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Track expenses, recoverables and detected spends.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              const FinarcCard(
                child: Row(
                  children: [
                    Icon(Icons.search, size: 18),
                    SizedBox(width: AppSpacing.xs),
                    Expanded(child: Text('Search / filter (placeholder)')),
                    Icon(Icons.tune_rounded, size: 18),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _StaticFilterChip(label: 'All'),
                  _StaticFilterChip(label: 'Expense'),
                  _StaticFilterChip(label: 'Income'),
                  _StaticFilterChip(label: 'Card'),
                  _StaticFilterChip(label: 'UPI'),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (txns.isEmpty)
                Column(
                  children: [
                    const FinarcEmptyState(
                      title: 'No transactions yet',
                      subtitle:
                          'Add your first expense or enable detection to start tracking.',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FinarcPrimaryButton(
                      onPressed: () => context.push('/expenses/add'),
                      icon: Icons.add,
                      label: 'Add Expense',
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    FinarcSecondaryButton(
                      onPressed: () => context.push('/notifications/setup'),
                      icon: Icons.notifications_active_outlined,
                      label: 'Enable Notification Detection',
                    ),
                  ],
                )
              else
                ...grouped.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FinarcSectionHeader(
                          title: _prettyDay(entry.key),
                          trailing: Text(
                            '${entry.value.length} txns',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        ...entry.value.map((t) {
                          final net = ref
                              .read(transactionEngineProvider)
                              .netExpense(t);
                          final isPositive =
                              t.type == 'income' || t.type == 'refund';
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.xs,
                            ),
                            child: FinarcTransactionTile(
                              title: t.title,
                              subtitle: t.category,
                              meta:
                                  '${_sourceLabel(t.paymentSourceType)} • ${_timeLabel(t.transactionDate)}',
                              amount:
                                  '${isPositive ? '+' : '-'}${inr(t.amount)}',
                              amountColor: isPositive
                                  ? AppColors.darkSuccess
                                  : AppColors.darkError,
                              prefix: CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.darkPrimarySoft,
                                child: Icon(
                                  _iconForType(t.type, t.paymentSourceType),
                                  size: 15,
                                  color: AppColors.darkAccent,
                                ),
                              ),
                              badges: [
                                _badge(
                                  context,
                                  t.paymentSourceType.toUpperCase(),
                                  FinarcStatusTone.info,
                                ),
                                _badge(
                                  context,
                                  t.category,
                                  FinarcStatusTone.neutral,
                                ),
                                if (t.cashbackAmount > 0)
                                  _badge(
                                    context,
                                    'Cashback ${inr(t.cashbackAmount)}',
                                    FinarcStatusTone.success,
                                  ),
                                if (t.detectedSourceType != null)
                                  _badge(
                                    context,
                                    'Detected ${_sourceLabel(t.detectedSourceType)}',
                                    FinarcStatusTone.warning,
                                  ),
                                if (t.isForOthers)
                                  _badge(
                                    context,
                                    'Recoverable ${inr(t.recoverableAmount ?? 0)}',
                                    FinarcStatusTone.warning,
                                  ),
                                if (t.linkedSplitExpenseId != null ||
                                    t.splitGroupId != null)
                                  _badge(
                                    context,
                                    'Split',
                                    FinarcStatusTone.info,
                                  ),
                                if (t.type == 'loanEmi')
                                  _badge(
                                    context,
                                    'Loan EMI',
                                    FinarcStatusTone.warning,
                                  ),
                                if ((t.personalShareAmount ?? 0) > 0 &&
                                    (t.personalShareAmount ?? 0) < t.amount)
                                  _badge(
                                    context,
                                    'My share ${inr(t.personalShareAmount ?? 0)}',
                                    FinarcStatusTone.neutral,
                                  ),
                                if (t.cashbackAmount > 0)
                                  _badge(
                                    context,
                                    'Net ${inr(net)}',
                                    FinarcStatusTone.info,
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),
              if (txns.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                FinarcPrimaryButton(
                  onPressed: () => context.push('/expenses/add'),
                  icon: Icons.add,
                  label: 'Add Expense',
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  static Widget _badge(
    BuildContext context,
    String label,
    FinarcStatusTone tone,
  ) {
    return FinarcStatusBadge(label: label, tone: tone, compact: true);
  }

  static String _sourceLabel(String? source) {
    switch (source) {
      case 'upiNotification':
        return 'UPI';
      case 'appNotification':
        return 'Notification';
      case 'creditCard':
        return 'Card';
      default:
        return (source ?? 'unknown');
    }
  }

  static String _prettyDay(String yyyyMmDd) {
    final parts = yyyyMmDd.split('-');
    if (parts.length != 3) return yyyyMmDd;
    final date = DateTime.tryParse(yyyyMmDd);
    if (date == null) return yyyyMmDd;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${target.day.toString().padLeft(2, '0')}/${target.month.toString().padLeft(2, '0')}/${target.year}';
  }

  static String _timeLabel(DateTime date) {
    final d = date.toLocal();
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final min = d.minute.toString().padLeft(2, '0');
    final meridiem = d.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $meridiem';
  }

  static IconData _iconForType(String type, String source) {
    if (type == 'loanEmi') return Icons.account_balance_outlined;
    if (type == 'income' || type == 'refund') return Icons.south_west_rounded;
    if (source == 'creditCard') return Icons.credit_card;
    if (source == 'upi') return Icons.qr_code_2_rounded;
    if (source == 'bank') return Icons.account_balance;
    return Icons.payments_outlined;
  }
}

class _StaticFilterChip extends StatelessWidget {
  const _StaticFilterChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return FinarcActionChip(
      label: label,
      selected: label == 'All',
      onTap: () {},
    );
  }
}
