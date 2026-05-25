import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../cards/data/billing_service.dart';
import '../../expenses/models/transaction_types.dart';
import '../../loans/data/loan_service.dart';
import '../../split/data/split_service.dart';
import 'analytics_models.dart';

class AnalyticsService {
  AnalyticsService(this._db, this._billing, this._loans, this._split);

  final AppDatabase _db;
  final BillingService _billing;
  final LoanService _loans;
  final SplitService _split;

  Future<AnalyticsSnapshot> buildSnapshot({
    required AnalyticsPeriod period,
    DateTimeRange? customRange,
    DateTime? now,
  }) async {
    final range = resolveDateRange(period, now: now, customRange: customRange);

    final allTransactions = await _db.select(_db.transactions).get();
    final rangeTxns = allTransactions
        .where((t) => range.contains(t.transactionDate))
        .toList(growable: false);

    final cards = await _db.select(_db.creditCards).get();
    final bills = await _db.select(_db.cardBills).get();
    final loans = await _db.select(_db.loans).get();
    final loanPayments = await _db.select(_db.loanPayments).get();
    final splitGroups = await (_db.select(
      _db.splitGroups,
    )..where((g) => g.archivedAt.isNull())).get();
    final shares = await _db.select(_db.splitExpenseShares).get();
    final bankAccounts = await _db.select(_db.bankAccounts).get();
    final cashWallets = await _db.select(_db.cashWallets).get();

    final hasAnyData =
        rangeTxns.isNotEmpty ||
        cards.isNotEmpty ||
        loans.isNotEmpty ||
        splitGroups.isNotEmpty;

    final spending = _buildSpending(rangeTxns, range);
    final income = _buildIncome(rangeTxns, range);
    final cardsSnap = _buildCards(rangeTxns, cards, bills, range);
    final loansSnap = await _buildLoans(
      loans: loans,
      loanPayments: loanPayments,
      range: range,
      bankAccounts: bankAccounts,
      cashWallets: cashWallets,
    );
    final splitsSnap = await _buildSplits(
      splitGroups: splitGroups,
      shares: shares,
    );
    final monthlyTrend = _buildMonthlyTrend(
      range: range,
      spendingTrend: spending.spendingTrend,
      incomeTrend: income.incomeTrend,
      billedTrend: cardsSnap.billedTrend,
      emiTrend: loansSnap.emiTrend,
      debtRatioTrend: loansSnap.debtRatioTrend,
    );

    return AnalyticsSnapshot(
      range: range,
      hasAnyData: hasAnyData,
      monthlyTrend: monthlyTrend,
      spending: spending,
      income: income,
      cards: cardsSnap,
      loans: loansSnap,
      splits: splitsSnap,
    );
  }

  SpendingAnalyticsSnapshot _buildSpending(
    List<Transaction> rangeTxns,
    AnalyticsDateRange range,
  ) {
    final spendingTxns = rangeTxns
        .where(_isLifestyleSpend)
        .toList(growable: false);

    final totalSpending = spendingTxns.fold<double>(
      0,
      (sum, t) => sum + _netLifestyleSpend(t),
    );
    final avgDaily = range.totalDays <= 0
        ? 0.0
        : totalSpending / range.totalDays;

    final categoryMap = <String, double>{};
    final merchantAmountMap = <String, double>{};
    final merchantCountMap = <String, int>{};
    final paymentModeMap = <String, double>{};

    final monthSpendMap = <String, double>{};

    for (final t in spendingTxns) {
      final amount = _netLifestyleSpend(t);
      if (amount <= 0) continue;
      categoryMap[t.category] = (categoryMap[t.category] ?? 0) + amount;
      merchantAmountMap[t.title] = (merchantAmountMap[t.title] ?? 0) + amount;
      merchantCountMap[t.title] = (merchantCountMap[t.title] ?? 0) + 1;
      final mode = _paymentModeLabel(t.paymentSourceType);
      paymentModeMap[mode] = (paymentModeMap[mode] ?? 0) + amount;
      final monthKey = _monthKey(t.transactionDate);
      monthSpendMap[monthKey] = (monthSpendMap[monthKey] ?? 0) + amount;
    }

    final categories = _sortNamedAmounts(categoryMap);
    final merchants = _sortNamedAmounts(merchantAmountMap);
    final paymentModes = _sortNamedAmounts(paymentModeMap);

    final recurring =
        merchantCountMap.entries
            .where((e) => e.value >= 2)
            .map(
              (e) => NamedAmount(
                name: e.key,
                count: e.value,
                amount: merchantAmountMap[e.key] ?? 0,
              ),
            )
            .toList(growable: false)
          ..sort((a, b) {
            final byCount = b.count.compareTo(a.count);
            if (byCount != 0) return byCount;
            return b.amount.compareTo(a.amount);
          });

    final monthKeys = _monthsInRange(range);
    final spendingTrend = monthKeys
        .map(
          (key) => TrendPoint(
            label: _monthLabelFromKey(key),
            value: monthSpendMap[key] ?? 0,
          ),
        )
        .toList(growable: false);

    return SpendingAnalyticsSnapshot(
      totalSpending: totalSpending,
      avgDailySpend: avgDaily,
      highestCategory: categories.isEmpty ? null : categories.first,
      highestMerchant: merchants.isEmpty ? null : merchants.first,
      recurringMerchants: recurring.take(5).toList(growable: false),
      categoryBreakdown: categories,
      topCategories: categories.take(6).toList(growable: false),
      topMerchants: merchants.take(6).toList(growable: false),
      paymentModeSplit: paymentModes,
      spendingTrend: spendingTrend,
    );
  }

  IncomeAnalyticsSnapshot _buildIncome(
    List<Transaction> rangeTxns,
    AnalyticsDateRange range,
  ) {
    final incomes = rangeTxns
        .where(
          (t) =>
              t.type == TransactionType.income ||
              t.type == TransactionType.refund,
        )
        .toList(growable: false);
    final expenses = rangeTxns.where(_isLifestyleSpend).toList(growable: false);

    final totalIncome = incomes.fold<double>(0, (sum, t) => sum + t.amount);
    final totalExpense = expenses.fold<double>(
      0,
      (sum, t) => sum + _netLifestyleSpend(t),
    );

    final monthIncomeMap = <String, double>{};
    for (final t in incomes) {
      final key = _monthKey(t.transactionDate);
      monthIncomeMap[key] = (monthIncomeMap[key] ?? 0) + t.amount;
    }

    final monthKeys = _monthsInRange(range);
    final incomeTrend = monthKeys
        .map(
          (key) => TrendPoint(
            label: _monthLabelFromKey(key),
            value: monthIncomeMap[key] ?? 0,
          ),
        )
        .toList(growable: false);

    return IncomeAnalyticsSnapshot(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netFlow: totalIncome - totalExpense,
      incomeTrend: incomeTrend,
    );
  }

  CardAnalyticsSnapshot _buildCards(
    List<Transaction> rangeTxns,
    List<CreditCard> cards,
    List<CardBill> bills,
    AnalyticsDateRange range,
  ) {
    final cardTxns = rangeTxns
        .where((t) => t.paymentSourceType == PaymentSourceType.creditCard)
        .toList(growable: false);

    final spendByCard = <int, double>{};
    for (final t in cardTxns) {
      spendByCard[t.paymentSourceId] =
          (spendByCard[t.paymentSourceId] ?? 0) + _netLifestyleSpend(t);
    }

    final usage =
        cards
            .map((c) {
              final amount = spendByCard[c.id] ?? 0;
              final utilization = c.creditLimit <= 0
                  ? 0.0
                  : (c.currentOutstanding / c.creditLimit)
                        .clamp(0, 1)
                        .toDouble();
              return CardUsageBreakdown(
                cardId: c.id,
                cardName: c.nickname,
                last4: c.last4,
                amount: amount,
                outstanding: c.currentOutstanding,
                creditLimit: c.creditLimit,
                utilization: utilization,
              );
            })
            .toList(growable: false)
          ..sort((a, b) => b.amount.compareTo(a.amount));

    final totalOutstanding = cards.fold<double>(
      0,
      (s, c) => s + c.currentOutstanding,
    );
    final totalLimit = cards.fold<double>(0, (s, c) => s + c.creditLimit);
    final utilization = totalLimit <= 0
        ? 0.0
        : (totalOutstanding / totalLimit).clamp(0, 1).toDouble();

    final now = DateTime.now();
    var billedTotal = 0.0;
    var paidTotal = 0.0;
    var pendingTotal = 0.0;
    var overdueCount = 0;
    var dueSoonCount = 0;
    var paidCount = 0;

    final billedMonthMap = <String, double>{};
    for (final bill in bills) {
      if (range.contains(bill.billingDate)) {
        billedTotal += bill.billedAmount;
        paidTotal += bill.paidAmount;
        pendingTotal += (bill.billedAmount - bill.paidAmount)
            .clamp(0, bill.billedAmount)
            .toDouble();
        final status = _billing.getDueStatusFromDate(
          isPaid: bill.status == 'paid' || bill.paidAmount >= bill.billedAmount,
          dueDate: bill.dueDate,
          now: now,
        );
        if (status == 'overdue') overdueCount += 1;
        if (status == 'dueSoon') dueSoonCount += 1;
        if (status == 'paid') paidCount += 1;

        final monthKey = _monthKey(bill.billingDate);
        billedMonthMap[monthKey] =
            (billedMonthMap[monthKey] ?? 0) + bill.billedAmount;
      }
    }

    final monthKeys = _monthsInRange(range);
    final billedTrend = monthKeys
        .map(
          (key) => TrendPoint(
            label: _monthLabelFromKey(key),
            value: billedMonthMap[key] ?? 0,
          ),
        )
        .toList(growable: false);

    return CardAnalyticsSnapshot(
      totalUtilization: utilization,
      highestSpendCard: usage.isEmpty ? null : usage.first,
      usageSplit: usage,
      billSummary: CardBillSummary(
        billedTotal: billedTotal,
        paidTotal: paidTotal,
        pendingTotal: pendingTotal,
        overdueCount: overdueCount,
        dueSoonCount: dueSoonCount,
        paidCount: paidCount,
      ),
      billedTrend: billedTrend,
    );
  }

  Future<LoanAnalyticsSnapshot> _buildLoans({
    required List<Loan> loans,
    required List<LoanPayment> loanPayments,
    required AnalyticsDateRange range,
    required List<BankAccount> bankAccounts,
    required List<CashWallet> cashWallets,
  }) async {
    final activeCount = loans.where((l) => l.closedAt == null).length;
    final closedCount = loans.where((l) => l.closedAt != null).length;
    final totalOutstanding = loans.fold<double>(
      0,
      (s, l) => s + l.currentOutstanding,
    );
    final monthlyEmiBurden = loans
        .where((l) => l.closedAt == null)
        .fold<double>(0, (s, l) => s + (l.emiAmount ?? 0));

    final upcoming = await _loans.getUpcomingEmis(withinDays: 30);
    final upcomingTotal = upcoming.fold<double>(
      0,
      (s, e) => s + (e.loan.emiAmount ?? 0),
    );

    final paymentsInRange = loanPayments
        .where((p) => range.contains(p.paymentDate))
        .toList(growable: false);
    final emiMonthMap = <String, double>{};
    for (final p in paymentsInRange) {
      final key = _monthKey(p.paymentDate);
      emiMonthMap[key] = (emiMonthMap[key] ?? 0) + p.amount;
    }

    final monthKeys = _monthsInRange(range);
    final emiTrend = monthKeys
        .map(
          (key) => TrendPoint(
            label: _monthLabelFromKey(key),
            value: emiMonthMap[key] ?? 0,
          ),
        )
        .toList(growable: false);

    final liquidAssets =
        bankAccounts.fold<double>(0, (s, b) => s + b.currentBalance) +
        cashWallets.fold<double>(0, (s, c) => s + c.currentBalance);

    final debtRatioTrend = monthKeys
        .map((key) {
          final date = _monthEndFromKey(key);
          final outstandingAt = _estimateOutstandingAt(
            loans: loans,
            loanPayments: loanPayments,
            date: date,
          );
          final ratio = liquidAssets <= 0
              ? 0.0
              : (outstandingAt / liquidAssets);
          return TrendPoint(label: _monthLabelFromKey(key), value: ratio);
        })
        .toList(growable: false);

    return LoanAnalyticsSnapshot(
      totalOutstanding: totalOutstanding,
      monthlyEmiBurden: monthlyEmiBurden,
      activeCount: activeCount,
      closedCount: closedCount,
      upcomingEmiTotal: upcomingTotal,
      upcomingEmiCount: upcoming.length,
      emiTrend: emiTrend,
      debtRatioTrend: debtRatioTrend,
    );
  }

  Future<SplitAnalyticsSnapshot> _buildSplits({
    required List<SplitGroup> splitGroups,
    required List<SplitExpenseShare> shares,
  }) async {
    final receivable = await _split.getCurrentUserReceivables();
    final payable = await _split.getCurrentUserPayables();

    final groupBalances = <NamedAmount>[];
    final owesYouMap = <String, double>{};
    final youOweMap = <String, double>{};

    for (final group in splitGroups) {
      final balances = await _split.getGroupBalances(group.id);
      final currentUser = balances
          .where((b) => b.member.isCurrentUser)
          .map((e) => e)
          .toList(growable: false);
      if (currentUser.isEmpty) continue;
      final yourNet = currentUser.first.net;

      groupBalances.add(NamedAmount(name: group.name, amount: yourNet));

      if (yourNet > 0) {
        for (final member in balances.where(
          (b) => !b.member.isCurrentUser && b.net < 0,
        )) {
          owesYouMap[member.member.name] =
              (owesYouMap[member.member.name] ?? 0) + member.net.abs();
        }
      } else if (yourNet < 0) {
        for (final member in balances.where(
          (b) => !b.member.isCurrentUser && b.net > 0,
        )) {
          youOweMap[member.member.name] =
              (youOweMap[member.member.name] ?? 0) + member.net;
        }
      }
    }

    final totalShares = shares.length;
    final settledShares = shares.where((s) => s.isSettled).length;
    final progress = totalShares == 0 ? 0.0 : settledShares / totalShares;

    groupBalances.sort((a, b) => b.amount.abs().compareTo(a.amount.abs()));

    return SplitAnalyticsSnapshot(
      totalRecoverable: receivable,
      totalPayable: payable,
      groupBalances: groupBalances,
      owesYou: _sortNamedAmounts(owesYouMap).take(5).toList(growable: false),
      youOwe: _sortNamedAmounts(youOweMap).take(5).toList(growable: false),
      settlementProgress: progress,
    );
  }

  List<MonthlyTrendPoint> _buildMonthlyTrend({
    required AnalyticsDateRange range,
    required List<TrendPoint> spendingTrend,
    required List<TrendPoint> incomeTrend,
    required List<TrendPoint> billedTrend,
    required List<TrendPoint> emiTrend,
    required List<TrendPoint> debtRatioTrend,
  }) {
    final keys = _monthsInRange(range);
    final spendMap = {for (final x in spendingTrend) x.label: x.value};
    final incomeMap = {for (final x in incomeTrend) x.label: x.value};
    final billedMap = {for (final x in billedTrend) x.label: x.value};
    final emiMap = {for (final x in emiTrend) x.label: x.value};
    final debtMap = {for (final x in debtRatioTrend) x.label: x.value};

    return keys
        .map((key) {
          final label = _monthLabelFromKey(key);
          return MonthlyTrendPoint(
            label: label,
            spend: spendMap[label] ?? 0,
            income: incomeMap[label] ?? 0,
            billed: billedMap[label] ?? 0,
            emi: emiMap[label] ?? 0,
            debtRatio: debtMap[label] ?? 0,
          );
        })
        .toList(growable: false);
  }

  bool _isLifestyleSpend(Transaction t) {
    if (t.type == TransactionType.transfer ||
        t.type == TransactionType.cardPayment ||
        t.type == TransactionType.income ||
        t.type == TransactionType.refund ||
        t.type == TransactionType.loanEmi) {
      return false;
    }
    return true;
  }

  double _netLifestyleSpend(Transaction t) {
    final base =
        t.personalShareAmount ??
        (t.isForOthers && t.recoverableAmount != null
            ? (t.amount - t.recoverableAmount!).clamp(0, t.amount).toDouble()
            : t.amount);
    return (base - t.cashbackAmount).clamp(0, double.infinity).toDouble();
  }

  List<NamedAmount> _sortNamedAmounts(Map<String, double> raw) {
    final items =
        raw.entries
            .map((e) => NamedAmount(name: e.key, amount: e.value))
            .toList(growable: false)
          ..sort((a, b) => b.amount.compareTo(a.amount));
    return items;
  }

  String _paymentModeLabel(String type) {
    switch (type) {
      case PaymentSourceType.cash:
        return 'Cash';
      case PaymentSourceType.upi:
        return 'UPI';
      case PaymentSourceType.creditCard:
        return 'Card';
      case PaymentSourceType.bank:
      default:
        return 'Bank';
    }
  }

  String _monthKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';

  List<String> _monthsInRange(AnalyticsDateRange range) {
    final list = <String>[];
    var cursor = DateTime(range.start.year, range.start.month, 1);
    final end = DateTime(range.end.year, range.end.month, 1);
    while (!cursor.isAfter(end)) {
      list.add(_monthKey(cursor));
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }
    return list;
  }

  String _monthLabelFromKey(String key) {
    final parts = key.split('-');
    if (parts.length != 2) return key;
    final y = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 1;
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${monthNames[(m - 1).clamp(0, 11)]} ${y % 100}';
  }

  DateTime _monthEndFromKey(String key) {
    final parts = key.split('-');
    final y = int.tryParse(parts[0]) ?? DateTime.now().year;
    final m = int.tryParse(parts[1]) ?? DateTime.now().month;
    return DateTime(y, m + 1, 0);
  }

  double _estimateOutstandingAt({
    required List<Loan> loans,
    required List<LoanPayment> loanPayments,
    required DateTime date,
  }) {
    var total = 0.0;
    for (final loan in loans) {
      if (loan.createdAt.isAfter(date)) {
        continue;
      }

      var outstandingAt = loan.currentOutstanding;
      for (final payment in loanPayments.where(
        (p) => p.loanId == loan.id && p.paymentDate.isAfter(date),
      )) {
        outstandingAt += payment.amount;
      }
      if (loan.closedAt != null && loan.closedAt!.isBefore(date)) {
        outstandingAt = 0;
      }
      total += outstandingAt;
    }
    return total;
  }
}
