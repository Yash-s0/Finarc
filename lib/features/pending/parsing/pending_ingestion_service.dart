import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/logging/app_log_service.dart';
import '../../expenses/models/transaction_types.dart';
import '../data/pending_service.dart';
import 'category_suggester.dart';
import 'confidence_level.dart';
import 'parser_models.dart';
import 'parser_confidence_scorer.dart';
import 'transaction_parser_registry.dart';

class PendingIngestionService {
  PendingIngestionService(this._db, this._pendingService, this._parserRegistry);

  final AppDatabase _db;
  final PendingService _pendingService;
  final TransactionParserRegistry _parserRegistry;

  ParserResult previewParserInput(ParserInput input) {
    return _parserRegistry.parseInput(input);
  }

  Future<List<int>> ingestParserInput(ParserInput input) async {
    final result = previewParserInput(input);
    await globalAppLogService.log(
      category: 'parser',
      message: 'parse-complete',
      meta: <String, Object?>{
        'sourceType': input.sourceType,
        'candidateCount': result.candidates.length,
      },
    );
    if (result.candidates.isEmpty) return const [];

    final createdIds = <int>[];
    final seenReferencesInPayload = <String>{};

    for (final candidate in result.candidates) {
      final candidateRef = _extractReference(candidate);
      if (candidateRef != null) {
        final payloadRefKey =
            '${candidate.amount.toStringAsFixed(2)}|${candidateRef.toLowerCase()}';
        if (seenReferencesInPayload.contains(payloadRefKey)) {
          await globalAppLogService.log(
            category: 'parser',
            message: 'candidate-deduped-same-payload-reference',
            meta: <String, Object?>{
              'sourceType': candidate.sourceType,
              'amount': candidate.amount,
              'transactionRef': candidateRef,
            },
          );
          continue;
        }
        seenReferencesInPayload.add(payloadRefKey);
      }
      final levelLabel =
          candidate.confidenceLevel ??
          ParserConfidenceScorer.confidenceLevelFromScore(
            candidate.confidenceScore,
          ).label;
      if (levelLabel == ConfidenceLevel.low.label) {
        await globalAppLogService.log(
          category: 'parser',
          message: 'candidate-skipped-low-confidence',
          meta: <String, Object?>{
            'sourceType': candidate.sourceType,
            'amount': candidate.amount,
            'merchant': candidate.merchant,
            'confidenceScore': candidate.confidenceScore,
            'confidenceLevel': levelLabel,
          },
        );
        continue;
      }
      if (await _hasReferenceDuplicate(candidate)) {
        await globalAppLogService.log(
          category: 'parser',
          message: 'candidate-deduped-reference',
          meta: <String, Object?>{
            'sourceType': candidate.sourceType,
            'amount': candidate.amount,
            'transactionRef': _extractReference(candidate) ?? '',
          },
        );
        continue;
      }
      if (await _hasSignatureDuplicate(candidate)) {
        await globalAppLogService.log(
          category: 'parser',
          message: 'candidate-deduped-signature',
          meta: <String, Object?>{
            'sourceType': candidate.sourceType,
            'amount': candidate.amount,
            'merchant': candidate.merchant,
          },
        );
        continue;
      }
      if (await _hasSimilarPending(candidate)) {
        await globalAppLogService.log(
          category: 'parser',
          message: 'candidate-deduped',
          meta: <String, Object?>{
            'sourceType': candidate.sourceType,
            'amount': candidate.amount,
          },
        );
        continue;
      }
      final paymentSourceType =
          candidate.paymentSourceTypeSuggestion ??
          _defaultSourceSuggestion(input);
      final paymentSourceIdSuggestion = await _suggestPaymentSourceId(
        sourceType: paymentSourceType,
        sourceHint: candidate.paymentSourceHint,
      );
      final pendingId = await _pendingService.createPendingTransaction(
        amount: candidate.amount,
        merchant: candidate.merchant,
        categorySuggestion:
            candidate.categorySuggestion ??
            CategorySuggester.suggest(candidate.merchant),
        paymentSourceTypeSuggestion: paymentSourceType,
        paymentSourceIdSuggestion: paymentSourceIdSuggestion,
        transactionDate: candidate.transactionDate,
        sourceType: candidate.sourceType,
        rawText: candidate.rawText,
        confidenceScore: candidate.confidenceScore,
      );

      createdIds.add(pendingId);

      final pending = await (_db.select(
        _db.pendingTransactions,
      )..where((p) => p.id.equals(pendingId))).getSingle();
      final duplicate = await _pendingService.detectPossibleDuplicate(pending);
      if (duplicate != null) {
        await _pendingService.markPendingAsDuplicate(pendingId, duplicate.id);
      }
    }

    return createdIds;
  }

  Future<bool> _hasReferenceDuplicate(
    DetectedTransactionCandidate candidate,
  ) async {
    final reference = _extractReference(candidate);
    if (reference == null) return false;

    final start = candidate.transactionDate.subtract(const Duration(days: 7));
    final end = candidate.transactionDate.add(const Duration(days: 7));
    final rows =
        await (_db.select(_db.pendingTransactions)..where(
              (p) =>
                  p.status.equals('pending') &
                  p.amount.equals(candidate.amount) &
                  p.transactionDate.isBiggerOrEqualValue(start) &
                  p.transactionDate.isSmallerOrEqualValue(end),
            ))
            .get();
    final refLower = reference.toLowerCase();
    return rows.any((row) => row.rawText.toLowerCase().contains(refLower));
  }

  Future<bool> _hasSignatureDuplicate(
    DetectedTransactionCandidate candidate,
  ) async {
    final sender = _metadataString(candidate, 'sender');
    final counterparty = _metadataString(candidate, 'counterparty');
    if (sender == null || counterparty == null) return false;

    final start = candidate.transactionDate.subtract(
      const Duration(minutes: 30),
    );
    final end = candidate.transactionDate.add(const Duration(minutes: 30));
    final rows =
        await (_db.select(_db.pendingTransactions)..where(
              (p) =>
                  p.status.equals('pending') &
                  p.amount.equals(candidate.amount) &
                  p.transactionDate.isBiggerOrEqualValue(start) &
                  p.transactionDate.isSmallerOrEqualValue(end),
            ))
            .get();
    final senderLower = sender.toLowerCase();
    final counterpartyLower = counterparty.toLowerCase();
    final candidateRef = _extractReference(candidate);
    for (final row in rows) {
      final raw = row.rawText.toLowerCase();
      final rowRef = _extractReferenceFromText(row.rawText);
      if (candidateRef != null &&
          rowRef != null &&
          candidateRef.toLowerCase() != rowRef.toLowerCase()) {
        continue;
      }
      if (_similarity(row.merchant, candidate.merchant) >= 0.8 &&
          raw.contains(senderLower) &&
          raw.contains(counterpartyLower)) {
        return true;
      }
    }
    return false;
  }

  Future<bool> _hasSimilarPending(
    DetectedTransactionCandidate candidate,
  ) async {
    final start = candidate.transactionDate.subtract(const Duration(hours: 24));
    final end = candidate.transactionDate.add(const Duration(hours: 24));
    final rows =
        await (_db.select(_db.pendingTransactions)..where(
              (p) =>
                  p.status.equals('pending') &
                  p.amount.equals(candidate.amount) &
                  p.transactionDate.isBiggerOrEqualValue(start) &
                  p.transactionDate.isSmallerOrEqualValue(end),
            ))
            .get();

    for (final row in rows) {
      final candidateRef = _extractReference(candidate);
      final rowRef = _extractReferenceFromText(row.rawText);
      if (candidateRef != null &&
          rowRef != null &&
          candidateRef.toLowerCase() != rowRef.toLowerCase()) {
        continue;
      }
      if (_similarity(row.merchant, candidate.merchant) >= 0.6) {
        return true;
      }
    }
    return false;
  }

  double _similarity(String a, String b) {
    final xa = a.toLowerCase().split(RegExp(r'\s+')).toSet();
    final xb = b.toLowerCase().split(RegExp(r'\s+')).toSet();
    if (xa.isEmpty || xb.isEmpty) return 0;
    return xa.intersection(xb).length / xa.union(xb).length;
  }

  String? _extractReference(DetectedTransactionCandidate candidate) {
    final fromMetadata = _metadataString(candidate, 'transactionRef');
    if (fromMetadata != null && fromMetadata.isNotEmpty) {
      return fromMetadata;
    }
    final match = RegExp(
      r'(?:RRN|UPI\s*Ref(?:erence)?|Txn(?:\s*ID)?|Ref(?:\s*No)?)\s*[:#.-]?\s*([A-Za-z0-9-]{6,})',
      caseSensitive: false,
    ).firstMatch(candidate.rawText);
    return match?.group(1)?.trim();
  }

  String? _metadataString(DetectedTransactionCandidate candidate, String key) {
    final value = candidate.metadata?[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  String? _extractReferenceFromText(String rawText) {
    final match = RegExp(
      r'(?:RRN|UPI\s*Ref(?:erence)?|Txn(?:\s*ID)?|Ref(?:\s*No)?)\s*[:#.-]?\s*([A-Za-z0-9-]{6,})',
      caseSensitive: false,
    ).firstMatch(rawText);
    return match?.group(1)?.trim();
  }

  String _defaultSourceSuggestion(ParserInput input) {
    if (input.sourceType == 'upiNotification') return PaymentSourceType.upi;
    if (input.sourceType == 'sms' || input.sourceType == 'appNotification') {
      return PaymentSourceType.bank;
    }
    return PaymentSourceType.cash;
  }

  Future<int?> _suggestPaymentSourceId({
    required String sourceType,
    required String? sourceHint,
  }) async {
    if (sourceHint == null || sourceHint.trim().isEmpty) return null;
    if (sourceType == PaymentSourceType.creditCard ||
        sourceType == PaymentSourceType.cash) {
      return null;
    }

    final hint = sourceHint.trim().toLowerCase();
    final banks = await _db.select(_db.bankAccounts).get();
    if (banks.isEmpty) return null;

    final hintedLast4 = RegExp(r'(\d{3,4})\b').firstMatch(hint)?.group(1);

    int? fallbackId;
    for (final bank in banks) {
      final bankName = bank.bankName.toLowerCase();
      final accountName = bank.accountName.toLowerCase();
      if (hint.contains(bankName) || hint.contains(accountName)) {
        fallbackId = bank.id;
        if (hintedLast4 != null &&
            (accountName.contains(hintedLast4) ||
                bankName.contains(hintedLast4))) {
          return bank.id;
        }
      }
      if (hintedLast4 != null && accountName.contains(hintedLast4)) {
        return bank.id;
      }
    }
    return fallbackId;
  }
}
