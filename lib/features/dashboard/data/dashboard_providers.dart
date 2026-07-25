import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../alerts/data/alerts_providers.dart';
import '../../cards/data/billing_service.dart';
import '../../analytics/data/analytics_providers.dart';
import '../../expenses/data/expenses_providers.dart';
import '../../loans/data/loan_service.dart';
import '../../pending/data/pending_providers.dart';
import '../../recoverables/data/recoverables_service.dart';
import '../../split/data/split_service.dart';
import 'net_worth_service.dart';

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.netWorth,
    required this.bankBalance,
    required this.cardDues,
    required this.cardOutstanding,
    required this.cashInHand,
    required this.monthlySpends,
    required this.pendingCount,
    required this.loansOutstanding,
    required this.recoverableAmount,
    required this.splitReceivableAmount,
    required this.splitPayableAmount,
    required this.recentTransactions,
    required this.dueSoonBillsCount,
    required this.bankAccountCount,
    required this.cashWalletCount,
    required this.cardCount,
    required this.notificationDetectionEnabled,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.payableAmount,
    required this.debtRatio,
    required this.monthlyEmiBurden,
    required this.unreadAlertsCount,
    required this.latestImportantAlert,
    this.monthlySpendTrend = const <MonthlySpendPoint>[],
  });

  final double netWorth;
  final double bankBalance;
  final double cardDues;
  final double cardOutstanding;
  final double cashInHand;
  final double monthlySpends;
  final int pendingCount;
  final double loansOutstanding;
  final double recoverableAmount;
  final double splitReceivableAmount;
  final double splitPayableAmount;
  final List<Transaction> recentTransactions;
  final int dueSoonBillsCount;
  final int bankAccountCount;
  final int cashWalletCount;
  final int cardCount;
  final bool notificationDetectionEnabled;
  final double totalAssets;
  final double totalLiabilities;
  final double payableAmount;
  final double debtRatio;
  final double monthlyEmiBurden;
  final int unreadAlertsCount;
  final Alert? latestImportantAlert;
  final List<MonthlySpendPoint> monthlySpendTrend;
}

class MonthlySpendPoint {
  const MonthlySpendPoint({
    required this.month,
    required this.amount,
    this.income = 0,
  });

  final DateTime month;
  final double amount;
  final double income;
}

final dashboardProvider = FutureProvider<DashboardSnapshot>((ref) async {
  await ref.watch(seedProvider.future);
  final db = ref.read(appDatabaseProvider);

  final banks = await db.select(db.bankAccounts).get();
  final cards = await db.select(db.creditCards).get();
  final wallets = await db.select(db.cashWallets).get();
  final allTxns = await db.select(db.transactions).get();
  final txns =
      await (db.select(db.transactions)
            ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)])
            ..limit(8))
          .get();
  final pendingCount =
      await (db.selectOnly(db.pendingTransactions)
            ..addColumns([db.pendingTransactions.id.count()])
            ..where(db.pendingTransactions.status.equals('pending')))
          .getSingle()
          .then((r) => r.read(db.pendingTransactions.id.count()) ?? 0);
  final bills = await db.select(db.cardBills).get();
  final unreadAlertsCount =
      await (db.selectOnly(db.alerts)
            ..addColumns([db.alerts.id.count()])
            ..where(db.alerts.readAt.isNull() & db.alerts.dismissedAt.isNull()))
          .getSingle()
          .then((r) => r.read(db.alerts.id.count()) ?? 0);
  final latestImportantAlert =
      await (db.select(db.alerts)
            ..where(
              (a) =>
                  a.dismissedAt.isNull() &
                  (a.priority.equals('critical') |
                      a.priority.equals('warning')),
            )
            ..orderBy([(a) => OrderingTerm.desc(a.createdAt)])
            ..limit(1))
          .getSingleOrNull();
  final settings = await (db.select(
    db.appSettings,
  )..limit(1)).getSingleOrNull();
  final billing = BillingService(db);
  final cardSnapshots = await billing.getAllCardBillingSnapshots();
  final cardOutstanding = cardSnapshots.fold<double>(
    0,
    (sum, snapshot) => sum + snapshot.totalOutstanding,
  );
  final cardDueAmount = cardSnapshots.fold<double>(
    0,
    (sum, snapshot) => sum + snapshot.billedDue,
  );
  final dueSoonBillsCount = bills.where((bill) {
    final status = billing.getDueStatus(bill);
    return status == 'dueSoon' || status == 'overdue';
  }).length;
  final splitService = SplitService(db, ref.read(transactionEngineProvider));
  final recoverablesService = RecoverablesService(
    db,
    splitService,
    ref.read(transactionEngineProvider),
  );
  final recoverableSnapshot = await recoverablesService.buildSnapshot();

  final netWorthService = NetWorthService(
    db,
    LoanService(db),
    splitService,
    billing,
  );
  final breakdown = await netWorthService.calculate();

  final now = DateTime.now();
  final monthlySpendTrend = _buildMonthlySpendTrend(
    allTxns,
    cards: cards,
    bills: bills,
    salaryCreditDay: settings?.salaryCreditDay,
    now: now,
  );
  final monthlySpends = monthlySpendTrend.isEmpty
      ? 0.0
      : monthlySpendTrend.last.amount;

  return DashboardSnapshot(
    netWorth: breakdown.netWorth,
    bankBalance: breakdown.bankBalance,
    cardDues: cardDueAmount,
    cardOutstanding: cardOutstanding,
    cashInHand: breakdown.cashBalance,
    monthlySpends: monthlySpends,
    pendingCount: pendingCount,
    loansOutstanding: breakdown.loanOutstanding,
    recoverableAmount: recoverableSnapshot.actionableRecoverableTotal,
    splitReceivableAmount: recoverableSnapshot.splitReceivables,
    splitPayableAmount: breakdown.splitPayables,
    recentTransactions: txns,
    dueSoonBillsCount: dueSoonBillsCount,
    bankAccountCount: banks.length,
    cashWalletCount: wallets.length,
    cardCount: cards.length,
    notificationDetectionEnabled:
        settings?.notificationDetectionEnabled ?? true,
    totalAssets: breakdown.totalAssets,
    totalLiabilities: breakdown.totalLiabilities,
    payableAmount: breakdown.payableAmount,
    debtRatio: breakdown.debtRatio,
    monthlyEmiBurden: breakdown.monthlyEmiBurden,
    unreadAlertsCount: unreadAlertsCount,
    latestImportantAlert: latestImportantAlert,
    monthlySpendTrend: monthlySpendTrend,
  );
});

List<MonthlySpendPoint> _buildMonthlySpendTrend(
  List<Transaction> transactions, {
  required List<CreditCard> cards,
  required List<CardBill> bills,
  required int? salaryCreditDay,
  required DateTime now,
}) {
  final currentMonth = DateTime(now.year, now.month);
  final months = List<DateTime>.generate(
    6,
    (index) => DateTime(currentMonth.year, currentMonth.month - (5 - index)),
  );
  final totals = <String, double>{
    for (final month in months) _monthKey(month): 0.0,
  };
  final incomeTotals = <String, double>{
    for (final month in months) _monthKey(month): 0.0,
  };
  final cardsById = {for (final card in cards) card.id: card};
  final billsById = {for (final bill in bills) bill.id: bill};

  for (final txn in transactions) {
    if (_isDashboardSpend(txn)) {
      final bucket = _spendBucketMonth(
        txn,
        cardsById: cardsById,
        billsById: billsById,
        salaryCreditDay: salaryCreditDay,
      );
      final key = _monthKey(bucket);
      if (totals.containsKey(key)) {
        totals[key] = totals[key]! + _dashboardLifestyleSpend(txn);
      }
    }

    if (_isDashboardIncome(txn)) {
      final key = _monthKey(
        DateTime(txn.transactionDate.year, txn.transactionDate.month),
      );
      if (incomeTotals.containsKey(key)) {
        incomeTotals[key] = incomeTotals[key]! + txn.amount;
      }
    }
  }

  return [
    for (final month in months)
      MonthlySpendPoint(
        month: month,
        amount: totals[_monthKey(month)] ?? 0,
        income: incomeTotals[_monthKey(month)] ?? 0,
      ),
  ];
}

bool _isDashboardIncome(Transaction txn) {
  return txn.type == 'income';
}

bool _isDashboardSpend(Transaction txn) {
  return txn.type != 'income' &&
      txn.type != 'refund' &&
      txn.type != 'transfer' &&
      txn.type != 'cardPayment' &&
      txn.type != 'loanEmi';
}

DateTime _spendBucketMonth(
  Transaction txn, {
  required Map<int, CreditCard> cardsById,
  required Map<int, CardBill> billsById,
  required int? salaryCreditDay,
}) {
  if (txn.paymentSourceType == 'creditCard') {
    final linkedBill = txn.cardBillId == null
        ? null
        : billsById[txn.cardBillId];
    if (linkedBill != null) {
      return DateTime(
        linkedBill.billingDate.year,
        linkedBill.billingDate.month,
      );
    }
    final card = cardsById[txn.paymentSourceId];
    if (card != null) {
      final billingDate = _billingDateForTransaction(card, txn.transactionDate);
      return DateTime(billingDate.year, billingDate.month);
    }
  }

  final cycleMonth = _salaryCycleMonth(
    txn.transactionDate,
    salaryCreditDay: salaryCreditDay,
  );
  return DateTime(cycleMonth.year, cycleMonth.month);
}

DateTime _salaryCycleMonth(DateTime date, {required int? salaryCreditDay}) {
  if (salaryCreditDay == null) return DateTime(date.year, date.month);
  final safeDay = _safeDay(date.year, date.month, salaryCreditDay).day;
  if (date.day < safeDay) {
    return DateTime(date.year, date.month - 1);
  }
  return DateTime(date.year, date.month);
}

DateTime _billingDateForTransaction(CreditCard card, DateTime txnDate) {
  final date = DateTime(txnDate.year, txnDate.month, txnDate.day);
  final thisMonthBilling = _safeDay(date.year, date.month, card.billingDay);
  if (date.isBefore(thisMonthBilling)) return thisMonthBilling;
  return _safeDay(date.year, date.month + 1, card.billingDay);
}

DateTime _safeDay(int year, int month, int day) {
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, day.clamp(1, lastDay));
}

String _monthKey(DateTime month) =>
    '${month.year}-${month.month.toString().padLeft(2, '0')}';

double _dashboardLifestyleSpend(Transaction t) {
  final recoverableBase =
      t.recoverableBaseAmount ??
      (t.isForOthers
          ? (t.amount - t.cashbackAmount).clamp(0, t.amount).toDouble()
          : 0.0);
  final base =
      t.personalShareAmount ??
      (t.isForOthers
          ? (t.amount - recoverableBase).clamp(0, t.amount).toDouble()
          : t.amount);
  return (base - t.cashbackAmount).clamp(0, double.infinity).toDouble();
}

final dashboardRefreshActionsProvider = Provider<Future<void> Function()>((
  ref,
) {
  return () async {
    await Future.wait([
      ref.refresh(dashboardProvider.future),
      ref.refresh(alertsInboxProvider.future),
      ref.refresh(alertsUnreadCountProvider.future),
      ref.refresh(latestImportantAlertProvider.future),
      ref.refresh(pendingTransactionsProvider.future),
      ref.refresh(pendingCountProvider.future),
      ref.refresh(analyticsSnapshotProvider.future),
    ]);
  };
});
