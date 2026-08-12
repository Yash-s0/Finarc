import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
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
  final _searchFocus = FocusNode();
  String _typeFilter = 'all';
  String _sourceFilter = 'all';
  String _categoryFilter = 'all';
  String _billingFilter = 'all';
  String _recoverableFilter = 'all';
  String _sourceOriginFilter = 'all';
  DateTimeRange? _dateRange;

  static const _quickFilterKey = Key('expenses-quick-filter');
  static const _resetFiltersKey = Key('expenses-reset-filters');

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(expenseListProvider);

    return FinarcScaffold(
      appBar: FinarcAppBar(
        title: 'Expenses',
        actions: [
          IconButton(
            tooltip: 'Search',
            onPressed: () => _searchFocus.requestFocus(),
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            tooltip: 'Add transaction',
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
                if (_sourceFilter == 'all' &&
                    _typeFilter == 'income' &&
                    txn.type != 'income' &&
                    txn.type != 'refund') {
                  return false;
                }
                if (_sourceFilter == 'all' &&
                    _typeFilter == 'expense' &&
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
                if (_billingFilter == 'unbilled' &&
                    txn.paymentSourceType != 'creditCard') {
                  return false;
                }
                if (_billingFilter == 'unbilled' && txn.cardBillId != null) {
                  return false;
                }
                if (_billingFilter == 'billed' && txn.cardBillId == null) {
                  return false;
                }
                if (_recoverableFilter == 'owed' && !txn.isForOthers) {
                  return false;
                }
                if (_recoverableFilter == 'owed') {
                  final remaining = _remainingRecoverableFor(txn);
                  if (remaining <= 0.009) return false;
                }
                if (_recoverableFilter == 'recovered') {
                  if (!txn.isForOthers ||
                      _remainingRecoverableFor(txn) > 0.009) {
                    return false;
                  }
                }
                if (_sourceOriginFilter != 'all' &&
                    txn.detectedSourceType != _sourceOriginFilter) {
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
          final totals = _ExpenseTotals.fromTransactions(filtered);

          final grouped = <String, List<dynamic>>{};
          for (final txn in filtered) {
            final key =
                '${txn.transactionDate.year}-${txn.transactionDate.month.toString().padLeft(2, '0')}-${txn.transactionDate.day.toString().padLeft(2, '0')}';
            grouped.putIfAbsent(key, () => []).add(txn);
          }
          final hasActiveFilters =
              _typeFilter != 'all' ||
              _sourceFilter != 'all' ||
              _categoryFilter != 'all' ||
              _billingFilter != 'all' ||
              _recoverableFilter != 'all' ||
              _sourceOriginFilter != 'all' ||
              _dateRange != null ||
              _search.text.trim().isNotEmpty;
          final activeFilterCount = _activeFilterCount;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(expenseListProvider);
              await ref.read(expenseListProvider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _summaryStrip(context, totals),
                const SizedBox(height: AppSpacing.sm),
                _filterPanel(
                  context,
                  txns: txns,
                  hasActiveFilters: hasActiveFilters,
                  activeFilterCount: activeFilterCount,
                ),
                const SizedBox(height: AppSpacing.md),
                if (filtered.isEmpty)
                  FinarcEmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'No transactions yet',
                    subtitle: hasActiveFilters
                        ? 'Clear filters or adjust your search to see more activity.'
                        : 'Add your first expense or enable detection to start tracking.',
                    actionLabel: 'Add Expense',
                    actionIcon: Icons.add,
                    onAction: () => context.push('/expenses/add'),
                    secondaryActionLabel: 'Enable Notification Detection',
                    secondaryActionIcon: Icons.notifications_active_outlined,
                    onSecondaryAction: () =>
                        context.push('/notifications/setup'),
                  )
                else
                  ...grouped.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FinarcSectionHeader(
                            title:
                                '${_prettyDay(entry.key)} · ${_transactionCountLabel(entry.value.length)}',
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          ...entry.value.map((t) {
                            final net = ref
                                .read(transactionEngineProvider)
                                .netExpense(t);
                            final recoverableBase =
                                t.recoverableBaseAmount ??
                                (t.isForOthers
                                    ? (t.amount - t.cashbackAmount)
                                          .clamp(0, t.amount)
                                          .toDouble()
                                    : 0.0);
                            final recovered = t.recoveredAmount
                                .clamp(0, recoverableBase)
                                .toDouble();
                            final remaining = (recoverableBase - recovered)
                                .clamp(0, recoverableBase)
                                .toDouble();
                            final isPositive =
                                FinarcTransactionPresentation.isPositive(
                                  type: t.type,
                                  paymentSourceType: t.paymentSourceType,
                                  title: t.title,
                                );
                            final badges = _badgesForTransaction(
                              t,
                              remaining: remaining,
                              recovered: recovered,
                            );
                            final amountMeta = _amountMetaForTransaction(
                              t,
                              net: net,
                            );
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.xs,
                              ),
                              child: _transactionActionWrapper(
                                context,
                                txn: t,
                                child: FinarcTransactionTile(
                                  onTap: () => context.push(
                                    '/expenses/transaction/${t.id}',
                                  ),
                                  title: t.title,
                                  subtitle: _subtitleForTransaction(t),
                                  meta: _metaForTransaction(t),
                                  amount:
                                      '${isPositive ? '+' : '-'}${inr(t.amount)}',
                                  amountMeta: amountMeta,
                                  amountColor: isPositive
                                      ? (isDark
                                            ? AppColors.darkSuccess
                                            : AppColors.lightSuccess)
                                      : (isDark
                                            ? AppColors.darkError
                                            : AppColors.lightError),
                                  prefix: CircleAvatar(
                                    radius: 16,
                                    backgroundColor:
                                        _iconBackgroundForTransaction(
                                          context,
                                          t,
                                        ),
                                    child: Icon(
                                      _iconForTransaction(t),
                                      size: 15,
                                      color: _iconColorForTransaction(
                                        context,
                                        t,
                                      ),
                                    ),
                                  ),
                                  badges: badges,
                                  compact: true,
                                ),
                              ),
                            );
                          }),
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

  Widget _summaryStrip(BuildContext context, _ExpenseTotals totals) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceLow : AppColors.lightSurfaceHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: _SummaryMetric(
                label: 'Spent',
                value: inr(totals.expense),
                color: isDark ? AppColors.darkError : AppColors.lightError,
              ),
            ),
            _SummaryDivider(isDark: isDark),
            Expanded(
              child: _SummaryMetric(
                label: 'Income',
                value: inr(totals.income),
                color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
              ),
            ),
            _SummaryDivider(isDark: isDark),
            Expanded(
              child: _SummaryMetric(
                label: 'Items',
                value: totals.count.toString(),
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _quickFilterValue {
    if (_typeFilter == 'expense' && _sourceFilter == 'all') return 'expense';
    if (_typeFilter == 'income' && _sourceFilter == 'all') return 'income';
    if (_sourceFilter == 'creditCard' && _typeFilter == 'all') {
      return 'creditCard';
    }
    if (_sourceFilter == 'upi' && _typeFilter == 'all') return 'upi';
    if (_sourceFilter == 'bank' && _typeFilter == 'all') return 'bank';
    if (_sourceFilter == 'cash' && _typeFilter == 'all') return 'cash';
    return 'all';
  }

  Widget _filterPanel(
    BuildContext context, {
    required List<dynamic> txns,
    required bool hasActiveFilters,
    required int activeFilterCount,
  }) {
    final categories =
        txns.map((t) => t.category as String).toSet().toList(growable: false)
          ..sort();
    final sourceOrigins =
        txns
            .map((t) => t.detectedSourceType as String?)
            .whereType<String>()
            .toSet()
            .toList(growable: false)
          ..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 44,
          child: TextField(
            focusNode: _searchFocus,
            controller: _search,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search transactions',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
              ),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              suffixIcon: _search.text.trim().isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                      },
                    ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _QuickFilterDropdown(
                key: _quickFilterKey,
                value: _quickFilterValue,
                activeFilterCount: activeFilterCount,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _applyQuickFilter(value));
                },
              ),
              const SizedBox(width: AppSpacing.xs),
              _FilterAction(
                icon: Icons.date_range_outlined,
                label: _dateRange == null
                    ? 'Date range'
                    : _formatDateRange(_dateRange!),
                selected: _dateRange != null,
                onTap: () => _pickDateRange(context),
              ),
              const SizedBox(width: AppSpacing.xs),
              _FilterAction(
                icon: Icons.account_balance_wallet_outlined,
                label: _sourceFilter == 'all'
                    ? 'All accounts'
                    : FinarcTransactionPresentation.sourceLabel(_sourceFilter),
                selected: _sourceFilter != 'all',
                onTap: () => _showFilterSheet(
                  context,
                  categories: categories,
                  sourceOrigins: sourceOrigins,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              _FilterAction(
                icon: Icons.sort_rounded,
                label: 'Sort: Date',
                onTap: () {},
              ),
              if (hasActiveFilters) ...[
                const SizedBox(width: AppSpacing.xs),
                _ResetFiltersButton(
                  key: _resetFiltersKey,
                  onPressed: () => setState(_resetFilters),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            _quickChip('All', 'all'),
            _quickChip('Unbilled', 'unbilled'),
            _quickChip('Owed', 'owed'),
            _quickChip('Cash', 'cash'),
            _quickChip('Card', 'creditCard'),
            _quickChip('UPI', 'upi'),
          ],
        ),
      ],
    );
  }

  String _formatDateRange(DateTimeRange range) {
    final start = range.start.toIso8601String().split('T').first;
    final end = range.end.toIso8601String().split('T').first;
    return '$start to $end';
  }

  int get _activeFilterCount {
    var count = 0;
    if (_typeFilter != 'all') count++;
    if (_sourceFilter != 'all') count++;
    if (_categoryFilter != 'all') count++;
    if (_billingFilter != 'all') count++;
    if (_recoverableFilter != 'all') count++;
    if (_sourceOriginFilter != 'all') count++;
    if (_dateRange != null) count++;
    return count;
  }

  Widget _quickChip(String label, String value) {
    final selected = switch (value) {
      'all' =>
        _typeFilter == 'all' &&
            _sourceFilter == 'all' &&
            _billingFilter == 'all' &&
            _recoverableFilter == 'all',
      'unbilled' => _billingFilter == 'unbilled',
      'owed' => _recoverableFilter == 'owed',
      'cash' || 'creditCard' || 'upi' => _sourceFilter == value,
      _ => false,
    };
    return FinarcActionChip(
      label: label,
      selected: selected,
      onTap: () {
        setState(() {
          if (value == 'all') {
            _typeFilter = 'all';
            _sourceFilter = 'all';
            _billingFilter = 'all';
            _recoverableFilter = 'all';
            return;
          }
          if (value == 'unbilled') {
            _billingFilter = selected ? 'all' : 'unbilled';
            return;
          }
          if (value == 'owed') {
            _recoverableFilter = selected ? 'all' : 'owed';
            return;
          }
          _typeFilter = 'all';
          _sourceFilter = selected ? 'all' : value;
        });
      },
    );
  }

  Future<void> _showFilterSheet(
    BuildContext context, {
    required List<String> categories,
    required List<String> sourceOrigins,
  }) async {
    var type = _typeFilter;
    var source = _sourceFilter;
    var category = _categoryFilter;
    var billing = _billingFilter;
    var recoverable = _recoverableFilter;
    var origin = _sourceOriginFilter;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.lg,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Filter transactions',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          if (_activeFilterCount > 0)
                            TextButton(
                              onPressed: () {
                                setSheetState(() {
                                  type = 'all';
                                  source = 'all';
                                  category = 'all';
                                  billing = 'all';
                                  recoverable = 'all';
                                  origin = 'all';
                                });
                                setState(() {
                                  _typeFilter = 'all';
                                  _sourceFilter = 'all';
                                  _categoryFilter = 'all';
                                  _billingFilter = 'all';
                                  _recoverableFilter = 'all';
                                  _sourceOriginFilter = 'all';
                                });
                              },
                              child: const Text('Clear'),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _FilterChoiceGroup(
                        title: 'Type',
                        value: type,
                        options: const {
                          'all': 'All',
                          'expense': 'Expenses',
                          'income': 'Income',
                        },
                        onChanged: (value) {
                          setSheetState(() => type = value);
                          setState(() {
                            _typeFilter = value;
                            _sourceFilter = 'all';
                          });
                          Navigator.pop(sheetContext);
                        },
                      ),
                      _FilterChoiceGroup(
                        title: 'Account',
                        value: source,
                        options: const {
                          'all': 'All accounts',
                          'creditCard': 'Card',
                          'upi': 'UPI',
                          'bank': 'Bank',
                          'cash': 'Cash',
                        },
                        onChanged: (value) {
                          setSheetState(() => source = value);
                          setState(() {
                            _sourceFilter = value;
                            _typeFilter = 'all';
                          });
                          Navigator.pop(sheetContext);
                        },
                      ),
                      _FilterChoiceGroup(
                        title: 'Category',
                        value: category,
                        options: {
                          'all': 'All categories',
                          for (final item in categories) item: item,
                        },
                        onChanged: (value) {
                          setSheetState(() => category = value);
                          setState(() => _categoryFilter = value);
                          Navigator.pop(sheetContext);
                        },
                      ),
                      _FilterChoiceGroup(
                        title: 'Billing',
                        value: billing,
                        options: const {
                          'all': 'Any billing state',
                          'unbilled': 'Unbilled',
                          'billed': 'Billed',
                        },
                        onChanged: (value) {
                          setSheetState(() => billing = value);
                          setState(() => _billingFilter = value);
                          Navigator.pop(sheetContext);
                        },
                      ),
                      _FilterChoiceGroup(
                        title: 'Recoverable',
                        value: recoverable,
                        options: const {
                          'all': 'Any recoverable state',
                          'owed': 'Owed',
                          'recovered': 'Recovered',
                        },
                        onChanged: (value) {
                          setSheetState(() => recoverable = value);
                          setState(() => _recoverableFilter = value);
                          Navigator.pop(sheetContext);
                        },
                      ),
                      if (sourceOrigins.isNotEmpty)
                        _FilterChoiceGroup(
                          title: 'Source',
                          value: origin,
                          options: {
                            'all': 'Any source',
                            for (final item in sourceOrigins)
                              item: _sourceLabel(item),
                          },
                          onChanged: (value) {
                            setSheetState(() => origin = value);
                            setState(() => _sourceOriginFilter = value);
                            Navigator.pop(sheetContext);
                          },
                        ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                setState(() {
                                  _typeFilter = type;
                                  _sourceFilter = source;
                                  _categoryFilter = category;
                                  _billingFilter = billing;
                                  _recoverableFilter = recoverable;
                                  _sourceOriginFilter = origin;
                                });
                                Navigator.pop(sheetContext);
                              },
                              child: const Text('Apply'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final result = await showDialog<_DateRangeDialogResult>(
      context: context,
      builder: (context) => _DateRangeCalendarDialog(
        initialRange: _dateRange,
        firstDate: DateTime(today.year - 5, today.month),
        today: today,
      ),
    );
    if (result == null) return;
    setState(() => _dateRange = result.cleared ? null : result.range);
  }

  void _applyQuickFilter(String value) {
    switch (value) {
      case 'expense':
        _typeFilter = 'expense';
        _sourceFilter = 'all';
        break;
      case 'income':
        _typeFilter = 'income';
        _sourceFilter = 'all';
        break;
      case 'creditCard':
      case 'upi':
      case 'bank':
      case 'cash':
        _typeFilter = 'all';
        _sourceFilter = value;
        _billingFilter = 'all';
        _recoverableFilter = 'all';
        break;
      case 'all':
      default:
        _typeFilter = 'all';
        _sourceFilter = 'all';
        _billingFilter = 'all';
        _recoverableFilter = 'all';
        break;
    }
  }

  void _resetFilters() {
    _typeFilter = 'all';
    _sourceFilter = 'all';
    _categoryFilter = 'all';
    _billingFilter = 'all';
    _recoverableFilter = 'all';
    _sourceOriginFilter = 'all';
    _dateRange = null;
    _search.clear();
  }

  static String _sourceLabel(String? source) {
    switch (source) {
      case 'sms':
        return 'SMS';
      case 'manual':
      case 'manualPaste':
        return 'Manual';
      case 'upiNotification':
        return 'UPI';
      case 'appNotification':
        return 'Notification';
      case 'cardPaymentNotification':
        return 'Notification';
      case 'creditCard':
        return 'Card';
      default:
        return (source ?? 'unknown');
    }
  }

  static double _remainingRecoverableFor(Transaction txn) {
    final recoverableBase =
        txn.recoverableBaseAmount ??
        (txn.isForOthers
            ? (txn.amount - txn.cashbackAmount).clamp(0, txn.amount).toDouble()
            : 0.0);
    final recovered = txn.recoveredAmount.clamp(0, recoverableBase).toDouble();
    return (recoverableBase - recovered).clamp(0, recoverableBase).toDouble();
  }

  static String _transactionCountLabel(int count) {
    return '$count ${count == 1 ? 'transaction' : 'transactions'}';
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

  static String _subtitleForTransaction(Transaction txn) {
    final parts = <String>[txn.category];
    parts.add(FinarcTransactionPresentation.sourceLabel(txn.paymentSourceType));
    final person = txn.recoverablePartyName?.trim();
    if (txn.isForOthers && person != null && person.isNotEmpty) {
      parts.add(person);
    }
    return parts.where((part) => part.trim().isNotEmpty).join(' · ');
  }

  static String _metaForTransaction(Transaction txn) {
    final parts = <String>[
      FinarcTransactionPresentation.meta(date: txn.transactionDate),
    ];
    if (txn.detectedSourceType != null) {
      parts.add(_sourceLabel(txn.detectedSourceType));
    }
    return parts.join(' · ');
  }

  static IconData _iconForTransaction(Transaction txn) {
    final category = txn.category.trim().toLowerCase();
    if (txn.type == 'loanEmi') return Icons.account_balance_outlined;
    if (txn.type == 'income' || txn.type == 'refund') {
      return Icons.south_west_rounded;
    }
    if (txn.type == 'transfer') return Icons.swap_horiz_rounded;
    if (txn.paymentSourceType == 'upi') return Icons.qr_code_2_rounded;
    if (txn.paymentSourceType == 'cash') return Icons.wallet_rounded;
    if (category.contains('food') ||
        category.contains('restaurant') ||
        category.contains('dining')) {
      return Icons.restaurant_rounded;
    }
    if (category.contains('shop') ||
        category.contains('grocery') ||
        category.contains('market')) {
      return Icons.shopping_bag_rounded;
    }
    if (category.contains('bill') ||
        category.contains('utility') ||
        category.contains('electric')) {
      return Icons.receipt_long_rounded;
    }
    if (category.contains('travel') ||
        category.contains('fuel') ||
        category.contains('transport')) {
      return Icons.directions_car_rounded;
    }
    if (category.contains('entertainment') ||
        category.contains('movie') ||
        category.contains('ott')) {
      return Icons.local_movies_rounded;
    }
    if (txn.paymentSourceType == 'creditCard') return Icons.credit_card;
    if (txn.paymentSourceType == 'bank') return Icons.account_balance;
    return Icons.payments_outlined;
  }

  Color _iconColorForTransaction(BuildContext context, Transaction txn) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (txn.type == 'income' || txn.type == 'refund') {
      return isDark ? AppColors.darkSuccess : AppColors.lightSuccess;
    }
    if (txn.type == 'transfer' || txn.paymentSourceType == 'upi') {
      return isDark ? AppColors.darkSuccess : AppColors.lightSuccess;
    }
    if (txn.paymentSourceType == 'creditCard') {
      return isDark ? AppColors.darkWarning : AppColors.lightWarning;
    }
    return isDark ? AppColors.darkAccent : AppColors.lightAccent;
  }

  Color _iconBackgroundForTransaction(BuildContext context, Transaction txn) {
    return _iconColorForTransaction(context, txn).withValues(alpha: 0.16);
  }

  Widget _transactionActionWrapper(
    BuildContext context, {
    required Transaction txn,
    required Widget child,
  }) {
    final editable = ref.read(transactionEngineProvider).isEditable(txn);
    if (!editable) return child;
    return Dismissible(
      key: ValueKey('expense-transaction-${txn.id}'),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          context.push('/expenses/transaction/${txn.id}');
          return false;
        }
        await _confirmDelete(txn.id);
        return false;
      },
      background: _SwipeActionBackground(
        alignment: Alignment.centerLeft,
        icon: Icons.edit_outlined,
        label: 'Edit',
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.22),
      ),
      secondaryBackground: _SwipeActionBackground(
        alignment: Alignment.centerRight,
        icon: Icons.delete_outline_rounded,
        label: 'Delete',
        color:
            (Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkError
                    : AppColors.lightError)
                .withValues(alpha: 0.22),
      ),
      child: child,
    );
  }

  Future<void> _confirmDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('This will reverse its balance effect.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(transactionEngineProvider).deleteTransaction(id);
      ref.invalidate(expenseListProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to delete: $e')));
    }
  }

  List<Widget> _badgesForTransaction(
    Transaction txn, {
    required double remaining,
    required double recovered,
  }) {
    final badges = <Widget>[];
    if (txn.paymentSourceType == 'creditCard') {
      badges.add(
        FinarcTransactionPresentation.billedBadge(
          billed: txn.cardBillId != null,
        ),
      );
    }
    if (txn.isForOthers) {
      badges.add(
        FinarcStatusBadge(
          label: remaining <= 0.009 ? 'Recovered' : 'Owed ${inr(remaining)}',
          tone: remaining <= 0.009
              ? FinarcStatusTone.success
              : FinarcStatusTone.warning,
          compact: true,
        ),
      );
    }
    if (txn.linkedSplitExpenseId != null || txn.splitGroupId != null) {
      badges.add(
        const FinarcStatusBadge(
          label: 'Split',
          tone: FinarcStatusTone.info,
          compact: true,
        ),
      );
    }
    if (txn.type == 'loanEmi') {
      badges.add(FinarcTransactionPresentation.emiBadge);
    }
    if (txn.detectedSourceType != null && badges.length < 3) {
      badges.add(
        FinarcStatusBadge(
          label: _sourceLabel(txn.detectedSourceType),
          tone: FinarcStatusTone.info,
          compact: true,
        ),
      );
    }
    if (txn.cashbackAmount > 0 && badges.length < 3) {
      badges.add(FinarcTransactionPresentation.cashbackBadge);
    }
    if (recovered > 0 && remaining > 0.009 && badges.length < 3) {
      badges.add(
        FinarcStatusBadge(
          label: 'Recovered ${inr(recovered)}',
          tone: FinarcStatusTone.success,
          compact: true,
        ),
      );
    }
    return badges.take(3).toList(growable: false);
  }

  String? _amountMetaForTransaction(Transaction txn, {required double net}) {
    final parts = <String>[];
    final share = txn.personalShareAmount;
    if (share != null && share > 0 && share < txn.amount) {
      parts.add('My share ${inr(share)}');
    }
    if (txn.cashbackAmount > 0) {
      parts.add('Net ${inr(net)}');
    }
    if (txn.isForOthers &&
        txn.recoverablePartyName?.trim().isNotEmpty == true) {
      parts.add(txn.recoverablePartyName!.trim());
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }
}

class _ExpenseTotals {
  const _ExpenseTotals({
    required this.expense,
    required this.income,
    required this.count,
  });

  final double expense;
  final double income;
  final int count;

  factory _ExpenseTotals.fromTransactions(List<Transaction> txns) {
    var expense = 0.0;
    var income = 0.0;
    for (final txn in txns) {
      if (txn.type == 'income' || txn.type == 'refund') {
        income += txn.amount;
      } else if (txn.type != 'transfer' && txn.type != 'cardPayment') {
        expense += txn.amount;
      }
    }
    return _ExpenseTotals(expense: expense, income: income, count: txns.length);
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
    );
  }
}

class _DateRangeDialogResult {
  const _DateRangeDialogResult._({this.range, this.cleared = false});

  const _DateRangeDialogResult.range(DateTimeRange range)
    : this._(range: range);

  const _DateRangeDialogResult.clear() : this._(cleared: true);

  final DateTimeRange? range;
  final bool cleared;
}

class _DateRangeCalendarDialog extends StatefulWidget {
  const _DateRangeCalendarDialog({
    required this.initialRange,
    required this.firstDate,
    required this.today,
  });

  final DateTimeRange? initialRange;
  final DateTime firstDate;
  final DateTime today;

  @override
  State<_DateRangeCalendarDialog> createState() =>
      _DateRangeCalendarDialogState();
}

class _DateRangeCalendarDialogState extends State<_DateRangeCalendarDialog> {
  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  late DateTime _visibleMonth;
  DateTime? _start;
  DateTime? _end;

  DateTime get _firstMonth =>
      DateTime(widget.firstDate.year, widget.firstDate.month);

  DateTime get _currentMonth => DateTime(widget.today.year, widget.today.month);

  @override
  void initState() {
    super.initState();
    final initialStart = widget.initialRange?.start;
    _start = initialStart == null ? null : DateUtils.dateOnly(initialStart);
    _end = widget.initialRange?.end == null
        ? null
        : DateUtils.dateOnly(widget.initialRange!.end);
    final requestedMonth = initialStart == null
        ? _currentMonth
        : DateTime(initialStart.year, initialStart.month);
    _visibleMonth = _clampMonth(requestedMonth);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select date range',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Future dates are unavailable.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    IconButton(
                      key: const Key('expenses-calendar-prev'),
                      onPressed: _canGoPrevious
                          ? () => setState(() {
                              _visibleMonth = DateTime(
                                _visibleMonth.year,
                                _visibleMonth.month - 1,
                              );
                            })
                          : null,
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          _monthLabel(_visibleMonth),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('expenses-calendar-next'),
                      onPressed: _canGoNext
                          ? () => setState(() {
                              _visibleMonth = DateTime(
                                _visibleMonth.year,
                                _visibleMonth.month + 1,
                              );
                            })
                          : null,
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: _weekdays
                      .map(
                        (day) => Expanded(
                          child: Center(
                            child: Text(
                              day,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: AppSpacing.xxs),
                _CalendarMonthGrid(
                  visibleMonth: _visibleMonth,
                  today: widget.today,
                  start: _start,
                  end: _end,
                  onDateTap: _selectDate,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _selectionLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(
                            context,
                          ).pop(const _DateRangeDialogResult.clear()),
                          child: const Text('Clear'),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    FilledButton(
                      onPressed: _start == null
                          ? null
                          : () {
                              final start = _start!;
                              final end = _end ?? _start!;
                              Navigator.of(context).pop(
                                _DateRangeDialogResult.range(
                                  DateTimeRange(start: start, end: end),
                                ),
                              );
                            },
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _canGoPrevious => _visibleMonth.isAfter(_firstMonth);

  bool get _canGoNext => _visibleMonth.isBefore(_currentMonth);

  String get _selectionLabel {
    if (_start == null) return 'Tap a start date, then an end date.';
    final end = _end ?? _start;
    return '${_formatDialogDate(_start!)} to ${_formatDialogDate(end!)}';
  }

  void _selectDate(DateTime date) {
    final selected = DateUtils.dateOnly(date);
    if (selected.isAfter(widget.today)) return;

    setState(() {
      if (_start == null || _end != null) {
        _start = selected;
        _end = null;
        return;
      }
      if (selected.isBefore(_start!)) {
        _start = selected;
        _end = null;
        return;
      }
      _end = selected;
    });
  }

  DateTime _clampMonth(DateTime month) {
    if (month.isBefore(_firstMonth)) return _firstMonth;
    if (month.isAfter(_currentMonth)) return _currentMonth;
    return month;
  }

  static String _monthLabel(DateTime month) {
    return '${_monthNames[month.month - 1]} ${month.year}';
  }

  static String _formatDialogDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _CalendarMonthGrid extends StatelessWidget {
  const _CalendarMonthGrid({
    required this.visibleMonth,
    required this.today,
    required this.start,
    required this.end,
    required this.onDateTap,
  });

  final DateTime visibleMonth;
  final DateTime today;
  final DateTime? start;
  final DateTime? end;
  final ValueChanged<DateTime> onDateTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firstDay = DateTime(visibleMonth.year, visibleMonth.month);
    final leadingBlanks = firstDay.weekday - 1;
    final daysInMonth = DateTime(
      visibleMonth.year,
      visibleMonth.month + 1,
      0,
    ).day;
    final cellCount = ((leadingBlanks + daysInMonth + 6) ~/ 7) * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: cellCount,
      itemBuilder: (context, index) {
        final dayNumber = index - leadingBlanks + 1;
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox.shrink();
        }
        final date = DateTime(visibleMonth.year, visibleMonth.month, dayNumber);
        final disabled = date.isAfter(today);
        final selectedStart = DateUtils.isSameDay(date, start);
        final selectedEnd = DateUtils.isSameDay(date, end);
        final inRange =
            start != null &&
            end != null &&
            date.isAfter(start!) &&
            date.isBefore(end!);
        final selected = selectedStart || selectedEnd;
        final isToday = DateUtils.isSameDay(date, today);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            key: Key(
              'expenses-calendar-day-${date.year}-${date.month}-${date.day}',
            ),
            onTap: disabled ? null : () => onDateTap(date),
            borderRadius: BorderRadius.circular(12),
            child: Ink(
              decoration: BoxDecoration(
                color: selected
                    ? (isDark ? AppColors.darkAccent : AppColors.lightAccent)
                    : inRange
                    ? (isDark
                          ? AppColors.darkPrimarySoft
                          : AppColors.lightPrimarySoft)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isToday && !selected
                      ? (isDark ? AppColors.darkAccent : AppColors.lightAccent)
                      : Colors.transparent,
                ),
              ),
              child: Center(
                child: Text(
                  '$dayNumber',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: disabled
                        ? (isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted)
                              .withValues(alpha: 0.35)
                        : selected
                        ? (isDark ? AppColors.darkBg : AppColors.lightBg)
                        : (isDark ? AppColors.darkText : AppColors.lightText),
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FilterAction extends StatelessWidget {
  const _FilterAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: selected
                ? (isDark
                      ? AppColors.darkPrimarySoft
                      : AppColors.lightPrimarySoft)
                : (isDark
                      ? AppColors.darkSurfaceLow
                      : AppColors.lightSurfaceHigh),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? (isDark ? AppColors.darkAccent : AppColors.lightAccent)
                        .withValues(alpha: 0.42)
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 9,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isDark
                        ? AppColors.darkAccent
                        : AppColors.lightAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickFilterDropdown extends StatelessWidget {
  const _QuickFilterDropdown({
    super.key,
    required this.value,
    required this.activeFilterCount,
    required this.onChanged,
  });

  final String value;
  final int activeFilterCount;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final selected = activeFilterCount > 0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected
            ? (isDark ? AppColors.darkPrimarySoft : AppColors.lightPrimarySoft)
            : (isDark ? AppColors.darkSurfaceLow : AppColors.lightSurfaceHigh),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? accent.withValues(alpha: 0.42)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isDense: true,
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: accent),
            selectedItemBuilder: (context) {
              final label = activeFilterCount == 0
                  ? 'Filter'
                  : 'Filter · $activeFilterCount';
              return List.generate(
                7,
                (_) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune_rounded, size: 18, color: accent),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            },
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All')),
              DropdownMenuItem(value: 'expense', child: Text('Expenses')),
              DropdownMenuItem(value: 'income', child: Text('Income')),
              DropdownMenuItem(value: 'creditCard', child: Text('Card')),
              DropdownMenuItem(value: 'upi', child: Text('UPI')),
              DropdownMenuItem(value: 'bank', child: Text('Bank')),
              DropdownMenuItem(value: 'cash', child: Text('Cash')),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

class _FilterChoiceGroup extends StatelessWidget {
  const _FilterChoiceGroup({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String title;
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: options.entries
                .map(
                  (entry) => FinarcActionChip(
                    label: entry.value,
                    selected: entry.key == value,
                    onTap: () => onChanged(entry.key),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _SwipeActionBackground extends StatelessWidget {
  const _SwipeActionBackground({
    required this.alignment,
    required this.icon,
    required this.label,
    required this.color,
  });

  final Alignment alignment;
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: ColoredBox(
        color: color,
        child: Align(
          alignment: alignment,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: textColor),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResetFiltersButton extends StatelessWidget {
  const _ResetFiltersButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkPrimarySoft
                : AppColors.lightPrimarySoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Icon(
              Icons.restart_alt_rounded,
              size: 20,
              color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
            ),
          ),
        ),
      ),
    );
  }
}
