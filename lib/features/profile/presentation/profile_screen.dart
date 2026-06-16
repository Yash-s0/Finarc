import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_controller.dart';
import '../../alerts/data/alerts_providers.dart';
import '../../dashboard/data/dashboard_providers.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../onboarding/data/onboarding_providers.dart';
import '../data/profile_settings_providers.dart';
import '../data/profile_settings_service.dart';
import '../../pending/data/pending_providers.dart';
import '../../pending/notifications/detection_settings.dart';
import '../../pending/notifications/notification_providers.dart';
import 'widgets/profile_sections.dart';

Future<void> _showProfileEditSheet(
  BuildContext context,
  WidgetRef ref,
  UserProfileSettings? profile,
) async {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController(text: profile?.name ?? '');
  final salary = TextEditingController(
    text: profile?.monthlySalary?.toString() ?? '',
  );
  final salaryDay = TextEditingController(
    text: profile?.salaryCreditDay?.toString() ?? '',
  );
  final company = TextEditingController(text: profile?.companyName ?? '');

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.md,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FinarcTextField(controller: name, label: 'Name'),
              const SizedBox(height: AppSpacing.xs),
              FinarcTextField(
                controller: salary,
                label: 'Monthly Salary',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return null;
                  final parsed = double.tryParse(text);
                  if (parsed == null || parsed <= 0) {
                    return 'Salary must be a positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              FinarcTextField(
                controller: salaryDay,
                label: 'Salary Credit Day',
                keyboardType: TextInputType.number,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return null;
                  final parsed = int.tryParse(text);
                  if (parsed == null || parsed < 1 || parsed > 31) {
                    return 'Day must be between 1 and 31';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              FinarcTextField(
                controller: company,
                label: 'Company Name',
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: AppSpacing.sm),
              FinarcPrimaryButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  await ref
                      .read(profileSettingsServiceProvider)
                      .save(
                        UserProfileSettings(
                          name: name.text.trim(),
                          monthlySalary: double.tryParse(salary.text.trim()),
                          salaryCreditDay: (() {
                            final parsed = int.tryParse(salaryDay.text.trim());
                            if (parsed == null) return null;
                            if (parsed < 1 || parsed > 31) return null;
                            return parsed;
                          })(),
                          companyName: company.text.trim(),
                        ),
                      );
                  ref.invalidate(userProfileSettingsProvider);
                  ref.invalidate(dashboardProvider);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
                label: 'Save Profile',
                icon: Icons.check_circle_outline,
              ),
            ],
          ),
        ),
      );
    },
  );
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessState = ref.watch(notificationAccessStatusProvider);
    final smsAccessState = ref.watch(smsPermissionStatusProvider);
    final notificationIngestionAvailabilityState = ref.watch(
      notificationIngestionAvailableProvider,
    );
    final smsIngestionAvailabilityState = ref.watch(
      smsIngestionAvailableProvider,
    );
    final postNotificationState = ref.watch(
      postNotificationsPermissionProvider,
    );
    final settings = ref.watch(detectionSettingsProvider).valueOrNull;
    final onboardingDone = ref.watch(onboardingCompletedProvider).valueOrNull;
    final detectionEnabled = settings?.notificationDetectionEnabled ?? true;
    final smsDetectionEnabled = settings?.smsDetectionEnabled ?? false;
    final diagnostics = ref.watch(ingestionDiagnosticsProvider);
    final profile = ref.watch(userProfileSettingsProvider).valueOrNull;
    final currentTheme = ref.watch(themeModeProvider);
    final notificationIngestionAvailable =
        notificationIngestionAvailabilityState.valueOrNull ?? false;
    final smsIngestionAvailable =
        smsIngestionAvailabilityState.valueOrNull ?? false;
    final notificationBadge = accessState.when(
      loading: () => const FinarcStatusBadge(
        label: 'Notification detection: Checking',
        tone: FinarcStatusTone.neutral,
        compact: true,
      ),
      error: (_, _) => const FinarcStatusBadge(
        label: 'Notification detection: Error',
        tone: FinarcStatusTone.warning,
        compact: true,
      ),
      data: (_) => FinarcStatusBadge(
        label: notificationIngestionAvailable
            ? 'Notification detection: Available'
            : 'Notification detection: Not available',
        tone: notificationIngestionAvailable
            ? FinarcStatusTone.success
            : FinarcStatusTone.warning,
        compact: true,
      ),
    );
    final smsBadge = smsAccessState.when(
      loading: () => const FinarcStatusBadge(
        label: 'SMS detection: Checking',
        tone: FinarcStatusTone.neutral,
        compact: true,
      ),
      error: (_, _) => const FinarcStatusBadge(
        label: 'SMS detection: Error',
        tone: FinarcStatusTone.warning,
        compact: true,
      ),
      data: (_) => FinarcStatusBadge(
        label: smsIngestionAvailable
            ? 'SMS detection: Available'
            : 'SMS detection: Not available in this build',
        tone: smsIngestionAvailable
            ? FinarcStatusTone.success
            : FinarcStatusTone.neutral,
        compact: true,
      ),
    );
    final localNotifBadge = postNotificationState.when(
      loading: () => const FinarcStatusBadge(
        label: 'Local notification permission: Checking',
        tone: FinarcStatusTone.neutral,
        compact: true,
      ),
      error: (_, _) => const FinarcStatusBadge(
        label: 'Local notification permission: Error',
        tone: FinarcStatusTone.warning,
        compact: true,
      ),
      data: (enabled) => FinarcStatusBadge(
        label: enabled
            ? 'Local notification permission: Granted'
            : 'Local notification permission: Not granted',
        tone: enabled ? FinarcStatusTone.success : FinarcStatusTone.warning,
        compact: true,
      ),
    );
    final detectionAccessBadge = accessState.when(
      loading: () => const FinarcStatusBadge(
        label: 'Checking access...',
        tone: FinarcStatusTone.neutral,
        compact: true,
      ),
      error: (_, _) => const FinarcStatusBadge(
        label: 'Access check failed',
        tone: FinarcStatusTone.warning,
        compact: true,
      ),
      data: (enabled) {
        if (!notificationIngestionAvailable) {
          return const FinarcStatusBadge(
            label: 'NOTIFICATION DETECTION NOT AVAILABLE',
            tone: FinarcStatusTone.warning,
            compact: true,
          );
        }
        return FinarcStatusBadge(
          label: enabled
              ? 'NOTIFICATION ACCESS ENABLED'
              : 'NOTIFICATION ACCESS DISABLED',
          tone: enabled ? FinarcStatusTone.success : FinarcStatusTone.warning,
          compact: true,
        );
      },
    );
    final smsAccessBadge = smsAccessState.when(
      loading: () => const FinarcStatusBadge(
        label: 'Checking SMS access...',
        tone: FinarcStatusTone.neutral,
        compact: true,
      ),
      error: (_, _) => const FinarcStatusBadge(
        label: 'SMS access check failed',
        tone: FinarcStatusTone.warning,
        compact: true,
      ),
      data: (enabled) {
        if (!smsIngestionAvailable) {
          return const FinarcStatusBadge(
            label: 'SMS NOT AVAILABLE IN THIS BUILD',
            tone: FinarcStatusTone.neutral,
            compact: true,
          );
        }
        return FinarcStatusBadge(
          label: enabled ? 'SMS ACCESS ENABLED' : 'SMS ACCESS DISABLED',
          tone: enabled ? FinarcStatusTone.success : FinarcStatusTone.warning,
          compact: true,
        );
      },
    );

    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Profile'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          ProfileHeaderCard(
            name: profile?.name,
            monthlySalary: profile?.monthlySalary,
            salaryCreditDay: profile?.salaryCreditDay,
            companyName: profile?.companyName,
            onEdit: () => _showProfileEditSheet(context, ref, profile),
          ),
          const SizedBox(height: AppSpacing.sm),
          ThemeSettingsSection(
            currentTheme: currentTheme,
            onThemeChanged: (theme) {
              ref.read(themeModeProvider.notifier).state = theme;
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          DebugToolsSection(
            onboardingDone: onboardingDone,
            onOpenOnboarding: () => context.push('/onboarding'),
            onResetOnboarding: () async {
              await ref.read(onboardingActionsProvider).reset();
              if (context.mounted) context.go('/onboarding');
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          NotificationTestingSection(
            notificationAccessBadge: notificationBadge,
            smsAccessBadge: smsBadge,
            postNotifBadge: localNotifBadge,
            detectionEnabled: detectionEnabled,
            smsDetectionEnabled: smsDetectionEnabled,
            reminderEnabled: settings?.reminderEnabled ?? false,
            diagnostics: diagnostics,
            onRequestNotificationPermission: () async {
              final granted = await ref
                  .read(notificationPermissionServiceProvider)
                  .requestPostNotificationsPermission();
              ref.invalidate(postNotificationsPermissionProvider);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    granted
                        ? 'Notification permission granted.'
                        : 'Notification permission denied.',
                  ),
                ),
              );
            },
            onSendTestNotification: () async {
              await ref
                  .read(notificationTestToolsServiceProvider)
                  .sendTestNotification();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Test notification sent. Check your notification tray.',
                  ),
                ),
              );
            },
            onCreateTestAlert: () async {
              final id = await ref
                  .read(notificationTestToolsServiceProvider)
                  .createTestAlert();
              ref.invalidate(alertsInboxProvider);
              ref.invalidate(alertsUnreadCountProvider);
              ref.invalidate(latestImportantAlertProvider);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    id == null
                        ? 'Test alert was not created.'
                        : 'Test alert created (id: $id).',
                  ),
                ),
              );
            },
            onMockTransactionNotification: () async {
              final ids = await ref
                  .read(notificationTestToolsServiceProvider)
                  .mockTransactionNotification();
              ref.invalidate(pendingTransactionsProvider);
              ref.invalidate(pendingCountProvider);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ids.isEmpty
                        ? 'No pending created from mock notification.'
                        : 'Mock notification created ${ids.length} pending transaction(s).',
                  ),
                ),
              );
            },
            onMockSmsTransaction: () async {
              final ids = await ref
                  .read(notificationTestToolsServiceProvider)
                  .mockSmsTransaction();
              ref.invalidate(pendingTransactionsProvider);
              ref.invalidate(pendingCountProvider);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ids.isEmpty
                        ? 'No pending created from mock SMS.'
                        : 'Mock SMS created ${ids.length} pending transaction(s).',
                  ),
                ),
              );
            },
            onOpenAlerts: () => context.push('/alerts'),
            onShowDiagnostics: () => context.push('/notifications/setup'),
            onClearDiagnostics: () {
              ref.read(ingestionDiagnosticsProvider.notifier).clear();
              ref.read(notificationDebugLogProvider.notifier).clear();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ingestion diagnostics cleared.')),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          BackupExportSection(
            onOpenLoans: () => context.push('/loans'),
            onOpenAlerts: () => context.push('/alerts'),
            settings: settings,
            onToggle: (key, value) {
              switch (key) {
                case 'smartAlertsEnabled':
                  return ref
                      .read(detectionSettingsProvider.notifier)
                      .applyChanges(smartAlertsEnabled: value);
                case 'lowBalanceAlertsEnabled':
                  return ref
                      .read(detectionSettingsProvider.notifier)
                      .applyChanges(lowBalanceAlertsEnabled: value);
                case 'largeExpenseAlertsEnabled':
                  return ref
                      .read(detectionSettingsProvider.notifier)
                      .applyChanges(largeExpenseAlertsEnabled: value);
                case 'unusualSpendingAlertsEnabled':
                  return ref
                      .read(detectionSettingsProvider.notifier)
                      .applyChanges(unusualSpendingAlertsEnabled: value);
                case 'recurringMerchantAlertsEnabled':
                  return ref
                      .read(detectionSettingsProvider.notifier)
                      .applyChanges(recurringMerchantAlertsEnabled: value);
                case 'weeklySummaryAlertsEnabled':
                  return ref
                      .read(detectionSettingsProvider.notifier)
                      .applyChanges(weeklySummaryAlertsEnabled: value);
                case 'monthlySummaryAlertsEnabled':
                  return ref
                      .read(detectionSettingsProvider.notifier)
                      .applyChanges(monthlySummaryAlertsEnabled: value);
                default:
                  return Future.value();
              }
            },
            timeFmt: _timeFmt,
            onConfigureQuietHours: () {
              if (settings != null) {
                _pickQuietHours(context, ref, settings);
              }
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          DetectionSettingsSection(
            accessBadge: detectionAccessBadge,
            smsAccessBadge: smsAccessBadge,
            notificationIngestionAvailable: notificationIngestionAvailable,
            smsIngestionAvailable: smsIngestionAvailable,
            detectionEnabled: detectionEnabled,
            smsDetectionEnabled: smsDetectionEnabled,
            onOpenNotificationSetup: () => context.push('/notifications/setup'),
            onOpenSmsSetup: () => context.push('/sms/setup'),
            onDetectionToggle: (value) {
              ref
                  .read(detectionSettingsProvider.notifier)
                  .applyChanges(notificationDetectionEnabled: value);
            },
            onSmsDetectionToggle: (value) {
              ref
                  .read(detectionSettingsProvider.notifier)
                  .applyChanges(smsDetectionEnabled: value);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          DataControlsEntryCard(
            onOpen: () => context.push(AppRoutes.profileDataControls),
          ),
          const SizedBox(height: AppSpacing.sm),
          const ReleaseDiagnosticsSection(),
          const SizedBox(height: AppSpacing.sm),
          const DeveloperSignatureFooter(),
        ],
      ),
    );
  }

  String _timeFmt(int hour, int minute) {
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final h = hour % 12 == 0 ? 12 : hour % 12;
    return '${h.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $suffix';
  }

  Future<void> _pickQuietHours(
    BuildContext context,
    WidgetRef ref,
    DetectionSettings settings,
  ) async {
    final start = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settings.quietHoursStartHour,
        minute: settings.quietHoursStartMinute,
      ),
    );
    if (start == null || !context.mounted) return;

    final end = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settings.quietHoursEndHour,
        minute: settings.quietHoursEndMinute,
      ),
    );
    if (end == null || !context.mounted) return;

    await ref
        .read(detectionSettingsProvider.notifier)
        .applyChanges(
          quietHoursStartHour: start.hour,
          quietHoursStartMinute: start.minute,
          quietHoursEndHour: end.hour,
          quietHoursEndMinute: end.minute,
        );
  }
}
