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

  static const _quickFilterKey = Key('expenses-quick-filter');
  static const _resetFiltersKey = Key('expenses-reset-filters');

  @override
  void dispose() {
    _search.dispose();
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
          final hasActiveFilters =
              _typeFilter != 'all' ||
              _sourceFilter != 'all' ||
              _categoryFilter != 'all' ||
              _dateRange != null ||
              _search.text.trim().isNotEmpty;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(expenseListProvider);
              await ref.read(expenseListProvider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                _filterPanel(
                  context,
                  txns: txns,
                  hasActiveFilters: hasActiveFilters,
                ),
                const SizedBox(height: AppSpacing.md),
                if (filtered.isEmpty)
                  Column(
                    children: [
                      FinarcEmptyState(
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
                                t.type == 'income' || t.type == 'refund';
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.xs,
                              ),
                              child: FinarcTransactionTile(
                                onTap: () => context.push(
                                  '/expenses/transaction/${t.id}',
                                ),
                                title: t.title,
                                subtitle: t.category,
                                meta: FinarcTransactionPresentation.meta(
                                  date: t.transactionDate,
                                  source:
                                      FinarcTransactionPresentation.sourceLabel(
                                        t.paymentSourceType,
                                      ),
                                ),
                                amount:
                                    '${isPositive ? '+' : '-'}${inr(t.amount)}',
                                amountColor: isPositive
                                    ? (isDark
                                          ? AppColors.darkSuccess
                                          : AppColors.lightSuccess)
                                    : (isDark
                                          ? AppColors.darkError
                                          : AppColors.lightError),
                                prefix: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: isDark
                                      ? AppColors.darkPrimarySoft
                                      : AppColors.lightPrimarySoft,
                                  child: Icon(
                                    _iconForType(t.type, t.paymentSourceType),
                                    size: 15,
                                    color: isDark
                                        ? AppColors.darkAccent
                                        : AppColors.lightAccent,
                                  ),
                                ),
                                badges: [
                                  if (t.paymentSourceType == 'creditCard')
                                    FinarcTransactionPresentation.billedBadge(
                                      billed: t.cardBillId != null,
                                    ),
                                  if (t.cashbackAmount > 0)
                                    FinarcTransactionPresentation.cashbackBadge,
                                  if (t.detectedSourceType != null)
                                    FinarcStatusBadge(
                                      label:
                                          'Detected ${_sourceLabel(t.detectedSourceType)}',
                                      tone: FinarcStatusTone.info,
                                      compact: true,
                                    ),
                                  if (t.isForOthers)
                                    FinarcStatusBadge(
                                      label:
                                          t.recoverablePartyName ??
                                          'For Others',
                                      tone: FinarcStatusTone.info,
                                      compact: true,
                                    ),
                                  if (t.isForOthers)
                                    FinarcTransactionPresentation.recoverableStatusBadge(
                                      t.recoverableStatus,
                                    ),
                                  if (t.isForOthers)
                                    FinarcStatusBadge(
                                      label: 'Remaining ${inr(remaining)}',
                                      tone: remaining <= 0.009
                                          ? FinarcStatusTone.success
                                          : FinarcStatusTone.warning,
                                      compact: true,
                                    ),
                                  if (t.isForOthers && recovered > 0)
                                    FinarcStatusBadge(
                                      label: 'Recovered ${inr(recovered)}',
                                      tone: FinarcStatusTone.success,
                                      compact: true,
                                    ),
                                  if (t.linkedSplitExpenseId != null ||
                                      t.splitGroupId != null)
                                    const FinarcStatusBadge(
                                      label: 'Split',
                                      tone: FinarcStatusTone.info,
                                      compact: true,
                                    ),
                                  if (t.type == 'loanEmi')
                                    FinarcTransactionPresentation.emiBadge,
                                  if ((t.personalShareAmount ?? 0) > 0 &&
                                      (t.personalShareAmount ?? 0) < t.amount)
                                    FinarcStatusBadge(
                                      label:
                                          'My share ${inr(t.personalShareAmount ?? 0)}',
                                      tone: FinarcStatusTone.neutral,
                                      compact: true,
                                    ),
                                  if (t.cashbackAmount > 0)
                                    FinarcStatusBadge(
                                      label: 'Net ${inr(net)}',
                                      tone: FinarcStatusTone.info,
                                      compact: true,
                                    ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }),
                if (filtered.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  FinarcPrimaryButton(
                    onPressed: () => context.push('/expenses/add'),
                    icon: Icons.add,
                    label: 'Add Expense',
                  ),
                ],
              ],
            ),
          );
        },
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
  }) {
    final categories =
        txns.map((t) => t.category as String).toSet().toList(growable: false)
          ..sort();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FinarcCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      borderColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      useShadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 46,
            child: TextField(
              controller: _search,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search transactions',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 22),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 42,
                  minHeight: 42,
                ),
                suffixIcon: _search.text.trim().isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _search.clear();
                          setState(() {});
                        },
                      ),
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 42,
                  minHeight: 42,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 300;
              final controls = [
                _FilterSelect(
                  label: 'Type',
                  icon: Icons.filter_alt_outlined,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      key: _quickFilterKey,
                      value: _quickFilterValue,
                      isExpanded: true,
                      isDense: true,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All')),
                        DropdownMenuItem(
                          value: 'expense',
                          child: Text('Expenses'),
                        ),
                        DropdownMenuItem(
                          value: 'income',
                          child: Text('Income'),
                        ),
                        DropdownMenuItem(
                          value: 'creditCard',
                          child: Text('Card'),
                        ),
                        DropdownMenuItem(value: 'upi', child: Text('UPI')),
                        DropdownMenuItem(value: 'bank', child: Text('Bank')),
                        DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _applyQuickFilter(value));
                      },
                    ),
                  ),
                ),
                _FilterSelect(
                  label: 'Category',
                  icon: Icons.category_outlined,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _categoryFilter,
                      isExpanded: true,
                      isDense: true,
                      items: [
                        const DropdownMenuItem(
                          value: 'all',
                          child: Text('All'),
                        ),
                        ...categories.map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _categoryFilter = value ?? 'all'),
                    ),
                  ),
                ),
              ];

              if (compact) {
                return Column(
                  children: [
                    controls[0],
                    const SizedBox(height: AppSpacing.xs),
                    controls[1],
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: controls[0]),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: controls[1]),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: _FilterAction(
                  icon: Icons.date_range_outlined,
                  label: _dateRange == null
                      ? 'Date range'
                      : _formatDateRange(_dateRange!),
                  onTap: () => _pickDateRange(context),
                ),
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
        ],
      ),
    );
  }

  String _formatDateRange(DateTimeRange range) {
    final start = range.start.toIso8601String().split('T').first;
    final end = range.end.toIso8601String().split('T').first;
    return '$start to $end';
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
        break;
      case 'all':
      default:
        _typeFilter = 'all';
        _sourceFilter = 'all';
        break;
    }
  }

  void _resetFilters() {
    _typeFilter = 'all';
    _sourceFilter = 'all';
    _categoryFilter = 'all';
    _dateRange = null;
    _search.clear();
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
}

class _FilterSelect extends StatelessWidget {
  const _FilterSelect({
    required this.label,
    required this.icon,
    required this.child,
  });

  final String label;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
        padding: const EdgeInsets.fromLTRB(AppSpacing.sm, 6, AppSpacing.sm, 6),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 2),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
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
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

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
            color: isDark
                ? AppColors.darkSurfaceLow
                : AppColors.lightSurfaceHigh,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 9,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isDark
                          ? AppColors.darkAccent
                          : AppColors.lightAccent,
                    ),
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
