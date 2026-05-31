import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import 'notification_providers.dart';

class NotificationDebugLogViewerScreen extends ConsumerWidget {
  const NotificationDebugLogViewerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotState = ref.watch(notificationDiagnosticsSnapshotProvider);
    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Notification Debug Log'),
      body: snapshotState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed to load logs: $error')),
        data: (snapshot) {
          final events = snapshot.events;
          if (events.isEmpty) {
            return const Center(
              child: FinarcEmptyState(
                title: 'No notification events yet',
                subtitle: 'Last 100 notification events will appear here.',
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: events.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
            itemBuilder: (context, index) {
              final event = events[index];
              final title = event.title.trim().isEmpty
                  ? '—'
                  : event.title.trim();
              return FinarcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'received ${event.timestamp.toLocal()}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    if (event.transactionDateChosen != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'tx-date ${event.transactionDateChosen!.toLocal()}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      event.packageName,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      event.bodyPreview,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FinarcStatusBadge(
                          label: event.decision.toUpperCase(),
                          tone: _toneForDecision(event.decision),
                          compact: true,
                        ),
                        FinarcStatusBadge(
                          label: event.reason,
                          tone: FinarcStatusTone.neutral,
                          compact: true,
                        ),
                        if (event.confidenceLevel != null)
                          FinarcStatusBadge(
                            label: event.confidenceLevel!,
                            tone: FinarcStatusTone.info,
                            compact: true,
                          ),
                        if ((event.duplicateDecision ?? '').isNotEmpty)
                          FinarcStatusBadge(
                            label: event.duplicateDecision!,
                            tone: FinarcStatusTone.warning,
                            compact: true,
                          ),
                        if ((event.possibleDuplicateReason ?? '').isNotEmpty)
                          FinarcStatusBadge(
                            label: event.possibleDuplicateReason!,
                            tone: FinarcStatusTone.info,
                            compact: true,
                          ),
                        if ((event.amountCandidate ?? '').isNotEmpty)
                          FinarcStatusBadge(
                            label: 'amount ${event.amountCandidate}',
                            tone: FinarcStatusTone.neutral,
                            compact: true,
                          ),
                        if ((event.blockedContext ?? '').isNotEmpty)
                          FinarcStatusBadge(
                            label: event.blockedContext!,
                            tone: FinarcStatusTone.neutral,
                            compact: true,
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  FinarcStatusTone _toneForDecision(String decision) {
    switch (decision) {
      case 'pending-created':
        return FinarcStatusTone.success;
      case 'duplicate':
        return FinarcStatusTone.warning;
      case 'ignored':
        return FinarcStatusTone.neutral;
      case 'parsed':
        return FinarcStatusTone.info;
      default:
        return FinarcStatusTone.neutral;
    }
  }
}
