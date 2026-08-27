import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import 'ingestion_diagnostics.dart';
import 'notification_providers.dart';
import 'sms_permission_service.dart';

class SmsAccessSetupScreen extends ConsumerWidget {
  const SmsAccessSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final smsPermission = ref.watch(smsPermissionStatusProvider);
    final receiverEnabled = ref.watch(smsReceiverEnabledProvider);
    final permissionRationale = ref.watch(smsPermissionRationaleProvider);
    final runtimeDiagnostics = ref.watch(smsRuntimeDiagnosticsProvider);
    final smsIngestionAvailable =
        ref.watch(smsIngestionAvailableProvider).valueOrNull ?? false;
    final settingsState = ref.watch(detectionSettingsProvider);
    final diagnostics = ref.watch(ingestionDiagnosticsProvider);
    final hasSmsAccess = smsPermission.valueOrNull ?? false;

    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'SMS Access'),
      body: settingsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
        data: (settings) => LayoutBuilder(
          builder: (context, constraints) {
            final statusCard = _SmsStatusCard(
              isReady: hasSmsAccess,
              smsPermission: smsPermission,
              receiverEnabled: receiverEnabled,
              smsIngestionAvailable: smsIngestionAvailable,
              permanentlyDenied:
                  !hasSmsAccess &&
                  settings.smsPermissionAskedAt != null &&
                  permissionRationale.valueOrNull == false,
              onManagePermissions: () async {
                if (!smsIngestionAvailable) return;
                if (hasSmsAccess) {
                  await ref
                      .read(smsPermissionServiceProvider)
                      .openAppPermissionSettings();
                  ref.invalidate(smsPermissionStatusProvider);
                  ref.invalidate(smsRuntimeDiagnosticsProvider);
                  return;
                }

                final granted = await ref
                    .read(smsPermissionServiceProvider)
                    .requestPermission();
                await ref
                    .read(detectionSettingsProvider.notifier)
                    .applyChanges(
                      smsPermissionAskedAt: DateTime.now(),
                      smsDetectionEnabled: granted,
                      smsBackfillEnabled:
                          granted || settings.smsBackfillEnabled,
                    );
                if (granted) {
                  await ref
                      .read(smsPermissionServiceProvider)
                      .scanRecentSms(settings.smsBackfillDays);
                  await ref
                      .read(detectionSettingsProvider.notifier)
                      .applyChanges(smsLastScannedAt: DateTime.now());
                }
                ref.read(smsPermissionCachedProvider.notifier).state = granted;
                ref.invalidate(smsPermissionStatusProvider);
                ref.invalidate(smsPermissionRationaleProvider);
                ref.invalidate(smsRuntimeDiagnosticsProvider);
              },
            );

            final detectionCard = _SmsDetectionCard(
              smsDetectionEnabled: settings.smsDetectionEnabled,
              smsBackfillEnabled: settings.smsBackfillEnabled,
              smsBackfillDays: settings.smsBackfillDays,
              smsIngestionAvailable: smsIngestionAvailable,
              hasSmsAccess: hasSmsAccess,
              onDetectionChanged: (value) async {
                if (value && !hasSmsAccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Enable SMS permission before turning on SMS detection.',
                      ),
                    ),
                  );
                  return;
                }
                await ref
                    .read(detectionSettingsProvider.notifier)
                    .applyChanges(smsDetectionEnabled: value);
              },
              onBackfillChanged: (value) => ref
                  .read(detectionSettingsProvider.notifier)
                  .applyChanges(smsBackfillEnabled: value),
              onBackfillDaysChanged: (value) => ref
                  .read(detectionSettingsProvider.notifier)
                  .applyChanges(smsBackfillDays: value),
              onReviewPastSms: smsIngestionAvailable
                  ? () => context.push(AppRoutes.smsRecovery)
                  : null,
              onQueueBackfill: () async {
                if (!smsIngestionAvailable) return;
                if (!hasSmsAccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'SMS permission is required before backfill.',
                      ),
                    ),
                  );
                  return;
                }
                final count = await ref
                    .read(smsPermissionServiceProvider)
                    .scanRecentSms(settings.smsBackfillDays);
                await ref
                    .read(detectionSettingsProvider.notifier)
                    .applyChanges(
                      smsLastScannedAt: DateTime.now(),
                      smsBackfillEnabled: true,
                    );
                ref.invalidate(smsPermissionStatusProvider);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Queued $count SMS messages for parsing.'),
                  ),
                );
              },
            );

            final diagnosticsCard = FinarcCard(
              padding: EdgeInsets.zero,
              useShadow: false,
              radius: AppRadius.lg,
              child: ExpansionTile(
                title: const Text('Advanced diagnostics'),
                childrenPadding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  0,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                children: [
                  _smsDiagnostics(context, runtimeDiagnostics, diagnostics),
                ],
              ),
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
                      Expanded(child: detectionCard),
                    ],
                  )
                else ...[
                  statusCard,
                  const SizedBox(height: AppSpacing.sm),
                  detectionCard,
                ],
                const SizedBox(height: AppSpacing.sm),
                diagnosticsCard,
              ],
            );
          },
        ),
      ),
    );
  }

  static Widget _smsDiagnostics(
    BuildContext context,
    AsyncValue<SmsRuntimeDiagnostics> runtimeDiagnostics,
    IngestionDiagnostics diagnostics,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        runtimeDiagnostics.when(
          loading: () => const Text('Checking Android runtime status...'),
          error: (e, _) => Text('Runtime diagnostics error: $e'),
          data: (native) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'READ_SMS: ${native.readSmsGranted ? 'granted' : 'not granted'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'RECEIVE_SMS: ${native.receiveSmsGranted ? 'granted' : 'not granted'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'Receiver declared: ${native.receiverDeclared ? 'yes' : 'no'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'Receiver enabled: ${native.receiverEnabled ? 'yes' : 'no'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'Last Android SMS received: ${native.lastReceivedAt == null ? '-' : native.lastReceivedAt!.toLocal().toIso8601String()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'Last actual sender: ${native.lastSender ?? '-'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'Last receiver callback success: ${native.lastCallbackSuccessAt == null ? '-' : native.lastCallbackSuccessAt!.toLocal().toIso8601String()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (native.lastError != null && native.lastError!.isNotEmpty)
                Text(
                  'Last receiver error: ${native.lastError}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              if (native.lastReceivedAt == null)
                Text(
                  'SMS receiver has not received any Android SMS broadcasts yet.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(height: AppSpacing.xs),
            ],
          ),
        ),
        Text(
          'Last event: ${diagnostics.lastSmsEventAt == null ? '-' : diagnostics.lastSmsEventAt!.toLocal().toIso8601String()}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          'Last sender: ${diagnostics.lastSmsSender ?? '-'}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          'Last result: ${diagnostics.lastSmsResult ?? '-'}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Received ${diagnostics.smsReceived} - Allowed ${diagnostics.smsAllowed} - Promotional blocked ${diagnostics.smsBlockedPromotional} - Unknown blocked ${diagnostics.smsBlockedUnknownSender} - Non-transaction blocked ${diagnostics.smsBlockedNonTransaction} - Parsed ${diagnostics.smsParsedPending} - Duplicates ${diagnostics.smsDuplicateSuppressed}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _SmsStatusCard extends StatelessWidget {
  const _SmsStatusCard({
    required this.isReady,
    required this.smsPermission,
    required this.receiverEnabled,
    required this.smsIngestionAvailable,
    required this.permanentlyDenied,
    required this.onManagePermissions,
  });

  final bool isReady;
  final AsyncValue<bool> smsPermission;
  final AsyncValue<bool> receiverEnabled;
  final bool smsIngestionAvailable;
  final bool permanentlyDenied;
  final VoidCallback? onManagePermissions;

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
                          ? 'SMS detection is ready'
                          : 'Set up SMS detection',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Finarc can scan transaction SMS in the background and review them before adding to your ledger.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _statusLine(
            context,
            label: 'SMS permission granted',
            state: smsPermission,
          ),
          const SizedBox(height: AppSpacing.xs),
          _statusLine(
            context,
            label: 'Background receiver enabled',
            state: receiverEnabled,
          ),
          if (!smsIngestionAvailable) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'SMS access needs Android permission and receiver support on this device.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (permanentlyDenied) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'SMS permission appears permanently denied. Open app settings and allow SMS access.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          FinarcPrimaryButton(
            onPressed: onManagePermissions,
            icon: Icons.settings_outlined,
            label: 'Manage permissions',
          ),
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

class _SmsDetectionCard extends StatelessWidget {
  const _SmsDetectionCard({
    required this.smsDetectionEnabled,
    required this.smsBackfillEnabled,
    required this.smsBackfillDays,
    required this.smsIngestionAvailable,
    required this.hasSmsAccess,
    required this.onDetectionChanged,
    required this.onBackfillChanged,
    required this.onBackfillDaysChanged,
    required this.onReviewPastSms,
    required this.onQueueBackfill,
  });

  final bool smsDetectionEnabled;
  final bool smsBackfillEnabled;
  final int smsBackfillDays;
  final bool smsIngestionAvailable;
  final bool hasSmsAccess;
  final ValueChanged<bool> onDetectionChanged;
  final ValueChanged<bool> onBackfillChanged;
  final ValueChanged<int> onBackfillDaysChanged;
  final VoidCallback? onReviewPastSms;
  final VoidCallback onQueueBackfill;

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
            'Detection',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.sm),
          _switchRow(
            context,
            title: 'SMS detection enabled',
            value: smsDetectionEnabled,
            onChanged: smsIngestionAvailable ? onDetectionChanged : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Backfill',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.sm),
          _switchRow(
            context,
            title: 'SMS backfill enabled',
            value: smsBackfillEnabled,
            onChanged: smsIngestionAvailable ? onBackfillChanged : null,
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Backfill days',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              DropdownButton<int>(
                value: smsBackfillDays,
                items: const [
                  DropdownMenuItem(value: 3, child: Text('3')),
                  DropdownMenuItem(value: 7, child: Text('7')),
                  DropdownMenuItem(value: 14, child: Text('14')),
                  DropdownMenuItem(value: 30, child: Text('30')),
                ],
                onChanged: smsIngestionAvailable
                    ? (value) {
                        if (value == null) return;
                        onBackfillDaysChanged(value);
                      }
                    : null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              final sideBySide = constraints.maxWidth >= 320;
              final review = FinarcSecondaryButton(
                onPressed: onReviewPastSms,
                icon: Icons.manage_search_outlined,
                label: 'Review past SMS',
              );
              final queue = FinarcPrimaryButton(
                onPressed: smsIngestionAvailable && hasSmsAccess
                    ? onQueueBackfill
                    : null,
                icon: Icons.history_toggle_off_outlined,
                label: 'Queue last $smsBackfillDays days',
              );
              if (!sideBySide) {
                return Column(
                  children: [
                    review,
                    const SizedBox(height: AppSpacing.xs),
                    queue,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: review),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: queue),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  static Widget _switchRow(
    BuildContext context, {
    required String title,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Switch.adaptive(value: value, onChanged: onChanged),
      ],
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
