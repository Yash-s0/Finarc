import 'package:drift/drift.dart';

import '../../accounts/data/wallet_types.dart';
import '../../../core/database/app_database.dart';
import '../../../core/logging/app_log_service.dart';
import '../../expenses/models/transaction_types.dart';
import '../data/pending_service.dart';
import 'bank_account_matcher.dart';
import 'category_suggester.dart';
import 'counterparty_normalizer.dart';
import 'confidence_level.dart';
import 'parser_models.dart';
import 'parser_confidence_scorer.dart';
import 'parser_text_utils.dart';
import 'transaction_direction_classifier.dart';
import 'transaction_parser_registry.dart';

class PendingIngestionService {
  PendingIngestionService(this._db, this._pendingService, this._parserRegistry);

  final AppDatabase _db;
  final PendingService _pendingService;
  final TransactionParserRegistry _parserRegistry;
  static const Duration _nearDuplicateWindow = Duration(minutes: 8);
  static const Duration _genericDuplicateWindow = Duration(minutes: 2);

  ParserResult previewParserInput(ParserInput input) {
    return _parserRegistry.parseInput(input);
  }

  String defaultSourceSuggestion(ParserInput input) {
    return _defaultSourceSuggestion(input);
  }

  Future<int?> suggestPaymentSourceId({
    required String sourceType,
    required String? sourceHint,
  }) {
    return _suggestPaymentSourceId(
      sourceType: sourceType,
      sourceHint: sourceHint,
    );
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
      final nearDuplicateDecision = await _evaluateNearDuplicate(candidate);
      if (nearDuplicateDecision.suppress) {
        await globalAppLogService.log(
          category: 'parser',
          message: 'candidate-deduped-near-duplicate',
          meta: <String, Object?>{
            'sourceType': candidate.sourceType,
            'amount': candidate.amount,
            'merchant': candidate.merchant,
            'reason': nearDuplicateDecision.reason,
          },
        );
        continue;
      }
      if (nearDuplicateDecision.possibleDuplicate) {
        await globalAppLogService.log(
          category: 'parser',
          message: 'candidate-possible-duplicate',
          meta: <String, Object?>{
            'sourceType': candidate.sourceType,
            'amount': candidate.amount,
            'merchant': candidate.merchant,
            'reason': nearDuplicateDecision.reason,
          },
        );
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

  Future<_NearDuplicateDecision> _evaluateNearDuplicate(
    DetectedTransactionCandidate candidate,
  ) async {
    final start = candidate.transactionDate.subtract(_nearDuplicateWindow);
    final end = candidate.transactionDate.add(_nearDuplicateWindow);
    final rows =
        await (_db.select(_db.pendingTransactions)..where(
              (p) =>
                  p.status.equals('pending') &
                  p.amount.equals(candidate.amount) &
                  p.transactionDate.isBiggerOrEqualValue(start) &
                  p.transactionDate.isSmallerOrEqualValue(end),
            ))
            .get();
    final candidateRef = _extractReference(candidate)?.toLowerCase();
    final candidateDirection = _directionFromCandidate(candidate);
    final candidateCounterparty = CounterpartyNormalizer.normalize(
      _metadataString(candidate, 'counterparty') ?? candidate.merchant,
    );
    final candidateSource = candidate.paymentSourceTypeSuggestion;
    final candidateSourceHint = _normalizeSourceHint(
      candidate.paymentSourceHint,
    );

    for (final row in rows) {
      final rowSourceHint = _normalizeSourceHint(
        ParserTextUtils.extractAccountHint(row.rawText),
      );
      final rowRef = _extractReferenceFromText(row.rawText)?.toLowerCase();

      if (_isGenericCrossSourceDuplicate(
        candidateCounterparty: candidateCounterparty,
        rowCounterparty: row.merchant,
        candidateSourceHint: candidateSourceHint,
        rowSourceHint: rowSourceHint,
        candidateRef: candidateRef,
        rowRef: rowRef,
        candidateDate: candidate.transactionDate,
        rowDate: row.transactionDate,
      )) {
        return const _NearDuplicateDecision(
          suppress: true,
          possibleDuplicate: false,
          reason: 'generic_notification_duplicate_within_2m',
        );
      }

      final rowDirection = _directionFromPending(row);
      if (candidateDirection != rowDirection) continue;

      if (!CounterpartyNormalizer.isSameOrNearMatch(
        candidateCounterparty,
        row.merchant,
      )) {
        continue;
      }

      if (candidateSource != null &&
          row.paymentSourceTypeSuggestion.trim().isNotEmpty &&
          row.paymentSourceTypeSuggestion != candidateSource) {
        continue;
      }
      if (candidateSourceHint != null &&
          rowSourceHint != null &&
          candidateSourceHint != rowSourceHint) {
        continue;
      }
      if (candidateRef != null && rowRef != null && candidateRef != rowRef) {
        return const _NearDuplicateDecision(
          suppress: false,
          possibleDuplicate: true,
          reason: 'possible_duplicate_different_reference_within_8m',
        );
      }

      return const _NearDuplicateDecision(
        suppress: true,
        possibleDuplicate: false,
        reason: 'near_duplicate_same_amount_counterparty_8m',
      );
    }

    return const _NearDuplicateDecision(
      suppress: false,
      possibleDuplicate: false,
      reason: null,
    );
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

  String _directionFromCandidate(DetectedTransactionCandidate candidate) {
    final metadataDirection = _metadataString(candidate, 'direction');
    if (metadataDirection == 'income') return 'income';
    if (metadataDirection == 'expense') return 'expense';
    final direction = PendingDirectionClassifier.detect(
      text: candidate.rawText,
      categoryHint: candidate.categorySuggestion,
    );
    switch (direction) {
      case PendingTransactionDirection.income:
        return 'income';
      case PendingTransactionDirection.expense:
        return 'expense';
      case PendingTransactionDirection.unknown:
        return 'unknown';
    }
  }

  String _directionFromPending(PendingTransaction pending) {
    final direction = PendingDirectionClassifier.detect(
      text: pending.rawText,
      categoryHint: pending.categorySuggestion,
    );
    switch (direction) {
      case PendingTransactionDirection.income:
        return 'income';
      case PendingTransactionDirection.expense:
        return 'expense';
      case PendingTransactionDirection.unknown:
        return 'unknown';
    }
  }

  String? _normalizeSourceHint(String? hint) {
    if (hint == null || hint.trim().isEmpty) return null;
    final digits = RegExp(r'(\d{3,4})(?!.*\d)').firstMatch(hint)?.group(1);
    if (digits != null && digits.isNotEmpty) return digits;
    return hint.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '').trim();
  }

  bool _isGenericCrossSourceDuplicate({
    required String candidateCounterparty,
    required String rowCounterparty,
    required String? candidateSourceHint,
    required String? rowSourceHint,
    required String? candidateRef,
    required String? rowRef,
    required DateTime candidateDate,
    required DateTime rowDate,
  }) {
    if (candidateSourceHint == null ||
        rowSourceHint == null ||
        candidateSourceHint != rowSourceHint) {
      return false;
    }
    if (candidateRef != null && rowRef != null) return false;
    if (!_isWeakCounterparty(candidateCounterparty) &&
        !_isWeakCounterparty(rowCounterparty)) {
      return false;
    }
    return candidateDate.difference(rowDate).abs() <= _genericDuplicateWindow;
  }

  bool _isWeakCounterparty(String value) {
    final normalized = CounterpartyNormalizer.normalize(value);
    if (normalized.isEmpty) return true;
    if (normalized == 'unknown merchant') return true;
    final compact = normalized.replaceAll(' ', '');
    if (RegExp(
      r'^(?:x+|\*+)?\d{3,4}$',
      caseSensitive: false,
    ).hasMatch(compact)) {
      return true;
    }
    const genericTokens = {
      'unknown',
      'merchant',
      'amount',
      'payment',
      'transfer',
      'credited',
      'debited',
      'sent',
      'received',
      'upi',
      'bank',
    };
    final tokens = normalized.split(' ').where((token) => token.isNotEmpty);
    return tokens.every(genericTokens.contains);
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
    if (sourceType == PaymentSourceType.creditCard) {
      final hintDigits = RegExp(
        r'(\d{3,4})(?!.*\d)',
      ).firstMatch(sourceHint)?.group(1);
      if (hintDigits == null || hintDigits.isEmpty) return null;
      final cards =
          await (_db.select(_db.creditCards)..where(
                (card) =>
                    card.last4.equals(hintDigits) |
                    card.last4.like('%$hintDigits'),
              ))
              .get();
      if (cards.length != 1) return null;
      return cards.single.id;
    }
    if (sourceType == PaymentSourceType.cash) {
      final wallets = await _db.select(_db.cashWallets).get();
      if (wallets.isEmpty) return null;
      final normalizedHint = sourceHint.trim().toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9]'),
        '',
      );
      for (final wallet in wallets) {
        if (normalizedHint.contains('amazonpay') &&
            WalletType.matches(wallet, WalletType.amazonPay)) {
          return wallet.id;
        }
        final walletName = wallet.walletName.toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9]'),
          '',
        );
        if (walletName.isNotEmpty &&
            (normalizedHint.contains(walletName) ||
                walletName.contains(normalizedHint))) {
          return wallet.id;
        }
      }
      return null;
    }

    final hint = sourceHint.trim().toLowerCase();
    final banks = await _db.select(_db.bankAccounts).get();
    if (banks.isEmpty) return null;
    final match = BankAccountMatcher.match(accounts: banks, sourceHint: hint);
    return match.accountId;
  }
}

class _NearDuplicateDecision {
  const _NearDuplicateDecision({
    required this.suppress,
    required this.possibleDuplicate,
    required this.reason,
  });

  final bool suppress;
  final bool possibleDuplicate;
  final String? reason;
}
