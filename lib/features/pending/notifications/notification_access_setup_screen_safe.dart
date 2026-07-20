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

final _postNotificationsPermissionStateProvider = FutureProvider<bool>((
  ref,
) async {
  return ref
      .read(_notificationPermissionServiceProvider)
      .isPostNotificationsGranted();
});

class NotificationAccessSetupScreenSafe extends ConsumerWidget {
  const NotificationAccessSetupScreenSafe({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessState = ref.watch(_notificationAccessStateProvider);
    final availableState = ref.watch(
      _notificationListenerAvailableStateProvider,
    );
    final postNotificationsState = ref.watch(
      _postNotificationsPermissionStateProvider,
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
                  'Android access required',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Android keeps notification listener access inside system Settings. Finarc opens that page so you can choose whether to allow local financial notification detection.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
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
                const SizedBox(height: AppSpacing.xs),
                postNotificationsState.when(
                  loading: () => const Text(
                    'Checking Finarc app notification permission...',
                  ),
                  error: (e, _) => Text('Permission error: $e'),
                  data: (enabled) => FinarcStatusBadge(
                    label: enabled
                        ? 'FINARC APP NOTIFICATIONS ALLOWED'
                        : 'FINARC APP NOTIFICATIONS BLOCKED',
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
                    ref.invalidate(_postNotificationsPermissionStateProvider);
                  },
                  icon: Icons.settings_outlined,
                  label: 'Open Android Settings',
                ),
                const SizedBox(height: AppSpacing.xs),
                FinarcSecondaryButton(
                  onPressed: () async {
                    await ref
                        .read(_notificationPermissionServiceProvider)
                        .requestPostNotificationsPermission();
                    ref.invalidate(_postNotificationsPermissionStateProvider);
                  },
                  icon: Icons.notifications_active_outlined,
                  label: 'Allow Finarc App Notifications',
                ),
                const SizedBox(height: AppSpacing.xs),
                FinarcSecondaryButton(
                  onPressed: () {
                    ref.invalidate(_notificationAccessStateProvider);
                    ref.invalidate(_notificationListenerAvailableStateProvider);
                    ref.invalidate(_postNotificationsPermissionStateProvider);
                  },
                  icon: Icons.refresh,
                  label: 'Refresh Status',
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
                  data: (settings) => Column(
                    children: [
                      _toggleRow(
                        context: context,
                        label: 'Detection enabled',
                        value: settings.notificationDetectionEnabled,
                        onChanged: (value) async {
                          final hasAccess = await ref.read(
                            _notificationAccessStateProvider.future,
                          );
                          if (value && !hasAccess) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Enable Android notification access before turning on detection.',
                                ),
                              ),
                            );
                            return;
                          }
                          await ref
                              .read(detectionSettingsProvider.notifier)
                              .applyChanges(
                                notificationDetectionEnabled: value,
                              );
                        },
                      ),
                      _toggleRow(
                        context: context,
                        label: 'Show local detection notifications',
                        value: settings.showDetectionNotifications,
                        onChanged: (value) => ref
                            .read(detectionSettingsProvider.notifier)
                            .applyChanges(showDetectionNotifications: value),
                      ),
                      _toggleRow(
                        context: context,
                        label: 'UPI/payment app notifications',
                        value: settings.paymentAppNotificationsEnabled,
                        onChanged: (value) => ref
                            .read(detectionSettingsProvider.notifier)
                            .applyChanges(
                              paymentAppNotificationsEnabled: value,
                            ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.sm,
                          right: AppSpacing.sm,
                          bottom: AppSpacing.xs,
                        ),
                        child: Text(
                          'UPI/payment app notifications can improve detection but may create duplicates. Turn this on if you expect Google Pay, PhonePe, Paytm, Amazon Pay, or CRED app notifications to be parsed.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleRow({
    required BuildContext context,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: onChanged,
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
