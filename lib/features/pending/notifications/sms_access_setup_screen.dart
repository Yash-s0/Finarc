import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import 'notification_providers.dart';

class SmsAccessSetupScreen extends ConsumerWidget {
  const SmsAccessSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final smsPermission = ref.watch(smsPermissionStatusProvider);
    final receiverAvailable = ref.watch(smsReceiverAvailableProvider);
    final settingsState = ref.watch(detectionSettingsProvider);
    final diagnostics = ref.watch(ingestionDiagnosticsProvider);
    final hasSmsAccess = smsPermission.valueOrNull ?? false;

    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'SMS Access'),
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
                    'Read transaction SMS locally',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Finarc only parses transaction-like SMS and creates pending transactions for your confirmation. No SMS is uploaded anywhere.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const FinarcStatusBadge(
                    label: 'Local-only parsing. User confirmation required.',
                    tone: FinarcStatusTone.info,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (!hasSmsAccess)
                    Text(
                      'If SMS remains unavailable in debug/profile builds, native SMS components may be disabled for safety.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FinarcCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FinarcSectionHeader(title: 'Permission Status'),
                  const SizedBox(height: AppSpacing.xs),
                  smsPermission.when(
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
                  const SizedBox(height: AppSpacing.sm),
                  receiverAvailable.when(
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => Text('Receiver status error: $e'),
                    data: (available) {
                      if (available) return const SizedBox.shrink();
                      return const Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.xs),
                        child: FinarcStatusBadge(
                          label: 'Unavailable in this build',
                          tone: FinarcStatusTone.warning,
                          compact: true,
                        ),
                      );
                    },
                  ),
                  FinarcPrimaryButton(
                    onPressed: () async {
                      final granted = await ref
                          .read(smsPermissionServiceProvider)
                          .requestPermission();
                      await ref
                          .read(detectionSettingsProvider.notifier)
                          .applyChanges(smsPermissionAskedAt: DateTime.now());
                      ref.read(smsPermissionCachedProvider.notifier).state =
                          granted;
                      ref.invalidate(smsPermissionStatusProvider);
                    },
                    icon: Icons.sms_outlined,
                    label: 'Enable SMS Access',
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  FinarcSecondaryButton(
                    onPressed: () => ref
                        .read(smsPermissionServiceProvider)
                        .openAppPermissionSettings(),
                    icon: Icons.settings_outlined,
                    label: 'Open App Permission Settings',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FinarcCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _toggle(
                    context,
                    'SMS detection enabled',
                    settings.smsDetectionEnabled,
                    (value) async {
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
                  ),
                  _toggle(
                    context,
                    'SMS backfill enabled',
                    settings.smsBackfillEnabled,
                    (value) => ref
                        .read(detectionSettingsProvider.notifier)
                        .applyChanges(smsBackfillEnabled: value),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Backfill days: ${settings.smsBackfillDays}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      DropdownButton<int>(
                        value: settings.smsBackfillDays,
                        items: const [
                          DropdownMenuItem(value: 3, child: Text('3')),
                          DropdownMenuItem(value: 7, child: Text('7')),
                          DropdownMenuItem(value: 14, child: Text('14')),
                          DropdownMenuItem(value: 30, child: Text('30')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          ref
                              .read(detectionSettingsProvider.notifier)
                              .applyChanges(smsBackfillDays: value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FinarcPrimaryButton(
                    onPressed: () async {
                      if (!hasSmsAccess) {
                        if (!context.mounted) return;
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
                          content: Text(
                            'Queued $count SMS messages for parsing.',
                          ),
                        ),
                      );
                    },
                    icon: Icons.history_toggle_off_outlined,
                    label: 'Backfill Last ${settings.smsBackfillDays} Days',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FinarcCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FinarcSectionHeader(title: 'SMS Diagnostics'),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Last event: ${diagnostics.lastSmsEventAt == null ? '—' : diagnostics.lastSmsEventAt!.toLocal().toIso8601String()}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Last sender: ${diagnostics.lastSmsSender ?? '—'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Last result: ${diagnostics.lastSmsResult ?? '—'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Received ${diagnostics.smsReceived} • Allowed ${diagnostics.smsAllowed} • Promotional blocked ${diagnostics.smsBlockedPromotional} • Unknown blocked ${diagnostics.smsBlockedUnknownSender} • Non-transaction blocked ${diagnostics.smsBlockedNonTransaction} • Parsed ${diagnostics.smsParsedPending} • Duplicates ${diagnostics.smsDuplicateSuppressed}',
                    style: Theme.of(context).textTheme.bodySmall,
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

  static Widget _toggle(
    BuildContext context,
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
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
}
