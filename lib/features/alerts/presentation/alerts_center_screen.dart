import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../data/alert_types.dart';
import '../data/alerts_providers.dart';

class AlertsCenterScreen extends ConsumerWidget {
  const AlertsCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onlyUnread = ref.watch(alertsOnlyUnreadProvider);
    final includeDismissed = ref.watch(alertsIncludeDismissedProvider);
    final type = ref.watch(alertsTypeFilterProvider);
    final unreadCount = ref.watch(alertsUnreadCountProvider).valueOrNull ?? 0;

    return FinarcScaffold(
      appBar: FinarcAppBar(
        title: 'Alerts Center',
        actions: [
          IconButton(
            onPressed: () => ref.read(alertActionsProvider).markAllRead(),
            icon: const Icon(Icons.drafts_outlined),
            tooltip: 'Mark all read',
          ),
          IconButton(
            onPressed: () => ref.read(alertActionsProvider).clearRead(),
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear all read',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(alertsInboxProvider);
          ref.invalidate(alertsUnreadCountProvider);
          await ref.read(alertsInboxProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Unread alerts: $unreadCount',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                FinarcStatusBadge(
                  label: onlyUnread ? 'UNREAD' : 'ALL',
                  tone: onlyUnread
                      ? FinarcStatusTone.warning
                      : FinarcStatusTone.neutral,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FinarcActionChip(
                  label: 'Unread',
                  selected: onlyUnread,
                  onTap: () =>
                      ref.read(alertsOnlyUnreadProvider.notifier).state =
                          !onlyUnread,
                ),
                FinarcActionChip(
                  label: 'Dismissed',
                  selected: includeDismissed,
                  onTap: () =>
                      ref.read(alertsIncludeDismissedProvider.notifier).state =
                          !includeDismissed,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FinarcActionChip(
                  label: 'All Types',
                  selected: type == null,
                  onTap: () =>
                      ref.read(alertsTypeFilterProvider.notifier).state = null,
                ),
                ...AlertType.all.map(
                  (value) => FinarcActionChip(
                    label: value,
                    selected: type == value,
                    onTap: () =>
                        ref.read(alertsTypeFilterProvider.notifier).state =
                            value,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ref
                .watch(alertsInboxProvider)
                .when(
                  loading: () => Column(
                    children: const [
                      FinarcLoadingSkeleton(height: 84),
                      SizedBox(height: AppSpacing.xs),
                      FinarcLoadingSkeleton(height: 84),
                    ],
                  ),
                  error: (e, _) => FinarcEmptyState(
                    title: 'Unable to load alerts',
                    subtitle: '$e',
                    icon: Icons.error_outline,
                  ),
                  data: (alerts) {
                    if (alerts.isEmpty) {
                      return FinarcEmptyState(
                        title: 'No alerts yet',
                        subtitle:
                            'Financial alerts and reminders will appear here.',
                        icon: Icons.notifications_none_rounded,
                      );
                    }

                    final today = <Alert>[];
                    final earlier = <Alert>[];
                    final now = DateTime.now();
                    final todayStart = DateTime(now.year, now.month, now.day);

                    for (final alert in alerts) {
                      final created = DateTime(
                        alert.createdAt.year,
                        alert.createdAt.month,
                        alert.createdAt.day,
                      );
                      if (created == todayStart) {
                        today.add(alert);
                      } else {
                        earlier.add(alert);
                      }
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (today.isNotEmpty) ...[
                          const FinarcSectionHeader(title: 'Today'),
                          const SizedBox(height: AppSpacing.xs),
                          ...today.map((a) => _tile(context, ref, a)),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        if (earlier.isNotEmpty) ...[
                          const FinarcSectionHeader(title: 'Earlier'),
                          const SizedBox(height: AppSpacing.xs),
                          ...earlier.map((a) => _tile(context, ref, a)),
                        ],
                      ],
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, WidgetRef ref, Alert alert) {
    final isUnread = alert.readAt == null;
    final dismissed = alert.dismissedAt != null;
    final tone = switch (alert.priority) {
      'critical' => FinarcStatusTone.error,
      'warning' => FinarcStatusTone.warning,
      _ => FinarcStatusTone.info,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: FinarcCard(
        onTap: () async {
          if (isUnread) {
            await ref.read(alertActionsProvider).markRead(alert.id);
          }
          final route = alert.actionRoute;
          if (route != null && route.trim().isNotEmpty && context.mounted) {
            context.push(route);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    alert.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                FinarcStatusBadge(
                  label: alert.priority.toUpperCase(),
                  tone: tone,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(alert.body, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Text(
                  _relativeTime(alert.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: AppSpacing.xs),
                if (isUnread)
                  const FinarcStatusBadge(
                    label: 'UNREAD',
                    tone: FinarcStatusTone.warning,
                    compact: true,
                  ),
                if (dismissed)
                  const FinarcStatusBadge(
                    label: 'DISMISSED',
                    tone: FinarcStatusTone.neutral,
                    compact: true,
                  ),
                const Spacer(),
                IconButton(
                  onPressed: () =>
                      ref.read(alertActionsProvider).dismiss(alert.id),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  tooltip: 'Dismiss',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
