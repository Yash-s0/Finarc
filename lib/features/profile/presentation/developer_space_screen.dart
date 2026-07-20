import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../pending/notifications/missed_message_sample_service.dart';
import '../../pending/notifications/notification_providers.dart';

class DeveloperSpaceScreen extends ConsumerStatefulWidget {
  const DeveloperSpaceScreen({super.key});

  @override
  ConsumerState<DeveloperSpaceScreen> createState() =>
      _DeveloperSpaceScreenState();
}

class _DeveloperSpaceScreenState extends ConsumerState<DeveloperSpaceScreen> {
  MissedMessageSampleFilter _filter = MissedMessageSampleFilter.all;

  @override
  Widget build(BuildContext context) {
    final samples = ref.watch(missedMessageSamplesProvider(_filter));
    final counts = ref.watch(missedMessageSampleCountsProvider).valueOrNull;

    return FinarcScaffold(
      appBar: FinarcAppBar(
        title: 'Developer Space',
        actions: [
          IconButton(
            tooltip: 'Export missed samples',
            icon: const Icon(Icons.ios_share_outlined),
            onPressed: () => _exportSamples(context),
          ),
          IconButton(
            tooltip: 'Clear debug messages',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () => _clearSamples(context),
          ),
        ],
      ),
      body: samples.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: FinarcEmptyState(
              title: 'Unable to load samples',
              subtitle: '$error',
            ),
          ),
        ),
        data: (rows) => _SampleList(
          rows: rows,
          selectedFilter: _filter,
          counts: counts ?? const <MissedMessageSampleFilter, int>{},
          onFilterChanged: (filter) => setState(() => _filter = filter),
        ),
      ),
    );
  }

  Future<void> _clearSamples(BuildContext context) async {
    ref.read(notificationDebugLogProvider.notifier).clear();
    ref.read(ingestionDiagnosticsProvider.notifier).clear();
    await ref.read(notificationDiagnosticsServiceProvider).clear();
    await ref.read(missedMessageSampleServiceProvider).clearSamples();
    ref.invalidate(notificationDiagnosticsSnapshotProvider);
    ref.invalidate(missedMessageSamplesProvider);
    ref.invalidate(missedMessageSampleCountsProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Developer samples cleared.')));
  }

  Future<void> _exportSamples(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Export missed samples?'),
        content: const Text(
          'This export can include raw financial message text. Keep the file private and delete it when you are done debugging.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Export'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final file = await ref
          .read(missedMessageSampleServiceProvider)
          .exportSamplesJsonl();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Missed samples exported to ${file.path}.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Missed sample export failed: $error')),
      );
    }
  }
}

class _SampleList extends StatelessWidget {
  const _SampleList({
    required this.rows,
    required this.selectedFilter,
    required this.counts,
    required this.onFilterChanged,
  });

  final List<MissedMessageSample> rows;
  final MissedMessageSampleFilter selectedFilter;
  final Map<MissedMessageSampleFilter, int> counts;
  final ValueChanged<MissedMessageSampleFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: rows.length + 1,
      separatorBuilder: (_, index) => index == 0
          ? const SizedBox(height: AppSpacing.md)
          : const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _FilterHeader(
            selectedFilter: selectedFilter,
            counts: counts,
            onFilterChanged: onFilterChanged,
            isEmpty: rows.isEmpty,
          );
        }
        return _DeveloperSampleCard(sample: rows[index - 1]);
      },
    );
  }
}

class _FilterHeader extends StatelessWidget {
  const _FilterHeader({
    required this.selectedFilter,
    required this.counts,
    required this.onFilterChanged,
    required this.isEmpty,
  });

  final MissedMessageSampleFilter selectedFilter;
  final Map<MissedMessageSampleFilter, int> counts;
  final ValueChanged<MissedMessageSampleFilter> onFilterChanged;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final filter in MissedMessageSampleFilter.values)
              ChoiceChip(
                label: Text('${filter.label} ${counts[filter] ?? 0}'),
                selected: selectedFilter == filter,
                onSelected: (_) => onFilterChanged(filter),
              ),
          ],
        ),
        if (isEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          FinarcEmptyState(
            title: _emptyTitle,
            subtitle:
                'Missed, duplicate, ignored, low-confidence, and manual paste samples saved for this filter will appear here.',
          ),
        ],
      ],
    );
  }

  String get _emptyTitle {
    return selectedFilter == MissedMessageSampleFilter.all
        ? 'No missed samples yet'
        : 'No ${selectedFilter.label.toLowerCase()} samples yet';
  }
}

class _DeveloperSampleCard extends StatelessWidget {
  const _DeveloperSampleCard({required this.sample});

  final MissedMessageSample sample;

  @override
  Widget build(BuildContext context) {
    return FinarcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sample.title?.trim().isNotEmpty == true
                          ? sample.title!
                          : sample.packageName,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${sample.packageName} • ${_formatTime(sample.lastSeenAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              FinarcStatusBadge(
                label: _typeLabel.toUpperCase(),
                tone: _tone,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (sample.sampleText.trim().isNotEmpty) ...[
            SelectableText(
              sample.sampleText,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          _MetaLine(label: 'Reason', value: sample.reason),
          _MetaLine(label: 'Parse', value: sample.parseResult),
          _MetaLine(label: 'Decision', value: sample.decision),
          if (sample.seenCount > 1)
            _MetaLine(label: 'Seen', value: '${sample.seenCount} times'),
          if (sample.candidateCount != null)
            _MetaLine(label: 'Candidates', value: '${sample.candidateCount}'),
          if (sample.confidenceLevel != null)
            _MetaLine(
              label: 'Confidence',
              value: '${sample.confidenceLevel} $_confidenceScore',
            ),
          if (sample.amountCandidate != null)
            _MetaLine(label: 'Amount hint', value: sample.amountCandidate!),
          if (sample.blockedContext != null)
            _MetaLine(label: 'Blocked context', value: sample.blockedContext!),
          if (sample.duplicateDecision != null)
            _MetaLine(label: 'Duplicate', value: sample.duplicateDecision!),
          if (sample.possibleDuplicateReason != null)
            _MetaLine(
              label: 'Possible duplicate',
              value: sample.possibleDuplicateReason!,
            ),
          if (sample.transactionDateChosen != null)
            _MetaLine(
              label: 'Transaction date',
              value: _formatTime(sample.transactionDateChosen!),
            ),
        ],
      ),
    );
  }

  IconData get _icon {
    return switch (sample.sampleType) {
      'bill_due' => Icons.receipt_long_outlined,
      'card_payment' => Icons.credit_card_outlined,
      'wallet_balance' => Icons.account_balance_wallet_outlined,
      'manual_paste' => Icons.content_paste_search_outlined,
      _ => Icons.rule_folder_outlined,
    };
  }

  String get _typeLabel {
    return switch (sample.sampleType) {
      'bill_due' => 'Bill due',
      'card_payment' => 'Card payment',
      'wallet_balance' => 'Wallet',
      'manual_paste' => 'Manual paste',
      _ => 'Parser failed',
    };
  }

  FinarcStatusTone get _tone {
    return switch (sample.sampleType) {
      'bill_due' => FinarcStatusTone.info,
      'card_payment' => FinarcStatusTone.info,
      'wallet_balance' => FinarcStatusTone.success,
      'manual_paste' => FinarcStatusTone.warning,
      _ => FinarcStatusTone.neutral,
    };
  }

  String get _confidenceScore {
    final score = sample.confidenceScore;
    if (score == null) return '';
    return '(${score.toStringAsFixed(2)})';
  }

  String _formatTime(DateTime value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    final mo = value.month.toString().padLeft(2, '0');
    return '$d/$mo/${value.year} $h:$m';
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxs),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
