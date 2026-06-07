import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import 'notification_providers.dart';
import 'notification_permission_service.dart';

final _notificationPermissionServiceProvider =
    Provider<NotificationPermissionService>((ref) {
      return NotificationPermissionService();
    });

final _notificationAccessStateProvider = FutureProvider<bool>((ref) async {
  return ref.read(_notificationPermissionServiceProvider).isAccessEnabled();
});

final _notificationListenerAvailableStateProvider = FutureProvider<bool>((
  ref,
) async {
  return ref
      .read(_notificationPermissionServiceProvider)
      .isListenerComponentAvailable();
});

class NotificationAccessSetupScreenSafe extends ConsumerWidget {
  const NotificationAccessSetupScreenSafe({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessState = ref.watch(_notificationAccessStateProvider);
    final availableState = ref.watch(
      _notificationListenerAvailableStateProvider,
    );
    final settingsState = ref.watch(detectionSettingsProvider);

    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Notification Access'),
      body: ListView(
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
                  'Finarc only checks selected financial notifications and creates pending transactions for your confirmation. Chat and social apps are ignored.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Bank and card issuer notifications stay enabled separately.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                const FinarcStatusBadge(
                  label: 'SMS is unavailable in this build.',
                  tone: FinarcStatusTone.neutral,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FinarcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FinarcSectionHeader(title: 'Financial App Sources'),
                const SizedBox(height: AppSpacing.sm),
                settingsState.when(
                  loading: () => const Text('Loading notification settings...'),
                  error: (e, _) => Text('Settings error: $e'),
                  data: (settings) => Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'UPI/payment app notifications',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              'UPI/payment app notifications can improve detection but may create duplicates. You can turn them off anytime.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Switch.adaptive(
                        value: settings.paymentAppNotificationsEnabled,
                        onChanged: (value) => ref
                            .read(detectionSettingsProvider.notifier)
                            .applyChanges(
                              paymentAppNotificationsEnabled: value,
                            ),
                      ),
                    ],
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
                const FinarcSectionHeader(title: 'Status & Access'),
                const SizedBox(height: AppSpacing.sm),
                availableState.when(
                  loading: () =>
                      const Text('Checking listener availability...'),
                  error: (e, _) => Text('Listener status error: $e'),
                  data: (available) => FinarcStatusBadge(
                    label: available
                        ? 'NOTIFICATION LISTENER AVAILABLE'
                        : 'NOTIFICATION LISTENER UNAVAILABLE',
                    tone: available
                        ? FinarcStatusTone.success
                        : FinarcStatusTone.warning,
                    compact: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                accessState.when(
                  loading: () => const Text('Checking access...'),
                  error: (e, _) => Text('Access error: $e'),
                  data: (enabled) => FinarcStatusBadge(
                    label: enabled
                        ? 'NOTIFICATION ACCESS ENABLED'
                        : 'NOTIFICATION ACCESS DISABLED',
                    tone: enabled
                        ? FinarcStatusTone.success
                        : FinarcStatusTone.warning,
                    compact: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                FinarcPrimaryButton(
                  onPressed: () async {
                    await ref
                        .read(_notificationPermissionServiceProvider)
                        .openAccessSettings();
                    ref.invalidate(_notificationAccessStateProvider);
                    ref.invalidate(_notificationListenerAvailableStateProvider);
                  },
                  icon: Icons.settings_outlined,
                  label: 'Open Android Notification Access',
                ),
                const SizedBox(height: AppSpacing.xs),
                FinarcSecondaryButton(
                  onPressed: () {
                    ref.invalidate(_notificationAccessStateProvider);
                    ref.invalidate(_notificationListenerAvailableStateProvider);
                  },
                  icon: Icons.refresh,
                  label: 'Refresh Status',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
