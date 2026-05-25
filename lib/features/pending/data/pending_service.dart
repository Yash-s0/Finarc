import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../expenses/data/transaction_engine.dart';
import '../../expenses/models/transaction_types.dart';
import '../models/pending_models.dart';

class PendingService {
  PendingService(this._db, this._engine);

  final AppDatabase _db;
  final TransactionEngine _engine;

  Future<int> createPendingTransaction({
    required double amount,
    required String merchant,
    required String categorySuggestion,
    required String paymentSourceTypeSuggestion,
    int? paymentSourceIdSuggestion,
    required DateTime transactionDate,
    required String sourceType,
    required String rawText,
    required double confidenceScore,
  }) {
    return _db
        .into(_db.pendingTransactions)
        .insert(
          PendingTransactionsCompanion.insert(
            amount: amount,
            merchant: merchant,
            categorySuggestion: categorySuggestion,
            paymentSourceTypeSuggestion: paymentSourceTypeSuggestion,
            paymentSourceIdSuggestion: Value(paymentSourceIdSuggestion),
            detectedAt: DateTime.now(),
            transactionDate: transactionDate,
            sourceType: sourceType,
            rawText: rawText,
            confidenceScore: confidenceScore,
          ),
        );
  }

  Future<List<PendingTransaction>> getPendingTransactions() {
    return (_db.select(_db.pendingTransactions)
          ..where((p) => p.status.equals('pending'))
          ..orderBy([(p) => OrderingTerm.desc(p.detectedAt)]))
        .get();
  }

  Future<void> confirmPendingTransaction(
    int pendingId,
    PendingEditData editedData,
  ) async {
    final pending = await (_db.select(
      _db.pendingTransactions,
    )..where((p) => p.id.equals(pendingId))).getSingle();

    final duplicate = await detectPossibleDuplicate(pending);
    if (duplicate != null) {
      throw StateError('Possible duplicate transaction found');
    }

    final type = editedData.paymentSourceType == PaymentSourceType.creditCard
        ? TransactionType.creditCard
        : editedData.paymentSourceType;

    await _engine.addTransaction(
      AddTransactionInput(
        type: type,
        amount: editedData.amount,
        title: editedData.merchant,
        category: editedData.category,
        transactionDate: editedData.transactionDate,
        paymentSourceType: editedData.paymentSourceType,
        paymentSourceId: editedData.paymentSourceId,
        cashbackAmount: editedData.cashbackAmount ?? 0,
        isForOthers: editedData.isForOthers,
        recoverableAmount: editedData.recoverableAmount,
        notes: editedData.notes,
        detectedSourceType: pending.sourceType,
      ),
    );

    await (_db.update(
      _db.pendingTransactions,
    )..where((p) => p.id.equals(pendingId))).write(
      PendingTransactionsCompanion(
        status: const Value('confirmed'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> ignorePendingTransaction(int pendingId) async {
    await (_db.update(
      _db.pendingTransactions,
    )..where((p) => p.id.equals(pendingId))).write(
      PendingTransactionsCompanion(
        status: const Value('ignored'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markPendingAsDuplicate(
    int pendingId,
    int existingTransactionId,
  ) async {
    await (_db.update(
      _db.pendingTransactions,
    )..where((p) => p.id.equals(pendingId))).write(
      PendingTransactionsCompanion(
        status: const Value('duplicate'),
        duplicateOfTransactionId: Value(existingTransactionId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> mergeDuplicatePendingTransaction(
    int pendingId,
    int existingTransactionId,
  ) async {
    await (_db.update(
      _db.pendingTransactions,
    )..where((p) => p.id.equals(pendingId))).write(
      PendingTransactionsCompanion(
        status: const Value('merged'),
        duplicateOfTransactionId: Value(existingTransactionId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updatePendingTransaction(
    int pendingId,
    PendingEditData editedData,
  ) async {
    await (_db.update(
      _db.pendingTransactions,
    )..where((p) => p.id.equals(pendingId))).write(
      PendingTransactionsCompanion(
        amount: Value(editedData.amount),
        merchant: Value(editedData.merchant),
        categorySuggestion: Value(editedData.category),
        paymentSourceTypeSuggestion: Value(editedData.paymentSourceType),
        paymentSourceIdSuggestion: Value(editedData.paymentSourceId),
        transactionDate: Value(editedData.transactionDate),
        cashbackAmount: Value(editedData.cashbackAmount),
        isForOthers: Value(editedData.isForOthers),
        recoverableAmount: Value(editedData.recoverableAmount),
        notes: Value(editedData.notes),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<Transaction?> detectPossibleDuplicate(
    PendingTransaction pendingTransaction,
  ) async {
    final rangeStart = pendingTransaction.transactionDate.subtract(
      const Duration(hours: 24),
    );
    final rangeEnd = pendingTransaction.transactionDate.add(
      const Duration(hours: 24),
    );

    final candidates =
        await (_db.select(_db.transactions)..where(
              (t) =>
                  t.amount.equals(pendingTransaction.amount) &
                  t.transactionDate.isBiggerOrEqualValue(rangeStart) &
                  t.transactionDate.isSmallerOrEqualValue(rangeEnd),
            ))
            .get();

    for (final txn in candidates) {
      final sameSource =
          txn.paymentSourceType ==
              pendingTransaction.paymentSourceTypeSuggestion &&
          (pendingTransaction.paymentSourceIdSuggestion == null ||
              txn.paymentSourceId ==
                  pendingTransaction.paymentSourceIdSuggestion);
      final similarity = _titleSimilarity(
        txn.title,
        pendingTransaction.merchant,
      );
      if (sameSource && similarity >= 0.6) return txn;
    }
    return null;
  }

  double _titleSimilarity(String a, String b) {
    final x = a.toLowerCase().trim();
    final y = b.toLowerCase().trim();
    if (x == y) return 1;
    final xs = x.split(RegExp(r'\s+')).toSet();
    final ys = y.split(RegExp(r'\s+')).toSet();
    if (xs.isEmpty || ys.isEmpty) return 0;
    final common = xs.intersection(ys).length;
    return common / xs.union(ys).length;
  }

  Future<void> seedDemoPendingTransactions() async {
    final existing = await getPendingTransactions();
    if (existing.isNotEmpty) return;
    await createPendingTransaction(
      amount: 1499,
      merchant: 'Swiggy',
      categorySuggestion: 'Food',
      paymentSourceTypeSuggestion: PaymentSourceType.creditCard,
      paymentSourceIdSuggestion: 1,
      transactionDate: DateTime.now().subtract(const Duration(minutes: 20)),
      sourceType: 'sms',
      rawText: 'INR 1,499 spent at SWIGGY via card ending 9031',
      confidenceScore: 0.94,
    );
    await createPendingTransaction(
      amount: 2999,
      merchant: 'Amazon',
      categorySuggestion: 'Shopping',
      paymentSourceTypeSuggestion: PaymentSourceType.creditCard,
      paymentSourceIdSuggestion: 2,
      transactionDate: DateTime.now().subtract(const Duration(hours: 2)),
      sourceType: 'appNotification',
      rawText: 'Amazon purchase Rs 2,999 on card ending 1148',
      confidenceScore: 0.88,
    );
    await createPendingTransaction(
      amount: 700,
      merchant: 'Rahul',
      categorySuggestion: 'Transfer',
      paymentSourceTypeSuggestion: PaymentSourceType.upi,
      paymentSourceIdSuggestion: 1,
      transactionDate: DateTime.now().subtract(const Duration(hours: 5)),
      sourceType: 'upiNotification',
      rawText: 'UPI debit Rs 700 to Rahul@okaxis',
      confidenceScore: 0.76,
    );
  }
}
