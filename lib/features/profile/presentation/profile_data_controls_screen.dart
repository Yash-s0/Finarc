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
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../accounts/data/accounts_providers.dart';
import '../../alerts/data/alerts_providers.dart';
import '../../cards/data/cards_providers.dart';
import '../../dashboard/data/dashboard_providers.dart';
import '../../expenses/data/expenses_providers.dart';
import '../../loans/data/loans_providers.dart';
import '../../onboarding/data/onboarding_providers.dart';
import '../../pending/data/pending_providers.dart';
import '../../pending/notifications/notification_providers.dart';
import '../../split/data/split_providers.dart';
import 'widgets/profile_sections.dart';

final _localRowsSummaryProvider = FutureProvider<LocalRowsSummary>((ref) async {
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

  return LocalRowsSummary(
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

class ProfileDataControlsScreen extends ConsumerWidget {
  const ProfileDataControlsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localRowsSummary = kDebugMode
        ? ref.watch(_localRowsSummaryProvider).valueOrNull
        : null;

    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Data Controls'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          FinarcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.admin_panel_settings_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Local data stays under your control',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Export backups, import saved data, or reset this device. No cloud sync is used.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          DataControlsSection(
            onExportBackup: () => _confirmExportFullBackup(context, ref),
            onImportBackup: () => _pickAndImportBackup(context, ref),
            onImportTransactions: () =>
                context.push(AppRoutes.transactionImport),
            onExportTransactions: () => _exportCsv(
              context,
              ref,
              fileNamePrefix: 'finarc_transactions',
              label: 'Transactions CSV',
              exporter: () =>
                  ref.read(backupServiceProvider).exportTransactionsCsv(),
            ),
            onExportExpenses: () => _exportCsv(
              context,
              ref,
              fileNamePrefix: 'finarc_expenses',
              label: 'Expenses CSV',
              exporter: () =>
                  ref.read(backupServiceProvider).exportExpensesCsv(),
            ),
            onExportAccounts: () => _exportCsv(
              context,
              ref,
              fileNamePrefix: 'finarc_accounts',
              label: 'Accounts CSV',
              exporter: () =>
                  ref.read(backupServiceProvider).exportAccountsCsv(),
            ),
            onExportCards: () => _exportCsv(
              context,
              ref,
              fileNamePrefix: 'finarc_cards',
              label: 'Cards CSV',
              exporter: () => ref.read(backupServiceProvider).exportCardsCsv(),
            ),
            onResetAll: () => _confirmResetAllData(context, ref),
            localRowsSummary: localRowsSummary,
          ),
        ],
      ),
    );
  }
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
        'This creates a readable local JSON backup file. This file contains financial data. Keep it private.',
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
      const SnackBar(
        content: Text(
          'Backup exported. This file contains financial data. Keep it private.',
        ),
      ),
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
  final shouldExport = await _confirmCsvExport(context, label);
  if (shouldExport != true || !context.mounted) return;

  final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
  final outputPath = await _buildExportPath('${fileNamePrefix}_$timestamp.csv');
  if (outputPath == null || !context.mounted) return;

  try {
    final csv = await exporter();
    await ref
        .read(backupServiceProvider)
        .writeStringToFile(filePath: outputPath, content: csv);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$label exported. This file contains financial data. Keep it private.',
        ),
      ),
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
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Only import a backup file you trust. Existing local data will be deleted before restore.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Created: ${preview.createdAt?.toLocal().toString() ?? '-'}'),
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

Future<bool?> _confirmCsvExport(BuildContext context, String label) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Export $label?'),
      content: const Text(
        'This file contains financial data. Keep it private.',
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
      const SnackBar(content: Text('All local data deleted. Starting fresh.')),
    );
    context.go('/onboarding');
  }
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
