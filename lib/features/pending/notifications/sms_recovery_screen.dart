import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../accounts/data/accounts_providers.dart';
import '../../cards/data/cards_providers.dart';
import '../../dashboard/data/dashboard_providers.dart';
import '../../expenses/data/expenses_providers.dart';
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

class _SmsRecoveryRange {
  const _SmsRecoveryRange({required this.from, required this.to});

  final DateTime from;
  final DateTime to;
}

class SmsRecoveryScreen extends ConsumerStatefulWidget {
  const SmsRecoveryScreen({super.key});

  @override
  ConsumerState<SmsRecoveryScreen> createState() => _SmsRecoveryScreenState();
}

class _SmsRecoveryScreenState extends ConsumerState<SmsRecoveryScreen> {
  bool _loading = false;
  bool _importing = false;
  _SmsRecoveryRangePreset _rangePreset = _SmsRecoveryRangePreset.days60;
  late DateTime _customStart;
  late DateTime _customEnd;
  List<SmsBackfillPreview>? _previews;
  final Set<String> _selectedIds = {};

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
              selectedCount: _selectedIds.length,
              onRangeChanged: _changeRangePreset,
              onPickCustomStart: () => _pickCustomDate(start: true),
              onPickCustomEnd: () => _pickCustomDate(start: false),
              onScan: _scan,
              onImportSelected: _selectedIds.isEmpty ? null : _importSelected,
              onImportAll: _importablePreviews.isEmpty ? null : _importAll,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildPreviewList(context),
          ],
        ],
      ),
    );
  }

  List<SmsBackfillPreview> get _importablePreviews {
    return (_previews ?? const [])
        .where((preview) => preview.canImport)
        .toList(growable: false);
  }

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
    });
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
    await _import(
      _importablePreviews.where((preview) => _selectedIds.contains(preview.id)),
    );
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
      return const Center(child: CircularProgressIndicator());
    }
    final previews = _previews;
    if (previews == null) {
      return FinarcCard(child: Text('Preview SMS for $_rangeLabel.'));
    }
    if (previews.isEmpty) {
      return FinarcCard(
        child: Text('No SMS messages were found for $_rangeLabel.'),
      );
    }
    final importableCount = previews
        .where((preview) => preview.canImport)
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FinarcSectionHeader(
          title: '$importableCount importable of ${previews.length} SMS',
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final preview in previews) ...[
          _SmsPreviewTile(
            preview: preview,
            selected: _selectedIds.contains(preview.id),
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
    );
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
                  label: 'SMS NOT AVAILABLE IN THIS BUILD',
                  tone: FinarcStatusTone.neutral,
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'Past SMS recovery requires local SMS access and is not available in this build.',
                ),
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
            label: 'SMS NOT AVAILABLE IN THIS BUILD',
            tone: FinarcStatusTone.neutral,
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'SMS recovery is only available in builds with local SMS access.',
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
    required this.onRangeChanged,
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
  final ValueChanged<_SmsRecoveryRangePreset?> onRangeChanged;
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
  });

  final SmsBackfillPreview preview;
  final bool selected;
  final ValueChanged<bool>? onSelectedChanged;

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
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Reason: ${preview.reason}',
                      style: Theme.of(context).textTheme.bodySmall,
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
