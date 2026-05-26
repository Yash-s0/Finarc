import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/database/backup/backup_models.dart';
import '../../../core/database/backup/backup_providers.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/database/reset_data_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../accounts/data/accounts_providers.dart';
import '../../alerts/data/alerts_providers.dart';
import '../../cards/data/cards_providers.dart';
import '../../dashboard/data/dashboard_providers.dart';
import '../../expenses/data/expenses_providers.dart';
import '../../loans/data/loans_providers.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../onboarding/data/onboarding_providers.dart';
import '../data/profile_settings_providers.dart';
import '../data/profile_settings_service.dart';
import '../../pending/data/pending_providers.dart';
import '../../pending/notifications/detection_settings.dart';
import '../../pending/notifications/notification_providers.dart';
import '../../split/data/split_providers.dart';

class _LocalRowsSummary {
  const _LocalRowsSummary({
    required this.accounts,
    required this.cards,
    required this.transactions,
    required this.pending,
    required this.splits,
  });

  final int accounts;
  final int cards;
  final int transactions;
  final int pending;
  final int splits;
}

final _localRowsSummaryProvider = FutureProvider<_LocalRowsSummary>((
  ref,
) async {
  final db = ref.read(appDatabaseProvider);
  final banks = await db.select(db.bankAccounts).get();
  final wallets = await db.select(db.cashWallets).get();
  final cards = await db.select(db.creditCards).get();
  final txns = await db.select(db.transactions).get();
  final pending = await db.select(db.pendingTransactions).get();
  final splitGroups = await db.select(db.splitGroups).get();
  final splitMembers = await db.select(db.splitMembers).get();
  final splitExpenses = await db.select(db.splitExpenses).get();
  final splitShares = await db.select(db.splitExpenseShares).get();
  final splitSettlements = await db.select(db.splitSettlements).get();

  return _LocalRowsSummary(
    accounts: banks.length + wallets.length,
    cards: cards.length,
    transactions: txns.length,
    pending: pending.length,
    splits:
        splitGroups.length +
        splitMembers.length +
        splitExpenses.length +
        splitShares.length +
        splitSettlements.length,
  );
});

Future<void> _showProfileEditSheet(
  BuildContext context,
  WidgetRef ref,
  UserProfileSettings? profile,
) async {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FinarcTextField(controller: name, label: 'Name'),
            const SizedBox(height: AppSpacing.xs),
            FinarcTextField(
              controller: salary,
              label: 'Monthly Salary',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: AppSpacing.xs),
            FinarcTextField(
              controller: salaryDay,
              label: 'Salary Credit Day',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.xs),
            FinarcTextField(controller: company, label: 'Company Name'),
            const SizedBox(height: AppSpacing.sm),
            FinarcPrimaryButton(
              onPressed: () async {
                await ref.read(profileSettingsServiceProvider).save(
                      UserProfileSettings(
                        name: name.text.trim(),
                        monthlySalary: double.tryParse(salary.text.trim()),
                        salaryCreditDay: int.tryParse(salaryDay.text.trim()),
                        companyName: company.text.trim(),
                      ),
                    );
                ref.invalidate(userProfileSettingsProvider);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              label: 'Save Profile',
              icon: Icons.check_circle_outline,
            ),
          ],
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
    final postNotificationState = ref.watch(
      postNotificationsPermissionProvider,
    );
    final settings = ref.watch(detectionSettingsProvider).valueOrNull;
    final onboardingDone = ref.watch(onboardingCompletedProvider).valueOrNull;
    final detectionEnabled = settings?.notificationDetectionEnabled ?? true;
    final smsDetectionEnabled = settings?.smsDetectionEnabled ?? false;
    final diagnostics = ref.watch(ingestionDiagnosticsProvider);
    final localRowsSummary = kDebugMode
        ? ref.watch(_localRowsSummaryProvider).valueOrNull
        : null;
    final profile = ref.watch(userProfileSettingsProvider).valueOrNull;

    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Profile'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          FinarcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile & Salary',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text('Name: ${profile?.name ?? '—'}'),
                Text(
                  'Monthly salary: ${profile?.monthlySalary == null ? '—' : profile!.monthlySalary!.toStringAsFixed(2)}',
                ),
                Text('Salary credit day: ${profile?.salaryCreditDay ?? '—'}'),
                Text('Company: ${profile?.companyName ?? '—'}'),
                const SizedBox(height: AppSpacing.sm),
                FinarcSecondaryButton(
                  onPressed: () => _showProfileEditSheet(context, ref, profile),
                  icon: Icons.edit_outlined,
                  label: 'Edit Profile & Salary',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FinarcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Setup Status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'First-run onboarding and local setup progress.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                FinarcStatusBadge(
                  label: onboardingDone == true
                      ? 'ONBOARDING COMPLETED'
                      : 'ONBOARDING PENDING',
                  tone: onboardingDone == true
                      ? FinarcStatusTone.success
                      : FinarcStatusTone.warning,
                  compact: true,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: FinarcSecondaryButton(
                        onPressed: () => context.push('/onboarding'),
                        label: 'Open Onboarding',
                        icon: Icons.flag_outlined,
                      ),
                    ),
                  ],
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(
                        child: FinarcSecondaryButton(
                          onPressed: () async {
                            await ref.read(onboardingActionsProvider).reset();
                            if (context.mounted) context.go('/onboarding');
                          },
                          label: 'Reset Onboarding (Debug)',
                          icon: Icons.restart_alt_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FinarcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notification Testing',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Verify local notification posting, alert storage, mock notification/SMS ingestion, and routing.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    accessState.when(
                      loading: () => const FinarcStatusBadge(
                        label: 'Notification access: Checking',
                        tone: FinarcStatusTone.neutral,
                        compact: true,
                      ),
                      error: (_, _) => const FinarcStatusBadge(
                        label: 'Notification access: Error',
                        tone: FinarcStatusTone.warning,
                        compact: true,
                      ),
                      data: (enabled) => FinarcStatusBadge(
                        label: enabled
                            ? 'Notification access: Enabled'
                            : 'Notification access: Disabled',
                        tone: enabled
                            ? FinarcStatusTone.success
                            : FinarcStatusTone.warning,
                        compact: true,
                      ),
                    ),
                    smsAccessState.when(
                      loading: () => const FinarcStatusBadge(
                        label: 'SMS permission: Checking',
                        tone: FinarcStatusTone.neutral,
                        compact: true,
                      ),
                      error: (_, _) => const FinarcStatusBadge(
                        label: 'SMS permission: Error',
                        tone: FinarcStatusTone.warning,
                        compact: true,
                      ),
                      data: (enabled) => FinarcStatusBadge(
                        label: enabled
                            ? 'SMS permission: Granted'
                            : 'SMS permission: Not granted',
                        tone: enabled
                            ? FinarcStatusTone.success
                            : FinarcStatusTone.warning,
                        compact: true,
                      ),
                    ),
                    postNotificationState.when(
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
                        tone: enabled
                            ? FinarcStatusTone.success
                            : FinarcStatusTone.warning,
                        compact: true,
                      ),
                    ),
                    FinarcStatusBadge(
                      label: detectionEnabled
                          ? 'Detection enabled: On'
                          : 'Detection enabled: Off',
                      tone: detectionEnabled
                          ? FinarcStatusTone.success
                          : FinarcStatusTone.warning,
                      compact: true,
                    ),
                    FinarcStatusBadge(
                      label: smsDetectionEnabled
                          ? 'SMS detection: On'
                          : 'SMS detection: Off',
                      tone: smsDetectionEnabled
                          ? FinarcStatusTone.success
                          : FinarcStatusTone.warning,
                      compact: true,
                    ),
                    FinarcStatusBadge(
                      label: (settings?.reminderEnabled ?? false)
                          ? 'Reminders: On'
                          : 'Reminders: Off',
                      tone: (settings?.reminderEnabled ?? false)
                          ? FinarcStatusTone.success
                          : FinarcStatusTone.neutral,
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: FinarcSecondaryButton(
                        onPressed: () async {
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
                        icon: Icons.notifications_active_outlined,
                        label: 'Request Notification Permission',
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
                        icon: Icons.send_rounded,
                        label: 'Send Test Notification',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: FinarcSecondaryButton(
                        onPressed: () async {
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
                        icon: Icons.add_alert_rounded,
                        label: 'Create Test Alert',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: FinarcSecondaryButton(
                        onPressed: () async {
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
                        icon: Icons.notifications_outlined,
                        label: 'Mock Transaction Notification',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: FinarcSecondaryButton(
                        onPressed: () async {
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
                        icon: Icons.sms_outlined,
                        label: 'Mock SMS Transaction',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: FinarcSecondaryButton(
                        onPressed: () => context.push('/alerts'),
                        icon: Icons.open_in_new_rounded,
                        label: 'Open Alerts Center',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'SMS received ${diagnostics.smsReceived} • allowed ${diagnostics.smsAllowed} • promo blocked ${diagnostics.smsBlockedPromotional} • unknown blocked ${diagnostics.smsBlockedUnknownSender} • parsed ${diagnostics.smsParsedPending} • dupes ${diagnostics.smsDuplicateSuppressed}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Notifications received ${diagnostics.notificationsReceived} • parsed ${diagnostics.notificationsParsedPending} • ignored ${diagnostics.notificationsIgnored} • dupes ${diagnostics.notificationsDuplicateSuppressed}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: FinarcSecondaryButton(
                        onPressed: () => context.push('/notification/setup'),
                        icon: Icons.analytics_outlined,
                        label: 'Show Ingestion Diagnostics',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: FinarcSecondaryButton(
                        onPressed: () {
                          ref
                              .read(ingestionDiagnosticsProvider.notifier)
                              .clear();
                          ref
                              .read(notificationDebugLogProvider.notifier)
                              .clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ingestion diagnostics cleared.'),
                            ),
                          );
                        },
                        icon: Icons.delete_sweep_outlined,
                        label: 'Clear Ingestion Diagnostics',
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
                Text(
                  'Alerts & Quiet Hours',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Control smart local alerts, summaries, and quiet-hour suppression.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: FinarcSecondaryButton(
                        onPressed: () => context.push('/alerts'),
                        label: 'Open Alerts Center',
                        icon: Icons.notifications_none_rounded,
                      ),
                    ),
                  ],
                ),
                if (settings != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  _settingToggle(
                    context,
                    label: 'Smart alerts enabled',
                    value: settings.smartAlertsEnabled,
                    onChanged: (value) {
                      ref
                          .read(detectionSettingsProvider.notifier)
                          .applyChanges(smartAlertsEnabled: value);
                    },
                  ),
                  _settingToggle(
                    context,
                    label: 'Low balance alerts',
                    value: settings.lowBalanceAlertsEnabled,
                    onChanged: (value) {
                      ref
                          .read(detectionSettingsProvider.notifier)
                          .applyChanges(lowBalanceAlertsEnabled: value);
                    },
                  ),
                  _settingToggle(
                    context,
                    label: 'Large expense alerts',
                    value: settings.largeExpenseAlertsEnabled,
                    onChanged: (value) {
                      ref
                          .read(detectionSettingsProvider.notifier)
                          .applyChanges(largeExpenseAlertsEnabled: value);
                    },
                  ),
                  _settingToggle(
                    context,
                    label: 'Unusual spending alerts',
                    value: settings.unusualSpendingAlertsEnabled,
                    onChanged: (value) {
                      ref
                          .read(detectionSettingsProvider.notifier)
                          .applyChanges(unusualSpendingAlertsEnabled: value);
                    },
                  ),
                  _settingToggle(
                    context,
                    label: 'Recurring merchant alerts',
                    value: settings.recurringMerchantAlertsEnabled,
                    onChanged: (value) {
                      ref
                          .read(detectionSettingsProvider.notifier)
                          .applyChanges(recurringMerchantAlertsEnabled: value);
                    },
                  ),
                  _settingToggle(
                    context,
                    label: 'Weekly summary alerts',
                    value: settings.weeklySummaryAlertsEnabled,
                    onChanged: (value) {
                      ref
                          .read(detectionSettingsProvider.notifier)
                          .applyChanges(weeklySummaryAlertsEnabled: value);
                    },
                  ),
                  _settingToggle(
                    context,
                    label: 'Monthly summary alerts',
                    value: settings.monthlySummaryAlertsEnabled,
                    onChanged: (value) {
                      ref
                          .read(detectionSettingsProvider.notifier)
                          .applyChanges(monthlySummaryAlertsEnabled: value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Quiet hours: ${_timeFmt(settings.quietHoursStartHour, settings.quietHoursStartMinute)} - ${_timeFmt(settings.quietHoursEndHour, settings.quietHoursEndMinute)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  FinarcSecondaryButton(
                    onPressed: () => _pickQuietHours(context, ref, settings),
                    icon: Icons.nightlight_round,
                    label: 'Configure Quiet Hours',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FinarcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Loans & EMIs',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Track loan outstanding, upcoming EMIs and payment history.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: FinarcSecondaryButton(
                        onPressed: () => context.push('/loans'),
                        label: 'Open Loans Dashboard',
                        icon: Icons.account_balance_outlined,
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
                Text(
                  'Notification Detection',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Reads transaction-like notifications locally and creates pending transactions for review.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                accessState.when(
                  loading: () => const FinarcStatusBadge(
                    label: 'Checking access...',
                    tone: FinarcStatusTone.neutral,
                    compact: true,
                  ),
                  error: (error, stackTrace) => const FinarcStatusBadge(
                    label: 'Access check failed',
                    tone: FinarcStatusTone.warning,
                    compact: true,
                  ),
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
                Row(
                  children: [
                    Expanded(
                      child: FinarcSecondaryButton(
                        onPressed: () => context.push('/notifications/setup'),
                        label: 'Open Setup',
                        icon: Icons.settings_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Text(
                      'Detection enabled',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    Switch.adaptive(
                      value: detectionEnabled,
                      onChanged: (value) {
                        ref
                            .read(detectionSettingsProvider.notifier)
                            .applyChanges(notificationDetectionEnabled: value);
                      },
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
                Text(
                  'SMS Detection',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Reads transaction-like SMS locally and creates pending entries for review.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                smsAccessState.when(
                  loading: () => const FinarcStatusBadge(
                    label: 'Checking SMS access...',
                    tone: FinarcStatusTone.neutral,
                    compact: true,
                  ),
                  error: (error, stackTrace) => const FinarcStatusBadge(
                    label: 'SMS access check failed',
                    tone: FinarcStatusTone.warning,
                    compact: true,
                  ),
                  data: (enabled) => FinarcStatusBadge(
                    label: enabled
                        ? 'SMS ACCESS ENABLED'
                        : 'SMS ACCESS DISABLED',
                    tone: enabled
                        ? FinarcStatusTone.success
                        : FinarcStatusTone.warning,
                    compact: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: FinarcSecondaryButton(
                        onPressed: () => context.push('/sms/setup'),
                        label: 'Open SMS Setup',
                        icon: Icons.sms_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Text(
                      'SMS detection enabled',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    Switch.adaptive(
                      value: smsDetectionEnabled,
                      onChanged: (value) {
                        ref
                            .read(detectionSettingsProvider.notifier)
                            .applyChanges(smsDetectionEnabled: value);
                      },
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
                Text(
                  'Data Controls',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Manual local backup/export/import. No cloud sync is used.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                FinarcSecondaryButton(
                  onPressed: () => _confirmExportFullBackup(context, ref),
                  label: 'Export Full Backup',
                  icon: Icons.download_rounded,
                ),
                const SizedBox(height: AppSpacing.xs),
                FinarcSecondaryButton(
                  onPressed: () => _pickAndImportBackup(context, ref),
                  label: 'Import Backup',
                  icon: Icons.upload_file_rounded,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: FinarcSecondaryButton(
                        onPressed: () => _exportCsv(
                          context,
                          ref,
                          fileNamePrefix: 'finarc_transactions',
                          label: 'Transactions CSV',
                          exporter: () => ref
                              .read(backupServiceProvider)
                              .exportTransactionsCsv(),
                        ),
                        label: 'Export Transactions CSV',
                        icon: Icons.receipt_long_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: FinarcSecondaryButton(
                        onPressed: () => _exportCsv(
                          context,
                          ref,
                          fileNamePrefix: 'finarc_expenses',
                          label: 'Expenses CSV',
                          exporter: () => ref
                              .read(backupServiceProvider)
                              .exportExpensesCsv(),
                        ),
                        label: 'Export Expenses CSV',
                        icon: Icons.trending_down_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: FinarcSecondaryButton(
                        onPressed: () => _exportCsv(
                          context,
                          ref,
                          fileNamePrefix: 'finarc_accounts',
                          label: 'Accounts CSV',
                          exporter: () => ref
                              .read(backupServiceProvider)
                              .exportAccountsCsv(),
                        ),
                        label: 'Export Accounts CSV',
                        icon: Icons.account_balance_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: FinarcSecondaryButton(
                        onPressed: () => _exportCsv(
                          context,
                          ref,
                          fileNamePrefix: 'finarc_cards',
                          label: 'Cards CSV',
                          exporter: () =>
                              ref.read(backupServiceProvider).exportCardsCsv(),
                        ),
                        label: 'Export Cards CSV',
                        icon: Icons.credit_card_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                const FinarcStatusBadge(
                  label: 'BACKUPS ARE UNENCRYPTED JSON/CSV FILES',
                  tone: FinarcStatusTone.warning,
                  compact: true,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Backup files are stored wherever you save them. Anyone with file access can read your financial data.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                FinarcSecondaryButton(
                  onPressed: () => _confirmResetAllData(context, ref),
                  label: 'Delete All Data & Start Fresh',
                  icon: Icons.delete_forever_outlined,
                ),
                if (kDebugMode && localRowsSummary != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Local rows: accounts ${localRowsSummary.accounts}, cards ${localRowsSummary.cards}, txns ${localRowsSummary.transactions}, pending ${localRowsSummary.pending}, splits ${localRowsSummary.splits}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const FinarcCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.dark_mode_outlined),
              title: Text('Theme toggle (placeholder)'),
              subtitle: Text(
                'Dark mode default is active. Full theme persistence controls are planned next.',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const FinarcCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.offline_bolt_rounded),
              title: Text('Offline-first mode'),
              subtitle: Text('All data is stored locally on device only.'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const FinarcCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.privacy_tip_outlined),
              title: Text('Privacy rules'),
              subtitle: Text(
                'No CVV, no expiry date storage, masked card numbers only, no cloud sync.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmExportFullBackup(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final shouldExport = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Unencrypted Backup?'),
        content: const Text(
          'This creates a readable local JSON backup file. Anyone with access to this file can read your financial data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Export'),
          ),
        ],
      ),
    );

    if (shouldExport != true || !context.mounted) return;

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final outputPath = await _buildExportPath('finarc_backup_$timestamp.json');
    if (outputPath == null || !context.mounted) return;

    try {
      await ref
          .read(backupServiceProvider)
          .exportBackupToFile(filePath: outputPath);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup exported to: $outputPath')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Backup export failed: $error')));
    }
  }

  Future<void> _exportCsv(
    BuildContext context,
    WidgetRef ref, {
    required String fileNamePrefix,
    required String label,
    required Future<String> Function() exporter,
  }) async {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final outputPath = await _buildExportPath(
      '${fileNamePrefix}_$timestamp.csv',
    );
    if (outputPath == null || !context.mounted) return;

    try {
      final csv = await exporter();
      await ref
          .read(backupServiceProvider)
          .writeStringToFile(filePath: outputPath, content: csv);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label exported to: $outputPath')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$label export failed: $error')));
    }
  }

  Future<void> _pickAndImportBackup(BuildContext context, WidgetRef ref) async {
    final selectedPath = await _askImportPath(context);
    if (selectedPath == null || !context.mounted) return;
    String? jsonText;
    if (await File(selectedPath).exists()) {
      jsonText = await File(selectedPath).readAsString();
    }
    if (!context.mounted) return;
    if (jsonText == null || jsonText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to read selected backup file.')),
      );
      return;
    }

    final importService = ref.read(importServiceProvider);
    final validation = importService.validateBackupJson(jsonText);
    if (!context.mounted) return;
    if (!validation.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid backup: ${validation.message}')),
      );
      return;
    }

    final preview = importService.previewBackup(jsonText);
    final shouldImport = await _showImportPreviewDialog(context, preview);
    if (shouldImport != true || !context.mounted) return;

    try {
      final result = await importService.importBackupReplaceAll(jsonText);
      _invalidateAfterDataChange(ref);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup imported successfully.')),
      );
      context.go(result.onboardingCompleted ? '/' : '/onboarding');
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Import failed: $error')));
    }
  }

  Future<String?> _buildExportPath(String fileName) async {
    final baseDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(baseDir.path, 'exports'));
    await backupDir.create(recursive: true);
    return p.join(backupDir.path, fileName);
  }

  Future<String?> _askImportPath(BuildContext context) async {
    final controller = TextEditingController();
    final baseDir = await getApplicationDocumentsDirectory();
    if (!context.mounted) return null;
    controller.text = p.join(baseDir.path, 'exports', 'finarc_backup.json');

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Backup JSON'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste the local JSON backup file path to import (replace all).',
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Backup file path',
                hintText: '/storage/emulated/0/Download/finarc_backup.json',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result.isEmpty) return null;
    return result;
  }

  Future<bool?> _showImportPreviewDialog(
    BuildContext context,
    BackupPreview preview,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Backup (Replace All)'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'This will permanently replace all local Finarc data on this device.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Created: ${preview.createdAt?.toLocal().toString() ?? '-'}',
              ),
              Text('Backup version: ${preview.backupVersion}'),
              Text('Schema version: ${preview.schemaVersion}'),
              const SizedBox(height: AppSpacing.sm),
              ...preview.counts.entries.map(
                (entry) => Text('${entry.key}: ${entry.value}'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Import & Replace'),
          ),
        ],
      ),
    );
  }

  void _invalidateAfterDataChange(WidgetRef ref) {
    ref.invalidate(dashboardProvider);
    ref.invalidate(accountsOverviewProvider);
    ref.invalidate(cardsOverviewProvider);
    ref.invalidate(expenseListProvider);
    ref.invalidate(pendingTransactionsProvider);
    ref.invalidate(pendingCountProvider);
    ref.invalidate(splitDashboardProvider);
    ref.invalidate(loansDashboardProvider);
    ref.invalidate(alertsInboxProvider);
    ref.invalidate(alertsUnreadCountProvider);
    ref.invalidate(latestImportantAlertProvider);
    ref.invalidate(onboardingCompletedProvider);
    ref.invalidate(detectionSettingsProvider);
    ref.invalidate(_localRowsSummaryProvider);
  }

  Widget _settingToggle(
    BuildContext context, {
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Switch.adaptive(value: value, onChanged: onChanged),
      ],
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

  Future<void> _confirmResetAllData(BuildContext context, WidgetRef ref) async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete all data?'),
          content: const Text(
            'This permanently deletes all local Finarc data on this device. This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldReset != true) return;

    final verification = await ResetDataService(
      ref.read(appDatabaseProvider),
    ).wipeAllUserDataAndRestartOnboarding();

    _invalidateAfterDataChange(ref);

    if (context.mounted) {
      if (!verification.isClean) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reset verification failed. Please try again.'),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All local data deleted. Starting fresh.'),
        ),
      );
      context.go('/onboarding');
    }
  }
}
