import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import 'notification_permission_service.dart';
import 'notification_providers.dart';

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
    final hasNotificationAccess = accessState.valueOrNull ?? false;

    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Notification Access'),
      body: settingsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Settings error: $e')),
        data: (settings) => LayoutBuilder(
          builder: (context, constraints) {
            final statusCard = _NotificationStatusCard(
              isReady: hasNotificationAccess,
              listenerAvailable: availableState,
              accessState: accessState,
              postNotifications: postNotificationsState,
              onOpenSettings: () async {
                await ref
                    .read(_notificationPermissionServiceProvider)
                    .openAccessSettings();
                _refreshAccessState(ref);
              },
              onAllowNotifications: postNotificationsState.valueOrNull == false
                  ? () async {
                      await ref
                          .read(_notificationPermissionServiceProvider)
                          .requestPostNotificationsPermission();
                      _refreshAccessState(ref);
                    }
                  : null,
              onRefresh: () => _refreshAccessState(ref),
            );

            final sourcesCard = _FinancialAppSourcesCard(
              detectionEnabled: settings.notificationDetectionEnabled,
              showLocalNotifications: settings.showDetectionNotifications,
              paymentAppNotifications: settings.paymentAppNotificationsEnabled,
              onDetectionChanged: (value) async {
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
                    .applyChanges(notificationDetectionEnabled: value);
              },
              onShowLocalChanged: (value) => ref
                  .read(detectionSettingsProvider.notifier)
                  .applyChanges(showDetectionNotifications: value),
              onPaymentAppsChanged: (value) => ref
                  .read(detectionSettingsProvider.notifier)
                  .applyChanges(paymentAppNotificationsEnabled: value),
            );

            final wide = constraints.maxWidth >= 620;
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: statusCard),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: sourcesCard),
                    ],
                  )
                else ...[
                  statusCard,
                  const SizedBox(height: AppSpacing.sm),
                  sourcesCard,
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  void _refreshAccessState(WidgetRef ref) {
    ref.invalidate(_notificationAccessStateProvider);
    ref.invalidate(_notificationListenerAvailableStateProvider);
    ref.invalidate(_postNotificationsPermissionStateProvider);
  }
}

class _NotificationStatusCard extends StatelessWidget {
  const _NotificationStatusCard({
    required this.isReady,
    required this.listenerAvailable,
    required this.accessState,
    required this.postNotifications,
    required this.onOpenSettings,
    required this.onAllowNotifications,
    required this.onRefresh,
  });

  final bool isReady;
  final AsyncValue<bool> listenerAvailable;
  final AsyncValue<bool> accessState;
  final AsyncValue<bool> postNotifications;
  final VoidCallback onOpenSettings;
  final VoidCallback? onAllowNotifications;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return FinarcCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      useShadow: false,
      radius: AppRadius.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SuccessIcon(),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isReady
                          ? 'Notification detection is ready'
                          : 'Set up notification detection',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Finarc can detect payment notifications from your apps. Detected items are reviewed before saving.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh status',
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded, size: 18),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _statusLine(
            context,
            label: 'Notification listener available',
            state: listenerAvailable,
          ),
          const SizedBox(height: AppSpacing.xs),
          _statusLine(
            context,
            label: 'Notification access enabled',
            state: accessState,
          ),
          const SizedBox(height: AppSpacing.xs),
          _statusLine(
            context,
            label: 'Finarc app notifications allowed',
            state: postNotifications,
          ),
          const SizedBox(height: AppSpacing.sm),
          FinarcPrimaryButton(
            onPressed: onOpenSettings,
            icon: Icons.settings_outlined,
            label: 'Open Android Settings',
          ),
          if (onAllowNotifications != null) ...[
            const SizedBox(height: AppSpacing.xs),
            FinarcSecondaryButton(
              onPressed: onAllowNotifications,
              icon: Icons.notifications_active_outlined,
              label: 'Allow Finarc App Notifications',
            ),
          ],
        ],
      ),
    );
  }

  static Widget _statusLine(
    BuildContext context, {
    required String label,
    required AsyncValue<bool> state,
  }) {
    return state.when(
      loading: () => _plainStatus(
        context,
        icon: Icons.hourglass_empty_rounded,
        label: '$label is being checked',
        ready: false,
      ),
      error: (e, _) => _plainStatus(
        context,
        icon: Icons.error_outline,
        label: '$label could not be checked',
        ready: false,
      ),
      data: (enabled) => _plainStatus(
        context,
        icon: enabled ? Icons.check_rounded : Icons.radio_button_unchecked,
        label: label,
        ready: enabled,
      ),
    );
  }

  static Widget _plainStatus(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool ready,
  }) {
    final color = ready
        ? AppColors.darkSuccess
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}

class _FinancialAppSourcesCard extends StatelessWidget {
  const _FinancialAppSourcesCard({
    required this.detectionEnabled,
    required this.showLocalNotifications,
    required this.paymentAppNotifications,
    required this.onDetectionChanged,
    required this.onShowLocalChanged,
    required this.onPaymentAppsChanged,
  });

  final bool detectionEnabled;
  final bool showLocalNotifications;
  final bool paymentAppNotifications;
  final ValueChanged<bool> onDetectionChanged;
  final ValueChanged<bool> onShowLocalChanged;
  final ValueChanged<bool> onPaymentAppsChanged;

  @override
  Widget build(BuildContext context) {
    return FinarcCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      useShadow: false,
      radius: AppRadius.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial App Sources',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.sm),
          _settingsRow(
            context,
            title: 'Detection enabled',
            helper: 'Detect notifications in the background.',
            value: detectionEnabled,
            onChanged: onDetectionChanged,
          ),
          _settingsRow(
            context,
            title: 'Show local detection notifications',
            helper: 'Get notified when items are pending.',
            value: showLocalNotifications,
            onChanged: onShowLocalChanged,
          ),
          _settingsRow(
            context,
            title: 'UPI/payment app notifications',
            helper:
                'Improve detection for Google Pay, PhonePe, Paytm, Amazon Pay, CRED and similar apps.',
            value: paymentAppNotifications,
            onChanged: onPaymentAppsChanged,
          ),
        ],
      ),
    );
  }

  static Widget _settingsRow(
    BuildContext context, {
    required String title,
    required String helper,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged(!value),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(helper, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Switch.adaptive(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessIcon extends StatelessWidget {
  const _SuccessIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.darkSuccess.withValues(alpha: 0.16),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.darkSuccess.withValues(alpha: 0.4)),
      ),
      child: const Icon(
        Icons.check_rounded,
        color: AppColors.darkSuccess,
        size: 24,
      ),
    );
  }
}
