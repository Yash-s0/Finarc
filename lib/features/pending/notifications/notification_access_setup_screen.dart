import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import 'notification_providers.dart';

class NotificationAccessSetupScreen extends ConsumerWidget {
  const NotificationAccessSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessState = ref.watch(notificationAccessStatusProvider);
    final smsAccessState = ref.watch(smsPermissionStatusProvider);
    final settingsState = ref.watch(detectionSettingsProvider);
    final debugEntries = ref.watch(notificationDebugLogProvider);

    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Notification Access'),
      body: settingsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
        data: (settings) => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            FinarcCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detect transactions from app notifications',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Finarc reads transaction notifications locally on your device. You review and confirm before any expense is added.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const FinarcStatusBadge(
                    label: 'No cloud sync. Data stays on device.',
                    tone: FinarcStatusTone.info,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FinarcCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FinarcSectionHeader(title: 'Status & Access'),
                  const SizedBox(height: AppSpacing.sm),
                  accessState.when(
                    loading: () => const Text('Checking access...'),
                    error: (e, _) => Text('Error: $e'),
                    data: (hasAccess) => Row(
                      children: [
                        FinarcStatusBadge(
                          label: hasAccess
                              ? 'ACCESS ENABLED'
                              : 'ACCESS NOT ENABLED',
                          tone: hasAccess
                              ? FinarcStatusTone.success
                              : FinarcStatusTone.warning,
                          compact: true,
                        ),
                        const Spacer(),
                        if (!hasAccess)
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.amber,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  FinarcPrimaryButton(
                    onPressed: () async {
                      await ref
                          .read(notificationPermissionServiceProvider)
                          .openAccessSettings();
                      ref.invalidate(notificationAccessStatusProvider);
                    },
                    icon: Icons.settings_outlined,
                    label: 'Open Android Notification Access',
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () =>
                          ref.invalidate(notificationAccessStatusProvider),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Refresh Status'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FinarcCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FinarcSectionHeader(title: 'SMS Detection'),
                  const SizedBox(height: AppSpacing.xs),
                  smsAccessState.when(
                    loading: () => const Text('Checking SMS permission...'),
                    error: (e, _) => Text('Error: $e'),
                    data: (granted) => Row(
                      children: [
                        FinarcStatusBadge(
                          label: granted
                              ? 'SMS ACCESS ENABLED'
                              : 'SMS ACCESS DISABLED',
                          tone: granted
                              ? FinarcStatusTone.success
                              : FinarcStatusTone.warning,
                          compact: true,
                        ),
                        const Spacer(),
                        if (!granted)
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.amber,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _toggleRow(
                    context: context,
                    label: 'SMS detection enabled',
                    value: settings.smsDetectionEnabled,
                    onChanged: (v) => ref
                        .read(detectionSettingsProvider.notifier)
                        .applyChanges(smsDetectionEnabled: v),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: FinarcSecondaryButton(
                          onPressed: () => context.push('/sms/setup'),
                          icon: Icons.sms_outlined,
                          label: 'Open SMS Setup',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(
                        child: FinarcPrimaryButton(
                          onPressed: () async {
                            final days = settings.smsBackfillDays;
                            final count = await ref
                                .read(smsPermissionServiceProvider)
                                .scanRecentSms(days);
                            await ref
                                .read(detectionSettingsProvider.notifier)
                                .applyChanges(
                                  smsLastScannedAt: DateTime.now(),
                                  smsBackfillEnabled: true,
                                );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Queued $count SMS messages for parsing.',
                                ),
                              ),
                            );
                          },
                          icon: Icons.history_toggle_off_outlined,
                          label:
                              'Backfill Last ${settings.smsBackfillDays} Days',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FinarcCard(
              child: Column(
                children: [
                  _toggleRow(
                    context: context,
                    label: 'Detection enabled',
                    value: settings.notificationDetectionEnabled,
                    onChanged: (v) => ref
                        .read(detectionSettingsProvider.notifier)
                        .applyChanges(notificationDetectionEnabled: v),
                  ),
                  _toggleRow(
                    context: context,
                    label: 'Show local detection notifications',
                    value: settings.showDetectionNotifications,
                    onChanged: (v) => ref
                        .read(detectionSettingsProvider.notifier)
                        .applyChanges(showDetectionNotifications: v),
                  ),
                  _toggleRow(
                    context: context,
                    label: 'Reminder system enabled',
                    value: settings.reminderEnabled,
                    onChanged: (v) => ref
                        .read(detectionSettingsProvider.notifier)
                        .applyChanges(reminderEnabled: v),
                  ),
                  _toggleRow(
                    context: context,
                    label: 'Pending transaction reminders',
                    value: settings.pendingTransactionReminderEnabled,
                    onChanged: (v) => ref
                        .read(detectionSettingsProvider.notifier)
                        .applyChanges(pendingTransactionReminderEnabled: v),
                  ),
                  _toggleRow(
                    context: context,
                    label: 'Card due reminders',
                    value: settings.cardDueReminderEnabled,
                    onChanged: (v) => ref
                        .read(detectionSettingsProvider.notifier)
                        .applyChanges(cardDueReminderEnabled: v),
                  ),
                  _toggleRow(
                    context: context,
                    label: 'Daily reminder',
                    value: settings.dailyReminderEnabled,
                    onChanged: (v) => ref
                        .read(detectionSettingsProvider.notifier)
                        .applyChanges(dailyReminderEnabled: v),
                  ),
                  _toggleRow(
                    context: context,
                    label: 'Weekly reminder',
                    value: settings.weeklyReminderEnabled,
                    onChanged: (v) => ref
                        .read(detectionSettingsProvider.notifier)
                        .applyChanges(weeklyReminderEnabled: v),
                  ),
                  _toggleRow(
                    context: context,
                    label: 'Settlement reminders (placeholder)',
                    value: settings.settlementReminderEnabled,
                    onChanged: (v) => ref
                        .read(detectionSettingsProvider.notifier)
                        .applyChanges(settlementReminderEnabled: v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FinarcCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FinarcSectionHeader(title: 'Reminder Time'),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Text(
                        'Time: ${_formatTime(settings.reminderHour, settings.reminderMinute)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Spacer(),
                      FinarcSecondaryButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(
                              hour: settings.reminderHour,
                              minute: settings.reminderMinute,
                            ),
                          );
                          if (picked == null) return;
                          await ref
                              .read(detectionSettingsProvider.notifier)
                              .applyChanges(
                                reminderHour: picked.hour,
                                reminderMinute: picked.minute,
                              );
                        },
                        label: 'Set Time',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Text(
                        'Weekly day: ${_weekdayLabel(settings.weeklyReminderWeekday)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Spacer(),
                      DropdownButton<int>(
                        value: settings.weeklyReminderWeekday,
                        items: const [
                          DropdownMenuItem(
                            value: DateTime.monday,
                            child: Text('Mon'),
                          ),
                          DropdownMenuItem(
                            value: DateTime.tuesday,
                            child: Text('Tue'),
                          ),
                          DropdownMenuItem(
                            value: DateTime.wednesday,
                            child: Text('Wed'),
                          ),
                          DropdownMenuItem(
                            value: DateTime.thursday,
                            child: Text('Thu'),
                          ),
                          DropdownMenuItem(
                            value: DateTime.friday,
                            child: Text('Fri'),
                          ),
                          DropdownMenuItem(
                            value: DateTime.saturday,
                            child: Text('Sat'),
                          ),
                          DropdownMenuItem(
                            value: DateTime.sunday,
                            child: Text('Sun'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          ref
                              .read(detectionSettingsProvider.notifier)
                              .applyChanges(weeklyReminderWeekday: value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: FinarcPrimaryButton(
                          onPressed: () => ref
                              .read(reminderServiceProvider)
                              .showImmediateReminderPreview(),
                          label: 'Send Test Reminder',
                          icon: Icons.notifications_active_outlined,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FinarcCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FinarcSectionHeader(title: 'Debug Log (Last 20)'),
                  const SizedBox(height: AppSpacing.xs),
                  if (debugEntries.isEmpty)
                    Text(
                      'No captured notification events yet.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  else
                    ...debugEntries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                '${entry.packageName} • ${entry.preview}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            FinarcStatusBadge(
                              label: entry.result,
                              tone: entry.result.startsWith('parsed')
                                  ? FinarcStatusTone.success
                                  : FinarcStatusTone.neutral,
                              compact: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FinarcSecondaryButton(
              onPressed: () => Navigator.of(context).pop(),
              label: 'Maybe Later',
            ),
          ],
        ),
      ),
    );
  }

  static Widget _toggleRow({
    required BuildContext context,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  static String _formatTime(int hour, int minute) {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final meridiem = hour >= 12 ? 'PM' : 'AM';
    return '$h:${minute.toString().padLeft(2, '0')} $meridiem';
  }

  static String _weekdayLabel(int value) {
    switch (value) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
      default:
        return 'Sunday';
    }
  }
}
