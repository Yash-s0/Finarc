import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/formatters.dart';
import '../../expenses/models/transaction_types.dart';

class BillingCycle {
  const BillingCycle({
    required this.cycleStartDate,
    required this.cycleEndDate,
    required this.billingDate,
    required this.dueDate,
  });

  final DateTime cycleStartDate;
  final DateTime cycleEndDate;
  final DateTime billingDate;
  final DateTime dueDate;
}

DateTime _creditCardDateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime _creditCardSafeDay(int year, int month, int day) {
  final maxDay = DateTime(year, month + 1, 0).day;
  final safeDay = day.clamp(1, maxDay);
  return DateTime(year, month, safeDay);
}

DateTime _latestBillingDateFor(CreditCard card, DateTime date) {
  final today = _creditCardDateOnly(date);
  final billingThisMonth = _creditCardSafeDay(
    today.year,
    today.month,
    card.billingDay,
  );
  return today.isBefore(billingThisMonth)
      ? _creditCardSafeDay(today.year, today.month - 1, card.billingDay)
      : billingThisMonth;
}

DateTime _creditCardCycleStartForBillingDate(
  CreditCard card,
  DateTime billingDate,
) {
  final previousBillingDate = _creditCardSafeDay(
    billingDate.year,
    billingDate.month - 1,
    card.billingDay,
  );
  return previousBillingDate.add(const Duration(days: 1));
}

bool isInActiveCreditCardBillingWindow({
  required CreditCard card,
  required DateTime transactionDate,
  required DateTime now,
}) {
  final today = _creditCardDateOnly(now);
  final txnDate = _creditCardDateOnly(transactionDate);
  final latestBillingDate = _latestBillingDateFor(card, today);
  final activeStart = _creditCardCycleStartForBillingDate(
    card,
    latestBillingDate,
  );
  return !txnDate.isBefore(activeStart) && !txnDate.isAfter(today);
}

String? creditCardTransactionImpactTypeForDate({
  required CreditCard card,
  required DateTime transactionDate,
  required DateTime now,
  required String transactionType,
}) {
  final txnDate = _creditCardDateOnly(transactionDate);
  final today = _creditCardDateOnly(now);
  if (!txnDate.isBefore(today)) return null;
  if (transactionType == TransactionType.cardPayment) {
    return TransactionImpactType.historicalNoBalance;
  }
  if (transactionType == TransactionType.creditCard ||
      transactionType == TransactionType.refund) {
    return isInActiveCreditCardBillingWindow(
          card: card,
          transactionDate: txnDate,
          now: today,
        )
        ? TransactionImpactType.cardStatementBalanceNeutral
        : TransactionImpactType.historicalNoBalance;
  }
  return TransactionImpactType.historicalNoBalance;
}

class CardBillingSnapshot {
  const CardBillingSnapshot({
    required this.cardId,
    required this.billedDue,
    required this.unbilledSpends,
    required this.totalOutstanding,
    required this.availableLimit,
    required this.utilizationPercent,
    required this.latestUnpaidBill,
    required this.nextStatementDate,
    required this.nextDueDate,
    required this.billedTransactions,
    required this.unbilledTransactions,
    required this.recentTransactions,
  });

  final int cardId;
  final double billedDue;
  final double unbilledSpends;
  final double totalOutstanding;
  final double availableLimit;
  final double utilizationPercent;
  final CardBill? latestUnpaidBill;
  final DateTime nextStatementDate;
  final DateTime nextDueDate;
  final List<Transaction> billedTransactions;
  final List<Transaction> unbilledTransactions;
  final List<Transaction> recentTransactions;

  @Deprecated('Use billedDue')
  double get currentBilledDue => billedDue;

  @Deprecated('Use billedDue')
  double get totalBilledDue => billedDue;
}

class CardPaymentResult {
  const CardPaymentResult({
    required this.requestedAmount,
    required this.appliedAmount,
    required this.remainingDueBefore,
    required this.remainingDueAfter,
    required this.paymentSourceType,
    required this.paymentSourceId,
    required this.cardId,
    this.billId,
    this.wasClamped = false,
    this.message,
  });

  final double requestedAmount;
  final double appliedAmount;
  final double remainingDueBefore;
  final double remainingDueAfter;
  final String paymentSourceType;
  final int paymentSourceId;
  final int cardId;
  final int? billId;
  final bool wasClamped;
  final String? message;
}

class BillingService {
  BillingService(this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  DateTime _safeDay(int year, int month, int day) =>
      _creditCardSafeDay(year, month, day);

  DateTime _billingDateFor(CreditCard card, DateTime date) =>
      _latestBillingDateFor(card, date);

  DateTime _billingDateForTransaction(CreditCard card, DateTime txnDate) {
    final date = _dateOnly(txnDate);
    final thisMonthBilling = _safeDay(date.year, date.month, card.billingDay);
    if (!date.isAfter(thisMonthBilling)) {
      return thisMonthBilling;
    }
    return _safeDay(date.year, date.month + 1, card.billingDay);
  }

  DateTime _cycleStartForBillingDate(CreditCard card, DateTime billingDate) =>
      _creditCardCycleStartForBillingDate(card, billingDate);

  DateTime _dueDateForBillingDate(CreditCard card, DateTime billingDate) {
    final dueThisMonth = _safeDay(
      billingDate.year,
      billingDate.month,
      card.dueDay,
    );
    return dueThisMonth.isAfter(billingDate)
        ? dueThisMonth
        : _safeDay(billingDate.year, billingDate.month + 1, card.dueDay);
  }

  DateTime _nextStatementDate(CreditCard card, DateTime now) {
    final latestBillingDate = _billingDateFor(card, now);
    return _safeDay(
      latestBillingDate.year,
      latestBillingDate.month + 1,
      card.billingDay,
    );
  }

  BillingCycle getCurrentCycle(CreditCard card, DateTime date) {
    final billingDate = _billingDateFor(card, date);

    return BillingCycle(
      cycleStartDate: _cycleStartForBillingDate(card, billingDate),
      cycleEndDate: billingDate,
      billingDate: billingDate,
      dueDate: _dueDateForBillingDate(card, billingDate),
    );
  }

  Future<void> reconcileCardAfterMutation({
    Transaction? previous,
    Transaction? current,
  }) async {
    final impactedCardIds = <int>{};
    if (_isCardAffecting(previous)) {
      impactedCardIds.add(previous!.paymentSourceId);
    }
    if (_isCardAffecting(current)) {
      impactedCardIds.add(current!.paymentSourceId);
    }
    for (final cardId in impactedCardIds) {
      final card = await (_db.select(
        _db.creditCards,
      )..where((c) => c.id.equals(cardId))).getSingleOrNull();
      if (card == null) continue;
      await _db.transaction(() async {
        await _promoteActiveHistoricalNoBalanceTransactions(card);
        await _ensureSyntheticOpeningBill(card);
        if (_isCardCharge(previous) && previous!.cardBillId != null) {
          await _flagPaidBillNeedsReview(previous.cardBillId!);
        }
        await _reconcileCardBillingAssignments(card);
        await _syncLegacyOutstanding(card.id);
      });
    }
  }

  Future<void> reconcileCardById(int cardId, {DateTime? now}) async {
    final card = await (_db.select(
      _db.creditCards,
    )..where((c) => c.id.equals(cardId))).getSingleOrNull();
    if (card == null) return;
    await _db.transaction(() async {
      await _promoteActiveHistoricalNoBalanceTransactions(card, now: now);
      await _ensureSyntheticOpeningBill(card);
      await _reconcileCardBillingAssignments(card, referenceNow: now);
      await _syncLegacyOutstanding(card.id);
    });
  }

  Future<double> calculateBilledDueForCard(int cardId) async {
    final card = await (_db.select(
      _db.creditCards,
    )..where((c) => c.id.equals(cardId))).getSingleOrNull();
    if (card == null) return 0;
    await _db.transaction(() async {
      await _promoteActiveHistoricalNoBalanceTransactions(card);
      await _ensureSyntheticOpeningBill(card);
      await _reconcileCardBillingAssignments(card);
    });
    final bills = await (_db.select(
      _db.cardBills,
    )..where((b) => b.cardId.equals(cardId))).get();
    return bills
        .where((bill) => bill.status != 'paid')
        .fold<double>(
          0,
          (sum, bill) =>
              sum +
              (bill.billedAmount - bill.paidAmount).clamp(0, bill.billedAmount),
        );
  }

  Future<CardBillingSnapshot> getCardBillingSnapshot(
    CreditCard card, {
    DateTime? now,
  }) async {
    final reference = now ?? _now();
    await _db.transaction(() async {
      await _promoteActiveHistoricalNoBalanceTransactions(card, now: reference);
      await _ensureSyntheticOpeningBill(card);
      await _reconcileCardBillingAssignments(card, referenceNow: reference);
    });

    final bills = await (_db.select(
      _db.cardBills,
    )..where((b) => b.cardId.equals(card.id))).get();
    bills.sort((a, b) => b.billingDate.compareTo(a.billingDate));

    final unpaidBills = bills
        .where(
          (b) => b.status != 'paid' && (b.billedAmount - b.paidAmount) > 0.009,
        )
        .toList(growable: false);
    final billedDue = unpaidBills.fold<double>(
      0,
      (sum, bill) =>
          sum +
          (bill.billedAmount - bill.paidAmount).clamp(0, bill.billedAmount),
    );

    final unbilledTransactions = await getUnbilledTransactions(card.id);
    final unbilledSpends = unbilledTransactions.fold<double>(
      0,
      (sum, txn) => sum + _billingImpact(txn),
    );

    final displayUnpaidBill = _latestDisplayUnpaidBill(unpaidBills);
    final billedTransactions = await _getOpenBilledTransactions(
      card.id,
      unpaidBills,
    );

    final recentTransactions =
        await (_db.select(_db.transactions)
              ..where(
                (t) =>
                    t.paymentSourceType.equals('creditCard') &
                    t.paymentSourceId.equals(card.id),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
            .get();

    final totalOutstanding = (billedDue + unbilledSpends)
        .clamp(0, double.infinity)
        .toDouble();
    final nextStatementDate = _nextStatementDate(card, reference);
    final nextDueDate = _dueDateForBillingDate(card, nextStatementDate);
    final availableLimit = (card.creditLimit - totalOutstanding).clamp(
      0,
      card.creditLimit,
    );
    final utilizationPercent = card.creditLimit == 0
        ? 0.0
        : (totalOutstanding / card.creditLimit).clamp(0, 1).toDouble();

    return CardBillingSnapshot(
      cardId: card.id,
      billedDue: billedDue,
      unbilledSpends: unbilledSpends,
      totalOutstanding: totalOutstanding,
      availableLimit: availableLimit.toDouble(),
      utilizationPercent: utilizationPercent,
      latestUnpaidBill: displayUnpaidBill,
      nextStatementDate: nextStatementDate,
      nextDueDate: nextDueDate,
      billedTransactions: billedTransactions,
      unbilledTransactions: unbilledTransactions,
      recentTransactions: recentTransactions,
    );
  }

  Future<CardBillingSnapshot> getCardBillingSnapshotById(
    int cardId, {
    DateTime? now,
  }) async {
    final card = await (_db.select(
      _db.creditCards,
    )..where((c) => c.id.equals(cardId))).getSingle();
    return getCardBillingSnapshot(card, now: now);
  }

  Future<List<CardBillingSnapshot>> getAllCardBillingSnapshots({
    DateTime? now,
  }) async {
    final cards = await _db.select(_db.creditCards).get();
    final snapshots = <CardBillingSnapshot>[];
    for (final card in cards) {
      snapshots.add(await getCardBillingSnapshot(card, now: now));
    }
    return snapshots;
  }

  Future<double> calculateUnbilledSpendsForCard(int cardId) async {
    final transactions = await getUnbilledTransactions(cardId);
    return transactions.fold<double>(
      0,
      (sum, txn) => sum + _billingImpact(txn),
    );
  }

  Future<List<Transaction>> getUnbilledTransactions(int cardId) async {
    return (_db.select(_db.transactions)
          ..where(
            (t) =>
                t.paymentSourceType.equals('creditCard') &
                t.paymentSourceId.equals(cardId) &
                (t.type.equals('creditCard') | t.type.equals('refund')) &
                _billingRelevantExpression(t) &
                t.cardBillId.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
        .get();
  }

  Future<List<Transaction>> getBilledTransactions(
    int cardId,
    int billId,
  ) async {
    return (_db.select(_db.transactions)
          ..where(
            (t) =>
                t.paymentSourceType.equals('creditCard') &
                t.paymentSourceId.equals(cardId) &
                t.cardBillId.equals(billId) &
                _billingRelevantExpression(t) &
                (t.type.equals('creditCard') | t.type.equals('refund')),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
        .get();
  }

  Future<CardBill?> generateBillForCard(int cardId) async {
    final card = await (_db.select(
      _db.creditCards,
    )..where((c) => c.id.equals(cardId))).getSingleOrNull();
    if (card == null) return null;

    await _db.transaction(() async {
      await _promoteActiveHistoricalNoBalanceTransactions(card);
      await _ensureSyntheticOpeningBill(card);
      await _reconcileCardBillingAssignments(card);
    });

    final currentCycle = getCurrentCycle(card, _now());
    return (_db.select(_db.cardBills)..where(
          (b) =>
              b.cardId.equals(cardId) &
              b.billingDate.equals(_dateOnly(currentCycle.billingDate)),
        ))
        .getSingleOrNull();
  }

  Future<CardPaymentResult> markBillAsPaid(
    int billId,
    int? paymentSourceId,
    double amount, {
    String paymentSourceType = 'bank',
    DateTime? transactionDate,
    String? notes,
  }) async {
    if (paymentSourceId == null) {
      throw ArgumentError('Payment source selection is required');
    }
    if (amount <= 0) {
      throw ArgumentError('Amount must be greater than 0');
    }
    if (paymentSourceType != 'bank' && paymentSourceType != 'cash') {
      throw ArgumentError('Unsupported payment source type');
    }

    final bill = await (_db.select(
      _db.cardBills,
    )..where((b) => b.id.equals(billId))).getSingle();
    final cardBeforePayment = await (_db.select(
      _db.creditCards,
    )..where((c) => c.id.equals(bill.cardId))).getSingleOrNull();
    if (cardBeforePayment != null) {
      await _db.transaction(() async {
        await _promoteActiveHistoricalNoBalanceTransactions(cardBeforePayment);
        await _ensureSyntheticOpeningBill(cardBeforePayment);
        await _reconcileCardBillingAssignments(cardBeforePayment);
        await _syncLegacyOutstanding(cardBeforePayment.id);
      });
    }
    final refreshedBill = await (_db.select(
      _db.cardBills,
    )..where((b) => b.id.equals(billId))).getSingle();
    final remainingDueBefore =
        (refreshedBill.billedAmount - refreshedBill.paidAmount)
            .clamp(0, refreshedBill.billedAmount)
            .toDouble();
    final appliedAmount = amount.clamp(0, remainingDueBefore).toDouble();
    final wasClamped = appliedAmount + 0.009 < amount;

    if (appliedAmount <= 0.009) {
      return CardPaymentResult(
        requestedAmount: amount,
        appliedAmount: 0,
        remainingDueBefore: remainingDueBefore,
        remainingDueAfter: remainingDueBefore,
        paymentSourceType: paymentSourceType,
        paymentSourceId: paymentSourceId,
        cardId: refreshedBill.cardId,
        billId: refreshedBill.id,
        wasClamped: true,
        message:
            'No payment was applied because this bill has no remaining due.',
      );
    }

    final nextPaid = refreshedBill.paidAmount + appliedAmount;
    final remainingDueAfter = (refreshedBill.billedAmount - nextPaid)
        .clamp(0, refreshedBill.billedAmount)
        .toDouble();
    final isPaid = remainingDueAfter <= 0.009;

    await _db.transaction(() async {
      await (_db.update(
        _db.cardBills,
      )..where((b) => b.id.equals(billId))).write(
        CardBillsCompanion(
          paidAmount: Value(nextPaid),
          status: Value(
            isPaid
                ? 'paid'
                : getDueStatusFromDate(
                    isPaid: false,
                    dueDate: refreshedBill.dueDate,
                    now: _now(),
                  ),
          ),
          paidAt: Value(isPaid ? (transactionDate ?? _now()) : null),
        ),
      );
      await _deductSourceBalance(
        paymentSourceType: paymentSourceType,
        paymentSourceId: paymentSourceId,
        amount: appliedAmount,
      );
      await _recordCardPaymentTransaction(
        amount: appliedAmount,
        paymentSourceType: paymentSourceType,
        paymentSourceId: paymentSourceId,
        cardId: refreshedBill.cardId,
        transactionDate: transactionDate ?? _now(),
        notes: notes?.trim().isNotEmpty == true
            ? notes!.trim()
            : 'Bill #${refreshedBill.id}',
      );
      final card = await (_db.select(
        _db.creditCards,
      )..where((c) => c.id.equals(refreshedBill.cardId))).getSingleOrNull();
      if (card != null) {
        await _reconcileCardBillingAssignments(card);
        await _syncLegacyOutstanding(card.id);
      }
    });

    return CardPaymentResult(
      requestedAmount: amount,
      appliedAmount: appliedAmount,
      remainingDueBefore: remainingDueBefore,
      remainingDueAfter: remainingDueAfter,
      paymentSourceType: paymentSourceType,
      paymentSourceId: paymentSourceId,
      cardId: refreshedBill.cardId,
      billId: refreshedBill.id,
      wasClamped: wasClamped,
      message: wasClamped
          ? 'Only ${inr(appliedAmount)} was applied because the bill due was lower than the entered amount.'
          : null,
    );
  }

  Future<CardPaymentResult> settleCardFromAccountTransfer({
    required int cardId,
    required String paymentSourceType,
    required int paymentSourceId,
    required double amount,
    DateTime? transactionDate,
    String? notes,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Amount must be greater than 0');
    }
    final cardBeforePayment = await (_db.select(
      _db.creditCards,
    )..where((c) => c.id.equals(cardId))).getSingleOrNull();
    if (cardBeforePayment != null) {
      await _db.transaction(() async {
        await _promoteActiveHistoricalNoBalanceTransactions(cardBeforePayment);
        await _ensureSyntheticOpeningBill(cardBeforePayment);
        await _reconcileCardBillingAssignments(cardBeforePayment);
        await _syncLegacyOutstanding(cardBeforePayment.id);
      });
    }

    final bills =
        await (_db.select(_db.cardBills)
              ..where((b) => b.cardId.equals(cardId))
              ..orderBy([(b) => OrderingTerm.asc(b.billingDate)]))
            .get();
    final unpaidBills = bills
        .where((bill) => !_isBillPaidLike(bill))
        .where((bill) => (bill.billedAmount - bill.paidAmount) > 0.009)
        .toList(growable: false);
    final remainingDueBefore = unpaidBills.fold<double>(
      0,
      (sum, bill) =>
          sum +
          (bill.billedAmount - bill.paidAmount).clamp(0, bill.billedAmount),
    );
    final appliedAmount = amount.clamp(0, remainingDueBefore).toDouble();
    final wasClamped = appliedAmount + 0.009 < amount;

    if (appliedAmount <= 0.009) {
      return CardPaymentResult(
        requestedAmount: amount,
        appliedAmount: 0,
        remainingDueBefore: remainingDueBefore,
        remainingDueAfter: remainingDueBefore,
        paymentSourceType: paymentSourceType,
        paymentSourceId: paymentSourceId,
        cardId: cardId,
        wasClamped: true,
        message:
            'No payment was applied because this card has no billed due to settle.',
      );
    }

    await _db.transaction(() async {
      await _deductSourceBalance(
        paymentSourceType: paymentSourceType,
        paymentSourceId: paymentSourceId,
        amount: appliedAmount,
      );
      var remaining = appliedAmount;
      for (final bill in unpaidBills) {
        if (remaining <= 0.009) break;
        final billRemaining = (bill.billedAmount - bill.paidAmount)
            .clamp(0, bill.billedAmount)
            .toDouble();
        if (billRemaining <= 0.009) continue;
        final settled = remaining < billRemaining ? remaining : billRemaining;
        final nextPaid = bill.paidAmount + settled;
        final nextPending = (bill.billedAmount - nextPaid)
            .clamp(0, bill.billedAmount)
            .toDouble();
        final nextStatus = nextPending <= 0.009
            ? 'paid'
            : getDueStatusFromDate(
                isPaid: false,
                dueDate: bill.dueDate,
                now: _now(),
              );
        await (_db.update(
          _db.cardBills,
        )..where((b) => b.id.equals(bill.id))).write(
          CardBillsCompanion(
            paidAmount: Value(nextPaid),
            status: Value(nextStatus),
            paidAt: Value(nextStatus == 'paid' ? _now() : null),
          ),
        );
        remaining -= settled;
      }
      await _recordCardPaymentTransaction(
        amount: appliedAmount,
        paymentSourceType: paymentSourceType,
        paymentSourceId: paymentSourceId,
        cardId: cardId,
        transactionDate: transactionDate ?? _now(),
        notes: notes,
      );
      final card = await (_db.select(
        _db.creditCards,
      )..where((c) => c.id.equals(cardId))).getSingleOrNull();
      if (card != null) {
        await _reconcileCardBillingAssignments(card);
        await _syncLegacyOutstanding(card.id);
      }
    });

    return CardPaymentResult(
      requestedAmount: amount,
      appliedAmount: appliedAmount,
      remainingDueBefore: remainingDueBefore,
      remainingDueAfter: (remainingDueBefore - appliedAmount)
          .clamp(0, remainingDueBefore)
          .toDouble(),
      paymentSourceType: paymentSourceType,
      paymentSourceId: paymentSourceId,
      cardId: cardId,
      wasClamped: wasClamped,
      message: wasClamped
          ? 'Only ${inr(appliedAmount)} was applied because the billed due was lower than the entered amount.'
          : null,
    );
  }

  Future<double> calculateAvailableLimit(int cardId) async {
    final card = await (_db.select(
      _db.creditCards,
    )..where((c) => c.id.equals(cardId))).getSingle();
    final snapshot = await getCardBillingSnapshot(card);
    final outstanding = snapshot.totalOutstanding;
    return (card.creditLimit - outstanding).clamp(0, card.creditLimit);
  }

  Future<double> calculateUtilization(int cardId) async {
    final card = await (_db.select(
      _db.creditCards,
    )..where((c) => c.id.equals(cardId))).getSingle();
    if (card.creditLimit == 0) return 0;
    final snapshot = await getCardBillingSnapshot(card);
    final outstanding = snapshot.totalOutstanding;
    return (outstanding / card.creditLimit).clamp(0, 1);
  }

  String getDueStatus(CardBill bill) {
    if (bill.status == 'needsReview') return 'needsReview';
    return getDueStatusFromDate(
      isPaid: bill.status == 'paid' || bill.paidAmount >= bill.billedAmount,
      dueDate: bill.dueDate,
      now: _now(),
    );
  }

  String getDueStatusFromDate({
    required bool isPaid,
    required DateTime dueDate,
    required DateTime now,
  }) {
    if (isPaid) return 'paid';
    final today = _dateOnly(now);
    final due = _dateOnly(dueDate);
    if (today.isAfter(due)) return 'overdue';
    final days = due.difference(today).inDays;
    if (days <= 3) return 'dueSoon';
    return 'billed';
  }

  bool _isCardAffecting(Transaction? txn) {
    return txn != null &&
        txn.paymentSourceType == 'creditCard' &&
        _isBillingRelevant(txn) &&
        (txn.type == 'creditCard' || txn.type == 'refund');
  }

  bool _isCardCharge(Transaction? txn) {
    return txn != null &&
        txn.paymentSourceType == 'creditCard' &&
        txn.type == 'creditCard';
  }

  double _billingImpact(Transaction txn) {
    if (txn.type == 'refund') return -txn.amount;
    return txn.amount;
  }

  bool _isBillingRelevant(Transaction txn) {
    return txn.transactionImpactType !=
        TransactionImpactType.historicalNoBalance;
  }

  Expression<bool> _billingRelevantExpression($TransactionsTable t) {
    return t.transactionImpactType.isNull() |
        t.transactionImpactType.isNotValue(
          TransactionImpactType.historicalNoBalance,
        );
  }

  CardBill? _latestDisplayUnpaidBill(List<CardBill> unpaidBills) {
    for (final bill in unpaidBills) {
      if (bill.status != 'opening') return bill;
    }
    return unpaidBills.isEmpty ? null : unpaidBills.first;
  }

  Future<List<Transaction>> _getOpenBilledTransactions(
    int cardId,
    List<CardBill> unpaidBills,
  ) async {
    final openBillIds = unpaidBills
        .where((bill) => bill.status != 'opening')
        .map((bill) => bill.id)
        .toSet();
    if (openBillIds.isEmpty) return const <Transaction>[];

    final candidates =
        await (_db.select(_db.transactions)
              ..where(
                (t) =>
                    t.paymentSourceType.equals('creditCard') &
                    t.paymentSourceId.equals(cardId) &
                    (t.type.equals('creditCard') | t.type.equals('refund')) &
                    _billingRelevantExpression(t) &
                    t.cardBillId.isNotNull(),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
            .get();
    return candidates
        .where((txn) => openBillIds.contains(txn.cardBillId))
        .toList(growable: false);
  }

  Future<void> _reconcileCardBillingAssignments(
    CreditCard card, {
    DateTime? referenceNow,
  }) async {
    final now = _dateOnly(referenceNow ?? _now());
    await _promoteActiveHistoricalNoBalanceTransactions(card, now: now);
    final bills =
        await (_db.select(_db.cardBills)
              ..where((b) => b.cardId.equals(card.id))
              ..orderBy([(b) => OrderingTerm.asc(b.billingDate)]))
            .get();

    final billById = <int, CardBill>{for (final bill in bills) bill.id: bill};
    final billByDateKey = <String, CardBill>{
      for (final bill in bills)
        _dateOnly(bill.billingDate).toIso8601String(): bill,
    };

    Future<CardBill> ensureBill(DateTime statementDate) async {
      final date = _dateOnly(statementDate);
      final key = date.toIso8601String();
      final existing = billByDateKey[key];
      if (existing != null) return existing;

      final cycleStart = _cycleStartForBillingDate(card, date);
      final dueDate = _dueDateForBillingDate(card, date);
      final billId = await _db
          .into(_db.cardBills)
          .insert(
            CardBillsCompanion.insert(
              cardId: card.id,
              cycleStartDate: Value(cycleStart),
              cycleEndDate: Value(date),
              billingDate: Value(date),
              dueDate: Value(dueDate),
              billedAmount: 0,
              status: Value(
                getDueStatusFromDate(isPaid: false, dueDate: dueDate, now: now),
              ),
            ),
          );
      final created = await (_db.select(
        _db.cardBills,
      )..where((b) => b.id.equals(billId))).getSingle();
      billById[billId] = created;
      billByDateKey[key] = created;
      return created;
    }

    final cardTransactions =
        await (_db.select(_db.transactions)
              ..where(
                (t) =>
                    t.paymentSourceType.equals('creditCard') &
                    t.paymentSourceId.equals(card.id) &
                    _billingRelevantExpression(t) &
                    (t.type.equals('creditCard') | t.type.equals('refund')),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.transactionDate)]))
            .get();

    await (_db.update(_db.transactions)..where(
          (t) =>
              t.paymentSourceType.equals('creditCard') &
              t.paymentSourceId.equals(card.id) &
              (t.type.equals('creditCard') | t.type.equals('refund')) &
              t.transactionImpactType.equals(
                TransactionImpactType.historicalNoBalance,
              ) &
              t.cardBillId.isNotNull(),
        ))
        .write(const TransactionsCompanion(cardBillId: Value(null)));

    for (final txn in cardTransactions) {
      final linkedOriginal = txn.relatedTransactionId == null
          ? null
          : await (_db.select(_db.transactions)
                  ..where((t) => t.id.equals(txn.relatedTransactionId!)))
                .getSingleOrNull();
      final linkedOriginalBill = linkedOriginal?.cardBillId == null
          ? null
          : billById[linkedOriginal!.cardBillId!];
      if (txn.type == 'refund' &&
          linkedOriginalBill != null &&
          _isBillPaidLike(linkedOriginalBill)) {
        await _flagPaidBillNeedsReview(linkedOriginalBill.id);
        await (_db.update(_db.transactions)..where((t) => t.id.equals(txn.id)))
            .write(const TransactionsCompanion(cardBillId: Value(null)));
        continue;
      }

      final expectedStatement = _billingDateForTransaction(
        card,
        txn.transactionDate,
      );
      final shouldBeUnbilled =
          linkedOriginalBill == null && expectedStatement.isAfter(now);
      if (shouldBeUnbilled) {
        if (txn.cardBillId != null) {
          final oldBill = billById[txn.cardBillId!];
          if (oldBill != null) {
            await _flagPaidBillNeedsReview(oldBill.id);
          }
          await (_db.update(_db.transactions)
                ..where((t) => t.id.equals(txn.id)))
              .write(const TransactionsCompanion(cardBillId: Value(null)));
        }
        continue;
      }

      final targetBill = txn.type == 'refund' && linkedOriginalBill != null
          ? linkedOriginalBill
          : await ensureBill(expectedStatement);
      if (txn.cardBillId == targetBill.id) continue;

      if (_isBillPaidLike(targetBill)) {
        await _flagPaidBillNeedsReview(targetBill.id);
        await (_db.update(_db.transactions)..where((t) => t.id.equals(txn.id)))
            .write(const TransactionsCompanion(cardBillId: Value(null)));
        continue;
      }

      await (_db.update(_db.transactions)..where((t) => t.id.equals(txn.id)))
          .write(TransactionsCompanion(cardBillId: Value(targetBill.id)));
    }

    final refreshedBills =
        await (_db.select(_db.cardBills)
              ..where((b) => b.cardId.equals(card.id))
              ..orderBy([(b) => OrderingTerm.asc(b.billingDate)]))
            .get();

    for (final bill in refreshedBills) {
      if (bill.status == 'opening') continue;
      if (_isBillPaidLike(bill)) continue;

      final billedTxns =
          await (_db.select(_db.transactions)..where(
                (t) =>
                    t.paymentSourceType.equals('creditCard') &
                    t.paymentSourceId.equals(card.id) &
                    (t.type.equals('creditCard') | t.type.equals('refund')) &
                    _billingRelevantExpression(t) &
                    t.cardBillId.equals(bill.id),
              ))
              .get();
      final isFutureEmptyBill =
          billedTxns.isEmpty && _dateOnly(bill.billingDate).isAfter(now);
      final hasLegacyUnmappedBillData =
          billedTxns.isEmpty && bill.billedAmount > 0.009 && !isFutureEmptyBill;
      if (hasLegacyUnmappedBillData) {
        continue;
      }
      final nextAmount = billedTxns
          .fold<double>(0, (sum, t) => sum + _billingImpact(t))
          .clamp(0, double.infinity)
          .toDouble();
      final hasOverpaidAdjustedBill = bill.paidAmount > nextAmount + 0.009;
      final pendingAmount = (nextAmount - bill.paidAmount)
          .clamp(0, nextAmount)
          .toDouble();
      final nextStatus = hasOverpaidAdjustedBill
          ? 'needsReview'
          : pendingAmount <= 0
          ? 'paid'
          : getDueStatusFromDate(
              isPaid: false,
              dueDate: bill.dueDate,
              now: now,
            );
      await (_db.update(
        _db.cardBills,
      )..where((b) => b.id.equals(bill.id))).write(
        CardBillsCompanion(
          billedAmount: Value(nextAmount),
          status: Value(nextStatus),
          paidAt: Value(nextStatus == 'paid' ? (bill.paidAt ?? _now()) : null),
        ),
      );
    }
  }

  bool _isBillPaidLike(CardBill bill) {
    if (bill.status == 'paid' || bill.status == 'needsReview') return true;
    if (bill.billedAmount <= 0.009) return false;
    return bill.paidAmount >= bill.billedAmount;
  }

  Future<void> _flagPaidBillNeedsReview(int billId) async {
    final bill = await (_db.select(
      _db.cardBills,
    )..where((b) => b.id.equals(billId))).getSingleOrNull();
    if (bill == null) return;
    if (bill.status == 'paid' || bill.paidAmount >= bill.billedAmount) {
      await (_db.update(_db.cardBills)..where((b) => b.id.equals(billId)))
          .write(const CardBillsCompanion(status: Value('needsReview')));
    }
  }

  Future<void> _promoteActiveHistoricalNoBalanceTransactions(
    CreditCard card, {
    DateTime? now,
  }) async {
    final reference = _dateOnly(now ?? _now());
    final candidates =
        await (_db.select(_db.transactions)
              ..where(
                (t) =>
                    t.paymentSourceType.equals('creditCard') &
                    t.paymentSourceId.equals(card.id) &
                    (t.type.equals('creditCard') | t.type.equals('refund')) &
                    t.transactionImpactType.equals(
                      TransactionImpactType.historicalNoBalance,
                    ),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.transactionDate)]))
            .get();

    for (final txn in candidates) {
      if (!isInActiveCreditCardBillingWindow(
        card: card,
        transactionDate: txn.transactionDate,
        now: reference,
      )) {
        continue;
      }
      await (_db.update(
        _db.transactions,
      )..where((t) => t.id.equals(txn.id))).write(
        TransactionsCompanion(
          transactionImpactType: const Value(
            TransactionImpactType.cardStatementBalanceNeutral,
          ),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<void> _ensureSyntheticOpeningBill(CreditCard card) async {
    final opening =
        await (_db.select(_db.cardBills)..where(
              (b) => b.cardId.equals(card.id) & b.status.equals('opening'),
            ))
            .getSingleOrNull();

    final representedOutstanding =
        await _calculateRepresentedOutstandingForOpening(
          card.id,
          includeOpening: false,
        );
    final delta = (card.currentOutstanding - representedOutstanding)
        .clamp(0, double.infinity)
        .toDouble();

    if (opening != null) {
      if ((opening.billedAmount - delta).abs() <= 0.009 &&
          opening.paidAmount <= 0.009) {
        return;
      }
      await (_db.update(
        _db.cardBills,
      )..where((b) => b.id.equals(opening.id))).write(
        CardBillsCompanion(
          billedAmount: Value(delta),
          paidAmount: const Value(0),
          dueDate: Value(_dueDateForBillingDate(card, _dateOnly(_now()))),
        ),
      );
      return;
    }

    if (delta <= 0.009) return;

    final today = _dateOnly(_now());
    final dueDate = _dueDateForBillingDate(card, today);
    await _db
        .into(_db.cardBills)
        .insert(
          CardBillsCompanion.insert(
            cardId: card.id,
            cycleStartDate: Value(today),
            cycleEndDate: Value(today),
            billingDate: Value(today),
            dueDate: Value(dueDate),
            billedAmount: delta,
            status: const Value('opening'),
          ),
        );
  }

  Future<double> _calculateRepresentedOutstandingForOpening(
    int cardId, {
    bool includeOpening = true,
  }) async {
    final bills =
        await (_db.select(_db.cardBills)..where(
              (b) => b.cardId.equals(cardId) & b.status.isNotValue('paid'),
            ))
            .get();
    final representedBills = includeOpening
        ? bills
        : bills.where((bill) => bill.status != 'opening');
    final billedDue = representedBills.fold<double>(
      0,
      (sum, bill) =>
          sum +
          (bill.billedAmount - bill.paidAmount).clamp(0, bill.billedAmount),
    );

    final unbilledTransactions =
        await (_db.select(_db.transactions)..where(
              (t) =>
                  t.paymentSourceType.equals('creditCard') &
                  t.paymentSourceId.equals(cardId) &
                  (t.type.equals('creditCard') | t.type.equals('refund')) &
                  _billingRelevantExpression(t) &
                  t.cardBillId.isNull(),
            ))
            .get();
    final unbilledSpends = unbilledTransactions.fold<double>(
      0,
      (sum, t) => sum + _billingImpact(t),
    );

    return billedDue + unbilledSpends;
  }

  Future<void> _deductSourceBalance({
    required String paymentSourceType,
    required int paymentSourceId,
    required double amount,
  }) async {
    if (paymentSourceType == 'cash') {
      final wallet = await (_db.select(
        _db.cashWallets,
      )..where((w) => w.id.equals(paymentSourceId))).getSingleOrNull();
      if (wallet == null) {
        throw ArgumentError('Selected cash wallet not found');
      }
      await (_db.update(
        _db.cashWallets,
      )..where((w) => w.id.equals(paymentSourceId))).write(
        CashWalletsCompanion(
          currentBalance: Value(wallet.currentBalance - amount),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return;
    }

    final bank = await (_db.select(
      _db.bankAccounts,
    )..where((b) => b.id.equals(paymentSourceId))).getSingleOrNull();
    if (bank == null) {
      throw ArgumentError('Selected bank account not found');
    }
    await (_db.update(
      _db.bankAccounts,
    )..where((b) => b.id.equals(paymentSourceId))).write(
      BankAccountsCompanion(
        currentBalance: Value(bank.currentBalance - amount),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> _recordCardPaymentTransaction({
    required double amount,
    required String paymentSourceType,
    required int paymentSourceId,
    required int cardId,
    required DateTime transactionDate,
    String? notes,
  }) async {
    final transferGroupId = 'cardpay_${DateTime.now().microsecondsSinceEpoch}';
    await _db
        .into(_db.transactions)
        .insert(
          TransactionsCompanion.insert(
            type: 'cardPayment',
            amount: amount,
            title: 'Card Bill Payment Out',
            category: 'Transfer',
            transactionDate: transactionDate,
            paymentSourceType: paymentSourceType,
            paymentSourceId: paymentSourceId,
            transferGroupId: Value(transferGroupId),
            sourceAccountId: Value(paymentSourceId),
            destinationAccountId: Value(cardId),
            notes: Value(notes),
          ),
        );
    await _db
        .into(_db.transactions)
        .insert(
          TransactionsCompanion.insert(
            type: 'cardPayment',
            amount: amount,
            title: 'Card Bill Payment In',
            category: 'Transfer',
            transactionDate: transactionDate,
            paymentSourceType: 'creditCard',
            paymentSourceId: cardId,
            transferGroupId: Value(transferGroupId),
            sourceAccountId: Value(paymentSourceId),
            destinationAccountId: Value(cardId),
            notes: Value(notes),
          ),
        );
  }

  Future<void> _syncLegacyOutstanding(int cardId) async {
    final card = await (_db.select(
      _db.creditCards,
    )..where((c) => c.id.equals(cardId))).getSingleOrNull();
    if (card == null) return;
    final representedOutstanding =
        await _calculateRepresentedOutstandingForOpening(cardId);
    if ((card.currentOutstanding - representedOutstanding).abs() <= 0.009) {
      return;
    }
    await (_db.update(
      _db.creditCards,
    )..where((c) => c.id.equals(cardId))).write(
      CreditCardsCompanion(
        currentOutstanding: Value(representedOutstanding),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
