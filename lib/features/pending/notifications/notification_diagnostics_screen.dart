import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import 'notification_providers.dart';

class NotificationDiagnosticsScreen extends ConsumerWidget {
  const NotificationDiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotState = ref.watch(notificationDiagnosticsSnapshotProvider);
    final listenerAvailable = ref.watch(notificationListenerAvailableProvider);
    final accessGranted = ref.watch(notificationAccessStatusProvider);

    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Notification Diagnostics'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          FinarcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FinarcSectionHeader(title: 'Listener Status'),
                const SizedBox(height: AppSpacing.xs),
                listenerAvailable.when(
                  loading: () =>
                      const Text('Checking listener registration...'),
                  error: (e, _) => Text('Listener check failed: $e'),
                  data: (available) => _statusRow(
                    context,
                    label: 'Listener registered',
                    value: available ? 'YES' : 'NO',
                    ok: available,
                  ),
                ),
                accessGranted.when(
                  loading: () => const Text('Checking Android access...'),
                  error: (e, _) => Text('Access check failed: $e'),
                  data: (enabled) => _statusRow(
                    context,
                    label: 'Android access granted',
                    value: enabled ? 'YES' : 'NO',
                    ok: enabled,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          snapshotState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('Failed to load diagnostics: $error'),
            data: (snapshot) => Column(
              children: [
                FinarcCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FinarcSectionHeader(title: 'Runtime Counters'),
                      const SizedBox(height: AppSpacing.xs),
                      _counterRow(
                        context,
                        'Notifications received',
                        snapshot.received,
                      ),
                      _counterRow(
                        context,
                        'Notifications ignored',
                        snapshot.ignored,
                      ),
                      _counterRow(
                        context,
                        'Notifications parsed',
                        snapshot.parsed,
                      ),
                      _counterRow(
                        context,
                        'Pending transactions created',
                        snapshot.pendingCreated,
                      ),
                      _counterRow(
                        context,
                        'Duplicates blocked',
                        snapshot.duplicatesBlocked,
                      ),
                      _counterRow(
                        context,
                        'Local notifications sent',
                        snapshot.localNotificationsSent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                FinarcCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FinarcSectionHeader(title: 'Last Notification'),
                      const SizedBox(height: AppSpacing.xs),
                      if (snapshot.lastEvent == null)
                        Text(
                          'No notification events captured yet.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      else ...[
                        _line(
                          context,
                          'Package',
                          snapshot.lastEvent!.packageName,
                        ),
                        _line(context, 'Title', snapshot.lastEvent!.title),
                        _line(context, 'Body', snapshot.lastEvent!.bodyPreview),
                        _line(
                          context,
                          'Timestamp',
                          snapshot.lastEvent!.timestamp.toLocal().toString(),
                        ),
                        _line(
                          context,
                          'Parse result',
                          snapshot.lastEvent!.parseResult,
                        ),
                        _line(context, 'Reason', snapshot.lastEvent!.reason),
                        if ((snapshot.lastEvent!.amountCandidate ?? '')
                            .isNotEmpty)
                          _line(
                            context,
                            'Amount candidate',
                            snapshot.lastEvent!.amountCandidate!,
                          ),
                        if ((snapshot.lastEvent!.blockedContext ?? '')
                            .isNotEmpty)
                          _line(
                            context,
                            'Blocked context',
                            snapshot.lastEvent!.blockedContext!,
                          ),
                        _line(
                          context,
                          'Confidence',
                          snapshot.lastEvent!.confidenceLevel ??
                              (snapshot.lastEvent!.confidenceScore
                                      ?.toStringAsFixed(2) ??
                                  '—'),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                FinarcPrimaryButton(
                  onPressed: () async {
                    final ids = await ref
                        .read(notificationTestToolsServiceProvider)
                        .generateTestDetection();
                    ref.invalidate(notificationDiagnosticsSnapshotProvider);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ids.isEmpty
                              ? 'Test detection did not create a pending transaction.'
                              : 'Test detection created ${ids.length} pending transaction(s).',
                        ),
                      ),
                    );
                  },
                  icon: Icons.bolt_rounded,
                  label: 'Generate Test Detection',
                ),
                const SizedBox(height: AppSpacing.xs),
                FinarcSecondaryButton(
                  onPressed: () =>
                      context.push('/notifications/diagnostics/logs'),
                  icon: Icons.list_alt_rounded,
                  label: 'Open Notification Debug Log',
                ),
                const SizedBox(height: AppSpacing.xs),
                FinarcSecondaryButton(
                  onPressed: () async {
                    await ref
                        .read(notificationDiagnosticsServiceProvider)
                        .clear();
                    ref.invalidate(notificationDiagnosticsSnapshotProvider);
                    ref.read(notificationDebugLogProvider.notifier).clear();
                    ref.read(ingestionDiagnosticsProvider.notifier).clear();
                  },
                  icon: Icons.delete_sweep_outlined,
                  label: 'Clear Diagnostics',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusRow(
    BuildContext context, {
    required String label,
    required String value,
    required bool ok,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          FinarcStatusBadge(
            label: value,
            tone: ok ? FinarcStatusTone.success : FinarcStatusTone.warning,
            compact: true,
          ),
        ],
      ),
    );
  }

  Widget _counterRow(BuildContext context, String label, int value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text('$value', style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }

  Widget _line(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
