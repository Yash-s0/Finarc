import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../pending/notifications/notification_diagnostics_service.dart';
import '../../pending/notifications/notification_ingestion_service.dart';
import '../../pending/notifications/notification_providers.dart';

class DeveloperSpaceScreen extends ConsumerWidget {
  const DeveloperSpaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoryEntries = ref
        .watch(notificationDebugLogProvider)
        .where(_isDebuggableMiss)
        .toList(growable: false);
    final snapshot = ref.watch(notificationDiagnosticsSnapshotProvider);
    final persistedEntries =
        snapshot.valueOrNull?.events
            .map(_entryFromEvent)
            .where(_isDebuggableMiss)
            .toList(growable: false) ??
        const <NotificationDebugEntry>[];
    final entries = _mergeEntries(persistedEntries, memoryEntries);

    return FinarcScaffold(
      appBar: FinarcAppBar(
        title: 'Developer Space',
        actions: [
          IconButton(
            tooltip: 'Clear debug messages',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () async {
              ref.read(notificationDebugLogProvider.notifier).clear();
              ref.read(ingestionDiagnosticsProvider.notifier).clear();
              await ref.read(notificationDiagnosticsServiceProvider).clear();
              ref.invalidate(notificationDiagnosticsSnapshotProvider);
            },
          ),
        ],
      ),
      body: snapshot.isLoading && entries.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : entries.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: FinarcEmptyState(
                  title: 'No missed messages yet',
                  subtitle:
                      'Ignored, duplicate, failed-parse, and low-confidence notification decisions will appear here.',
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                return _DeveloperMessageCard(entry: entries[index]);
              },
            ),
    );
  }

  bool _isDebuggableMiss(NotificationDebugEntry entry) {
    if (entry.decision == 'pending-created') return false;
    if (entry.decision == 'ignored' || entry.decision == 'duplicate') {
      return true;
    }
    return entry.reason == 'parser-no-candidate' ||
        entry.reason == 'confidence-low' ||
        entry.parseResult == 'parser-failed' ||
        entry.parseResult == 'parsed-low-confidence';
  }

  List<NotificationDebugEntry> _mergeEntries(
    List<NotificationDebugEntry> persisted,
    List<NotificationDebugEntry> memory,
  ) {
    final seen = <String>{};
    final merged = <NotificationDebugEntry>[];
    for (final entry in [...memory, ...persisted]) {
      final key = [
        entry.receivedAt.toIso8601String(),
        entry.packageName,
        entry.decision,
        entry.reason,
        entry.bodyPreview,
      ].join('|');
      if (seen.add(key)) merged.add(entry);
    }
    merged.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    return merged.take(100).toList(growable: false);
  }

  NotificationDebugEntry _entryFromEvent(NotificationDiagnosticsEvent event) {
    return NotificationDebugEntry(
      receivedAt: event.timestamp,
      packageName: event.packageName,
      title: event.title,
      bodyPreview: event.bodyPreview,
      decision: event.decision,
      reason: event.reason,
      parseResult: event.parseResult,
      result: event.parseResult,
      providerName: event.providerName,
      confidenceScore: event.confidenceScore,
      confidenceLevel: event.confidenceLevel,
      localNotificationSent: event.localNotificationSent,
      sender: event.sender,
      senderFilterResult: event.senderFilterResult,
      candidateCount: event.candidateCount,
      duplicateDecision: event.duplicateDecision,
      possibleDuplicateReason: event.possibleDuplicateReason,
      amountCandidate: event.amountCandidate,
      blockedContext: event.blockedContext,
      receivedAtUsed: event.receivedAtUsed,
      transactionDateChosen: event.transactionDateChosen,
    );
  }
}

class _DeveloperMessageCard extends StatelessWidget {
  const _DeveloperMessageCard({required this.entry});

  final NotificationDebugEntry entry;

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
                      entry.title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${entry.packageName} • ${_formatTime(entry.receivedAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              FinarcStatusBadge(
                label: entry.decision.toUpperCase(),
                tone: _tone,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (entry.bodyPreview.trim().isNotEmpty) ...[
            SelectableText(
              entry.bodyPreview,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          _MetaLine(label: 'Reason', value: entry.reason),
          _MetaLine(label: 'Parse', value: entry.parseResult ?? entry.result),
          if (entry.candidateCount != null)
            _MetaLine(label: 'Candidates', value: '${entry.candidateCount}'),
          if (entry.confidenceLevel != null)
            _MetaLine(
              label: 'Confidence',
              value: '${entry.confidenceLevel} $_confidenceScore',
            ),
          if (entry.senderFilterResult != null)
            _MetaLine(label: 'Sender filter', value: entry.senderFilterResult!),
          if (entry.duplicateDecision != null)
            _MetaLine(label: 'Duplicate', value: entry.duplicateDecision!),
          if (entry.possibleDuplicateReason != null)
            _MetaLine(
              label: 'Possible duplicate',
              value: entry.possibleDuplicateReason!,
            ),
          if (entry.transactionDateChosen != null)
            _MetaLine(
              label: 'Transaction date',
              value: _formatTime(entry.transactionDateChosen!),
            ),
        ],
      ),
    );
  }

  IconData get _icon {
    return switch (entry.decision) {
      'ignored' => Icons.block_outlined,
      'duplicate' => Icons.copy_all_outlined,
      _ => Icons.rule_folder_outlined,
    };
  }

  FinarcStatusTone get _tone {
    return switch (entry.decision) {
      'ignored' => FinarcStatusTone.warning,
      'duplicate' => FinarcStatusTone.info,
      _ => FinarcStatusTone.neutral,
    };
  }

  String get _confidenceScore {
    final score = entry.confidenceScore;
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
