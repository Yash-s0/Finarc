import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/logging/logging_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../data/pending_providers.dart';
import '../notifications/notification_ingestion_service.dart';
import '../notifications/notification_log_sanitizer.dart';
import '../notifications/notification_providers.dart';
import '../parsing/parser_models.dart';

class ManualMessageParserScreen extends ConsumerStatefulWidget {
  const ManualMessageParserScreen({super.key});

  @override
  ConsumerState<ManualMessageParserScreen> createState() =>
      _ManualMessageParserScreenState();
}

class _ManualMessageParserScreenState
    extends ConsumerState<ManualMessageParserScreen> {
  final _rawText = TextEditingController();
  final _sender = TextEditingController();
  final _packageName = TextEditingController();
  String _sourceType = 'sms';
  String? _analysisTitle;
  String? _analysisBody;
  bool _isParsing = false;

  @override
  void dispose() {
    _rawText.dispose();
    _sender.dispose();
    _packageName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FinarcScaffold(
      appBar: FinarcAppBar(title: 'Paste Message'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            'Paste a bank, wallet, card, or UPI message to create a pending transaction.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _sourceChip('sms', 'SMS'),
              _sourceChip('upiNotification', 'UPI'),
              _sourceChip('appNotification', 'Notification'),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          FinarcTextField(
            controller: _rawText,
            label: 'Message text',
            maxLines: 8,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: FinarcTextField(controller: _sender, label: 'Sender'),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FinarcTextField(
                  controller: _packageName,
                  label: 'Package',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FinarcPrimaryButton(
            onPressed: _isParsing ? null : _parsePastedMessage,
            label: _isParsing ? 'Parsing...' : 'Parse & Add',
            icon: Icons.playlist_add_check_circle_outlined,
          ),
          if (_analysisTitle != null && _analysisBody != null) ...[
            const SizedBox(height: AppSpacing.md),
            FinarcCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _analysisTitle!,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _analysisBody!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          FinarcSecondaryButton(
            onPressed: () => context.push('/profile/developer-space'),
            icon: Icons.developer_mode_outlined,
            label: 'Open Developer Space',
          ),
        ],
      ),
    );
  }

  Widget _sourceChip(String value, String label) {
    return FinarcActionChip(
      label: label,
      selected: _sourceType == value,
      onTap: () => setState(() => _sourceType = value),
    );
  }

  Future<void> _parsePastedMessage() async {
    final raw = _rawText.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter message text.')));
      return;
    }

    setState(() {
      _isParsing = true;
      _analysisTitle = null;
      _analysisBody = null;
    });

    final input = ParserInput(
      rawText: raw,
      sourceType: _sourceType,
      sender: _sender.text.trim().isEmpty ? null : _sender.text.trim(),
      packageName: _packageName.text.trim().isEmpty
          ? 'manual-paste'
          : _packageName.text.trim(),
      receivedAt: DateTime.now(),
      notificationTitle: null,
      notificationBody: null,
    );

    try {
      final action = ref.read(pendingActionProvider);
      final preview = action.previewParsedInput(input);
      final created = await action.ingestParsedInput(input);
      await _recordManualPasteDiagnostic(
        input: input,
        preview: preview,
        created: created,
      );

      if (!mounted) return;
      final analysis = _manualPasteAnalysis(preview, created);
      setState(() {
        _analysisTitle = analysis.title;
        _analysisBody = analysis.body;
        _isParsing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            created.isEmpty
                ? 'No pending transaction created. See analysis below.'
                : 'Created ${created.length} pending transaction(s).',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _analysisTitle = 'Parse failed';
        _analysisBody =
            'The pasted message could not be processed. This sample was not added.';
        _isParsing = false;
      });
    }
  }

  Future<void> _recordManualPasteDiagnostic({
    required ParserInput input,
    required ParserResult preview,
    required List<int> created,
  }) async {
    final best = preview.candidates.isEmpty ? null : preview.candidates.first;
    final analysis = _manualPasteAnalysis(preview, created);
    final entry = NotificationDebugEntry(
      receivedAt: input.receivedAt,
      packageName: input.packageName ?? input.sender ?? 'manual-paste',
      title: 'Manual paste',
      bodyPreview: input.rawText.length > 600
          ? '${input.rawText.substring(0, 600)}...'
          : input.rawText,
      decision: created.isEmpty ? 'parsed' : 'pending-created',
      reason: analysis.reason,
      result: analysis.parseResult,
      parseResult: analysis.parseResult,
      sourceType: 'manualPaste',
      confidenceScore: best?.confidenceScore,
      confidenceLevel: best?.confidenceLevel,
      candidateCount: preview.candidates.length,
      transactionDateChosen: best?.transactionDate,
      sender: input.sender,
    );
    ref.read(notificationDebugLogProvider.notifier).append(entry);
    await ref
        .read(missedMessageSampleServiceProvider)
        .recordFromDebugEntry(entry, createdPendingCount: created.length);
    await ref
        .read(appLogServiceProvider)
        .log(
          category: 'notification_event',
          message: entry.decision,
          meta: notificationDiskLogMeta(entry),
        );
    ref.invalidate(notificationDiagnosticsSnapshotProvider);
  }

  _ManualPasteAnalysis _manualPasteAnalysis(
    ParserResult preview,
    List<int> created,
  ) {
    final candidateCount = preview.candidates.length;
    if (candidateCount == 0) {
      final warning = preview.warnings?.join(' ') ?? '';
      return _ManualPasteAnalysis(
        title: 'No transaction detected',
        body:
            'No parser produced a transaction candidate. ${warning.isEmpty ? 'This wording likely needs a new parser pattern.' : warning} Saved to Developer Space for parser improvement.',
        reason: 'manual-paste-parser-no-candidate',
        parseResult: 'parser-failed',
      );
    }

    final best = preview.candidates.first;
    if (created.isNotEmpty) {
      return _ManualPasteAnalysis(
        title: 'Pending transaction created',
        body:
            '${preview.parserName} found $candidateCount candidate(s). Best match: ${best.merchant}, ${inr(best.amount)}, confidence ${best.confidenceLevel ?? best.confidenceScore.toStringAsFixed(2)}. If the original notification was missed, notification delivery, package/sender filtering, or duplicate suppression likely blocked it before parsing.',
        reason: 'manual-paste-created',
        parseResult: 'parsed-pending-created',
      );
    }

    final isLow = (best.confidenceLevel ?? '').toUpperCase() == 'LOW';
    return _ManualPasteAnalysis(
      title: isLow ? 'Candidate was low confidence' : 'Parsed but not added',
      body: isLow
          ? '${preview.parserName} found a candidate, but confidence was low (${best.confidenceScore.toStringAsFixed(2)}). Add stronger amount, merchant, date, or source-hint handling for this wording.'
          : '${preview.parserName} found $candidateCount candidate(s), but ingestion skipped them. This is usually duplicate/reference suppression or an existing pending match.',
      reason: isLow ? 'manual-paste-low-confidence' : 'manual-paste-skipped',
      parseResult: isLow ? 'parsed-low-confidence' : 'duplicate-or-skipped',
    );
  }
}

class _ManualPasteAnalysis {
  const _ManualPasteAnalysis({
    required this.title,
    required this.body,
    required this.reason,
    required this.parseResult,
  });

  final String title;
  final String body;
  final String reason;
  final String parseResult;
}
