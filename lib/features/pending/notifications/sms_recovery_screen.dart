import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/numeric_input_formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../accounts/data/accounts_providers.dart';
import '../../cards/data/cards_providers.dart';
import '../../dashboard/data/dashboard_providers.dart';
import '../../expenses/data/expenses_providers.dart';
import '../../expenses/models/transaction_types.dart';
import '../../expenses/presentation/payment_source_selector_support.dart';
import '../data/pending_providers.dart';
import 'notification_providers.dart';
import 'sms_recovery_service.dart';

enum _SmsRecoveryRangePreset {
  days30(30, 'Last 30 days'),
  days60(60, 'Last 60 days'),
  days90(90, 'Last 90 days'),
  custom(null, 'Custom range');

  const _SmsRecoveryRangePreset(this.days, this.label);

  final int? days;
  final String label;
}

enum _SmsRecoveryStatusTab { ready, needsSource, duplicate, ignored }

class _SmsRecoveryRange {
  const _SmsRecoveryRange({required this.from, required this.to});

  final DateTime from;
  final DateTime to;
}

class _SmsSourceFilterOption {
  const _SmsSourceFilterOption({required this.key, required this.label});

  final String key;
  final String label;
}

class _SmsRecoverySummaryRow {
  const _SmsRecoverySummaryRow({
    required this.month,
    required this.sources,
    required this.total,
    required this.ready,
    required this.added,
    required this.needsSource,
    required this.duplicate,
    required this.ignored,
    required this.readyAmount,
  });

  final DateTime month;
  final List<String> sources;
  final int total;
  final int ready;
  final int added;
  final int needsSource;
  final int duplicate;
  final int ignored;
  final double readyAmount;
}

class SmsRecoveryScreen extends ConsumerStatefulWidget {
  const SmsRecoveryScreen({super.key});

  @override
  ConsumerState<SmsRecoveryScreen> createState() => _SmsRecoveryScreenState();
}

class _SmsRecoveryScreenState extends ConsumerState<SmsRecoveryScreen> {
  static const _allSourceFilterKey = 'all';

  bool _loading = false;
  bool _importing = false;
  _SmsRecoveryRangePreset _rangePreset = _SmsRecoveryRangePreset.days60;
  late DateTime _customStart;
  late DateTime _customEnd;
  List<SmsBackfillPreview>? _previews;
  final Set<String> _selectedIds = {};
  String _sourceFilterKey = _allSourceFilterKey;
  _SmsRecoveryStatusTab _statusTab = _SmsRecoveryStatusTab.ready;

  @override
  void initState() {
    super.initState();
    final today = _dateOnly(DateTime.now());
    _customEnd = today;
    _customStart = today.subtract(const Duration(days: 60));
  }

  @override
  Widget build(BuildContext context) {
    final smsAvailable =
        ref.watch(smsIngestionAvailableProvider).valueOrNull ?? false;
    final smsPermission = ref.watch(smsPermissionStatusProvider);
    final hasPermission = smsPermission.valueOrNull ?? false;
    final paymentSources = ref.watch(paymentSourcesProvider).valueOrNull;
    final sourceFilterOptions = _sourceFilterOptions(paymentSources);
    final sourceFilterKey = _effectiveSourceFilterKey(sourceFilterOptions);

    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Import Past SMS'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          FinarcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recover past SMS',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Preview transaction-like SMS locally, then add selected parsed messages as transactions.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                const FinarcStatusBadge(
                  label: 'Preview first. Adds confirmed records.',
                  tone: FinarcStatusTone.info,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (!smsAvailable)
            const _UnavailableCard()
          else if (!hasPermission)
            _PermissionCard(
              onEnable: () => _requestPermission(context),
              onOpenSettings: () => ref
                  .read(smsPermissionServiceProvider)
                  .openAppPermissionSettings(),
            )
          else ...[
            _ScanActionsCard(
              rangePreset: _rangePreset,
              customStart: _customStart,
              customEnd: _customEnd,
              rangeLabel: _rangeLabel,
              loading: _loading,
              importing: _importing,
              importableCount: _importablePreviews.length,
              selectedCount: _selectedImportablePreviews.length,
              sourceFilterKey: sourceFilterKey,
              sourceFilterOptions: sourceFilterOptions,
              onRangeChanged: _changeRangePreset,
              onSourceFilterChanged: _changeSourceFilter,
              onPickCustomStart: () => _pickCustomDate(start: true),
              onPickCustomEnd: () => _pickCustomDate(start: false),
              onScan: _scan,
              onImportSelected: _selectedImportablePreviews.isEmpty
                  ? null
                  : _importSelected,
              onImportAll: _importablePreviews.isEmpty ? null : _importAll,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildPreviewList(context, paymentSources),
          ],
        ],
      ),
    );
  }

  List<SmsBackfillPreview> get _importablePreviews {
    return _visiblePreviews
        .where((preview) => preview.canImport)
        .toList(growable: false);
  }

  List<SmsBackfillPreview> get _selectedImportablePreviews {
    return _importablePreviews
        .where((preview) => _selectedIds.contains(preview.id))
        .toList(growable: false);
  }

  List<SmsBackfillPreview> get _transactionPreviews {
    return (_previews ?? const [])
        .where((preview) => preview.isTransactionCandidate)
        .toList(growable: false);
  }

  List<SmsBackfillPreview> get _sourceFilteredPreviews {
    final key = _sourceFilterKey;
    final previews = _previews ?? const <SmsBackfillPreview>[];
    if (key == _allSourceFilterKey) return previews;
    if (!previews.any((preview) => _previewSourceKey(preview) == key)) {
      return previews;
    }
    return previews
        .where((preview) => _previewSourceKey(preview) == key)
        .toList(growable: false);
  }

  List<SmsBackfillPreview> get _visiblePreviews {
    return _sourceFilteredPreviews
        .where((preview) => _matchesStatusTab(preview, _statusTab))
        .toList(growable: false);
  }

  bool _matchesStatusTab(
    SmsBackfillPreview preview,
    _SmsRecoveryStatusTab tab,
  ) {
    switch (tab) {
      case _SmsRecoveryStatusTab.ready:
        return preview.status == SmsBackfillPreviewStatus.importable ||
            preview.status == SmsBackfillPreviewStatus.imported;
      case _SmsRecoveryStatusTab.needsSource:
        return preview.status == SmsBackfillPreviewStatus.sourceMissing;
      case _SmsRecoveryStatusTab.duplicate:
        return preview.status == SmsBackfillPreviewStatus.duplicateLikely;
      case _SmsRecoveryStatusTab.ignored:
        return preview.status == SmsBackfillPreviewStatus.ignored ||
            preview.status == SmsBackfillPreviewStatus.parserFailed ||
            preview.status == SmsBackfillPreviewStatus.importFailed;
    }
  }

  List<_SmsSourceFilterOption> _sourceFilterOptions(
    PaymentSourcesData? sources,
  ) {
    final options = <_SmsSourceFilterOption>[
      const _SmsSourceFilterOption(
        key: _allSourceFilterKey,
        label: 'All transaction SMS',
      ),
    ];
    final seen = <String>{_allSourceFilterKey};
    for (final preview in _transactionPreviews) {
      if (preview.paymentSourceType != PaymentSourceType.creditCard ||
          preview.paymentSourceId == null) {
        continue;
      }
      final key = _sourceKey(
        preview.paymentSourceType!,
        preview.paymentSourceId!,
      );
      if (!seen.add(key)) continue;
      options.add(
        _SmsSourceFilterOption(
          key: key,
          label: _cardFilterLabel(sources, preview.paymentSourceId!),
        ),
      );
    }
    return options;
  }

  String _effectiveSourceFilterKey(List<_SmsSourceFilterOption> options) {
    if (options.any((option) => option.key == _sourceFilterKey)) {
      return _sourceFilterKey;
    }
    return _allSourceFilterKey;
  }

  String _cardFilterLabel(PaymentSourcesData? sources, int cardId) {
    final cards = sources?.cards ?? const [];
    for (final card in cards) {
      if (card.id == cardId) return '${card.bankName} card XX${card.last4}';
    }
    return 'Card source $cardId';
  }

  String? _previewSourceKey(SmsBackfillPreview preview) {
    final type = preview.paymentSourceType;
    final id = preview.paymentSourceId;
    if (type == null || id == null) return null;
    return _sourceKey(type, id);
  }

  String _sourceKey(String type, int id) => '$type:$id';

  _SmsRecoveryRange get _selectedRange {
    final days = _rangePreset.days;
    if (days == null) {
      return _SmsRecoveryRange(
        from: _startOfDay(_customStart),
        to: _endOfDay(_customEnd),
      );
    }
    final now = DateTime.now();
    return _SmsRecoveryRange(
      from: now.subtract(Duration(days: days)),
      to: now,
    );
  }

  String get _rangeLabel {
    if (_rangePreset != _SmsRecoveryRangePreset.custom) {
      return _rangePreset.label.toLowerCase();
    }
    return '${_formatDate(_customStart)} to ${_formatDate(_customEnd)}';
  }

  int get _selectedRangeDays {
    final range = _selectedRange;
    final days = range.to.difference(range.from).inDays + 1;
    return days.clamp(1, 3650).toInt();
  }

  DateTime _dateOnly(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  DateTime _startOfDay(DateTime value) {
    final date = _dateOnly(value);
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _endOfDay(DateTime value) {
    final date = _dateOnly(value);
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  String _formatDate(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    final local = value.toLocal();
    return '${two(local.day)}/${two(local.month)}/${local.year}';
  }

  void _changeRangePreset(_SmsRecoveryRangePreset? value) {
    if (value == null) return;
    setState(() {
      _rangePreset = value;
      _previews = null;
      _selectedIds.clear();
      _sourceFilterKey = _allSourceFilterKey;
      _statusTab = _SmsRecoveryStatusTab.ready;
    });
  }

  void _changeSourceFilter(String? value) {
    if (value == null) return;
    setState(() => _sourceFilterKey = value);
  }

  Future<void> _pickCustomDate({required bool start}) async {
    final initial = start ? _customStart : _customEnd;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (start) {
        _customStart = _dateOnly(picked);
        if (_customStart.isAfter(_customEnd)) {
          _customEnd = _customStart;
        }
      } else {
        _customEnd = _dateOnly(picked);
        if (_customEnd.isBefore(_customStart)) {
          _customStart = _customEnd;
        }
      }
      _previews = null;
      _selectedIds.clear();
      _sourceFilterKey = _allSourceFilterKey;
      _statusTab = _SmsRecoveryStatusTab.ready;
    });
  }

  Future<void> _requestPermission(BuildContext context) async {
    final granted = await ref
        .read(smsPermissionServiceProvider)
        .requestPermission();
    await ref
        .read(detectionSettingsProvider.notifier)
        .applyChanges(smsPermissionAskedAt: DateTime.now());
    ref.read(smsPermissionCachedProvider.notifier).state = granted;
    ref.invalidate(smsPermissionStatusProvider);
    ref.invalidate(smsPermissionRationaleProvider);
    ref.invalidate(smsRuntimeDiagnosticsProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          granted ? 'SMS permission enabled.' : 'SMS permission denied.',
        ),
      ),
    );
  }

  Future<void> _scan() async {
    final granted = await _syncSmsPermissionCache();
    if (!granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SMS permission is required before scan.'),
        ),
      );
      return;
    }
    setState(() {
      _loading = true;
      _selectedIds.clear();
    });
    final range = _selectedRange;
    final previews = await ref
        .read(smsRecoveryServiceProvider)
        .previewRange(from: range.from, to: range.to);
    if (!mounted) return;
    setState(() {
      _previews = previews;
      _selectedIds.addAll(
        previews
            .where((preview) => preview.canImport)
            .map((preview) => preview.id),
      );
      _loading = false;
      _sourceFilterKey = _allSourceFilterKey;
      _statusTab = _SmsRecoveryStatusTab.ready;
    });
    await ref
        .read(detectionSettingsProvider.notifier)
        .applyChanges(
          smsBackfillDays: _selectedRangeDays,
          smsLastScannedAt: DateTime.now(),
        );
  }

  Future<void> _importAll() async {
    await _import(_importablePreviews);
  }

  Future<void> _importSelected() async {
    await _import(_selectedImportablePreviews);
  }

  Future<void> _import(Iterable<SmsBackfillPreview> previews) async {
    final list = previews.toList(growable: false);
    if (list.isEmpty) return;
    final granted = await _syncSmsPermissionCache();
    if (!granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SMS permission is required before import.'),
        ),
      );
      return;
    }
    setState(() => _importing = true);
    final result = await ref
        .read(smsRecoveryServiceProvider)
        .importPreviews(list);
    if (!mounted) return;
    final current = _previews ?? const <SmsBackfillPreview>[];
    final replacements = {
      for (final preview in result.previews) preview.id: preview,
    };
    setState(() {
      _previews = current
          .map((preview) => replacements[preview.id] ?? preview)
          .toList(growable: false);
      _selectedIds.removeAll(replacements.keys);
      _importing = false;
    });
    await ref
        .read(detectionSettingsProvider.notifier)
        .applyChanges(
          smsBackfillEnabled: true,
          smsBackfillDays: _selectedRangeDays,
          smsLastScannedAt: DateTime.now(),
        );
    ref.invalidate(pendingTransactionsProvider);
    ref.invalidate(pendingCountProvider);
    ref.invalidate(expenseListProvider);
    ref.invalidate(paymentSourcesProvider);
    ref.invalidate(accountsOverviewProvider);
    ref.invalidate(cardsOverviewProvider);
    ref.invalidate(dashboardProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added ${result.importedCount}; skipped ${result.duplicateOrSkippedCount}.',
        ),
      ),
    );
  }

  Future<bool> _syncSmsPermissionCache() async {
    final granted = await ref
        .read(smsPermissionServiceProvider)
        .isPermissionGranted();
    ref.read(smsPermissionCachedProvider.notifier).state = granted;
    ref.invalidate(smsPermissionStatusProvider);
    return granted;
  }

  Widget _buildPreviewList(
    BuildContext context,
    PaymentSourcesData? paymentSources,
  ) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final previews = _previews;
    if (previews == null) {
      return FinarcCard(child: Text('Preview SMS for $_rangeLabel.'));
    }
    if (previews.isEmpty) {
      return FinarcCard(child: Text('No SMS were found for $_rangeLabel.'));
    }
    final summaryRows = _summaryRows(paymentSources);
    final visiblePreviews = _visiblePreviews;
    final importableCount = visiblePreviews
        .where((preview) => preview.canImport)
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SmsRecoverySummaryCard(rows: summaryRows),
        const SizedBox(height: AppSpacing.sm),
        _SmsStatusTabs(
          selected: _statusTab,
          counts: {
            for (final tab in _SmsRecoveryStatusTab.values)
              tab: _sourceFilteredPreviews
                  .where((preview) => _matchesStatusTab(preview, tab))
                  .length,
          },
          onChanged: (tab) => setState(() => _statusTab = tab),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (visiblePreviews.isEmpty)
          FinarcCard(child: Text(_emptyTabMessage))
        else ...[
          FinarcSectionHeader(
            title:
                '$importableCount importable of ${visiblePreviews.length} $_statusTabListLabel',
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final preview in visiblePreviews) ...[
            _SmsPreviewTile(
              preview: preview,
              selected: _selectedIds.contains(preview.id),
              onViewMessage: () => _showFullMessage(preview),
              onEdit:
                  preview.isTransactionCandidate &&
                      preview.status != SmsBackfillPreviewStatus.imported
                  ? () => _editPreview(preview)
                  : null,
              onAttachProof:
                  preview.status == SmsBackfillPreviewStatus.duplicateLikely
                  ? () => _import([preview])
                  : null,
              onSelectedChanged: preview.canImport
                  ? (selected) {
                      setState(() {
                        if (selected) {
                          _selectedIds.add(preview.id);
                        } else {
                          _selectedIds.remove(preview.id);
                        }
                      });
                    }
                  : null,
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ],
    );
  }

  String get _emptyTabMessage {
    switch (_statusTab) {
      case _SmsRecoveryStatusTab.ready:
        return 'No ready transaction SMS matched this filter.';
      case _SmsRecoveryStatusTab.needsSource:
        return 'No transaction SMS need a source.';
      case _SmsRecoveryStatusTab.duplicate:
        return 'No duplicate-like transaction SMS matched this filter.';
      case _SmsRecoveryStatusTab.ignored:
        return 'No ignored SMS matched this filter.';
    }
  }

  String get _statusTabListLabel {
    switch (_statusTab) {
      case _SmsRecoveryStatusTab.ready:
        return 'ready SMS';
      case _SmsRecoveryStatusTab.needsSource:
        return 'SMS needing source';
      case _SmsRecoveryStatusTab.duplicate:
        return 'duplicate-like SMS';
      case _SmsRecoveryStatusTab.ignored:
        return 'ignored SMS';
    }
  }

  List<_SmsRecoverySummaryRow> _summaryRows(PaymentSourcesData? sources) {
    final rows = <String, _SmsRecoverySummaryAccumulator>{};
    for (final preview in _previews ?? const <SmsBackfillPreview>[]) {
      final date = preview.transactionDate ?? preview.receivedAt;
      final month = DateTime(date.year, date.month);
      final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      final accumulator = rows.putIfAbsent(
        key,
        () => _SmsRecoverySummaryAccumulator(month),
      );
      accumulator.add(preview, _summarySourceLabel(preview, sources));
    }
    final result = rows.values.map((value) => value.toRow()).toList();
    result.sort((a, b) => b.month.compareTo(a.month));
    return result;
  }

  String _summarySourceLabel(
    SmsBackfillPreview preview,
    PaymentSourcesData? sources,
  ) {
    final type = preview.paymentSourceType;
    final sourceId = preview.paymentSourceId;
    if (type == PaymentSourceType.creditCard && sourceId != null) {
      return _cardFilterLabel(sources, sourceId);
    }
    if (type == PaymentSourceType.creditCard) return 'Card source missing';
    if (type == PaymentSourceType.bank) return 'Bank/UPI source';
    if (type == PaymentSourceType.upi) return 'UPI source';
    if (type == PaymentSourceType.cash) return 'Cash/wallet source';
    if (preview.status == SmsBackfillPreviewStatus.ignored ||
        preview.status == SmsBackfillPreviewStatus.parserFailed) {
      return 'Ignored/non-transaction';
    }
    return 'Unmatched source';
  }

  Future<void> _showFullMessage(SmsBackfillPreview preview) {
    return FinarcBottomSheet.show<void>(
      context,
      isScrollControlled: true,
      child: _SmsFullMessageSheet(preview: preview),
    );
  }

  Future<void> _editPreview(SmsBackfillPreview preview) async {
    final sources = ref.read(paymentSourcesProvider).valueOrNull;
    final edited = await FinarcBottomSheet.show<SmsBackfillPreview>(
      context,
      isScrollControlled: true,
      child: _SmsPreviewEditSheet(
        preview: preview,
        sources:
            sources ??
            const PaymentSourcesData(banks: [], cards: [], cashWallets: []),
      ),
    );
    if (edited == null || !mounted) return;
    setState(() {
      _previews = (_previews ?? const [])
          .map((item) => item.id == edited.id ? edited : item)
          .toList(growable: false);
      if (edited.canImport) {
        _selectedIds.add(edited.id);
      } else {
        _selectedIds.remove(edited.id);
      }
    });
  }
}

class _SmsRecoverySummaryAccumulator {
  _SmsRecoverySummaryAccumulator(this.month);

  final DateTime month;
  final Set<String> sources = {};
  int total = 0;
  int ready = 0;
  int added = 0;
  int needsSource = 0;
  int duplicate = 0;
  int ignored = 0;
  double readyAmount = 0;

  void add(SmsBackfillPreview preview, String sourceLabel) {
    total += 1;
    if (sourceLabel.trim().isNotEmpty) sources.add(sourceLabel);
    switch (preview.status) {
      case SmsBackfillPreviewStatus.importable:
        ready += 1;
        readyAmount += preview.amount ?? 0;
      case SmsBackfillPreviewStatus.imported:
        added += 1;
      case SmsBackfillPreviewStatus.sourceMissing:
        needsSource += 1;
      case SmsBackfillPreviewStatus.duplicateLikely:
        duplicate += 1;
      case SmsBackfillPreviewStatus.ignored:
      case SmsBackfillPreviewStatus.parserFailed:
      case SmsBackfillPreviewStatus.importFailed:
        ignored += 1;
    }
  }

  _SmsRecoverySummaryRow toRow() {
    return _SmsRecoverySummaryRow(
      month: month,
      sources: sources.toList(growable: false)..sort(),
      total: total,
      ready: ready,
      added: added,
      needsSource: needsSource,
      duplicate: duplicate,
      ignored: ignored,
      readyAmount: readyAmount,
    );
  }
}

class _SmsRecoverySummaryCard extends StatelessWidget {
  const _SmsRecoverySummaryCard({required this.rows});

  final List<_SmsRecoverySummaryRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return FinarcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recovery Summary',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final row in rows) ...[
            _SmsRecoverySummaryRowView(row: row),
            if (row != rows.last) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _SmsRecoverySummaryRowView extends StatelessWidget {
  const _SmsRecoverySummaryRowView({required this.row});

  final _SmsRecoverySummaryRow row;

  @override
  Widget build(BuildContext context) {
    final sources = row.sources.take(2).join(' • ');
    final extraSourceCount = row.sources.length > 2
        ? row.sources.length - 2
        : 0;
    final sourceText = sources.isEmpty
        ? 'No matched source'
        : extraSourceCount > 0
        ? '$sources • +$extraSourceCount more'
        : sources;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _monthLabel(row.month),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            FinarcStatusBadge(
              label: '${row.total} SMS',
              tone: FinarcStatusTone.neutral,
              compact: true,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(sourceText, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            FinarcStatusBadge(
              label: 'Ready ${row.ready}',
              tone: FinarcStatusTone.success,
              compact: true,
            ),
            if (row.added > 0)
              FinarcStatusBadge(
                label: 'Added ${row.added}',
                tone: FinarcStatusTone.info,
                compact: true,
              ),
            FinarcStatusBadge(
              label: 'Needs source ${row.needsSource}',
              tone: row.needsSource > 0
                  ? FinarcStatusTone.warning
                  : FinarcStatusTone.neutral,
              compact: true,
            ),
            FinarcStatusBadge(
              label: 'Duplicate ${row.duplicate}',
              tone: row.duplicate > 0
                  ? FinarcStatusTone.warning
                  : FinarcStatusTone.neutral,
              compact: true,
            ),
            FinarcStatusBadge(
              label: 'Ignored ${row.ignored}',
              tone: FinarcStatusTone.neutral,
              compact: true,
            ),
          ],
        ),
        if (row.readyAmount > 0) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Ready amount ${inr(row.readyAmount)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  static String _monthLabel(DateTime month) {
    const names = [
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
    return '${names[month.month - 1]} ${month.year}';
  }
}

class _SmsStatusTabs extends StatelessWidget {
  const _SmsStatusTabs({
    required this.selected,
    required this.counts,
    required this.onChanged,
  });

  final _SmsRecoveryStatusTab selected;
  final Map<_SmsRecoveryStatusTab, int> counts;
  final ValueChanged<_SmsRecoveryStatusTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: _SmsRecoveryStatusTab.values
          .map(
            (tab) => FinarcActionChip(
              label: '${_label(tab)} ${counts[tab] ?? 0}',
              icon: _icon(tab),
              selected: selected == tab,
              onTap: () => onChanged(tab),
            ),
          )
          .toList(growable: false),
    );
  }

  String _label(_SmsRecoveryStatusTab tab) {
    switch (tab) {
      case _SmsRecoveryStatusTab.ready:
        return 'Ready';
      case _SmsRecoveryStatusTab.needsSource:
        return 'Needs Source';
      case _SmsRecoveryStatusTab.duplicate:
        return 'Duplicate';
      case _SmsRecoveryStatusTab.ignored:
        return 'Ignored';
    }
  }

  IconData _icon(_SmsRecoveryStatusTab tab) {
    switch (tab) {
      case _SmsRecoveryStatusTab.ready:
        return Icons.check_circle_outline;
      case _SmsRecoveryStatusTab.needsSource:
        return Icons.account_balance_wallet_outlined;
      case _SmsRecoveryStatusTab.duplicate:
        return Icons.copy_outlined;
      case _SmsRecoveryStatusTab.ignored:
        return Icons.visibility_off_outlined;
    }
  }
}

class SmsRecoveryScreenSafe extends StatelessWidget {
  const SmsRecoveryScreenSafe({super.key});

  @override
  Widget build(BuildContext context) {
    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Import Past SMS'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: const [
          FinarcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FinarcStatusBadge(
                  label: 'SMS ACCESS REQUIRED',
                  tone: FinarcStatusTone.warning,
                ),
                SizedBox(height: AppSpacing.xs),
                Text('Enable local SMS access before importing past messages.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnavailableCard extends StatelessWidget {
  const _UnavailableCard();

  @override
  Widget build(BuildContext context) {
    return const FinarcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FinarcStatusBadge(
            label: 'SMS ACCESS REQUIRED',
            tone: FinarcStatusTone.warning,
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'Enable local SMS permission and receiver access before importing past messages.',
          ),
        ],
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.onEnable, required this.onOpenSettings});

  final VoidCallback onEnable;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return FinarcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FinarcStatusBadge(
            label: 'SMS permission required',
            tone: FinarcStatusTone.warning,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Allow SMS access to preview and recover transaction messages from your selected range.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          FinarcPrimaryButton(
            onPressed: onEnable,
            icon: Icons.sms_outlined,
            label: 'Enable SMS Access',
          ),
          const SizedBox(height: AppSpacing.xs),
          FinarcSecondaryButton(
            onPressed: onOpenSettings,
            icon: Icons.settings_outlined,
            label: 'Open App Permission Settings',
          ),
        ],
      ),
    );
  }
}

class _ScanActionsCard extends StatelessWidget {
  const _ScanActionsCard({
    required this.rangePreset,
    required this.customStart,
    required this.customEnd,
    required this.rangeLabel,
    required this.loading,
    required this.importing,
    required this.importableCount,
    required this.selectedCount,
    required this.sourceFilterKey,
    required this.sourceFilterOptions,
    required this.onRangeChanged,
    required this.onSourceFilterChanged,
    required this.onPickCustomStart,
    required this.onPickCustomEnd,
    required this.onScan,
    required this.onImportSelected,
    required this.onImportAll,
  });

  final _SmsRecoveryRangePreset rangePreset;
  final DateTime customStart;
  final DateTime customEnd;
  final String rangeLabel;
  final bool loading;
  final bool importing;
  final int importableCount;
  final int selectedCount;
  final String sourceFilterKey;
  final List<_SmsSourceFilterOption> sourceFilterOptions;
  final ValueChanged<_SmsRecoveryRangePreset?> onRangeChanged;
  final ValueChanged<String?> onSourceFilterChanged;
  final VoidCallback onPickCustomStart;
  final VoidCallback onPickCustomEnd;
  final VoidCallback onScan;
  final VoidCallback? onImportSelected;
  final VoidCallback? onImportAll;

  @override
  Widget build(BuildContext context) {
    return FinarcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<_SmsRecoveryRangePreset>(
            initialValue: rangePreset,
            decoration: const InputDecoration(labelText: 'SMS range'),
            items: _SmsRecoveryRangePreset.values
                .map(
                  (preset) => DropdownMenuItem(
                    value: preset,
                    child: Text(preset.label),
                  ),
                )
                .toList(growable: false),
            onChanged: loading || importing ? null : onRangeChanged,
          ),
          if (rangePreset == _SmsRecoveryRangePreset.custom) ...[
            const SizedBox(height: AppSpacing.xs),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FinarcSecondaryButton(
                  onPressed: loading || importing ? null : onPickCustomStart,
                  icon: Icons.date_range_outlined,
                  label: 'From ${_formatDate(customStart)}',
                ),
                const SizedBox(height: AppSpacing.xs),
                FinarcSecondaryButton(
                  onPressed: loading || importing ? null : onPickCustomEnd,
                  icon: Icons.event_available_outlined,
                  label: 'To ${_formatDate(customEnd)}',
                ),
              ],
            ),
          ],
          if (sourceFilterOptions.length > 1) ...[
            const SizedBox(height: AppSpacing.xs),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Card filter'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: sourceFilterKey,
                  isExpanded: true,
                  items: sourceFilterOptions
                      .map(
                        (option) => DropdownMenuItem(
                          value: option.key,
                          child: Text(option.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: loading || importing
                      ? null
                      : onSourceFilterChanged,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          FinarcPrimaryButton(
            onPressed: loading || importing ? null : onScan,
            isLoading: loading,
            icon: Icons.manage_search_outlined,
            label: 'Preview $rangeLabel',
          ),
          const SizedBox(height: AppSpacing.xs),
          FinarcSecondaryButton(
            onPressed: loading || importing ? null : onImportSelected,
            isLoading: importing && selectedCount > 0,
            icon: Icons.playlist_add_check_outlined,
            label: 'Add Selected ($selectedCount)',
          ),
          const SizedBox(height: AppSpacing.xs),
          FinarcSecondaryButton(
            onPressed: loading || importing ? null : onImportAll,
            icon: Icons.download_done_outlined,
            label: 'Add All Importable ($importableCount)',
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    final local = value.toLocal();
    return '${two(local.day)}/${two(local.month)}/${local.year}';
  }
}

class _SmsPreviewTile extends StatelessWidget {
  const _SmsPreviewTile({
    required this.preview,
    required this.selected,
    required this.onSelectedChanged,
    required this.onViewMessage,
    required this.onEdit,
    required this.onAttachProof,
  });

  final SmsBackfillPreview preview;
  final bool selected;
  final ValueChanged<bool>? onSelectedChanged;
  final VoidCallback onViewMessage;
  final VoidCallback? onEdit;
  final VoidCallback? onAttachProof;

  @override
  Widget build(BuildContext context) {
    return FinarcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: preview.canImport && selected,
                onChanged: onSelectedChanged == null
                    ? null
                    : (value) => onSelectedChanged!(value ?? false),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            preview.merchant ?? preview.sender,
                            style: Theme.of(context).textTheme.titleSmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _StatusBadge(status: preview.status),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${preview.sender} • ${_formatDateTime(preview.receivedAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (preview.amount != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        '₹${_formatAmount(preview.amount!)} • ${preview.parserName ?? 'Parser'}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      preview.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Reason: ${preview.reason}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        FinarcSecondaryButton(
                          onPressed: onViewMessage,
                          icon: Icons.notes_outlined,
                          label: 'View Message',
                          expand: false,
                        ),
                        FinarcSecondaryButton(
                          onPressed: onEdit,
                          icon: Icons.edit_outlined,
                          label: 'Edit',
                          expand: false,
                        ),
                        if (onAttachProof != null)
                          FinarcSecondaryButton(
                            onPressed: onAttachProof,
                            icon: Icons.attachment_outlined,
                            label: 'Attach Proof',
                            expand: false,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    final local = value.toLocal();
    return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
  }

  String _formatAmount(double value) {
    final fixed = value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final whole = parts.first;
    final buffer = StringBuffer();
    for (var i = 0; i < whole.length; i += 1) {
      if (i > 0 && (whole.length - i) % 3 == 0) buffer.write(',');
      buffer.write(whole[i]);
    }
    return '${buffer.toString()}.${parts.last}';
  }
}

class _SmsFullMessageSheet extends StatelessWidget {
  const _SmsFullMessageSheet({required this.preview});

  final SmsBackfillPreview preview;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            preview.merchant ?? preview.sender,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '${preview.sender} • ${_formatSheetDateTime(preview.receivedAt)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          SelectableText(
            preview.body,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  String _formatSheetDateTime(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    final local = value.toLocal();
    return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
  }
}

class _SmsPreviewEditSheet extends StatefulWidget {
  const _SmsPreviewEditSheet({required this.preview, required this.sources});

  final SmsBackfillPreview preview;
  final PaymentSourcesData sources;

  @override
  State<_SmsPreviewEditSheet> createState() => _SmsPreviewEditSheetState();
}

class _SmsPreviewEditSheetState extends State<_SmsPreviewEditSheet> {
  static const _modes = [
    FinarcPaymentModeOption(
      value: PaymentSourceType.cash,
      label: 'Cash',
      icon: Icons.payments_rounded,
    ),
    FinarcPaymentModeOption(
      value: PaymentSourceType.upi,
      label: 'UPI',
      icon: Icons.qr_code_scanner_rounded,
    ),
    FinarcPaymentModeOption(
      value: PaymentSourceType.creditCard,
      label: 'Card',
      icon: Icons.credit_card_rounded,
    ),
    FinarcPaymentModeOption(
      value: PaymentSourceType.bank,
      label: 'Bank',
      icon: Icons.account_balance_rounded,
    ),
  ];

  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _title = TextEditingController();
  final _category = TextEditingController();
  final _dateController = TextEditingController();
  late DateTime _date;
  late String _sourceType;
  int? _sourceId;

  @override
  void initState() {
    super.initState();
    final preview = widget.preview;
    _amount.text = (preview.amount ?? 0).toStringAsFixed(2);
    _title.text = preview.merchant ?? '';
    _category.text = preview.category ?? 'General';
    _date = preview.transactionDate ?? preview.receivedAt;
    _dateController.text = _formatDateTime(_date);
    _sourceType = preview.paymentSourceType ?? PaymentSourceType.bank;
    _sourceId = preview.paymentSourceId;
  }

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    _category.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sourceConfig = sourceConfigForMode(widget.sources, _sourceType);
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Edit Transaction',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            FinarcTextField(
              controller: _amount,
              label: 'Amount',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [StripLeadingZeroFormatter()],
              validator: (value) {
                final amount = double.tryParse(value ?? '');
                if (amount == null || amount <= 0) {
                  return 'Amount must be greater than 0';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            FinarcTextField(
              controller: _title,
              label: 'Title',
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.xs),
            FinarcTextField(controller: _category, label: 'Category'),
            const SizedBox(height: AppSpacing.xs),
            FinarcTextField(
              controller: _dateController,
              label: 'Date',
              readOnly: true,
              suffixIcon: const Icon(Icons.calendar_today_outlined),
              onTap: _pickDate,
            ),
            const SizedBox(height: AppSpacing.sm),
            FinarcPaymentSelector(
              title: 'Payment Source',
              selectedMode: _sourceType,
              modes: _modes,
              onModeChanged: (value) => setState(() {
                _sourceType = value;
                _sourceId = null;
              }),
              sources: sourceConfig.options,
              selectedSourceId: _sourceId,
              onSourceChanged: (value) => setState(() => _sourceId = value),
              sourceLabel: sourceConfig.fieldLabel,
              singleSourcePrefix: sourceConfig.singlePrefix,
              sourceValidator: (value) {
                if (sourceConfig.options.length <= 1) return null;
                return value == null ? 'Source required' : null;
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            FinarcPrimaryButton(
              onPressed: _save,
              icon: Icons.check_circle_outline,
              label: 'Save Changes',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _date = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _date.hour,
        _date.minute,
        _date.second,
      );
      _dateController.text = _formatDateTime(_date);
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final sourceConfig = sourceConfigForMode(widget.sources, _sourceType);
    final sourceId = resolveAutoSelectedSourceId(
      _sourceId,
      sourceConfig.options,
    );
    if (sourceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(sourceConfig.emptyMessage ?? 'Source required')),
      );
      return;
    }
    Navigator.of(context).pop(
      widget.preview.copyWith(
        status: SmsBackfillPreviewStatus.importable,
        reason: 'Edited by user',
        amount: double.parse(_amount.text),
        merchant: _title.text.trim(),
        category: _category.text.trim().isEmpty
            ? 'General'
            : _category.text.trim(),
        transactionDate: _date,
        paymentSourceType: _sourceType,
        paymentSourceId: sourceId,
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    final local = value.toLocal();
    return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final SmsBackfillPreviewStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = switch (status) {
      SmsBackfillPreviewStatus.importable => (
        'IMPORTABLE',
        FinarcStatusTone.success,
      ),
      SmsBackfillPreviewStatus.ignored => ('IGNORED', FinarcStatusTone.neutral),
      SmsBackfillPreviewStatus.parserFailed => (
        'NO PARSE',
        FinarcStatusTone.warning,
      ),
      SmsBackfillPreviewStatus.sourceMissing => (
        'SOURCE MISSING',
        FinarcStatusTone.warning,
      ),
      SmsBackfillPreviewStatus.duplicateLikely => (
        'DUPLICATE',
        FinarcStatusTone.warning,
      ),
      SmsBackfillPreviewStatus.imported => ('IMPORTED', FinarcStatusTone.info),
      SmsBackfillPreviewStatus.importFailed => (
        'SKIPPED',
        FinarcStatusTone.warning,
      ),
    };
    return FinarcStatusBadge(label: label, tone: tone, compact: true);
  }
}
