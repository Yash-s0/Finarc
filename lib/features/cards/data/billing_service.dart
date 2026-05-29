import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

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

class BillingService {
  BillingService(this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  DateTime _atDay(DateTime anchor, int day) {
    final date = _dateOnly(anchor);
    return _safeDay(date.year, date.month, day);
  }

  DateTime _safeDay(int year, int month, int day) {
    final maxDay = DateTime(year, month + 1, 0).day;
    final safeDay = day.clamp(1, maxDay);
    return DateTime(year, month, safeDay);
  }

  DateTime _billingDateFor(CreditCard card, DateTime date) {
    final today = _dateOnly(date);
    final billingThisMonth = _atDay(today, card.billingDay);
    return today.isBefore(billingThisMonth)
        ? _safeDay(today.year, today.month - 1, card.billingDay)
        : billingThisMonth;
  }

  DateTime _billingDateForTransaction(CreditCard card, DateTime txnDate) {
    final date = _dateOnly(txnDate);
    final thisMonthBilling = _safeDay(date.year, date.month, card.billingDay);
    if (!date.isAfter(thisMonthBilling)) {
      return thisMonthBilling;
    }
    return _safeDay(date.year, date.month + 1, card.billingDay);
  }

  DateTime _cycleStartForBillingDate(CreditCard card, DateTime billingDate) {
    final previousBillingDate = _safeDay(
      billingDate.year,
      billingDate.month - 1,
      card.billingDay,
    );
    return previousBillingDate.add(const Duration(days: 1));
  }

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
    if (_isCardCharge(previous)) {
      impactedCardIds.add(previous!.paymentSourceId);
    }
    if (_isCardCharge(current)) {
      impactedCardIds.add(current!.paymentSourceId);
    }
    for (final cardId in impactedCardIds) {
      final card = await (_db.select(
        _db.creditCards,
      )..where((c) => c.id.equals(cardId))).getSingleOrNull();
      if (card == null) continue;
      await _db.transaction(() async {
        await _ensureSyntheticOpeningBill(card);
        if (_isCardCharge(previous) && previous!.cardBillId != null) {
          await _flagPaidBillNeedsReview(previous.cardBillId!);
        }
        await _reconcileCardBillingAssignments(card);
      });
    }
  }

  Future<double> calculateBilledDueForCard(int cardId) async {
    final card = await (_db.select(
      _db.creditCards,
    )..where((c) => c.id.equals(cardId))).getSingleOrNull();
    if (card == null) return 0;
    await _db.transaction(() async {
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
    final latestUnpaidBill = unpaidBills.isEmpty ? null : unpaidBills.first;
    final billedDue = unpaidBills.fold<double>(
      0,
      (sum, bill) =>
          sum +
          (bill.billedAmount - bill.paidAmount).clamp(0, bill.billedAmount),
    );

    final unbilledTransactions = await getUnbilledTransactions(card.id);
    final unbilledSpends = unbilledTransactions.fold<double>(
      0,
      (sum, txn) => sum + txn.amount,
    );

    final billedTransactions = latestUnpaidBill == null
        ? <Transaction>[]
        : await getBilledTransactions(card.id, latestUnpaidBill.id);

    final recentTransactions =
        await (_db.select(_db.transactions)
              ..where(
                (t) =>
                    t.paymentSourceType.equals('creditCard') &
                    t.paymentSourceId.equals(card.id),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)])
              ..limit(10))
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
      latestUnpaidBill: latestUnpaidBill,
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
    return transactions.fold<double>(0, (sum, txn) => sum + txn.amount);
  }

  Future<List<Transaction>> getUnbilledTransactions(int cardId) async {
    return (_db.select(_db.transactions)
          ..where(
            (t) =>
                t.paymentSourceType.equals('creditCard') &
                t.paymentSourceId.equals(cardId) &
                t.type.equals('creditCard') &
                t.cardBillId.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.transactionDate)]))
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
                t.type.equals('creditCard'),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.transactionDate)]))
        .get();
  }

  Future<CardBill?> generateBillForCard(int cardId) async {
    final card = await (_db.select(
      _db.creditCards,
    )..where((c) => c.id.equals(cardId))).getSingleOrNull();
    if (card == null) return null;

    await _db.transaction(() async {
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

  Future<void> markBillAsPaid(
    int billId,
    int? bankAccountId,
    double amount,
  ) async {
    if (bankAccountId == null) {
      throw ArgumentError(
        'Bank account selection is required for card payment',
      );
    }

    final bill = await (_db.select(
      _db.cardBills,
    )..where((b) => b.id.equals(billId))).getSingle();

    final nextPaid = (bill.paidAmount + amount)
        .clamp(0, bill.billedAmount)
        .toDouble();
    final isPaid = nextPaid >= bill.billedAmount;

    await (_db.update(_db.cardBills)..where((b) => b.id.equals(billId))).write(
      CardBillsCompanion(
        paidAmount: Value(nextPaid),
        status: Value(isPaid ? 'paid' : getDueStatus(bill)),
        paidAt: Value(isPaid ? _now() : null),
      ),
    );

    final account = await (_db.select(
      _db.bankAccounts,
    )..where((a) => a.id.equals(bankAccountId))).getSingleOrNull();
    if (account != null) {
      await (_db.update(
        _db.bankAccounts,
      )..where((a) => a.id.equals(account.id))).write(
        BankAccountsCompanion(
          currentBalance: Value(account.currentBalance - amount),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }

    final transferGroupId = 'cardpay_${DateTime.now().microsecondsSinceEpoch}';
    await _db
        .into(_db.transactions)
        .insert(
          TransactionsCompanion.insert(
            type: 'cardPayment',
            amount: amount,
            title: 'Card Bill Payment',
            category: 'Transfer',
            transactionDate: _now(),
            paymentSourceType: 'bank',
            paymentSourceId: bankAccountId,
            transferGroupId: Value(transferGroupId),
            sourceAccountId: Value(bankAccountId),
            destinationAccountId: Value(bill.cardId),
            notes: Value('Bill #${bill.id}'),
          ),
        );

    final card = await (_db.select(
      _db.creditCards,
    )..where((c) => c.id.equals(bill.cardId))).getSingleOrNull();
    if (card != null) {
      await _db.transaction(() async {
        await _ensureSyntheticOpeningBill(card);
        await _reconcileCardBillingAssignments(card);
      });
    }
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

  bool _isCardCharge(Transaction? txn) {
    return txn != null &&
        txn.paymentSourceType == 'creditCard' &&
        txn.type == 'creditCard';
  }

  Future<void> _reconcileCardBillingAssignments(
    CreditCard card, {
    DateTime? referenceNow,
  }) async {
    final now = _dateOnly(referenceNow ?? _now());
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

    final charges =
        await (_db.select(_db.transactions)
              ..where(
                (t) =>
                    t.paymentSourceType.equals('creditCard') &
                    t.paymentSourceId.equals(card.id) &
                    t.type.equals('creditCard'),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.transactionDate)]))
            .get();

    for (final txn in charges) {
      final expectedStatement = _billingDateForTransaction(
        card,
        txn.transactionDate,
      );
      final shouldBeUnbilled = expectedStatement.isAfter(now);
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

      final targetBill = await ensureBill(expectedStatement);
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
                    t.type.equals('creditCard') &
                    t.cardBillId.equals(bill.id),
              ))
              .get();
      final hasLegacyUnmappedBillData =
          billedTxns.isEmpty &&
          _dateOnly(bill.cycleEndDate) != _dateOnly(bill.billingDate);
      if (hasLegacyUnmappedBillData) {
        continue;
      }
      final nextAmount = billedTxns.fold<double>(0, (sum, t) => sum + t.amount);
      final pendingAmount = (nextAmount - bill.paidAmount)
          .clamp(0, nextAmount)
          .toDouble();
      final nextStatus = pendingAmount <= 0
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

  Future<void> _ensureSyntheticOpeningBill(CreditCard card) async {
    final opening =
        await (_db.select(_db.cardBills)..where(
              (b) => b.cardId.equals(card.id) & b.status.equals('opening'),
            ))
            .getSingleOrNull();
    if (opening != null) return;

    final representedOutstanding =
        await _calculateRepresentedOutstandingForOpening(card.id);
    final delta = (card.currentOutstanding - representedOutstanding).toDouble();
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

  Future<double> _calculateRepresentedOutstandingForOpening(int cardId) async {
    final bills =
        await (_db.select(_db.cardBills)..where(
              (b) => b.cardId.equals(cardId) & b.status.isNotValue('paid'),
            ))
            .get();
    final billedDue = bills.fold<double>(
      0,
      (sum, bill) =>
          sum +
          (bill.billedAmount - bill.paidAmount).clamp(0, bill.billedAmount),
    );

    final unbilledCharges =
        await (_db.select(_db.transactions)..where(
              (t) =>
                  t.paymentSourceType.equals('creditCard') &
                  t.paymentSourceId.equals(cardId) &
                  t.type.equals('creditCard') &
                  t.cardBillId.isNull(),
            ))
            .get();
    final unbilledSpends = unbilledCharges.fold<double>(
      0,
      (sum, t) => sum + t.amount,
    );

    return billedDue + unbilledSpends;
  }
}
