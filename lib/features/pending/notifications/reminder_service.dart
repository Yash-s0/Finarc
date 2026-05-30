import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/formatters.dart';
import '../../cards/data/billing_service.dart';
import '../../expenses/data/transaction_engine.dart';
import '../../loans/data/loan_service.dart';
import '../../recoverables/data/recoverables_service.dart';
import '../../split/data/split_service.dart';
import 'notification_local_notifier.dart';

class ReminderService {
  ReminderService(this._db, this._notifier);

  final AppDatabase _db;
  final NotificationLocalNotifier _notifier;

  static const int dailyReminderId = 2101;
  static const int weeklyReminderId = 2102;
  static const int pendingReminderId = 2103;
  static const int cardDueReminderBaseId = 3000;
  static const int loanEmiReminderBaseId = 5000;

  Future<void> scheduleDailyReminder(TimeOfDay time) async {
    final next = _nextTime(time);
    final body = await dailySummaryText();
    await _notifier.scheduleReminder(
      reminderId: dailyReminderId,
      triggerAt: next,
      title: 'Finarc Daily Summary',
      body: body,
      route: '/',
      repeatDaily: true,
    );
  }

  Future<void> scheduleWeeklyReminder(int weekday, TimeOfDay time) async {
    final next = _nextWeekdayTime(weekday, time);
    final body = await weeklySummaryText();
    await _notifier.scheduleReminder(
      reminderId: weeklyReminderId,
      triggerAt: next,
      title: 'Finarc Weekly Summary',
      body: body,
      route: '/',
      repeatWeekly: true,
    );
  }

  Future<void> cancelDailyReminder() =>
      _notifier.cancelReminder(dailyReminderId);

  Future<void> cancelWeeklyReminder() =>
      _notifier.cancelReminder(weeklyReminderId);

  Future<void> schedulePendingConfirmationReminder() async {
    final count = await _pendingCount();
    if (count <= 0) {
      await _notifier.cancelReminder(pendingReminderId);
      return;
    }

    final triggerAt = DateTime.now().add(const Duration(minutes: 30));
    await _notifier.scheduleReminder(
      reminderId: pendingReminderId,
      triggerAt: triggerAt,
      title: 'Pending Transactions',
      body: pendingReminderText(count),
      route: '/pending',
    );
  }

  Future<void> scheduleCardDueReminder(CreditCard card, CardBill bill) async {
    final status = BillingService(_db).getDueStatus(bill);
    final reminderId = cardDueReminderBaseId + bill.id;

    if (status == 'paid') {
      await _notifier.cancelReminder(reminderId);
      return;
    }

    final now = DateTime.now();
    final dueAtNine = DateTime(
      bill.dueDate.year,
      bill.dueDate.month,
      bill.dueDate.day,
      9,
    );
    final twoDaysBefore = dueAtNine.subtract(const Duration(days: 2));
    final oneDayBefore = dueAtNine.subtract(const Duration(days: 1));

    DateTime trigger;
    if (now.isBefore(twoDaysBefore)) {
      trigger = twoDaysBefore;
    } else if (now.isBefore(oneDayBefore)) {
      trigger = oneDayBefore;
    } else if (now.isBefore(dueAtNine)) {
      trigger = dueAtNine;
    } else if (status == 'overdue') {
      trigger = now.add(const Duration(seconds: 10));
    } else {
      trigger = now.add(const Duration(minutes: 5));
    }

    await _notifier.scheduleReminder(
      reminderId: reminderId,
      triggerAt: trigger,
      title: '${card.bankName} card bill reminder',
      body: dueBillReminderText(card, bill),
      route: '/cards/${card.id}',
    );
  }

  Future<void> syncCardDueReminders({required bool enabled}) async {
    final cards = await _db.select(_db.creditCards).get();
    final bills = await _db.select(_db.cardBills).get();
    for (final bill in bills) {
      final reminderId = cardDueReminderBaseId + bill.id;
      if (!enabled) {
        await _notifier.cancelReminder(reminderId);
        continue;
      }
      CreditCard? card;
      for (final value in cards) {
        if (value.id == bill.cardId) {
          card = value;
          break;
        }
      }
      if (card == null) continue;
      await scheduleCardDueReminder(card, bill);
    }
  }

  Future<void> scheduleLoanEmiReminder(EmiSchedule schedule) async {
    final reminderId = loanEmiReminderBaseId + schedule.loan.id;
    final now = DateTime.now();
    final dueAtNine = DateTime(
      schedule.nextDate.year,
      schedule.nextDate.month,
      schedule.nextDate.day,
      9,
    );

    DateTime triggerAt;
    if (schedule.daysUntilDue < 0) {
      triggerAt = now.add(const Duration(seconds: 10));
    } else if (schedule.daysUntilDue <= 2) {
      triggerAt = now.isBefore(dueAtNine)
          ? dueAtNine
          : now.add(const Duration(minutes: 5));
    } else {
      triggerAt = dueAtNine.subtract(const Duration(days: 2));
      if (!triggerAt.isAfter(now)) {
        triggerAt = now.add(const Duration(minutes: 5));
      }
    }

    await _notifier.scheduleReminder(
      reminderId: reminderId,
      triggerAt: triggerAt,
      title: '${schedule.loan.title} EMI reminder',
      body: loanEmiReminderText(schedule),
      route: '/loans/${schedule.loan.id}',
    );
  }

  Future<void> syncLoanEmiReminders({required bool enabled}) async {
    final loanService = LoanService(_db);
    final loans = await _db.select(_db.loans).get();
    for (final loan in loans) {
      await _notifier.cancelReminder(loanEmiReminderBaseId + loan.id);
    }
    if (!enabled) return;

    final schedules = await loanService.getUpcomingEmis(withinDays: 30);
    for (final schedule in schedules) {
      await scheduleLoanEmiReminder(schedule);
    }
  }

  Future<void> showImmediateReminderPreview() async {
    final body = await dailySummaryText();
    await _notifier.showReminder(
      title: 'Finarc reminder preview',
      body: body,
      route: '/',
    );
  }

  Future<String> dailySummaryText() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    final txns = await _db.select(_db.transactions).get();
    final todayTxns = txns
        .where(
          (t) =>
              !t.transactionDate.isBefore(start) &&
              t.transactionDate.isBefore(end),
        )
        .toList(growable: false);
    final spends = todayTxns
        .where((t) => t.type != 'income' && t.type != 'refund')
        .fold<double>(0, (sum, t) => sum + (t.amount - t.cashbackAmount));
    final pending = await _pendingCount();
    final dueSoon = await _dueSoonCount();
    final splitLine = await _splitSettlementReminderLine();
    final emiLine = await _loanEmiReminderLine(days: 2);
    final recoverableLine = await _recoverableReminderLine();
    final base =
        'Today: ${inr(spends)} spent · $pending pending · $dueSoon bill due soon.';
    var summary = base;
    if (recoverableLine != null) summary = '$summary $recoverableLine';
    if (splitLine != null) summary = '$summary $splitLine';
    if (emiLine != null) summary = '$summary $emiLine';
    return summary;
  }

  Future<String> weeklySummaryText() async {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 7));

    final txns = await _db.select(_db.transactions).get();
    final weekTxns = txns
        .where(
          (t) =>
              !t.transactionDate.isBefore(start) &&
              t.transactionDate.isBefore(end),
        )
        .toList(growable: false);
    final spends = weekTxns
        .where((t) => t.type != 'income' && t.type != 'refund')
        .fold<double>(0, (sum, t) => sum + (t.amount - t.cashbackAmount));
    final pending = await _pendingCount();
    final splitLine = await _splitSettlementReminderLine();
    final emiLine = await _loanEmiReminderLine(days: 7);
    final recoverableLine = await _recoverableReminderLine();
    final base = 'This week: ${inr(spends)} spent · $pending pending.';
    var summary = base;
    if (recoverableLine != null) summary = '$summary $recoverableLine';
    if (splitLine != null) summary = '$summary $splitLine';
    if (emiLine != null) summary = '$summary $emiLine';
    return summary;
  }

  String pendingReminderText(int pendingCount) {
    return 'You have $pendingCount transactions waiting for confirmation.';
  }

  String dueBillReminderText(CreditCard card, CardBill bill) {
    final today = DateTime.now();
    final base = DateTime(today.year, today.month, today.day);
    final due = DateTime(
      bill.dueDate.year,
      bill.dueDate.month,
      bill.dueDate.day,
    );
    final days = due.difference(base).inDays;
    final pendingAmount = (bill.billedAmount - bill.paidAmount)
        .clamp(0, bill.billedAmount)
        .toDouble();
    if (days < 0) {
      return '${card.bankName} card bill of ${inr(pendingAmount)} is overdue.';
    }
    if (days == 0) {
      return '${card.bankName} card bill of ${inr(pendingAmount)} is due today.';
    }
    if (days == 1) {
      return '${card.bankName} card bill of ${inr(pendingAmount)} is due in 1 day.';
    }
    return '${card.bankName} card bill of ${inr(pendingAmount)} is due in $days days.';
  }

  String loanEmiReminderText(EmiSchedule schedule) {
    final amount = inr(schedule.loan.emiAmount ?? 0);
    if (schedule.daysUntilDue < 0) {
      return '${schedule.loan.title} EMI of $amount is overdue.';
    }
    if (schedule.daysUntilDue == 0) {
      return 'EMI of $amount is due today.';
    }
    if (schedule.daysUntilDue == 1) {
      return 'EMI of $amount is due tomorrow.';
    }
    return 'EMI of $amount is due in ${schedule.daysUntilDue} days.';
  }

  DateTime _nextTime(TimeOfDay time) {
    final now = DateTime.now();
    final today = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (today.isAfter(now)) return today;
    return today.add(const Duration(days: 1));
  }

  DateTime _nextWeekdayTime(int weekday, TimeOfDay time) {
    final now = DateTime.now();
    var daysToAdd = (weekday - now.weekday) % 7;
    if (daysToAdd < 0) {
      daysToAdd += 7;
    }
    var candidate = DateTime(
      now.year,
      now.month,
      now.day + daysToAdd,
      time.hour,
      time.minute,
    );
    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 7));
    }
    return candidate;
  }

  Future<int> _pendingCount() async {
    final rows = await (_db.select(
      _db.pendingTransactions,
    )..where((p) => p.status.equals('pending'))).get();
    return rows.length;
  }

  Future<int> _dueSoonCount() async {
    final bills = await _db.select(_db.cardBills).get();
    final billing = BillingService(_db);
    var count = 0;
    for (final bill in bills) {
      final status = billing.getDueStatus(bill);
      if (status == 'dueSoon') count += 1;
    }
    return count;
  }

  Future<String?> _recoverableReminderLine() async {
    final engine = TransactionEngine(_db);
    final recoverables = await RecoverablesService(
      _db,
      SplitService(_db, engine),
      engine,
    ).buildSnapshot();
    final actionable = recoverables.actionableRecoverableTotal;
    if (actionable <= 0.009) return null;

    final byPerson = <String, double>{};
    for (final item in [
      ...recoverables.cardBilledItems,
      ...recoverables.bankUpiItems,
      ...recoverables.cashItems,
    ]) {
      byPerson[item.partyName] =
          (byPerson[item.partyName] ?? 0) + item.openAmount;
    }

    String personHint = '';
    if (byPerson.isNotEmpty) {
      final top = byPerson.entries.toList(growable: false)
        ..sort((a, b) => b.value.compareTo(a.value));
      final leader = top.first;
      personHint = ' Top: ${leader.key} ${inr(leader.value)}.';
    }

    return 'Actionable recoverable ${inr(actionable)}.$personHint';
  }

  Future<String?> _splitSettlementReminderLine() async {
    final setting = await (_db.select(
      _db.appSettings,
    )..limit(1)).getSingleOrNull();
    if (setting == null || !setting.settlementReminderEnabled) return null;

    final members = await _db.select(_db.splitMembers).get();
    final currentUserMembers = members
        .where((m) => m.isCurrentUser)
        .toList(growable: false);
    if (currentUserMembers.isEmpty) return null;

    final expenses = await _db.select(_db.splitExpenses).get();
    final shares = await _db.select(_db.splitExpenseShares).get();
    final settlements = await _db.select(_db.splitSettlements).get();

    final netByMember = <int, double>{for (final m in members) m.id: 0};
    final sharesByExpense = <int, List<SplitExpenseShare>>{};
    for (final share in shares) {
      sharesByExpense.putIfAbsent(share.splitExpenseId, () => []).add(share);
    }
    for (final expense in expenses) {
      final expenseShares =
          sharesByExpense[expense.id] ?? const <SplitExpenseShare>[];
      for (final share in expenseShares) {
        netByMember[share.memberId] =
            (netByMember[share.memberId] ?? 0) - share.exactAmount;
        netByMember[expense.paidByMemberId] =
            (netByMember[expense.paidByMemberId] ?? 0) + share.exactAmount;
      }
    }
    for (final settlement in settlements) {
      netByMember[settlement.fromMemberId] =
          (netByMember[settlement.fromMemberId] ?? 0) + settlement.amount;
      netByMember[settlement.toMemberId] =
          (netByMember[settlement.toMemberId] ?? 0) - settlement.amount;
    }

    var receivable = 0.0;
    var payable = 0.0;
    for (final member in currentUserMembers) {
      final net = netByMember[member.id] ?? 0;
      if (net > 0) {
        receivable += net;
      } else if (net < 0) {
        payable += net.abs();
      }
    }

    if (receivable <= 0.009 && payable <= 0.009) return null;
    if (payable > receivable) {
      return 'You owe ${inr(payable)} in split groups.';
    }
    return '${inr(receivable)} pending from split groups.';
  }

  Future<String?> _loanEmiReminderLine({required int days}) async {
    final setting = await (_db.select(
      _db.appSettings,
    )..limit(1)).getSingleOrNull();
    if (setting == null || !setting.reminderEnabled) return null;

    final schedules = await LoanService(_db).getUpcomingEmis(withinDays: days);
    if (schedules.isEmpty) return null;

    final overdue = schedules
        .where((s) => s.daysUntilDue < 0)
        .toList(growable: false);
    if (overdue.isNotEmpty) {
      return '${overdue.first.loan.title} EMI overdue.';
    }

    final dueSoon = schedules
        .where((s) => s.daysUntilDue <= days)
        .toList(growable: false);
    if (dueSoon.isEmpty) return null;

    final total = dueSoon.fold<double>(
      0,
      (sum, s) => sum + (s.loan.emiAmount ?? 0),
    );
    if (days <= 2 && dueSoon.length == 1) {
      return 'EMI of ${inr(dueSoon.first.loan.emiAmount ?? 0)} due soon.';
    }
    return 'Total upcoming EMI this week: ${inr(total)}.';
  }
}
