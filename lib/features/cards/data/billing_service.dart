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

class BillingService {
  BillingService(this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  DateTime _atDay(DateTime anchor, int day) {
    return _safeDay(anchor.year, anchor.month, day);
  }

  DateTime _safeDay(int year, int month, int day) {
    final maxDay = DateTime(year, month + 1, 0).day;
    final safeDay = day.clamp(1, maxDay);
    return DateTime(year, month, safeDay);
  }

  BillingCycle getCurrentCycle(CreditCard card, DateTime date) {
    final billingThisMonth = _atDay(date, card.billingDay);
    final billingDate = date.isBefore(billingThisMonth)
        ? _safeDay(date.year, date.month - 1, card.billingDay)
        : billingThisMonth;
    final dueThisMonth = _safeDay(
      billingDate.year,
      billingDate.month,
      card.dueDay,
    );
    final dueDate = dueThisMonth.isAfter(billingDate)
        ? dueThisMonth
        : _safeDay(billingDate.year, billingDate.month + 1, card.dueDay);

    return BillingCycle(
      cycleStartDate: _safeDay(
        billingDate.year,
        billingDate.month - 1,
        card.billingDay,
      ),
      cycleEndDate: billingDate,
      billingDate: billingDate,
      dueDate: dueDate,
    );
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

    final cycle = getCurrentCycle(card, _now());

    final existing =
        await (_db.select(_db.cardBills)..where(
              (b) =>
                  b.cardId.equals(cardId) &
                  b.billingDate.equals(cycle.billingDate),
            ))
            .getSingleOrNull();
    if (existing != null) return existing;

    final cycleTransactions =
        await (_db.select(_db.transactions)
              ..where(
                (t) =>
                    t.paymentSourceType.equals('creditCard') &
                    t.paymentSourceId.equals(cardId) &
                    t.type.equals('creditCard') &
                    t.cardBillId.isNull() &
                    t.transactionDate.isBiggerOrEqualValue(
                      cycle.cycleStartDate,
                    ) &
                    t.transactionDate.isSmallerOrEqualValue(cycle.cycleEndDate),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.transactionDate)]))
            .get();

    final billedAmount = cycleTransactions.fold<double>(
      0,
      (s, t) => s + t.amount,
    );
    final status = getDueStatusFromDate(
      isPaid: false,
      dueDate: cycle.dueDate,
      now: _now(),
    );

    final billId = await _db
        .into(_db.cardBills)
        .insert(
          CardBillsCompanion.insert(
            cardId: cardId,
            cycleStartDate: Value(cycle.cycleStartDate),
            cycleEndDate: Value(cycle.cycleEndDate),
            billingDate: Value(cycle.billingDate),
            dueDate: Value(cycle.dueDate),
            billedAmount: billedAmount,
            status: Value(status),
          ),
        );

    for (final txn in cycleTransactions) {
      await (_db.update(_db.transactions)..where((t) => t.id.equals(txn.id)))
          .write(TransactionsCompanion(cardBillId: Value(billId)));
    }

    return (_db.select(
      _db.cardBills,
    )..where((b) => b.id.equals(billId))).getSingle();
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
    final card = await (_db.select(
      _db.creditCards,
    )..where((c) => c.id.equals(bill.cardId))).getSingle();

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

    final nextOutstanding = (card.currentOutstanding - amount)
        .clamp(0, card.creditLimit)
        .toDouble();
    await (_db.update(
      _db.creditCards,
    )..where((c) => c.id.equals(card.id))).write(
      CreditCardsCompanion(
        currentOutstanding: Value(nextOutstanding),
        updatedAt: Value(_now()),
      ),
    );

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
            destinationAccountId: Value(card.id),
            notes: Value('Bill #${bill.id}'),
          ),
        );
  }

  Future<double> calculateAvailableLimit(int cardId) async {
    final card = await (_db.select(
      _db.creditCards,
    )..where((c) => c.id.equals(cardId))).getSingle();
    return (card.creditLimit - card.currentOutstanding).clamp(
      0,
      card.creditLimit,
    );
  }

  Future<double> calculateUtilization(int cardId) async {
    final card = await (_db.select(
      _db.creditCards,
    )..where((c) => c.id.equals(cardId))).getSingle();
    if (card.creditLimit == 0) return 0;
    return (card.currentOutstanding / card.creditLimit).clamp(0, 1);
  }

  String getDueStatus(CardBill bill) {
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
    if (now.isAfter(dueDate)) return 'overdue';
    final days = dueDate
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    if (days <= 3) return 'dueSoon';
    return 'billed';
  }
}
