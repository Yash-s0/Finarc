import 'package:flutter/material.dart';

enum AnalyticsPeriod { thisMonth, lastMonth, last3Months, thisYear, custom }

class AnalyticsDateRange {
  const AnalyticsDateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  int get totalDays => end.difference(start).inDays + 1;

  String get label =>
      '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';

  bool contains(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return !d.isBefore(start) && !d.isAfter(end);
  }
}

class NamedAmount {
  const NamedAmount({
    required this.name,
    required this.amount,
    this.count = 0,
    this.extra,
  });

  final String name;
  final double amount;
  final int count;
  final String? extra;
}

class TrendPoint {
  const TrendPoint({required this.label, required this.value});

  final String label;
  final double value;
}

class MonthlyTrendPoint {
  const MonthlyTrendPoint({
    required this.label,
    required this.spend,
    required this.income,
    required this.billed,
    required this.emi,
    required this.debtRatio,
  });

  final String label;
  final double spend;
  final double income;
  final double billed;
  final double emi;
  final double debtRatio;
}

class CardUsageBreakdown {
  const CardUsageBreakdown({
    required this.cardId,
    required this.cardName,
    required this.last4,
    required this.amount,
    required this.outstanding,
    required this.creditLimit,
    required this.utilization,
  });

  final int cardId;
  final String cardName;
  final String last4;
  final double amount;
  final double outstanding;
  final double creditLimit;
  final double utilization;
}

class CardBillSummary {
  const CardBillSummary({
    required this.billedTotal,
    required this.paidTotal,
    required this.pendingTotal,
    required this.overdueCount,
    required this.dueSoonCount,
    required this.paidCount,
  });

  final double billedTotal;
  final double paidTotal;
  final double pendingTotal;
  final int overdueCount;
  final int dueSoonCount;
  final int paidCount;
}

class SplitAnalyticsSnapshot {
  const SplitAnalyticsSnapshot({
    required this.totalRecoverable,
    required this.totalPayable,
    required this.groupBalances,
    required this.owesYou,
    required this.youOwe,
    required this.settlementProgress,
  });

  final double totalRecoverable;
  final double totalPayable;
  final List<NamedAmount> groupBalances;
  final List<NamedAmount> owesYou;
  final List<NamedAmount> youOwe;
  final double settlementProgress;
}

class LoanAnalyticsSnapshot {
  const LoanAnalyticsSnapshot({
    required this.totalOutstanding,
    required this.monthlyEmiBurden,
    required this.activeCount,
    required this.closedCount,
    required this.upcomingEmiTotal,
    required this.upcomingEmiCount,
    required this.emiTrend,
    required this.debtRatioTrend,
  });

  final double totalOutstanding;
  final double monthlyEmiBurden;
  final int activeCount;
  final int closedCount;
  final double upcomingEmiTotal;
  final int upcomingEmiCount;
  final List<TrendPoint> emiTrend;
  final List<TrendPoint> debtRatioTrend;
}

class CardAnalyticsSnapshot {
  const CardAnalyticsSnapshot({
    required this.totalUtilization,
    required this.highestSpendCard,
    required this.usageSplit,
    required this.billSummary,
    required this.billedTrend,
  });

  final double totalUtilization;
  final CardUsageBreakdown? highestSpendCard;
  final List<CardUsageBreakdown> usageSplit;
  final CardBillSummary billSummary;
  final List<TrendPoint> billedTrend;
}

class SpendingAnalyticsSnapshot {
  const SpendingAnalyticsSnapshot({
    required this.totalSpending,
    required this.avgDailySpend,
    required this.highestCategory,
    required this.highestMerchant,
    required this.recurringMerchants,
    required this.categoryBreakdown,
    required this.topCategories,
    required this.topMerchants,
    required this.paymentModeSplit,
    required this.spendingTrend,
  });

  final double totalSpending;
  final double avgDailySpend;
  final NamedAmount? highestCategory;
  final NamedAmount? highestMerchant;
  final List<NamedAmount> recurringMerchants;
  final List<NamedAmount> categoryBreakdown;
  final List<NamedAmount> topCategories;
  final List<NamedAmount> topMerchants;
  final List<NamedAmount> paymentModeSplit;
  final List<TrendPoint> spendingTrend;
}

class IncomeAnalyticsSnapshot {
  const IncomeAnalyticsSnapshot({
    required this.totalIncome,
    required this.totalExpense,
    required this.netFlow,
    required this.incomeTrend,
  });

  final double totalIncome;
  final double totalExpense;
  final double netFlow;
  final List<TrendPoint> incomeTrend;
}

class AnalyticsSnapshot {
  const AnalyticsSnapshot({
    required this.range,
    required this.hasAnyData,
    required this.monthlyTrend,
    required this.spending,
    required this.income,
    required this.cards,
    required this.loans,
    required this.splits,
  });

  final AnalyticsDateRange range;
  final bool hasAnyData;
  final List<MonthlyTrendPoint> monthlyTrend;
  final SpendingAnalyticsSnapshot spending;
  final IncomeAnalyticsSnapshot income;
  final CardAnalyticsSnapshot cards;
  final LoanAnalyticsSnapshot loans;
  final SplitAnalyticsSnapshot splits;
}

class AnalyticsSectionTab {
  const AnalyticsSectionTab({required this.id, required this.label});

  final String id;
  final String label;
}

const analyticsSectionTabs = <AnalyticsSectionTab>[
  AnalyticsSectionTab(id: 'overview', label: 'Overview'),
  AnalyticsSectionTab(id: 'spending', label: 'Spending'),
  AnalyticsSectionTab(id: 'income', label: 'Income'),
  AnalyticsSectionTab(id: 'cards', label: 'Cards'),
  AnalyticsSectionTab(id: 'loans', label: 'Loans'),
  AnalyticsSectionTab(id: 'splits', label: 'Splits'),
];

String analyticsPeriodLabel(AnalyticsPeriod period) {
  switch (period) {
    case AnalyticsPeriod.thisMonth:
      return 'This Month';
    case AnalyticsPeriod.lastMonth:
      return 'Last Month';
    case AnalyticsPeriod.last3Months:
      return 'Last 3 Months';
    case AnalyticsPeriod.thisYear:
      return 'This Year';
    case AnalyticsPeriod.custom:
      return 'Custom';
  }
}

AnalyticsDateRange resolveDateRange(
  AnalyticsPeriod period, {
  DateTime? now,
  DateTimeRange? customRange,
}) {
  final base = DateTime(
    now?.year ?? DateTime.now().year,
    now?.month ?? DateTime.now().month,
    now?.day ?? DateTime.now().day,
  );

  switch (period) {
    case AnalyticsPeriod.thisMonth:
      return AnalyticsDateRange(
        start: DateTime(base.year, base.month, 1),
        end: DateTime(base.year, base.month + 1, 0),
      );
    case AnalyticsPeriod.lastMonth:
      final start = DateTime(base.year, base.month - 1, 1);
      return AnalyticsDateRange(
        start: start,
        end: DateTime(start.year, start.month + 1, 0),
      );
    case AnalyticsPeriod.last3Months:
      final start = DateTime(base.year, base.month - 2, 1);
      return AnalyticsDateRange(
        start: start,
        end: DateTime(base.year, base.month + 1, 0),
      );
    case AnalyticsPeriod.thisYear:
      return AnalyticsDateRange(
        start: DateTime(base.year, 1, 1),
        end: DateTime(base.year, 12, 31),
      );
    case AnalyticsPeriod.custom:
      if (customRange != null) {
        return AnalyticsDateRange(
          start: DateTime(
            customRange.start.year,
            customRange.start.month,
            customRange.start.day,
          ),
          end: DateTime(
            customRange.end.year,
            customRange.end.month,
            customRange.end.day,
          ),
        );
      }
      return AnalyticsDateRange(
        start: DateTime(base.year, base.month, 1),
        end: DateTime(base.year, base.month + 1, 0),
      );
  }
}
