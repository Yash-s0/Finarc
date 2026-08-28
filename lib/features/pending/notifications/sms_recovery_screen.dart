import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
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
  days7(7, 'Last 7 days'),
  days14(14, 'Last 14 days'),
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
    final showImportActions =
        smsAvailable &&
        hasPermission &&
        !_loading &&
        _transactionPreviews.isNotEmpty;

    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Import Past SMS'),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                showImportActions ? AppSpacing.sm : AppSpacing.md,
              ),
              children: [
                const _SmsRecoveryIntro(),
                const SizedBox(height: AppSpacing.md),
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
                    previewLabel: _previewActionLabel,
                    loading: _loading,
                    importing: _importing,
                    sourceFilterKey: sourceFilterKey,
                    sourceFilterOptions: sourceFilterOptions,
                    onRangeChanged: _changeRangePreset,
                    onSourceFilterChanged: _changeSourceFilter,
                    onPickCustomStart: () => _pickCustomDate(start: true),
                    onPickCustomEnd: () => _pickCustomDate(start: false),
                    onScan: _scan,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildPreviewList(context),
                ],
              ],
            ),
          ),
          if (showImportActions)
            _SmsImportActions(
              importing: _importing,
              importableCount: _importablePreviews.length,
              selectedCount: _selectedImportablePreviews.length,
              onImportSelected: _selectedImportablePreviews.isEmpty
                  ? null
                  : _importSelected,
              onImportAll: _importablePreviews.isEmpty ? null : _importAll,
            ),
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

  String get _previewActionLabel {
    if (_rangePreset == _SmsRecoveryRangePreset.custom) {
      return 'Preview custom range';
    }
    return 'Preview ${_rangePreset.label.toLowerCase()}';
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

  void _selectVisibleImportable() {
    setState(() {
      _selectedIds.addAll(
        _visiblePreviews
            .where((preview) => preview.canImport)
            .map((preview) => preview.id),
      );
    });
  }

  void _clearSelection() {
    setState(_selectedIds.clear);
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

  Widget _buildPreviewList(BuildContext context) {
    if (_loading) {
      return const _SmsRecoveryStateCard(
        icon: Icons.manage_search_outlined,
        title: 'Scanning SMS...',
        subtitle: 'This may take a few seconds.',
        showProgress: true,
      );
    }
    final previews = _previews;
    if (previews == null) {
      return const _SmsRecoveryStateCard(
        icon: Icons.sms_outlined,
        title: 'No preview yet',
        subtitle:
            'Choose a date range and scan your SMS to review transaction-like messages.',
      );
    }
    if (previews.isEmpty) {
      return const _SmsRecoveryStateCard(
        icon: Icons.search_off_outlined,
        title: 'No transaction-like SMS found',
        subtitle: 'Try a wider date range or check your SMS permissions.',
      );
    }
    if (_transactionPreviews.isEmpty) {
      return const _SmsRecoveryStateCard(
        icon: Icons.search_off_outlined,
        title: 'No transaction-like SMS found',
        subtitle: 'Try a wider date range or check your SMS permissions.',
      );
    }
    final visiblePreviews = _visiblePreviews;
    final importableCount = visiblePreviews
        .where((preview) => preview.canImport)
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SmsResultOverview(
          totalCount: _transactionPreviews.length,
          importableCount: _allImportableCount,
          needsSourceCount: _statusCount(
            SmsBackfillPreviewStatus.sourceMissing,
          ),
          duplicateCount: _statusCount(
            SmsBackfillPreviewStatus.duplicateLikely,
          ),
          importedCount: _statusCount(SmsBackfillPreviewStatus.imported),
          ignoredCount:
              _statusCount(SmsBackfillPreviewStatus.ignored) +
              _statusCount(SmsBackfillPreviewStatus.parserFailed) +
              _statusCount(SmsBackfillPreviewStatus.importFailed),
        ),
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
        const SizedBox(height: AppSpacing.sm),
        if (visiblePreviews.isEmpty)
          _SmsRecoveryStateCard(
            icon: Icons.filter_alt_off_outlined,
            title: _emptyTabTitle,
            subtitle: _emptyTabMessage,
          )
        else ...[
          _SmsSelectionToolbar(
            selectedCount: _selectedImportablePreviews.length,
            visibleImportableCount: importableCount,
            totalVisibleCount: visiblePreviews.length,
            label: _statusTabListLabel,
            onSelectAll: importableCount == 0 ? null : _selectVisibleImportable,
            onClear: _selectedIds.isEmpty ? null : _clearSelection,
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

  int get _allImportableCount {
    return (_previews ?? const <SmsBackfillPreview>[])
        .where((preview) => preview.canImport)
        .length;
  }

  int _statusCount(SmsBackfillPreviewStatus status) {
    return (_previews ?? const <SmsBackfillPreview>[])
        .where((preview) => preview.status == status)
        .length;
  }

  String get _emptyTabTitle {
    switch (_statusTab) {
      case _SmsRecoveryStatusTab.ready:
        return 'No importable messages';
      case _SmsRecoveryStatusTab.needsSource:
        return 'No messages need a source';
      case _SmsRecoveryStatusTab.duplicate:
        return 'No duplicates found';
      case _SmsRecoveryStatusTab.ignored:
        return 'No ignored messages';
    }
  }

  String get _emptyTabMessage {
    switch (_statusTab) {
      case _SmsRecoveryStatusTab.ready:
        return 'Change the filter or scan a wider range.';
      case _SmsRecoveryStatusTab.needsSource:
        return 'Parsed messages with missing sources will appear here.';
      case _SmsRecoveryStatusTab.duplicate:
        return 'Messages already imported or likely duplicated will appear here.';
      case _SmsRecoveryStatusTab.ignored:
        return 'Non-transaction and unsupported SMS will appear here.';
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

class _SmsRecoveryIntro extends StatelessWidget {
  const _SmsRecoveryIntro();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recover past SMS', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Scan recent SMS for transaction-like messages. Review everything before anything is added to Finarc.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Icon(Icons.lock_outline, size: 16, color: muted),
            const SizedBox(width: AppSpacing.xxs),
            Expanded(
              child: Text(
                'Processed locally on this device.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: muted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SmsRecoveryStateCard extends StatelessWidget {
  const _SmsRecoveryStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.showProgress = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    return FinarcCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      useShadow: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: showProgress
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation(accent),
                    ),
                  )
                : Icon(icon, color: accent, size: 24),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _SmsResultOverview extends StatelessWidget {
  const _SmsResultOverview({
    required this.totalCount,
    required this.importableCount,
    required this.needsSourceCount,
    required this.duplicateCount,
    required this.importedCount,
    required this.ignoredCount,
  });

  final int totalCount;
  final int importableCount;
  final int needsSourceCount;
  final int duplicateCount;
  final int importedCount;
  final int ignoredCount;

  @override
  Widget build(BuildContext context) {
    final details = <String>[
      '$importableCount importable',
      if (needsSourceCount > 0) '$needsSourceCount need source',
      if (duplicateCount > 0) '$duplicateCount duplicates',
      if (importedCount > 0) '$importedCount imported',
      if (ignoredCount > 0) '$ignoredCount ignored',
    ];

    return FinarcCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      useShadow: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SmsAccentIcon(icon: Icons.fact_check_outlined),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalCount ${totalCount == 1 ? 'message' : 'messages'} found',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  details.join(' • '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmsSelectionToolbar extends StatelessWidget {
  const _SmsSelectionToolbar({
    required this.selectedCount,
    required this.visibleImportableCount,
    required this.totalVisibleCount,
    required this.label,
    required this.onSelectAll,
    required this.onClear,
  });

  final int selectedCount;
  final int visibleImportableCount;
  final int totalVisibleCount;
  final String label;
  final VoidCallback? onSelectAll;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$visibleImportableCount importable of $totalVisibleCount $label',
            style: Theme.of(context).textTheme.labelLarge,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        TextButton(onPressed: onSelectAll, child: const Text('Select all')),
        TextButton(
          onPressed: selectedCount == 0 ? null : onClear,
          child: Text('Clear ($selectedCount)'),
        ),
      ],
    );
  }
}

class _SmsImportActions extends StatelessWidget {
  const _SmsImportActions({
    required this.importing,
    required this.importableCount,
    required this.selectedCount,
    required this.onImportSelected,
    required this.onImportAll,
  });

  final bool importing;
  final int importableCount;
  final int selectedCount;
  final VoidCallback? onImportSelected;
  final VoidCallback? onImportAll;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.45),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 360;
              final selectedButton = FinarcPrimaryButton(
                onPressed: importing ? null : onImportSelected,
                isLoading: importing && selectedCount > 0,
                icon: Icons.playlist_add_check_outlined,
                label: 'Add selected ($selectedCount)',
              );
              final allButton = FinarcSecondaryButton(
                onPressed: importing ? null : onImportAll,
                icon: Icons.download_done_outlined,
                label: 'Add all importable ($importableCount)',
              );

              if (compact) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    selectedButton,
                    const SizedBox(height: AppSpacing.xs),
                    allButton,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: selectedButton),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: allButton),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SmsAccentIcon extends StatelessWidget {
  const _SmsAccentIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(icon, color: accent, size: 21),
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
    required this.previewLabel,
    required this.loading,
    required this.importing,
    required this.sourceFilterKey,
    required this.sourceFilterOptions,
    required this.onRangeChanged,
    required this.onSourceFilterChanged,
    required this.onPickCustomStart,
    required this.onPickCustomEnd,
    required this.onScan,
  });

  final _SmsRecoveryRangePreset rangePreset;
  final DateTime customStart;
  final DateTime customEnd;
  final String previewLabel;
  final bool loading;
  final bool importing;
  final String sourceFilterKey;
  final List<_SmsSourceFilterOption> sourceFilterOptions;
  final ValueChanged<_SmsRecoveryRangePreset?> onRangeChanged;
  final ValueChanged<String?> onSourceFilterChanged;
  final VoidCallback onPickCustomStart;
  final VoidCallback onPickCustomEnd;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return FinarcCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      useShadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SMS range', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          DropdownButtonFormField<_SmsRecoveryRangePreset>(
            initialValue: rangePreset,
            isExpanded: true,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
            ),
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
            label: previewLabel,
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
      padding: const EdgeInsets.all(AppSpacing.sm),
      useShadow: false,
      onTap: onViewMessage,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: preview.canImport
                ? 'Select ${preview.merchant ?? preview.sender}'
                : '${preview.merchant ?? preview.sender} cannot be selected',
            child: Checkbox(
              value: preview.canImport && selected,
              onChanged: onSelectedChanged == null
                  ? null
                  : (value) => onSelectedChanged!(value ?? false),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        preview.merchant ?? preview.sender,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (preview.amount != null) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        inr(preview.amount!),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${_sourceLabel(preview)} • ${_formatShortDate(preview.transactionDate ?? preview.receivedAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _StatusBadge(status: preview.status),
                    Text(
                      preview.reason,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    TextButton.icon(
                      onPressed: onViewMessage,
                      icon: const Icon(Icons.notes_outlined, size: 18),
                      label: const Text('View SMS'),
                    ),
                    if (onEdit != null)
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit'),
                      ),
                    if (onAttachProof != null)
                      TextButton.icon(
                        onPressed: onAttachProof,
                        icon: const Icon(Icons.attachment_outlined, size: 18),
                        label: const Text('Attach proof'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatShortDate(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    final local = value.toLocal();
    return '${two(local.day)}/${two(local.month)}/${local.year}';
  }

  String _sourceLabel(SmsBackfillPreview preview) {
    final parser = preview.parserName ?? 'SMS';
    switch (preview.paymentSourceType) {
      case PaymentSourceType.creditCard:
        return 'Card • $parser';
      case PaymentSourceType.bank:
        return 'Bank • $parser';
      case PaymentSourceType.cash:
        return 'Cash • $parser';
      case PaymentSourceType.upi:
        return 'UPI • $parser';
      default:
        return '${preview.sender} • $parser';
    }
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
          _SmsSheetField(label: 'Amount', value: _amountText(preview)),
          _SmsSheetField(label: 'Merchant', value: preview.merchant ?? '-'),
          _SmsSheetField(
            label: 'Date',
            value: _formatSheetDateTime(
              preview.transactionDate ?? preview.receivedAt,
            ),
          ),
          _SmsSheetField(label: 'Source', value: _sourceText(preview)),
          _SmsSheetField(label: 'Status', value: _statusText(preview.status)),
          const SizedBox(height: AppSpacing.sm),
          Text('Raw SMS', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xxs),
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

  String _amountText(SmsBackfillPreview preview) {
    final amount = preview.amount;
    return amount == null ? '-' : inr(amount);
  }

  String _sourceText(SmsBackfillPreview preview) {
    switch (preview.paymentSourceType) {
      case PaymentSourceType.creditCard:
        return 'Card';
      case PaymentSourceType.bank:
        return 'Bank';
      case PaymentSourceType.cash:
        return 'Cash';
      case PaymentSourceType.upi:
        return 'UPI';
      default:
        return preview.sender;
    }
  }

  String _statusText(SmsBackfillPreviewStatus status) {
    switch (status) {
      case SmsBackfillPreviewStatus.importable:
        return 'Importable';
      case SmsBackfillPreviewStatus.ignored:
        return 'Ignored';
      case SmsBackfillPreviewStatus.parserFailed:
        return 'No parse';
      case SmsBackfillPreviewStatus.sourceMissing:
        return 'Source missing';
      case SmsBackfillPreviewStatus.duplicateLikely:
        return 'Duplicate';
      case SmsBackfillPreviewStatus.imported:
        return 'Imported';
      case SmsBackfillPreviewStatus.importFailed:
        return 'Skipped';
    }
  }
}

class _SmsSheetField extends StatelessWidget {
  const _SmsSheetField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
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
        'Importable',
        FinarcStatusTone.success,
      ),
      SmsBackfillPreviewStatus.ignored => ('Ignored', FinarcStatusTone.neutral),
      SmsBackfillPreviewStatus.parserFailed => (
        'No parse',
        FinarcStatusTone.warning,
      ),
      SmsBackfillPreviewStatus.sourceMissing => (
        'Source missing',
        FinarcStatusTone.warning,
      ),
      SmsBackfillPreviewStatus.duplicateLikely => (
        'Duplicate',
        FinarcStatusTone.warning,
      ),
      SmsBackfillPreviewStatus.imported => ('Imported', FinarcStatusTone.info),
      SmsBackfillPreviewStatus.importFailed => (
        'Skipped',
        FinarcStatusTone.warning,
      ),
    };
    return FinarcStatusBadge(label: label, tone: tone, compact: true);
  }
}
