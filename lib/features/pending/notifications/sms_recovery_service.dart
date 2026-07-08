import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../cards/data/billing_service.dart';
import '../../expenses/data/transaction_engine.dart';
import '../../expenses/models/transaction_types.dart';
import '../parsing/category_suggester.dart';
import '../parsing/counterparty_normalizer.dart';
import '../parsing/parser_models.dart';
import '../parsing/pending_ingestion_service.dart';
import '../parsing/parser_text_utils.dart';
import '../parsing/transaction_direction_classifier.dart';
import 'notification_keyword_filter.dart';
import 'notification_payload.dart';
import 'sms_permission_service.dart';
import 'sms_sender_filter.dart';

enum SmsBackfillPreviewStatus {
  importable,
  ignored,
  parserFailed,
  sourceMissing,
  duplicateLikely,
  imported,
  importFailed,
}

class SmsBackfillPreview {
  const SmsBackfillPreview({
    required this.id,
    required this.sender,
    required this.body,
    required this.receivedAt,
    required this.status,
    required this.reason,
    required this.payload,
    this.amount,
    this.merchant,
    this.category,
    this.transactionDate,
    this.parserName,
    this.paymentSourceType,
    this.paymentSourceId,
    this.createdTransactionCount = 0,
    this.pendingIds = const [],
  });

  final String id;
  final String sender;
  final String body;
  final DateTime receivedAt;
  final SmsBackfillPreviewStatus status;
  final String reason;
  final NotificationPayload payload;
  final double? amount;
  final String? merchant;
  final String? category;
  final DateTime? transactionDate;
  final String? parserName;
  final String? paymentSourceType;
  final int? paymentSourceId;
  final int createdTransactionCount;
  final List<int> pendingIds;

  bool get canImport => status == SmsBackfillPreviewStatus.importable;
  bool get isTransactionCandidate {
    return amount != null &&
        merchant != null &&
        transactionDate != null &&
        status != SmsBackfillPreviewStatus.ignored &&
        status != SmsBackfillPreviewStatus.parserFailed;
  }

  SmsBackfillPreview copyWith({
    SmsBackfillPreviewStatus? status,
    String? reason,
    double? amount,
    String? merchant,
    String? category,
    DateTime? transactionDate,
    String? paymentSourceType,
    int? paymentSourceId,
    List<int>? pendingIds,
    int? createdTransactionCount,
  }) {
    return SmsBackfillPreview(
      id: id,
      sender: sender,
      body: body,
      receivedAt: receivedAt,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      payload: payload,
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      category: category ?? this.category,
      transactionDate: transactionDate ?? this.transactionDate,
      parserName: parserName,
      paymentSourceType: paymentSourceType ?? this.paymentSourceType,
      paymentSourceId: paymentSourceId ?? this.paymentSourceId,
      createdTransactionCount:
          createdTransactionCount ?? this.createdTransactionCount,
      pendingIds: pendingIds ?? this.pendingIds,
    );
  }
}

class SmsBackfillImportResult {
  const SmsBackfillImportResult({
    required this.importedCount,
    required this.duplicateOrSkippedCount,
    required this.previews,
  });

  final int importedCount;
  final int duplicateOrSkippedCount;
  final List<SmsBackfillPreview> previews;
}

class SmsRecoveryService {
  SmsRecoveryService(
    this._db,
    this._smsPermissionService,
    this._pendingIngestionService,
    this._transactionEngine,
    this._keywordFilter,
    this._senderFilter,
  );

  final AppDatabase _db;
  final SmsPermissionService _smsPermissionService;
  final PendingIngestionService _pendingIngestionService;
  final TransactionEngine _transactionEngine;
  final NotificationKeywordFilter _keywordFilter;
  final SmsSenderFilter _senderFilter;

  Future<List<SmsBackfillPreview>> previewLastDays(int days) async {
    final rows = await _smsPermissionService.previewRecentSms(days);
    return _classifyRows(rows);
  }

  Future<List<SmsBackfillPreview>> previewRange({
    required DateTime from,
    required DateTime to,
  }) async {
    final rows = await _smsPermissionService.previewSmsRange(
      from: from,
      to: to,
    );
    return _classifyRows(rows);
  }

  Future<List<SmsBackfillPreview>> _classifyRows(
    List<SmsPreviewRow> rows,
  ) async {
    final previews = <SmsBackfillPreview>[];
    final seen = <String>{};
    for (final row in rows) {
      final payload = NotificationPayload.fromMap(row.toPayloadMap());
      final id = _fingerprint(
        sender: row.sender,
        body: row.body,
        receivedAt: row.receivedAt,
      );
      if (!seen.add(id)) continue;
      previews.add(await classifyPayload(payload, id: id));
    }
    return previews;
  }

  Future<SmsBackfillPreview> classifyPayload(
    NotificationPayload payload, {
    String? id,
  }) async {
    final sender = payload.sender ?? payload.appName ?? 'SMS';
    final body = payload.body ?? payload.combinedText;
    final previewId =
        id ??
        _fingerprint(
          sender: sender,
          body: body,
          receivedAt: payload.receivedAt,
        );

    final senderResult = _senderFilter.evaluate(payload.sender);
    if (!senderResult.accepted) {
      return _blocked(
        previewId,
        payload,
        senderResult.reason,
        SmsBackfillPreviewStatus.ignored,
      );
    }

    final keywordResult = _keywordFilter.evaluate(payload);
    if (!keywordResult.accepted) {
      return _blocked(
        previewId,
        payload,
        keywordResult.reason,
        SmsBackfillPreviewStatus.ignored,
      );
    }

    if (ParserTextUtils.looksLikeNonExpenseCardMessage(payload.combinedText)) {
      return _blocked(
        previewId,
        payload,
        'non-expense-card-message',
        SmsBackfillPreviewStatus.ignored,
      );
    }

    final parserInput = _parserInputFromPayload(payload);
    final result = _pendingIngestionService.previewParserInput(parserInput);
    if (result.candidates.isEmpty) {
      return _blocked(
        previewId,
        payload,
        _parserFailureReason(result),
        SmsBackfillPreviewStatus.parserFailed,
        parserName: result.parserName,
      );
    }

    final candidate = result.candidates.first;
    final existingEvidence = await _hasSourceEvidence(previewId);
    final duplicate = existingEvidence
        ? const _SmsDuplicateMatch(sourceEvidenceExists: true)
        : await _findLikelyDuplicate(candidate);
    final paymentSourceType =
        candidate.paymentSourceTypeSuggestion ??
        _pendingIngestionService.defaultSourceSuggestion(parserInput);
    final paymentSourceId = await _pendingIngestionService
        .suggestPaymentSourceId(
          sourceType: paymentSourceType,
          sourceHint: candidate.paymentSourceHint,
        );
    if (paymentSourceId == null) {
      return SmsBackfillPreview(
        id: previewId,
        sender: sender,
        body: body,
        receivedAt: payload.receivedAt,
        status: SmsBackfillPreviewStatus.sourceMissing,
        reason: 'Payment source not matched',
        payload: payload,
        amount: candidate.amount,
        merchant: candidate.merchant,
        category:
            candidate.categorySuggestion ??
            CategorySuggester.suggest(candidate.merchant),
        transactionDate: candidate.transactionDate,
        parserName: candidate.parserName,
        paymentSourceType: paymentSourceType,
      );
    }
    return SmsBackfillPreview(
      id: previewId,
      sender: sender,
      body: body,
      receivedAt: payload.receivedAt,
      status: duplicate != null
          ? SmsBackfillPreviewStatus.duplicateLikely
          : SmsBackfillPreviewStatus.importable,
      reason: existingEvidence
          ? 'SMS already imported or attached'
          : duplicate != null
          ? 'Likely already exists'
          : 'Ready to import',
      payload: payload,
      amount: candidate.amount,
      merchant: candidate.merchant,
      category:
          candidate.categorySuggestion ??
          CategorySuggester.suggest(candidate.merchant),
      transactionDate: candidate.transactionDate,
      parserName: candidate.parserName,
      paymentSourceType: paymentSourceType,
      paymentSourceId: paymentSourceId,
    );
  }

  Future<SmsBackfillImportResult> importPreviews(
    Iterable<SmsBackfillPreview> previews,
  ) async {
    var imported = 0;
    var skipped = 0;
    final updated = <SmsBackfillPreview>[];
    for (final preview in previews) {
      if (!preview.canImport &&
          preview.status != SmsBackfillPreviewStatus.duplicateLikely) {
        skipped += 1;
        updated.add(preview);
        continue;
      }
      final candidate = _parseCandidate(preview.payload);
      if (candidate == null) {
        skipped += 1;
        updated.add(
          preview.copyWith(
            status: SmsBackfillPreviewStatus.importFailed,
            reason: 'Skipped by parser during import',
          ),
        );
        continue;
      }
      if (await _hasSourceEvidence(preview.id)) {
        skipped += 1;
        updated.add(
          preview.copyWith(
            status: SmsBackfillPreviewStatus.duplicateLikely,
            reason: 'SMS already imported or attached',
          ),
        );
        continue;
      }
      final duplicate = await _findLikelyDuplicatePreview(preview, candidate);
      if (duplicate != null) {
        if (duplicate.transactionId != null) {
          await _recordSourceEvidence(
            preview: preview,
            candidate: candidate,
            transactionId: duplicate.transactionId,
            status: 'duplicateAttached',
          );
        }
        skipped += 1;
        updated.add(
          preview.copyWith(
            status: SmsBackfillPreviewStatus.duplicateLikely,
            reason: duplicate.transactionId != null
                ? 'SMS proof attached to existing transaction'
                : 'Likely already exists',
          ),
        );
        continue;
      }
      final transactionId = await _addRecoveredTransaction(
        preview: preview,
        candidate: candidate,
      );
      if (transactionId == null) {
        skipped += 1;
        updated.add(
          preview.copyWith(
            status: SmsBackfillPreviewStatus.sourceMissing,
            reason: 'Payment source not matched',
          ),
        );
      } else {
        await _recordSourceEvidence(
          preview: preview,
          candidate: candidate,
          transactionId: transactionId,
          status: 'imported',
        );
        imported += 1;
        updated.add(
          preview.copyWith(
            status: SmsBackfillPreviewStatus.imported,
            reason: 'Added as transaction',
            createdTransactionCount: 1,
          ),
        );
      }
    }
    return SmsBackfillImportResult(
      importedCount: imported,
      duplicateOrSkippedCount: skipped,
      previews: updated,
    );
  }

  ParserInput _parserInputFromPayload(NotificationPayload payload) {
    return ParserInput(
      rawText: payload.combinedText,
      sourceType: 'sms',
      packageName: payload.packageName,
      sender: payload.sender ?? payload.appName,
      receivedAt: payload.captureTime,
      postTime: payload.postTime,
      notificationTitle: payload.title,
      notificationBody: payload.body,
    );
  }

  DetectedTransactionCandidate? _parseCandidate(NotificationPayload payload) {
    final result = _pendingIngestionService.previewParserInput(
      _parserInputFromPayload(payload),
    );
    if (result.candidates.isEmpty) return null;
    return result.candidates.first;
  }

  Future<int?> _addRecoveredTransaction({
    required SmsBackfillPreview preview,
    required DetectedTransactionCandidate candidate,
  }) async {
    final parserInput = _parserInputFromPayload(preview.payload);
    final paymentSourceType =
        candidate.paymentSourceTypeSuggestion ??
        _pendingIngestionService.defaultSourceSuggestion(parserInput);
    final paymentSourceId = preview.paymentSourceType == paymentSourceType
        ? preview.paymentSourceId
        : await _pendingIngestionService.suggestPaymentSourceId(
            sourceType: paymentSourceType,
            sourceHint: candidate.paymentSourceHint,
          );
    if (paymentSourceId == null) return null;

    final category =
        preview.category ??
        candidate.categorySuggestion ??
        CategorySuggester.suggest(candidate.merchant);
    final transactionType = _transactionTypeFor(
      candidate: candidate,
      category: category,
      paymentSourceType: paymentSourceType,
    );
    final amount = preview.amount ?? candidate.amount;
    final merchant = preview.merchant ?? candidate.merchant;
    final transactionDate =
        preview.transactionDate ?? candidate.transactionDate;
    final transactionImpactType = await _transactionImpactTypeFor(
      transactionType: transactionType,
      paymentSourceType: paymentSourceType,
      paymentSourceId: paymentSourceId,
      transactionDate: transactionDate,
    );
    return _transactionEngine.addTransaction(
      AddTransactionInput(
        type: transactionType,
        amount: amount,
        title: merchant,
        category: category,
        notes: 'Imported from SMS recovery',
        transactionDate: transactionDate,
        paymentSourceType: paymentSourceType,
        paymentSourceId: paymentSourceId,
        detectedSourceType: 'smsRecovery',
        transactionImpactType: transactionImpactType,
      ),
    );
  }

  Future<void> _recordSourceEvidence({
    required SmsBackfillPreview preview,
    required DetectedTransactionCandidate candidate,
    required int? transactionId,
    required String status,
  }) async {
    final amount = preview.amount ?? candidate.amount;
    final merchant = preview.merchant ?? candidate.merchant;
    final transactionDate =
        preview.transactionDate ?? candidate.transactionDate;
    await _db
        .into(_db.transactionSourceEvents)
        .insert(
          TransactionSourceEventsCompanion.insert(
            transactionId: Value(transactionId),
            sourceType: 'smsRecovery',
            sourceFingerprint: preview.id,
            status: status,
            sender: Value(preview.sender),
            sourceReceivedAt: Value(preview.receivedAt),
            parserName: Value(preview.parserName ?? candidate.parserName),
            amount: Value(amount),
            merchant: Value(merchant),
            transactionDate: Value(transactionDate),
            rawText: preview.body,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  String _transactionTypeFor({
    required DetectedTransactionCandidate candidate,
    required String category,
    required String paymentSourceType,
  }) {
    if (category.trim().toLowerCase() == 'refund') {
      return TransactionType.refund;
    }
    final direction = PendingDirectionClassifier.detect(
      text: candidate.rawText,
      categoryHint: category,
    );
    if (direction == PendingTransactionDirection.income) {
      return paymentSourceType == PaymentSourceType.creditCard
          ? TransactionType.refund
          : TransactionType.income;
    }
    return paymentSourceType == PaymentSourceType.creditCard
        ? TransactionType.creditCard
        : paymentSourceType;
  }

  Future<String?> _transactionImpactTypeFor({
    required String transactionType,
    required String paymentSourceType,
    required int paymentSourceId,
    required DateTime transactionDate,
  }) async {
    if (paymentSourceType == PaymentSourceType.creditCard) {
      final card = await (_db.select(
        _db.creditCards,
      )..where((c) => c.id.equals(paymentSourceId))).getSingleOrNull();
      if (card != null) {
        return creditCardTransactionImpactTypeForDate(
          card: card,
          transactionDate: transactionDate,
          now: DateTime.now(),
          transactionType: transactionType,
        );
      }
    }
    final date = _dateOnly(transactionDate);
    final today = _dateOnly(DateTime.now());
    return date.isBefore(today)
        ? TransactionImpactType.historicalNoBalance
        : null;
  }

  DateTime _dateOnly(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  SmsBackfillPreview _blocked(
    String id,
    NotificationPayload payload,
    String reason,
    SmsBackfillPreviewStatus status, {
    String? parserName,
  }) {
    return SmsBackfillPreview(
      id: id,
      sender: payload.sender ?? payload.appName ?? 'SMS',
      body: payload.body ?? payload.combinedText,
      receivedAt: payload.receivedAt,
      status: status,
      reason: reason,
      payload: payload,
      parserName: parserName,
    );
  }

  String _parserFailureReason(ParserResult result) {
    final warnings = result.warnings;
    if (warnings != null && warnings.isNotEmpty) return warnings.first;
    final errors = result.errors;
    if (errors != null && errors.isNotEmpty) return errors.first;
    return 'Parser did not find a transaction candidate';
  }

  Future<_SmsDuplicateMatch?> _findLikelyDuplicate(
    DetectedTransactionCandidate candidate,
  ) async {
    return _findLikelyDuplicateValues(
      amount: candidate.amount,
      merchant: candidate.merchant,
      transactionDate: candidate.transactionDate,
    );
  }

  Future<_SmsDuplicateMatch?> _findLikelyDuplicatePreview(
    SmsBackfillPreview preview,
    DetectedTransactionCandidate candidate,
  ) {
    return _findLikelyDuplicateValues(
      amount: preview.amount ?? candidate.amount,
      merchant: preview.merchant ?? candidate.merchant,
      transactionDate: preview.transactionDate ?? candidate.transactionDate,
    );
  }

  Future<_SmsDuplicateMatch?> _findLikelyDuplicateValues({
    required double amount,
    required String merchant,
    required DateTime transactionDate,
  }) async {
    final start = transactionDate.subtract(const Duration(minutes: 10));
    final end = transactionDate.add(const Duration(minutes: 10));
    final transactionRows =
        await (_db.select(_db.transactions)..where(
              (t) =>
                  t.amount.equals(amount) &
                  t.transactionDate.isBiggerOrEqualValue(start) &
                  t.transactionDate.isSmallerOrEqualValue(end),
            ))
            .get();
    for (final row in transactionRows) {
      if (_sameCounterparty(row.title, merchant)) {
        return _SmsDuplicateMatch(transactionId: row.id);
      }
    }

    final pendingRows =
        await (_db.select(_db.pendingTransactions)..where(
              (p) =>
                  p.amount.equals(amount) &
                  p.transactionDate.isBiggerOrEqualValue(start) &
                  p.transactionDate.isSmallerOrEqualValue(end),
            ))
            .get();
    for (final row in pendingRows) {
      if (_sameCounterparty(row.merchant, merchant)) {
        return _SmsDuplicateMatch(pendingId: row.id);
      }
    }

    return null;
  }

  Future<bool> _hasSourceEvidence(String sourceFingerprint) async {
    final row =
        await (_db.select(_db.transactionSourceEvents)..where(
              (event) => event.sourceFingerprint.equals(sourceFingerprint),
            ))
            .getSingleOrNull();
    return row != null;
  }

  bool _sameCounterparty(String existing, String merchant) {
    final left = CounterpartyNormalizer.normalize(existing);
    final right = CounterpartyNormalizer.normalize(merchant);
    if (left.isEmpty || right.isEmpty) return false;
    if (left == right) return true;
    return left.contains(right) || right.contains(left);
  }

  String _fingerprint({
    required String sender,
    required String body,
    required DateTime receivedAt,
  }) {
    final roundedMillis = (receivedAt.millisecondsSinceEpoch ~/ 10000) * 10000;
    final payload =
        '${sender.toLowerCase()}|${body.toLowerCase()}|$roundedMillis';
    var hash = 0xcbf29ce484222325;
    const prime = 0x100000001b3;
    for (final code in payload.codeUnits) {
      hash ^= code;
      hash = (hash * prime) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16);
  }
}

class _SmsDuplicateMatch {
  const _SmsDuplicateMatch({
    this.transactionId,
    this.pendingId,
    this.sourceEvidenceExists = false,
  });

  final int? transactionId;
  final int? pendingId;
  final bool sourceEvidenceExists;

  bool get exists =>
      transactionId != null || pendingId != null || sourceEvidenceExists;
}
