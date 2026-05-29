import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../data/expenses_providers.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  final _search = TextEditingController();
  String _typeFilter = 'all';
  String _sourceFilter = 'all';
  String _categoryFilter = 'all';
  DateTimeRange? _dateRange;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          final filtered = txns
              .where((txn) {
                if (_typeFilter == 'income' &&
                    txn.type != 'income' &&
                    txn.type != 'refund') {
                  return false;
                }
                if (_typeFilter == 'expense' &&
                    (txn.type == 'income' || txn.type == 'refund')) {
                  return false;
                }
                if (_sourceFilter != 'all' &&
                    txn.paymentSourceType != _sourceFilter) {
                  return false;
                }
                if (_categoryFilter != 'all' &&
                    txn.category.toLowerCase() !=
                        _categoryFilter.toLowerCase()) {
                  return false;
                }
                if (_dateRange != null &&
                    !_dateRange!.start.isBefore(txn.transactionDate) &&
                    _dateRange!.start.day != txn.transactionDate.day) {
                  return false;
                }
                if (_dateRange != null &&
                    !_dateRange!.end
                        .add(const Duration(days: 1))
                        .isAfter(txn.transactionDate)) {
                  return false;
                }
                final query = _search.text.trim().toLowerCase();
                if (query.isNotEmpty) {
                  final haystack =
                      '${txn.title} ${txn.category} ${txn.notes ?? ''}'
                          .toLowerCase();
                  if (!haystack.contains(query)) return false;
                }
                return true;
              })
              .toList(growable: false);

          final grouped = <String, List<dynamic>>{};
          for (final txn in filtered) {
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
              FinarcCard(
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 18),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: TextField(
                        controller: _search,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Search title/category/notes',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _filterChip(
                    'All',
                    _typeFilter == 'all',
                    () => setState(() => _typeFilter = 'all'),
                  ),
                  _filterChip(
                    'Expense',
                    _typeFilter == 'expense',
                    () => setState(() => _typeFilter = 'expense'),
                  ),
                  _filterChip(
                    'Income',
                    _typeFilter == 'income',
                    () => setState(() => _typeFilter = 'income'),
                  ),
                  _filterChip(
                    'Card',
                    _sourceFilter == 'creditCard',
                    () => setState(() => _sourceFilter = 'creditCard'),
                  ),
                  _filterChip(
                    'UPI',
                    _sourceFilter == 'upi',
                    () => setState(() => _sourceFilter = 'upi'),
                  ),
                  _filterChip('Reset', false, () {
                    setState(() {
                      _typeFilter = 'all';
                      _sourceFilter = 'all';
                      _categoryFilter = 'all';
                      _dateRange = null;
                      _search.clear();
                    });
                  }),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _categoryFilter,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: [
                        const DropdownMenuItem(
                          value: 'all',
                          child: Text('All'),
                        ),
                        ...txns
                            .map((t) => t.category)
                            .toSet()
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            ),
                      ],
                      onChanged: (v) =>
                          setState(() => _categoryFilter = v ?? 'all'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _sourceFilter,
                      decoration: const InputDecoration(labelText: 'Source'),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All')),
                        DropdownMenuItem(value: 'bank', child: Text('Bank')),
                        DropdownMenuItem(value: 'upi', child: Text('UPI')),
                        DropdownMenuItem(value: 'cash', child: Text('Cash')),
                        DropdownMenuItem(
                          value: 'creditCard',
                          child: Text('Card'),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _sourceFilter = v ?? 'all'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              FinarcSecondaryButton(
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(now.year - 5),
                    lastDate: DateTime(now.year + 5),
                    initialDateRange: _dateRange,
                  );
                  if (picked == null) return;
                  setState(() => _dateRange = picked);
                },
                icon: Icons.date_range_outlined,
                label: _dateRange == null
                    ? 'Pick Date Range'
                    : '${_dateRange!.start.toIso8601String().split('T').first} to ${_dateRange!.end.toIso8601String().split('T').first}',
              ),
              const SizedBox(height: AppSpacing.md),
              if (filtered.isEmpty)
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
                              onTap: () =>
                                  context.push('/expenses/transaction/${t.id}'),
                              title: t.title,
                              subtitle: t.category,
                              meta:
                                  '${_sourceLabel(t.paymentSourceType)} • ${transactionDateLabel(t.transactionDate)}',
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
                                    '${t.recoverablePartyName ?? 'Recoverable'} ${inr(t.recoverableAmount ?? 0)}',
                                    FinarcStatusTone.warning,
                                  ),
                                if (t.isForOthers)
                                  _badge(
                                    context,
                                    t.recoverableStatus == 'recovered'
                                        ? 'Recovered'
                                        : t.recoverableStatus == 'partial'
                                        ? 'Partial'
                                        : 'Unpaid',
                                    t.recoverableStatus == 'recovered'
                                        ? FinarcStatusTone.success
                                        : t.recoverableStatus == 'partial'
                                        ? FinarcStatusTone.info
                                        : FinarcStatusTone.warning,
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

  static IconData _iconForType(String type, String source) {
    if (type == 'loanEmi') return Icons.account_balance_outlined;
    if (type == 'income' || type == 'refund') return Icons.south_west_rounded;
    if (source == 'creditCard') return Icons.credit_card;
    if (source == 'upi') return Icons.qr_code_2_rounded;
    if (source == 'bank') return Icons.account_balance;
    return Icons.payments_outlined;
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return FinarcActionChip(label: label, selected: selected, onTap: onTap);
  }
}
