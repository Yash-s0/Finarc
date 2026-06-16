import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/logging/app_log_service.dart';
import '../../cards/data/billing_service.dart';
import '../../expenses/data/transaction_engine.dart';
import '../../expenses/models/transaction_types.dart';
import '../models/pending_models.dart';
import '../notifications/card_payment_pending_codec.dart';
import '../parsing/bank_account_matcher.dart';
import '../parsing/parser_text_utils.dart';
import '../parsing/transaction_direction_classifier.dart';

class PendingConfirmationException implements Exception {
  const PendingConfirmationException({
    required this.pendingId,
    required this.detectedType,
    required this.reason,
    required this.userMessage,
    this.missingFields = const <String>[],
  });

  final int pendingId;
  final String detectedType;
  final String reason;
  final String userMessage;
  final List<String> missingFields;
}

class PendingService {
  PendingService(this._db, this._engine);

  final AppDatabase _db;
  final TransactionEngine _engine;
  static const Duration _transactionDuplicateWindow = Duration(minutes: 10);
  static const Duration _cardPaymentDuplicateWindow = Duration(minutes: 20);

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
    final resolvedData = await _resolveConfirmationData(
      pending: pending,
      editedData: editedData,
    );
    final cardPaymentData = CardPaymentPendingCodec.tryDecode(pending.rawText);
    if (cardPaymentData != null) {
      await _confirmCardPaymentPending(
        pending: pending,
        pendingId: pendingId,
        editedData: resolvedData,
        metadata: cardPaymentData,
      );
      return;
    }
    final detectedType = _resolveDetectedType(pending, resolvedData);
    await _validateConfirmationInput(
      pendingId: pendingId,
      detectedType: detectedType,
      editedData: resolvedData,
    );

    final duplicate = await detectPossibleDuplicate(pending);
    if (duplicate != null) {
      await _logConfirmFailure(
        pendingId: pendingId,
        detectedType: detectedType,
        reason: 'possible-duplicate-transaction',
      );
      throw PendingConfirmationException(
        pendingId: pendingId,
        detectedType: detectedType,
        reason: 'possible-duplicate-transaction',
        userMessage: 'Possible duplicate transaction found.',
      );
    }

    final type = _resolvedTransactionType(
      detectedType: detectedType,
      paymentSourceType: resolvedData.paymentSourceType,
      category: resolvedData.category,
    );
    final recoverableBaseAmount = resolvedData.isForOthers
        ? (resolvedData.amount - (resolvedData.cashbackAmount ?? 0))
              .clamp(0, resolvedData.amount)
              .toDouble()
        : 0.0;
    final recoveredAmount = resolvedData.isForOthers
        ? (resolvedData.recoveredAmount ?? 0)
              .clamp(0, recoverableBaseAmount)
              .toDouble()
        : 0.0;
    _validateRecoverableInput(
      isForOthers: resolvedData.isForOthers,
      partyName: resolvedData.recoverablePartyName,
    );

    try {
      await _engine.addTransaction(
        AddTransactionInput(
          type: type,
          amount: resolvedData.amount,
          title: resolvedData.merchant,
          category: resolvedData.category,
          transactionDate: resolvedData.transactionDate,
          paymentSourceType: resolvedData.paymentSourceType,
          paymentSourceId: resolvedData.paymentSourceId,
          cashbackAmount: resolvedData.cashbackAmount ?? 0,
          isForOthers: resolvedData.isForOthers,
          recoverableAmount: resolvedData.isForOthers
              ? (recoverableBaseAmount - recoveredAmount)
                    .clamp(0, recoverableBaseAmount)
                    .toDouble()
              : null,
          recoveredAmount: recoveredAmount,
          recoverablePartyName: resolvedData.recoverablePartyName,
          notes: resolvedData.notes,
          detectedSourceType: pending.sourceType,
        ),
      );
    } on ArgumentError catch (error) {
      final message = error.message?.toString() ?? error.toString();
      final reason = _validationReasonFromEngineMessage(message);
      final userMessage = _userMessageForValidationReason(
        reason,
        detectedType: detectedType,
      );
      await _logConfirmFailure(
        pendingId: pendingId,
        detectedType: detectedType,
        reason: reason,
        missingFields: _missingFieldsForReason(reason),
      );
      throw PendingConfirmationException(
        pendingId: pendingId,
        detectedType: detectedType,
        reason: reason,
        userMessage: userMessage,
        missingFields: _missingFieldsForReason(reason),
      );
    }

    await (_db.update(
      _db.pendingTransactions,
    )..where((p) => p.id.equals(pendingId))).write(
      PendingTransactionsCompanion(
        status: const Value('confirmed'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<PendingEditData> _resolveConfirmationData({
    required PendingTransaction pending,
    required PendingEditData editedData,
  }) async {
    if (editedData.paymentSourceId != null) return editedData;

    final resolvedId =
        pending.paymentSourceIdSuggestion ??
        await _resolveSuggestedSourceId(
          paymentSourceType: editedData.paymentSourceType,
          rawText: pending.rawText,
        );
    if (resolvedId == null) return editedData;

    if (pending.paymentSourceIdSuggestion != resolvedId) {
      await (_db.update(
        _db.pendingTransactions,
      )..where((p) => p.id.equals(pending.id))).write(
        PendingTransactionsCompanion(
          paymentSourceIdSuggestion: Value(resolvedId),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }

    return editedData.copyWith(paymentSourceId: resolvedId);
  }

  Future<int?> _resolveSuggestedSourceId({
    required String paymentSourceType,
    required String rawText,
  }) async {
    switch (paymentSourceType) {
      case PaymentSourceType.cash:
        final wallets = await _db.select(_db.cashWallets).get();
        return wallets.length == 1 ? wallets.first.id : null;
      case PaymentSourceType.creditCard:
        return _resolveSuggestedCardId(rawText);
      case PaymentSourceType.upi:
      case PaymentSourceType.bank:
        return _resolveSuggestedBankId(rawText);
      default:
        return null;
    }
  }

  Future<int?> _resolveSuggestedBankId(String rawText) async {
    final banks = await _db.select(_db.bankAccounts).get();
    if (banks.isEmpty) return null;

    final sourceHint = ParserTextUtils.extractAccountHint(rawText);
    final match = BankAccountMatcher.match(
      accounts: banks,
      sourceHint: sourceHint,
    );
    if (match.accountId != null) return match.accountId;
    return banks.length == 1 ? banks.first.id : null;
  }

  Future<int?> _resolveSuggestedCardId(String rawText) async {
    final cards = await _db.select(_db.creditCards).get();
    if (cards.isEmpty) return null;

    final last4 = ParserTextUtils.extractLast4Hint(rawText);
    if (last4 != null) {
      final matches = cards.where((card) => card.last4 == last4).toList();
      if (matches.length == 1) return matches.first.id;
    }

    return cards.length == 1 ? cards.first.id : null;
  }

  Future<void> _validateConfirmationInput({
    required int pendingId,
    required String detectedType,
    required PendingEditData editedData,
  }) async {
    final missing = <String>[];
    if (editedData.amount <= 0) missing.add('amount');
    if (editedData.paymentSourceId == null) missing.add('paymentSourceId');
    if (editedData.merchant.trim().isEmpty) missing.add('merchant');

    if (missing.isEmpty) return;
    final reason =
        missing.contains('paymentSourceId') &&
            detectedType == TransactionType.income
        ? 'missing-destination-account'
        : missing.contains('paymentSourceId')
        ? 'missing-payment-source'
        : 'invalid-pending-data';
    final userMessage = _userMessageForValidationReason(
      reason,
      detectedType: detectedType,
    );
    await _logConfirmFailure(
      pendingId: pendingId,
      detectedType: detectedType,
      reason: reason,
      missingFields: missing,
    );
    throw PendingConfirmationException(
      pendingId: pendingId,
      detectedType: detectedType,
      reason: reason,
      userMessage: userMessage,
      missingFields: missing,
    );
  }

  Future<void> _confirmCardPaymentPending({
    required PendingTransaction pending,
    required int pendingId,
    required PendingEditData editedData,
    required CardPaymentPendingData metadata,
  }) async {
    final missing = <String>[];
    if (editedData.amount <= 0) missing.add('amount');
    if (editedData.paymentSourceId == null) missing.add('paymentSourceId');
    final cardId =
        metadata.destinationCardId ??
        await _resolveCardId(
          issuer: metadata.issuer,
          cardLast4: metadata.cardLast4,
        );
    if (cardId == null) missing.add('destinationCardId');

    if (missing.isNotEmpty) {
      final reason = missing.contains('destinationCardId')
          ? 'missing-destination-card'
          : 'missing-payment-source';
      await _logConfirmFailure(
        pendingId: pendingId,
        detectedType: TransactionType.cardPayment,
        reason: reason,
        missingFields: missing,
      );
      throw PendingConfirmationException(
        pendingId: pendingId,
        detectedType: TransactionType.cardPayment,
        reason: reason,
        userMessage: reason == 'missing-destination-card'
            ? 'Destination credit card could not be determined for this card payment.'
            : 'Payment source is required for this card payment.',
        missingFields: missing,
      );
    }

    final duplicate = await _detectPossibleCardPaymentDuplicate(
      amount: editedData.amount,
      paymentSourceType: editedData.paymentSourceType,
      paymentSourceId: editedData.paymentSourceId!,
      cardId: cardId!,
      transactionDate: editedData.transactionDate,
    );
    if (duplicate != null) {
      await _logConfirmFailure(
        pendingId: pendingId,
        detectedType: TransactionType.cardPayment,
        reason: 'possible-duplicate-transaction',
      );
      throw PendingConfirmationException(
        pendingId: pendingId,
        detectedType: TransactionType.cardPayment,
        reason: 'possible-duplicate-transaction',
        userMessage: 'Possible duplicate card payment found.',
      );
    }

    try {
      await BillingService(_db).settleCardFromAccountTransfer(
        cardId: cardId,
        paymentSourceType: editedData.paymentSourceType,
        paymentSourceId: editedData.paymentSourceId!,
        amount: editedData.amount,
        transactionDate: editedData.transactionDate,
        notes: editedData.notes,
      );
    } on ArgumentError catch (error) {
      final message = error.message?.toString() ?? error.toString();
      final reason = _validationReasonFromEngineMessage(message);
      final userMessage = _userMessageForValidationReason(
        reason,
        detectedType: TransactionType.cardPayment,
      );
      await _logConfirmFailure(
        pendingId: pendingId,
        detectedType: TransactionType.cardPayment,
        reason: reason,
        missingFields: _missingFieldsForReason(reason),
      );
      throw PendingConfirmationException(
        pendingId: pendingId,
        detectedType: TransactionType.cardPayment,
        reason: reason,
        userMessage: userMessage,
        missingFields: _missingFieldsForReason(reason),
      );
    }

    await (_db.update(
      _db.pendingTransactions,
    )..where((p) => p.id.equals(pendingId))).write(
      PendingTransactionsCompanion(
        merchant: Value(editedData.merchant),
        paymentSourceTypeSuggestion: Value(editedData.paymentSourceType),
        paymentSourceIdSuggestion: Value(editedData.paymentSourceId),
        amount: Value(editedData.amount),
        transactionDate: Value(editedData.transactionDate),
        notes: Value(editedData.notes),
        status: const Value('confirmed'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  String _resolveDetectedType(
    PendingTransaction pending,
    PendingEditData editedData,
  ) {
    final category = editedData.category.trim().toLowerCase();
    if (category == 'refund') return TransactionType.refund;
    if (category == 'income' ||
        category == 'salary' ||
        category == 'received') {
      return TransactionType.income;
    }
    final direction = PendingDirectionClassifier.detect(
      text: pending.rawText,
      categoryHint: editedData.category,
    );
    if (direction == PendingTransactionDirection.income) {
      return TransactionType.income;
    }
    return editedData.paymentSourceType == PaymentSourceType.creditCard
        ? TransactionType.creditCard
        : editedData.paymentSourceType;
  }

  String _resolvedTransactionType({
    required String detectedType,
    required String paymentSourceType,
    required String category,
  }) {
    if (detectedType == TransactionType.income ||
        detectedType == TransactionType.refund) {
      return detectedType;
    }
    if (category.trim().toLowerCase() == 'refund') {
      return TransactionType.refund;
    }
    return paymentSourceType == PaymentSourceType.creditCard
        ? TransactionType.creditCard
        : paymentSourceType;
  }

  String _validationReasonFromEngineMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('payment source is required') ||
        lower.contains('bank account required')) {
      return 'missing-payment-source';
    }
    if (lower.contains('amount must be greater than 0')) {
      return 'invalid-amount';
    }
    if (lower.contains('card source must use')) {
      return 'invalid-source-type';
    }
    return 'engine-validation-failed';
  }

  List<String> _missingFieldsForReason(String reason) {
    switch (reason) {
      case 'missing-payment-source':
      case 'missing-destination-account':
        return const ['paymentSourceId'];
      case 'invalid-amount':
        return const ['amount'];
      default:
        return const <String>[];
    }
  }

  String _userMessageForValidationReason(
    String reason, {
    required String detectedType,
  }) {
    if (reason == 'missing-destination-account' ||
        (reason == 'missing-payment-source' &&
            detectedType == TransactionType.income)) {
      return 'Select destination account to confirm this income.';
    }
    if (reason == 'missing-payment-source') {
      return 'Select payment source to confirm this transaction.';
    }
    if (reason == 'invalid-amount') {
      return 'Amount must be greater than 0.';
    }
    return 'Unable to confirm transaction. Please edit and try again.';
  }

  Future<void> _logConfirmFailure({
    required int pendingId,
    required String detectedType,
    required String reason,
    List<String> missingFields = const <String>[],
  }) async {
    await globalAppLogService.log(
      category: 'pending-confirm',
      message: 'confirm-failed',
      meta: <String, Object?>{
        'pendingId': pendingId,
        'detectedType': detectedType,
        'missingFields': missingFields,
        'validationReason': reason,
      },
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
    final recoverableBaseAmount = editedData.isForOthers
        ? (editedData.amount - (editedData.cashbackAmount ?? 0))
              .clamp(0, editedData.amount)
              .toDouble()
        : 0.0;
    final recoveredAmount = editedData.isForOthers
        ? (editedData.recoveredAmount ?? 0)
              .clamp(0, recoverableBaseAmount)
              .toDouble()
        : 0.0;
    final remainingRecoverable = editedData.isForOthers
        ? (recoverableBaseAmount - recoveredAmount)
              .clamp(0, recoverableBaseAmount)
              .toDouble()
        : null;
    _validateRecoverableInput(
      isForOthers: editedData.isForOthers,
      partyName: editedData.recoverablePartyName,
    );
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
        recoverableAmount: Value(remainingRecoverable),
        recoverableBaseAmount: Value(
          editedData.isForOthers ? recoverableBaseAmount : null,
        ),
        recoveredAmount: Value(recoveredAmount),
        recoverablePartyName: Value(editedData.recoverablePartyName),
        notes: Value(editedData.notes),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<Transaction?> detectPossibleDuplicate(
    PendingTransaction pendingTransaction,
  ) async {
    final rangeStart = pendingTransaction.transactionDate.subtract(
      _transactionDuplicateWindow,
    );
    final rangeEnd = pendingTransaction.transactionDate.add(
      _transactionDuplicateWindow,
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

  Future<Transaction?> _detectPossibleCardPaymentDuplicate({
    required double amount,
    required String paymentSourceType,
    required int paymentSourceId,
    required int cardId,
    required DateTime transactionDate,
  }) async {
    final rangeStart = transactionDate.subtract(_cardPaymentDuplicateWindow);
    final rangeEnd = transactionDate.add(_cardPaymentDuplicateWindow);
    final rows =
        await (_db.select(_db.transactions)..where(
              (t) =>
                  t.type.equals(TransactionType.cardPayment) &
                  t.amount.equals(amount) &
                  t.paymentSourceType.equals(paymentSourceType) &
                  t.paymentSourceId.equals(paymentSourceId) &
                  t.destinationAccountId.equals(cardId) &
                  t.transactionDate.isBiggerOrEqualValue(rangeStart) &
                  t.transactionDate.isSmallerOrEqualValue(rangeEnd),
            ))
            .get();
    return rows.isEmpty ? null : rows.first;
  }

  Future<int?> _resolveCardId({String? issuer, String? cardLast4}) async {
    if (cardLast4 == null) return null;
    final cards = await (_db.select(
      _db.creditCards,
    )..where((c) => c.last4.equals(cardLast4))).get();
    if (cards.isEmpty) return null;
    if (issuer == null || issuer.trim().isEmpty) {
      return cards.length == 1 ? cards.first.id : null;
    }
    final normalizedIssuer = _normalizeLookup(issuer);
    final matches = cards
        .where((card) {
          final bank = _normalizeLookup(card.bankName);
          final nickname = _normalizeLookup(card.nickname);
          return bank == normalizedIssuer || nickname == normalizedIssuer;
        })
        .toList(growable: false);
    if (matches.length == 1) return matches.first.id;
    return null;
  }

  String? _normalizeLookup(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();
    if (normalized.isEmpty) return null;
    return normalized;
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

  void _validateRecoverableInput({
    required bool isForOthers,
    required String? partyName,
  }) {
    if (!isForOthers) return;
    final name = partyName?.trim() ?? '';
    if (name.isEmpty) {
      throw ArgumentError('Paid for whom? is required for for-others entries');
    }
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
