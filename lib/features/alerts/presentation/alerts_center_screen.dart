import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
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
    final inboxMode = _InboxMode.fromState(
      onlyUnread: onlyUnread,
      includeDismissed: includeDismissed,
    );

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
            onPressed: () => _confirmClearRead(context, ref),
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
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xxl,
          ),
          children: [
            _InboxSegmentedControl(
              mode: inboxMode,
              unreadCount: unreadCount,
              onChanged: (mode) => _setInboxMode(ref, mode),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _TypeFilterButton(
                    label: type == null ? 'All types' : _alertTypeLabel(type),
                    selected: type != null,
                    onTap: () => _showTypeFilterSheet(context, ref, type),
                  ),
                ),
                if (type != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    tooltip: 'Clear type filter',
                    onPressed: () =>
                        ref.read(alertsTypeFilterProvider.notifier).state =
                            null,
                    icon: const Icon(Icons.filter_alt_off_outlined),
                  ),
                ],
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
                    final visibleAlerts = inboxMode == _InboxMode.dismissed
                        ? alerts
                              .where((alert) => alert.dismissedAt != null)
                              .toList(growable: false)
                        : alerts;

                    if (visibleAlerts.isEmpty) {
                      return FinarcEmptyState(
                        title: _emptyTitle(inboxMode, type),
                        subtitle: _emptySubtitle(inboxMode, type),
                        icon: Icons.notifications_none_rounded,
                        actionLabel: type != null ? 'Clear filters' : null,
                        actionIcon: Icons.filter_alt_off_outlined,
                        onAction: type != null
                            ? () =>
                                  ref
                                          .read(
                                            alertsTypeFilterProvider.notifier,
                                          )
                                          .state =
                                      null
                            : null,
                      );
                    }

                    final today = <Alert>[];
                    final yesterday = <Alert>[];
                    final earlier = <Alert>[];
                    final now = DateTime.now();
                    final todayStart = DateTime(now.year, now.month, now.day);
                    final yesterdayStart = todayStart.subtract(
                      const Duration(days: 1),
                    );

                    for (final alert in visibleAlerts) {
                      final created = DateTime(
                        alert.createdAt.year,
                        alert.createdAt.month,
                        alert.createdAt.day,
                      );
                      if (created == todayStart) {
                        today.add(alert);
                      } else if (created == yesterdayStart) {
                        yesterday.add(alert);
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
                        if (yesterday.isNotEmpty) ...[
                          const FinarcSectionHeader(title: 'Yesterday'),
                          const SizedBox(height: AppSpacing.xs),
                          ...yesterday.map((a) => _tile(context, ref, a)),
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
    final tone = _toneForAlert(alert);
    final iconColor = _colorForTone(context, tone);
    final hasRoute =
        alert.actionRoute != null && alert.actionRoute!.trim().isNotEmpty;

    final card = Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: FinarcCard(
        padding: const EdgeInsets.all(12),
        radius: AppRadius.lg,
        useShadow: false,
        backgroundColor: _cardColor(context, isUnread: isUnread),
        borderColor: _borderColor(context, tone: tone, isUnread: isUnread),
        onTap: () async {
          if (isUnread) {
            await ref.read(alertActionsProvider).markRead(alert.id);
          }
          final route = alert.actionRoute;
          if (route != null && route.trim().isNotEmpty && context.mounted) {
            context.push(route);
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 34,
                  width: 34,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    _iconForAlert(alert.alertType),
                    size: 18,
                    color: iconColor,
                  ),
                ),
                if (isUnread)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: iconColor,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _titleForAlert(alert),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: isUnread
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                              ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      FinarcStatusBadge(
                        label: _statusLabelForAlert(alert),
                        tone: tone,
                        compact: true,
                      ),
                    ],
                  ),
                  if (alert.body.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      alert.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        _relativeTime(alert.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (dismissed) ...[
                        const SizedBox(width: AppSpacing.xs),
                        const FinarcStatusBadge(
                          label: 'Dismissed',
                          tone: FinarcStatusTone.neutral,
                          compact: true,
                        ),
                      ],
                      if (hasRoute) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          _actionLabel(alert.alertType),
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (hasRoute)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.xs, top: 2),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.46),
                ),
              )
            else if (!dismissed)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.xs),
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 30,
                    height: 30,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: () =>
                      ref.read(alertActionsProvider).dismiss(alert.id),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  tooltip: 'Dismiss',
                ),
              ),
          ],
        ),
      ),
    );

    if (dismissed) return card;
    return Dismissible(
      key: ValueKey('alert-${alert.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await ref.read(alertActionsProvider).dismiss(alert.id);
        return false;
      },
      background: const SizedBox.shrink(),
      secondaryBackground: _DismissBackground(),
      child: card,
    );
  }

  void _setInboxMode(WidgetRef ref, _InboxMode mode) {
    final unread = ref.read(alertsOnlyUnreadProvider.notifier);
    final dismissed = ref.read(alertsIncludeDismissedProvider.notifier);
    switch (mode) {
      case _InboxMode.all:
        unread.state = false;
        dismissed.state = false;
        break;
      case _InboxMode.unread:
        unread.state = true;
        dismissed.state = false;
        break;
      case _InboxMode.dismissed:
        unread.state = false;
        dismissed.state = true;
        break;
    }
  }

  Future<void> _confirmClearRead(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear read alerts?'),
        content: const Text('Read alerts will be removed from the inbox.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(alertActionsProvider).clearRead();
    }
  }

  Future<void> _showTypeFilterSheet(
    BuildContext context,
    WidgetRef ref,
    String? selected,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
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
                        'Alert type',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          ref.read(alertsTypeFilterProvider.notifier).state =
                              null;
                          Navigator.pop(sheetContext);
                        },
                        child: const Text('All types'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final group in _alertTypeGroups.entries) ...[
                    Text(
                      group.key,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: group.value
                          .map(
                            (value) => FinarcActionChip(
                              label: _alertTypeLabel(value),
                              selected: selected == value,
                              onTap: () {
                                ref
                                        .read(alertsTypeFilterProvider.notifier)
                                        .state =
                                    value;
                                Navigator.pop(sheetContext);
                              },
                            ),
                          )
                          .toList(growable: false),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static const _alertTypeGroups = {
    'Transactions': [
      AlertType.pendingTransaction,
      AlertType.largeExpense,
      AlertType.unusualSpending,
    ],
    'Bills & payments': [
      AlertType.cardDue,
      AlertType.emiDue,
      AlertType.splitSettlement,
      AlertType.lowBalance,
    ],
    'Insights': [
      AlertType.recurringMerchant,
      AlertType.weeklySummary,
      AlertType.monthlySummary,
    ],
    'General': [AlertType.reminder, AlertType.info],
  };

  static String _alertTypeLabel(String? type) {
    switch (type) {
      case AlertType.pendingTransaction:
        return 'Pending transactions';
      case AlertType.cardDue:
        return 'Card bills';
      case AlertType.emiDue:
        return 'EMI reminders';
      case AlertType.splitSettlement:
        return 'Split settlements';
      case AlertType.lowBalance:
        return 'Low balance';
      case AlertType.unusualSpending:
        return 'Unusual spending';
      case AlertType.recurringMerchant:
        return 'Recurring payments';
      case AlertType.largeExpense:
        return 'Large expenses';
      case AlertType.weeklySummary:
        return 'Weekly summary';
      case AlertType.monthlySummary:
        return 'Monthly summary';
      case AlertType.reminder:
        return 'Reminders';
      case AlertType.info:
        return 'Information';
      default:
        return 'Alert';
    }
  }

  static String _titleForAlert(Alert alert) {
    if (alert.alertType == AlertType.pendingTransaction) {
      return 'Transaction detected';
    }
    return alert.title.trim().isEmpty
        ? _alertTypeLabel(alert.alertType)
        : alert.title;
  }

  static String _statusLabelForAlert(Alert alert) {
    if (alert.priority == 'critical') return 'Urgent';
    if (alert.priority == 'warning') return 'Warning';
    if (alert.alertType == AlertType.reminder) return 'Reminder';
    return 'Info';
  }

  static String _actionLabel(String type) {
    switch (type) {
      case AlertType.pendingTransaction:
        return 'Review';
      case AlertType.cardDue:
        return 'View card';
      case AlertType.emiDue:
        return 'View EMI';
      case AlertType.splitSettlement:
        return 'View split';
      case AlertType.lowBalance:
        return 'View account';
      case AlertType.weeklySummary:
      case AlertType.monthlySummary:
      case AlertType.recurringMerchant:
      case AlertType.unusualSpending:
      case AlertType.largeExpense:
        return 'View insights';
      default:
        return 'Open';
    }
  }

  static IconData _iconForAlert(String type) {
    switch (type) {
      case AlertType.pendingTransaction:
        return Icons.receipt_long_rounded;
      case AlertType.cardDue:
        return Icons.credit_card_rounded;
      case AlertType.emiDue:
        return Icons.event_available_rounded;
      case AlertType.splitSettlement:
        return Icons.call_split_rounded;
      case AlertType.lowBalance:
        return Icons.account_balance_wallet_rounded;
      case AlertType.unusualSpending:
        return Icons.query_stats_rounded;
      case AlertType.recurringMerchant:
        return Icons.repeat_rounded;
      case AlertType.largeExpense:
        return Icons.trending_up_rounded;
      case AlertType.weeklySummary:
      case AlertType.monthlySummary:
        return Icons.bar_chart_rounded;
      case AlertType.reminder:
        return Icons.notifications_active_rounded;
      case AlertType.info:
      default:
        return Icons.info_outline_rounded;
    }
  }

  static FinarcStatusTone _toneForAlert(Alert alert) {
    if (alert.priority == 'critical') return FinarcStatusTone.error;
    if (alert.priority == 'warning') return FinarcStatusTone.warning;
    if (alert.alertType == AlertType.lowBalance ||
        alert.alertType == AlertType.cardDue ||
        alert.alertType == AlertType.emiDue ||
        alert.alertType == AlertType.reminder) {
      return FinarcStatusTone.warning;
    }
    return FinarcStatusTone.info;
  }

  Color _colorForTone(BuildContext context, FinarcStatusTone tone) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (tone) {
      FinarcStatusTone.error =>
        isDark ? AppColors.darkError : AppColors.lightError,
      FinarcStatusTone.warning =>
        isDark ? AppColors.darkWarning : AppColors.lightWarning,
      FinarcStatusTone.success =>
        isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
      FinarcStatusTone.info =>
        isDark ? AppColors.darkAccent : AppColors.lightAccent,
      FinarcStatusTone.neutral =>
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
    };
  }

  Color _cardColor(BuildContext context, {required bool isUnread}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!isUnread) {
      return isDark ? AppColors.darkSurfaceLow : AppColors.lightSurface;
    }
    return isDark
        ? AppColors.darkSurfaceHigh.withValues(alpha: 0.78)
        : AppColors.lightSurface;
  }

  Color _borderColor(
    BuildContext context, {
    required FinarcStatusTone tone,
    required bool isUnread,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!isUnread) return isDark ? AppColors.darkBorder : AppColors.lightBorder;
    return _colorForTone(context, tone).withValues(alpha: 0.28);
  }

  static String _emptyTitle(_InboxMode mode, String? type) {
    if (type != null) return 'No alerts match these filters';
    return switch (mode) {
      _InboxMode.unread => 'No unread alerts',
      _InboxMode.dismissed => 'No dismissed alerts',
      _InboxMode.all => "You're all caught up",
    };
  }

  static String _emptySubtitle(_InboxMode mode, String? type) {
    if (type != null) return 'Clear filters to review more alerts.';
    return switch (mode) {
      _InboxMode.unread => 'No unread alerts need your attention right now.',
      _InboxMode.dismissed => 'Dismissed alerts will appear here.',
      _InboxMode.all => 'No alerts to review right now.',
    };
  }

  String _relativeTime(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

enum _InboxMode {
  all,
  unread,
  dismissed;

  static _InboxMode fromState({
    required bool onlyUnread,
    required bool includeDismissed,
  }) {
    if (onlyUnread) return _InboxMode.unread;
    if (includeDismissed) return _InboxMode.dismissed;
    return _InboxMode.all;
  }
}

class _InboxSegmentedControl extends StatelessWidget {
  const _InboxSegmentedControl({
    required this.mode,
    required this.unreadCount,
    required this.onChanged,
  });

  final _InboxMode mode;
  final int unreadCount;
  final ValueChanged<_InboxMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceLow : AppColors.lightSurfaceHigh,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          _segment(context, _InboxMode.all, 'All'),
          _segment(context, _InboxMode.unread, 'Unread $unreadCount'),
          _segment(context, _InboxMode.dismissed, 'Dismissed'),
        ],
      ),
    );
  }

  Widget _segment(BuildContext context, _InboxMode value, String label) {
    final selected = value == mode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected
                  ? Colors.white
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.78),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeFilterButton extends StatelessWidget {
  const _TypeFilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? (isDark
                      ? AppColors.darkPrimarySoft
                      : AppColors.lightPrimarySoft)
                : (isDark
                      ? AppColors.darkSurfaceLow
                      : AppColors.lightSurfaceHigh),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.45)
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.category_outlined, size: 18, color: accent),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _DismissBackground extends StatelessWidget {
  const _DismissBackground();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkWarning
        : AppColors.lightWarning;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: ColoredBox(
          color: color.withValues(alpha: 0.2),
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.archive_outlined, color: color),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Dismiss',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
