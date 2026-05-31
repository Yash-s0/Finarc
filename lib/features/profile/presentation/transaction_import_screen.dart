import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../accounts/data/accounts_providers.dart';
import '../../alerts/data/alerts_providers.dart';
import '../../analytics/data/analytics_providers.dart';
import '../../cards/data/cards_providers.dart';
import '../../dashboard/data/dashboard_providers.dart';
import '../../expenses/data/expenses_providers.dart';
import '../../loans/data/loans_providers.dart';
import '../../pending/data/pending_providers.dart';
import '../../profile/data/profile_settings_providers.dart';
import '../../split/data/split_providers.dart';
import '../data/transaction_import_models.dart';
import '../data/transaction_import_providers.dart';

const _sampleImportJson = '''{
  "transactions": [
    {
      "date": "2026-05-31T14:30:00",
      "amount": 401,
      "type": "expense",
      "title": "Amazon",
      "category": "Groceries",
      "paymentMode": "card",
      "sourceName": "ICICI Amazon",
      "cashback": 70,
      "forOthers": true,
      "personName": "Rahul",
      "recoveredAmount": 0,
      "notes": "optional"
    }
  ]
}''';

const _sampleIncomeJson = '''{
  "transactions": [
    {
      "date": "2026-05-31T10:00:00",
      "amount": 85000,
      "type": "income",
      "title": "Monthly Salary",
      "category": "Salary",
      "paymentMode": "bank",
      "sourceName": "Salary Account",
      "notes": "May salary"
    }
  ]
}''';

const _sampleUpiJson = '''{
  "transactions": [
    {
      "date": "2026-05-31T19:20:00",
      "amount": 240,
      "type": "expense",
      "title": "Tea Shop",
      "paymentMode": "upi",
      "sourceName": "HDFC Main",
      "notes": "UPI payment"
    }
  ]
}''';

class TransactionImportScreen extends ConsumerStatefulWidget {
  const TransactionImportScreen({super.key});

  @override
  ConsumerState<TransactionImportScreen> createState() =>
      _TransactionImportScreenState();
}

class _TransactionImportScreenState
    extends ConsumerState<TransactionImportScreen> {
  bool _pickingFile = false;

  @override
  Widget build(BuildContext context) {
    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Transaction Import'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          FinarcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FinarcSectionHeader(title: 'Import Transactions'),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Import JSON rows into normal transactions using current engine rules.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                FinarcPrimaryButton(
                  onPressed: _pickingFile ? null : _pickJsonFile,
                  icon: Icons.file_open_outlined,
                  label: _pickingFile
                      ? 'Opening file picker...'
                      : 'Import JSON File',
                ),
                const SizedBox(height: AppSpacing.xs),
                FinarcSecondaryButton(
                  onPressed: () =>
                      context.push('/profile/transaction-import/paste'),
                  icon: Icons.edit_note_rounded,
                  label: 'Paste/Create JSON',
                ),
                const SizedBox(height: AppSpacing.xs),
                FinarcSecondaryButton(
                  onPressed: () =>
                      context.push('/profile/transaction-import/sample-format'),
                  icon: Icons.article_outlined,
                  label: 'View Sample Format',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickJsonFile() async {
    setState(() => _pickingFile = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );
      if (!mounted || result == null || result.files.isEmpty) return;

      final file = result.files.first;
      String? jsonText;
      if (file.bytes != null) {
        jsonText = utf8.decode(file.bytes!, allowMalformed: true);
      } else if (file.path != null && file.path!.isNotEmpty) {
        jsonText = await File(file.path!).readAsString();
      }

      if (!mounted) return;
      if (jsonText == null || jsonText.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to read selected JSON file.')),
        );
        return;
      }
      await _openPreview(jsonText);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open JSON file: $error')),
      );
    } finally {
      if (mounted) setState(() => _pickingFile = false);
    }
  }

  Future<void> _openPreview(String jsonText) async {
    final parsed = await ref
        .read(transactionImportServiceProvider)
        .parsePreview(jsonText);
    if (!mounted) return;
    if (!parsed.isValidJson || parsed.preview == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(parsed.message)));
      return;
    }

    await context.push(
      '/profile/transaction-import/preview',
      extra: parsed.preview,
    );
  }
}

class TransactionImportPasteScreen extends ConsumerStatefulWidget {
  const TransactionImportPasteScreen({super.key});

  @override
  ConsumerState<TransactionImportPasteScreen> createState() =>
      _TransactionImportPasteScreenState();
}

class _TransactionImportPasteScreenState
    extends ConsumerState<TransactionImportPasteScreen> {
  final _controller = TextEditingController();
  bool _running = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Paste Transaction JSON'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          FinarcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FinarcSectionHeader(title: 'Paste/Create JSON'),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _controller,
                  minLines: 14,
                  maxLines: 22,
                  style: Theme.of(context).textTheme.bodySmall,
                  decoration: const InputDecoration(
                    hintText: '{"transactions": [...] }',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                FinarcSecondaryButton(
                  onPressed: _running
                      ? null
                      : () => setState(
                          () => _controller.text = _sampleImportJson,
                        ),
                  icon: Icons.auto_fix_high_outlined,
                  label: 'Insert Sample JSON',
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: FinarcSecondaryButton(
                        onPressed: _running ? null : _validate,
                        icon: Icons.verified_outlined,
                        label: 'Validate',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: FinarcPrimaryButton(
                        onPressed: _running ? null : _preview,
                        icon: Icons.preview_outlined,
                        label: 'Preview Import',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _validate() async {
    await _runParsing(showPreview: false);
  }

  Future<void> _preview() async {
    await _runParsing(showPreview: true);
  }

  Future<void> _runParsing({required bool showPreview}) async {
    final jsonText = _controller.text.trim();
    if (jsonText.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Paste JSON first.')));
      return;
    }

    setState(() => _running = true);
    try {
      final parsed = await ref
          .read(transactionImportServiceProvider)
          .parsePreview(jsonText);
      if (!mounted) return;

      if (!parsed.isValidJson || parsed.preview == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(parsed.message)));
        return;
      }

      final preview = parsed.preview!;
      if (!showPreview) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Validated: ${preview.validRows} valid, ${preview.invalidRows} invalid.',
            ),
          ),
        );
        return;
      }

      await context.push('/profile/transaction-import/preview', extra: preview);
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }
}

class TransactionImportPreviewScreen extends ConsumerStatefulWidget {
  const TransactionImportPreviewScreen({super.key, required this.preview});

  final TransactionImportPreview preview;

  @override
  ConsumerState<TransactionImportPreviewScreen> createState() =>
      _TransactionImportPreviewScreenState();
}

class _TransactionImportPreviewScreenState
    extends ConsumerState<TransactionImportPreviewScreen> {
  bool _importing = false;

  @override
  Widget build(BuildContext context) {
    final preview = widget.preview;
    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Import Preview'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          FinarcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FinarcSectionHeader(title: 'Summary'),
                const SizedBox(height: AppSpacing.xs),
                Text('Total rows: ${preview.totalRows}'),
                Text('Valid rows: ${preview.validRows}'),
                Text('Invalid rows: ${preview.invalidRows}'),
                Text('Total expense: ${inr(preview.totalExpenseAmount)}'),
                Text('Total income: ${inr(preview.totalIncomeAmount)}'),
                if (preview.generalWarnings.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  ...preview.generalWarnings.map(
                    (warning) => Text('• $warning'),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                if (preview.validRows > 0)
                  FinarcPrimaryButton(
                    onPressed: _importing ? null : _import,
                    icon: Icons.download_done_rounded,
                    label: _importing
                        ? 'Importing...'
                        : 'Import Valid Rows Only (${preview.validRows})',
                  ),
                if (preview.validRows == 0)
                  const FinarcStatusBadge(
                    label: 'No valid rows to import',
                    tone: FinarcStatusTone.warning,
                    compact: true,
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...preview.rows.map((row) => _PreviewRowCard(row: row)),
        ],
      ),
    );
  }

  Future<void> _import() async {
    setState(() => _importing = true);
    try {
      final result = await ref
          .read(transactionImportServiceProvider)
          .importValidRows(widget.preview);
      _invalidateAfterImport(ref);
      if (!mounted) return;
      await context.push('/profile/transaction-import/result', extra: result);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  void _invalidateAfterImport(WidgetRef ref) {
    ref.invalidate(accountsOverviewProvider);
    ref.invalidate(cardsOverviewProvider);
    ref.invalidate(expenseListProvider);
    ref.invalidate(dashboardProvider);
    ref.invalidate(analyticsSnapshotProvider);
    ref.invalidate(splitDashboardProvider);
    ref.invalidate(loansDashboardProvider);
    ref.invalidate(pendingTransactionsProvider);
    ref.invalidate(pendingCountProvider);
    ref.invalidate(alertsInboxProvider);
    ref.invalidate(alertsUnreadCountProvider);
    ref.invalidate(latestImportantAlertProvider);
    ref.invalidate(userProfileSettingsProvider);
  }
}

class _PreviewRowCard extends StatelessWidget {
  const _PreviewRowCard({required this.row});

  final TransactionImportPreviewRow row;

  @override
  Widget build(BuildContext context) {
    final isValid = row.isValid;
    final warnings = row.issues.where((issue) => issue.isWarning).toList();
    final errors = row.issues.where((issue) => !issue.isWarning).toList();
    final amount = row.raw['amount']?.toString() ?? '-';
    final title = row.raw['title']?.toString() ?? 'Untitled';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: FinarcCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Row ${row.rowNumber}: $title',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                FinarcStatusBadge(
                  label: isValid ? 'VALID' : 'INVALID',
                  tone: isValid
                      ? (warnings.isEmpty
                            ? FinarcStatusTone.success
                            : FinarcStatusTone.info)
                      : FinarcStatusTone.warning,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text('Amount: $amount'),
            if (row.resolved != null)
              Text(
                'Source: ${row.resolved!.sourceLabel} (${row.resolved!.paymentMode})',
              ),
            if (errors.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xxs),
              ...errors.map((issue) => Text('• ${issue.message}')),
            ],
            if (warnings.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xxs),
              ...warnings.map(
                (issue) => Text(
                  '⚠ ${issue.message}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class TransactionImportResultScreen extends StatelessWidget {
  const TransactionImportResultScreen({super.key, required this.result});

  final TransactionImportExecutionResult result;

  @override
  Widget build(BuildContext context) {
    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Import Result'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          FinarcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FinarcSectionHeader(title: 'Import Completed'),
                const SizedBox(height: AppSpacing.sm),
                Text('Total rows: ${result.totalRows}'),
                Text('Imported: ${result.importedCount}'),
                Text('Skipped: ${result.skippedCount}'),
                Text('Failed: ${result.failedCount}'),
                const SizedBox(height: AppSpacing.sm),
                FinarcPrimaryButton(
                  onPressed: () => context.go('/profile'),
                  icon: Icons.check_circle_outline,
                  label: 'Done',
                ),
              ],
            ),
          ),
          if (result.failureReasons.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            FinarcCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FinarcSectionHeader(title: 'Failure Reasons'),
                  const SizedBox(height: AppSpacing.xs),
                  ...result.failureReasons.map((reason) => Text('• $reason')),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class TransactionImportSampleFormatScreen extends StatelessWidget {
  const TransactionImportSampleFormatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Supported JSON Format'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _SampleCard(title: 'Minimal Sample', content: _sampleImportJson),
          const SizedBox(height: AppSpacing.sm),
          _SampleCard(
            title: 'For Others + Card Sample',
            content: _sampleImportJson,
          ),
          const SizedBox(height: AppSpacing.sm),
          _SampleCard(title: 'Income Sample', content: _sampleIncomeJson),
          const SizedBox(height: AppSpacing.sm),
          _SampleCard(title: 'Bank/UPI Sample', content: _sampleUpiJson),
        ],
      ),
    );
  }
}

class _SampleCard extends StatelessWidget {
  const _SampleCard({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return FinarcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              content,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
