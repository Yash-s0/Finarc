import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/logging/app_log_service.dart';
import '../../expenses/models/transaction_types.dart';
import '../data/pending_service.dart';
import 'category_suggester.dart';
import 'parser_models.dart';
import 'transaction_parser_registry.dart';

class PendingIngestionService {
  PendingIngestionService(this._db, this._pendingService, this._parserRegistry);

  final AppDatabase _db;
  final PendingService _pendingService;
  final TransactionParserRegistry _parserRegistry;

  Future<List<int>> ingestParserInput(ParserInput input) async {
    final result = _parserRegistry.parseInput(input);
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

    for (final candidate in result.candidates) {
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
      final pendingId = await _pendingService.createPendingTransaction(
        amount: candidate.amount,
        merchant: candidate.merchant,
        categorySuggestion:
            candidate.categorySuggestion ??
            CategorySuggester.suggest(candidate.merchant),
        paymentSourceTypeSuggestion:
            candidate.paymentSourceTypeSuggestion ??
            _defaultSourceSuggestion(input),
        paymentSourceIdSuggestion: null,
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

  String _defaultSourceSuggestion(ParserInput input) {
    if (input.sourceType == 'upiNotification') return PaymentSourceType.upi;
    if (input.sourceType == 'sms' || input.sourceType == 'appNotification') {
      return PaymentSourceType.bank;
    }
    return PaymentSourceType.cash;
  }
}
