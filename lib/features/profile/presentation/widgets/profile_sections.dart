import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../../pending/notifications/detection_settings.dart';
import '../../../pending/notifications/ingestion_diagnostics.dart';

class LocalRowsSummary {
  const LocalRowsSummary({
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

class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({
    super.key,
    required this.name,
    required this.monthlySalary,
    required this.salaryCreditDay,
    required this.companyName,
    required this.onEdit,
  });

  final String? name;
  final double? monthlySalary;
  final int? salaryCreditDay;
  final String? companyName;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final trimmedName = name?.trim();
    final hasName = trimmedName != null && trimmedName.isNotEmpty;
    final trimmedCompany = companyName?.trim();
    final hasCompany = trimmedCompany != null && trimmedCompany.isNotEmpty;
    return FinarcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile & Salary',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('Name: ${hasName ? trimmedName : 'Add your name'}'),
          Text('Company: ${hasCompany ? trimmedCompany : 'Add company'}'),
          Text(
            monthlySalary != null
                ? 'Monthly salary: ${inr(monthlySalary!)}'
                : 'Monthly salary: Add salary',
          ),
          Text(
            salaryCreditDay != null
                ? 'Salary credit day: $salaryCreditDay'
                : 'Salary credit day: Add salary day',
          ),
          const SizedBox(height: AppSpacing.sm),
          FinarcSecondaryButton(
            onPressed: onEdit,
            icon: Icons.edit_outlined,
            label: 'Edit',
          ),
        ],
      ),
    );
  }
}

class DataControlsEntryCard extends StatelessWidget {
  const DataControlsEntryCard({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return FinarcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.folder_copy_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data Controls',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Manage local backups, imports, exports and reset options.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          FinarcSecondaryButton(
            onPressed: onOpen,
            icon: Icons.arrow_forward_rounded,
            label: 'Open Data Controls',
          ),
        ],
      ),
    );
  }
}

class DataControlsSection extends StatelessWidget {
  const DataControlsSection({
    super.key,
    required this.onExportBackup,
    required this.onImportBackup,
    required this.onImportTransactions,
    required this.onExportTransactions,
    required this.onExportExpenses,
    required this.onExportAccounts,
    required this.onExportCards,
    required this.onResetAll,
    this.localRowsSummary,
  });

  final VoidCallback onExportBackup;
  final VoidCallback onImportBackup;
  final VoidCallback onImportTransactions;
  final VoidCallback onExportTransactions;
  final VoidCallback onExportExpenses;
  final VoidCallback onExportAccounts;
  final VoidCallback onExportCards;
  final VoidCallback onResetAll;
  final LocalRowsSummary? localRowsSummary;

  @override
  Widget build(BuildContext context) {
    return FinarcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Data Controls', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Manual local backup/export/import. No cloud sync is used.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          FinarcSecondaryButton(
            onPressed: onExportBackup,
            label: 'Export Full Backup',
            icon: Icons.download_rounded,
          ),
          const SizedBox(height: AppSpacing.xs),
          FinarcSecondaryButton(
            onPressed: onImportBackup,
            label: 'Import Full Backup',
            icon: Icons.upload_file_rounded,
          ),
          const SizedBox(height: AppSpacing.xs),
          FinarcSecondaryButton(
            onPressed: onImportTransactions,
            label: 'Import Transactions',
            icon: Icons.playlist_add_check_circle_outlined,
          ),
          const SizedBox(height: AppSpacing.sm),
          FinarcSecondaryButton(
            onPressed: onExportTransactions,
            label: 'Export Transactions CSV',
            icon: Icons.receipt_long_outlined,
          ),
          const SizedBox(height: AppSpacing.xs),
          FinarcSecondaryButton(
            onPressed: onExportExpenses,
            label: 'Export Expenses CSV',
            icon: Icons.trending_down_rounded,
          ),
          const SizedBox(height: AppSpacing.xs),
          FinarcSecondaryButton(
            onPressed: onExportAccounts,
            label: 'Export Accounts CSV',
            icon: Icons.account_balance_outlined,
          ),
          const SizedBox(height: AppSpacing.xs),
          FinarcSecondaryButton(
            onPressed: onExportCards,
            label: 'Export Cards CSV',
            icon: Icons.credit_card_outlined,
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
            onPressed: onResetAll,
            label: 'Delete All Data & Start Fresh',
            icon: Icons.delete_forever_outlined,
          ),
          if (kDebugMode && localRowsSummary != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Local rows: accounts ${localRowsSummary!.accounts}, cards ${localRowsSummary!.cards}, txns ${localRowsSummary!.transactions}, pending ${localRowsSummary!.pending}, splits ${localRowsSummary!.splits}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class NotificationTestingSection extends StatelessWidget {
  const NotificationTestingSection({
    super.key,
    required this.notificationAccessBadge,
    required this.smsAccessBadge,
    required this.postNotifBadge,
    required this.detectionEnabled,
    required this.smsDetectionEnabled,
    required this.reminderEnabled,
    required this.diagnostics,
    required this.onRequestNotificationPermission,
    required this.onSendTestNotification,
    required this.onCreateTestAlert,
    required this.onMockTransactionNotification,
    required this.onMockSmsTransaction,
    required this.onOpenAlerts,
    required this.onShowDiagnostics,
    required this.onClearDiagnostics,
  });

  final Widget notificationAccessBadge;
  final Widget smsAccessBadge;
  final Widget postNotifBadge;
  final bool detectionEnabled;
  final bool smsDetectionEnabled;
  final bool reminderEnabled;
  final IngestionDiagnostics diagnostics;
  final VoidCallback onRequestNotificationPermission;
  final VoidCallback onSendTestNotification;
  final VoidCallback onCreateTestAlert;
  final VoidCallback onMockTransactionNotification;
  final VoidCallback onMockSmsTransaction;
  final VoidCallback onOpenAlerts;
  final VoidCallback onShowDiagnostics;
  final VoidCallback onClearDiagnostics;

  @override
  Widget build(BuildContext context) {
    return FinarcCard(
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
              notificationAccessBadge,
              smsAccessBadge,
              postNotifBadge,
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
                label: reminderEnabled ? 'Reminders: On' : 'Reminders: Off',
                tone: reminderEnabled
                    ? FinarcStatusTone.success
                    : FinarcStatusTone.neutral,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          FinarcSecondaryButton(
            onPressed: onRequestNotificationPermission,
            icon: Icons.notifications_active_outlined,
            label: 'Request Notification Permission',
          ),
          const SizedBox(height: AppSpacing.xs),
          FinarcPrimaryButton(
            onPressed: onSendTestNotification,
            icon: Icons.send_rounded,
            label: 'Send Test Notification',
          ),
          const SizedBox(height: AppSpacing.xs),
          FinarcSecondaryButton(
            onPressed: onCreateTestAlert,
            icon: Icons.add_alert_rounded,
            label: 'Create Test Alert',
          ),
          const SizedBox(height: AppSpacing.xs),
          FinarcSecondaryButton(
            onPressed: onMockTransactionNotification,
            icon: Icons.notifications_outlined,
            label: 'Mock Transaction Notification',
          ),
          const SizedBox(height: AppSpacing.xs),
          FinarcSecondaryButton(
            onPressed: onMockSmsTransaction,
            icon: Icons.sms_outlined,
            label: 'Mock SMS Transaction',
          ),
          const SizedBox(height: AppSpacing.xs),
          FinarcSecondaryButton(
            onPressed: onOpenAlerts,
            icon: Icons.open_in_new_rounded,
            label: 'Open Alerts Center',
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
          FinarcSecondaryButton(
            onPressed: onShowDiagnostics,
            icon: Icons.analytics_outlined,
            label: 'Show Ingestion Diagnostics',
          ),
          const SizedBox(height: AppSpacing.xs),
          FinarcSecondaryButton(
            onPressed: onClearDiagnostics,
            icon: Icons.delete_sweep_outlined,
            label: 'Clear Ingestion Diagnostics',
          ),
        ],
      ),
    );
  }
}

class DetectionSettingsSection extends StatelessWidget {
  const DetectionSettingsSection({
    super.key,
    required this.accessBadge,
    required this.smsAccessBadge,
    required this.notificationIngestionAvailable,
    required this.smsIngestionAvailable,
    required this.detectionEnabled,
    required this.smsDetectionEnabled,
    required this.onOpenNotificationSetup,
    required this.onOpenNotificationDiagnostics,
    required this.onOpenSmsSetup,
    required this.onDetectionToggle,
    required this.onSmsDetectionToggle,
  });

  final Widget accessBadge;
  final Widget smsAccessBadge;
  final bool notificationIngestionAvailable;
  final bool smsIngestionAvailable;
  final bool detectionEnabled;
  final bool smsDetectionEnabled;
  final VoidCallback onOpenNotificationSetup;
  final VoidCallback onOpenNotificationDiagnostics;
  final VoidCallback onOpenSmsSetup;
  final ValueChanged<bool> onDetectionToggle;
  final ValueChanged<bool> onSmsDetectionToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
                'Finarc only checks selected financial notifications and creates pending transactions for your confirmation. Chat and social apps are ignored.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              accessBadge,
              if (!notificationIngestionAvailable) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Notification listener is unavailable in this build.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              FinarcSecondaryButton(
                onPressed: onOpenNotificationSetup,
                label: 'Open Setup',
                icon: Icons.settings_outlined,
              ),
              const SizedBox(height: AppSpacing.xs),
              FinarcSecondaryButton(
                onPressed: onOpenNotificationDiagnostics,
                label: 'Notification Diagnostics',
                icon: Icons.analytics_outlined,
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
                    onChanged: notificationIngestionAvailable
                        ? onDetectionToggle
                        : null,
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
              smsAccessBadge,
              if (!smsIngestionAvailable) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'SMS reading is not available in this build.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              FinarcSecondaryButton(
                onPressed: onOpenSmsSetup,
                label: 'Open SMS Setup',
                icon: Icons.sms_outlined,
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
                    onChanged: smsIngestionAvailable
                        ? onSmsDetectionToggle
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class BackupExportSection extends StatelessWidget {
  const BackupExportSection({
    super.key,
    required this.onOpenLoans,
    required this.onOpenAlerts,
    required this.settings,
    required this.onToggle,
    required this.timeFmt,
    required this.onConfigureQuietHours,
  });

  final VoidCallback onOpenLoans;
  final VoidCallback onOpenAlerts;
  final DetectionSettings? settings;
  final Future<void> Function(String key, bool value) onToggle;
  final String Function(int h, int m) timeFmt;
  final VoidCallback onConfigureQuietHours;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
              FinarcSecondaryButton(
                onPressed: onOpenAlerts,
                label: 'Open Alerts Center',
                icon: Icons.notifications_none_rounded,
              ),
              if (settings != null) ...[
                const SizedBox(height: AppSpacing.xs),
                _toggle(
                  context,
                  'Smart alerts enabled',
                  settings!.smartAlertsEnabled,
                  (v) => onToggle('smartAlertsEnabled', v),
                ),
                _toggle(
                  context,
                  'Low balance alerts',
                  settings!.lowBalanceAlertsEnabled,
                  (v) => onToggle('lowBalanceAlertsEnabled', v),
                ),
                _toggle(
                  context,
                  'Large expense alerts',
                  settings!.largeExpenseAlertsEnabled,
                  (v) => onToggle('largeExpenseAlertsEnabled', v),
                ),
                _toggle(
                  context,
                  'Unusual spending alerts',
                  settings!.unusualSpendingAlertsEnabled,
                  (v) => onToggle('unusualSpendingAlertsEnabled', v),
                ),
                _toggle(
                  context,
                  'Recurring merchant alerts',
                  settings!.recurringMerchantAlertsEnabled,
                  (v) => onToggle('recurringMerchantAlertsEnabled', v),
                ),
                _toggle(
                  context,
                  'Weekly summary alerts',
                  settings!.weeklySummaryAlertsEnabled,
                  (v) => onToggle('weeklySummaryAlertsEnabled', v),
                ),
                _toggle(
                  context,
                  'Monthly summary alerts',
                  settings!.monthlySummaryAlertsEnabled,
                  (v) => onToggle('monthlySummaryAlertsEnabled', v),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Quiet hours: ${timeFmt(settings!.quietHoursStartHour, settings!.quietHoursStartMinute)} - ${timeFmt(settings!.quietHoursEndHour, settings!.quietHoursEndMinute)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                FinarcSecondaryButton(
                  onPressed: onConfigureQuietHours,
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
              FinarcSecondaryButton(
                onPressed: onOpenLoans,
                label: 'Open Loans Dashboard',
                icon: Icons.account_balance_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _toggle(
    BuildContext context,
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Switch.adaptive(value: value, onChanged: onChanged),
      ],
    );
  }
}

class DebugToolsSection extends StatelessWidget {
  const DebugToolsSection({
    super.key,
    required this.onboardingDone,
    required this.onOpenOnboarding,
    required this.onResetOnboarding,
  });

  final bool? onboardingDone;
  final VoidCallback onOpenOnboarding;
  final VoidCallback onResetOnboarding;

  @override
  Widget build(BuildContext context) {
    return FinarcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Setup Status', style: Theme.of(context).textTheme.titleMedium),
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
          FinarcSecondaryButton(
            onPressed: onOpenOnboarding,
            label: 'Open Onboarding',
            icon: Icons.flag_outlined,
          ),
          if (kDebugMode) ...[
            const SizedBox(height: AppSpacing.xs),
            FinarcSecondaryButton(
              onPressed: onResetOnboarding,
              label: 'Reset Onboarding (Debug)',
              icon: Icons.restart_alt_rounded,
            ),
          ],
        ],
      ),
    );
  }
}

class ReleaseDiagnosticsSection extends StatelessWidget {
  const ReleaseDiagnosticsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        FinarcCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.offline_bolt_rounded),
            title: Text('Offline-first mode'),
            subtitle: Text('All data is stored locally on device only.'),
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        FinarcCard(
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
    );
  }
}

class ThemeSettingsSection extends StatelessWidget {
  const ThemeSettingsSection({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
  });

  final ThemeMode currentTheme;
  final ValueChanged<ThemeMode> onThemeChanged;

  @override
  Widget build(BuildContext context) {
    return FinarcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appearance',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Choose your preferred theme.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment<ThemeMode>(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto_rounded),
                label: Text('System'),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_rounded),
                label: Text('Light'),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_rounded),
                label: Text('Dark'),
              ),
            ],
            selected: {currentTheme},
            onSelectionChanged: (Set<ThemeMode> newSelection) {
              onThemeChanged(newSelection.first);
            },
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              selectedForegroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
