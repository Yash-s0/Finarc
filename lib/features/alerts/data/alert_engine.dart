import '../../../core/database/app_database.dart';
import '../../../core/logging/app_log_service.dart';
import '../../../core/utils/formatters.dart';
import '../../cards/data/billing_service.dart';
import '../../expenses/models/transaction_types.dart';
import '../../loans/data/loan_service.dart';
import '../../pending/notifications/notification_local_notifier.dart';
import '../../split/data/split_service.dart';
import 'alert_service.dart';
import 'alert_types.dart';

class AlertEngine {
  AlertEngine({
    required AppDatabase database,
    required AlertService alertService,
    required this._notifier,
    required BillingService billingService,
    required LoanService loanService,
    required SplitService splitService,
  }) : _db = database,
       _alerts = alertService,
       _billing = billingService,
       _loans = loanService,
       _split = splitService;

  final AppDatabase _db;
  final AlertService _alerts;
  final NotificationLocalNotifier _notifier;
  final BillingService _billing;
  final LoanService _loans;
  final SplitService _split;

  Future<void> onPendingDetected({
    required int pendingId,
    required String title,
    required String body,
  }) async {
    final alert = await _alerts.createAlert(
      CreateAlertInput(
        alertType: AlertType.pendingTransaction,
        title: title,
        body: body,
        priority: AlertPriority.info,
        actionRoute: '/pending?openPendingId=$pendingId',
        payload: {'pendingId': pendingId},
        dedupeKey: 'pending_detected_$pendingId',
      ),
      dedupeWindow: const Duration(days: 7),
    );
    if (alert == null) return;
  }

  Future<void> evaluateAfterTransaction(Transaction transaction) async {
    final settings = await _currentSettings();
    if (settings == null || !settings.smartAlertsEnabled) return;

    await _evaluateLargeExpense(transaction, settings);
    await _evaluateLowBalance(settings);
    await _evaluateUnusualSpending(settings);
    await _evaluateRecurringMerchant(settings);
  }

  Future<void> evaluateDueAlerts() async {
    final settings = await _currentSettings();
    if (settings == null || !settings.smartAlertsEnabled) return;

    await _evaluateCardDueAlerts();
    await _evaluateEmiDueAlerts();
  }

  Future<void> evaluateSplitAlerts() async {
    final settings = await _currentSettings();
    if (settings == null || !settings.smartAlertsEnabled) return;
    if (!settings.settlementReminderEnabled) return;

    final receivable = await _split.getCurrentUserReceivables();
    final payable = await _split.getCurrentUserPayables();
    if (receivable <= 0 && payable <= 0) return;

    String title;
    String body;
    AlertPriority priority;
    String dedupeKey;

    if (receivable >= payable) {
      title = 'Split settlement reminder';
      body = 'You are owed ${inr(receivable)} across split groups.';
      priority = AlertPriority.warning;
      dedupeKey =
          'split_receivable_${DateTime.now().year}_${DateTime.now().month}';
    } else {
      title = 'Split payable reminder';
      body = 'You owe ${inr(payable)} across split groups.';
      priority = AlertPriority.warning;
      dedupeKey =
          'split_payable_${DateTime.now().year}_${DateTime.now().month}';
    }

    final alert = await _alerts.createAlert(
      CreateAlertInput(
        alertType: AlertType.splitSettlement,
        title: title,
        body: body,
        priority: priority,
        actionRoute: '/split',
        dedupeKey: dedupeKey,
      ),
      dedupeWindow: const Duration(hours: 12),
    );
    if (alert != null) {
      await _showLocalAlertIfAllowed(alert);
    }
  }

  Future<void> evaluateSummaryAlerts() async {
    final settings = await _currentSettings();
    if (settings == null || !settings.smartAlertsEnabled) return;

    final now = DateTime.now();
    if (settings.weeklySummaryAlertsEnabled && now.weekday == DateTime.sunday) {
      final spend = await _spendBetween(
        now.subtract(const Duration(days: 6)),
        now,
      );
      final alert = await _alerts.createAlert(
        CreateAlertInput(
          alertType: AlertType.weeklySummary,
          title: 'Weekly summary',
          body: 'Spent ${inr(spend)} this week.',
          priority: AlertPriority.info,
          actionRoute: '/analytics',
          dedupeKey: 'weekly_summary_${now.year}_${_weekOfYear(now)}',
        ),
        dedupeWindow: const Duration(days: 7),
      );
      if (alert != null) await _showLocalAlertIfAllowed(alert);
    }

    if (settings.monthlySummaryAlertsEnabled && now.day >= 28) {
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 0);
      final spend = await _spendBetween(start, end);
      final topCategory = await _topCategoryBetween(start, end);

      final alert = await _alerts.createAlert(
        CreateAlertInput(
          alertType: AlertType.monthlySummary,
          title: 'Monthly summary',
          body:
              'Spent ${inr(spend)} this month. Top category: ${topCategory ?? 'N/A'}.',
          priority: AlertPriority.info,
          actionRoute: '/analytics',
          dedupeKey: 'monthly_summary_${now.year}_${now.month}',
        ),
        dedupeWindow: const Duration(days: 31),
      );
      if (alert != null) await _showLocalAlertIfAllowed(alert);
    }
  }

  Future<void> _evaluateLargeExpense(
    Transaction transaction,
    AppSetting settings,
  ) async {
    if (!settings.largeExpenseAlertsEnabled) return;
    if (transaction.type == TransactionType.transfer ||
        transaction.type == TransactionType.cardPayment ||
        transaction.type == TransactionType.income ||
        transaction.type == TransactionType.refund) {
      return;
    }

    final threshold = settings.largeExpenseThreshold;
    if (transaction.amount < threshold) return;

    final alert = await _alerts.createAlert(
      CreateAlertInput(
        alertType: AlertType.largeExpense,
        title: 'Large expense detected',
        body: '${inr(transaction.amount)} at ${transaction.title}',
        priority: transaction.amount >= threshold * 2
            ? AlertPriority.critical
            : AlertPriority.warning,
        actionRoute: '/expenses',
        dedupeKey: 'large_expense_${transaction.id}',
      ),
      dedupeWindow: const Duration(days: 3),
    );
    if (alert != null) await _showLocalAlertIfAllowed(alert);
  }

  Future<void> _evaluateLowBalance(AppSetting settings) async {
    if (!settings.lowBalanceAlertsEnabled) return;

    final threshold = settings.lowBalanceThreshold;
    final banks = await _db.select(_db.bankAccounts).get();
    final wallets = await _db.select(_db.cashWallets).get();

    for (final bank in banks) {
      if (bank.currentBalance > threshold) continue;
      final priority = bank.currentBalance <= threshold * 0.5
          ? AlertPriority.critical
          : AlertPriority.warning;
      final alert = await _alerts.createAlert(
        CreateAlertInput(
          alertType: AlertType.lowBalance,
          title: 'Low balance alert',
          body: '${bank.accountName} balance below ${inr(threshold)}.',
          priority: priority,
          actionRoute: '/accounts/detail/bank/${bank.id}',
          dedupeKey: 'low_balance_bank_${bank.id}',
        ),
        dedupeWindow: const Duration(hours: 12),
      );
      if (alert != null) await _showLocalAlertIfAllowed(alert);
    }

    for (final wallet in wallets) {
      if (wallet.currentBalance > threshold) continue;
      final priority = wallet.currentBalance <= threshold * 0.5
          ? AlertPriority.critical
          : AlertPriority.warning;
      final alert = await _alerts.createAlert(
        CreateAlertInput(
          alertType: AlertType.lowBalance,
          title: 'Low cash wallet balance',
          body: '${wallet.walletName} below ${inr(threshold)}.',
          priority: priority,
          actionRoute: '/accounts/detail/cash/${wallet.id}',
          dedupeKey: 'low_balance_cash_${wallet.id}',
        ),
        dedupeWindow: const Duration(hours: 12),
      );
      if (alert != null) await _showLocalAlertIfAllowed(alert);
    }
  }

  Future<void> _evaluateUnusualSpending(AppSetting settings) async {
    if (!settings.unusualSpendingAlertsEnabled) return;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final txns = await _db.select(_db.transactions).get();
    final todaySpending = txns
        .where(
          (t) =>
              !t.transactionDate.isBefore(todayStart) &&
              t.transactionDate.isBefore(todayEnd) &&
              _isLifestyleSpend(t),
        )
        .fold<double>(0, (sum, t) => sum + _netSpend(t));

    final dailyTotals = <String, double>{};
    final baselineStart = todayStart.subtract(const Duration(days: 7));
    for (final t in txns) {
      if (t.transactionDate.isBefore(baselineStart) ||
          !t.transactionDate.isBefore(todayStart)) {
        continue;
      }
      if (!_isLifestyleSpend(t)) continue;
      final key =
          '${t.transactionDate.year}-${t.transactionDate.month}-${t.transactionDate.day}';
      dailyTotals[key] = (dailyTotals[key] ?? 0) + _netSpend(t);
    }
    if (dailyTotals.isEmpty) return;

    final avg =
        dailyTotals.values.fold<double>(0, (s, v) => s + v) /
        dailyTotals.length;
    final multiplier = settings.unusualSpendingMultiplier;
    if (avg <= 0 || todaySpending <= avg * multiplier) return;

    final alert = await _alerts.createAlert(
      CreateAlertInput(
        alertType: AlertType.unusualSpending,
        title: 'Unusual spending today',
        body:
            'Today spend ${inr(todaySpending)} is ${(todaySpending / avg).toStringAsFixed(1)}x your recent average.',
        priority: AlertPriority.warning,
        actionRoute: '/analytics',
        dedupeKey: 'unusual_spending_${now.year}_${now.month}_${now.day}',
      ),
      dedupeWindow: const Duration(hours: 24),
    );
    if (alert != null) await _showLocalAlertIfAllowed(alert);
  }

  Future<void> _evaluateRecurringMerchant(AppSetting settings) async {
    if (!settings.recurringMerchantAlertsEnabled) return;

    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 30));

    final txns = await _db.select(_db.transactions).get();
    final merchantCount = <String, int>{};

    for (final t in txns) {
      if (t.transactionDate.isBefore(start) || t.transactionDate.isAfter(now)) {
        continue;
      }
      if (!_isLifestyleSpend(t)) continue;
      merchantCount[t.title] = (merchantCount[t.title] ?? 0) + 1;
    }

    if (merchantCount.isEmpty) return;
    final top = merchantCount.entries.toList(growable: false)
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEntry = top.first;
    if (topEntry.value < 6) return;

    final alert = await _alerts.createAlert(
      CreateAlertInput(
        alertType: AlertType.recurringMerchant,
        title: 'Recurring merchant alert',
        body:
            'You spent at ${topEntry.key} ${topEntry.value} times in the last 30 days.',
        priority: AlertPriority.info,
        actionRoute: '/analytics',
        dedupeKey: 'recurring_${topEntry.key.toLowerCase()}',
      ),
      dedupeWindow: const Duration(days: 14),
    );
    if (alert != null) await _showLocalAlertIfAllowed(alert);
  }

  Future<void> _evaluateCardDueAlerts() async {
    final bills = await _db.select(_db.cardBills).get();
    final cards = await _db.select(_db.creditCards).get();
    final now = DateTime.now();

    for (final bill in bills) {
      final card = cards.where((c) => c.id == bill.cardId).firstOrNull;
      if (card == null) continue;
      final status = _billing.getDueStatus(bill);
      if (status == 'paid') continue;

      final dueDateOnly = DateTime(
        bill.dueDate.year,
        bill.dueDate.month,
        bill.dueDate.day,
      );
      final today = DateTime(now.year, now.month, now.day);
      final days = dueDateOnly.difference(today).inDays;
      if (days > 2 && status != 'overdue') continue;

      final priority = status == 'overdue'
          ? AlertPriority.critical
          : AlertPriority.warning;
      final pendingAmount = (bill.billedAmount - bill.paidAmount)
          .clamp(0, bill.billedAmount)
          .toDouble();
      final title = status == 'overdue'
          ? '${card.bankName} bill overdue'
          : '${card.bankName} bill due soon';
      final body = status == 'overdue'
          ? '${inr(pendingAmount)} overdue for payment.'
          : '${inr(pendingAmount)} due in ${days <= 0 ? 'today' : '$days day(s)'}.';

      final alert = await _alerts.createAlert(
        CreateAlertInput(
          alertType: AlertType.cardDue,
          title: title,
          body: body,
          priority: priority,
          actionRoute: '/cards/${card.id}/bills/${bill.id}',
          dedupeKey: 'card_due_${bill.id}_$status',
        ),
        dedupeWindow: const Duration(hours: 12),
      );
      if (alert != null) await _showLocalAlertIfAllowed(alert);
    }
  }

  Future<void> _evaluateEmiDueAlerts() async {
    final schedules = await _loans.getUpcomingEmis(withinDays: 3);
    for (final schedule in schedules) {
      final due = schedule.daysUntilDue;
      if (due > 2) continue;
      final priority = due < 0 ? AlertPriority.critical : AlertPriority.warning;
      final amount = inr(schedule.loan.emiAmount ?? 0);
      final title = due < 0 ? 'EMI overdue' : 'EMI due soon';
      final body = due < 0
          ? '${schedule.loan.title} EMI of $amount is overdue.'
          : (due == 0
                ? '${schedule.loan.title} EMI of $amount is due today.'
                : '${schedule.loan.title} EMI of $amount is due in $due day(s).');

      final alert = await _alerts.createAlert(
        CreateAlertInput(
          alertType: AlertType.emiDue,
          title: title,
          body: body,
          priority: priority,
          actionRoute: '/loans/${schedule.loan.id}',
          dedupeKey:
              'emi_due_${schedule.loan.id}_${schedule.nextDate.toIso8601String()}',
        ),
        dedupeWindow: const Duration(hours: 12),
      );
      if (alert != null) await _showLocalAlertIfAllowed(alert);
    }
  }

  Future<void> _showLocalAlertIfAllowed(Alert alert) async {
    final settings = await _currentSettings();
    if (settings == null) return;
    await globalAppLogService.log(
      category: 'alert-engine',
      message: 'alert-created',
      meta: <String, Object?>{
        'type': alert.alertType,
        'priority': alert.priority,
        'route': alert.actionRoute ?? '/alerts',
      },
    );
    if (!_isWithinQuietHours(DateTime.now(), settings)) {
      await _notifier.showAlert(
        title: alert.title,
        body: alert.body,
        route: alert.actionRoute ?? '/alerts',
        channelType: _channelTypeForAlert(alert.alertType),
      );
      await globalAppLogService.log(
        category: 'alert-engine',
        message: 'alert-notified',
        meta: <String, Object?>{'type': alert.alertType},
      );
    }
  }

  String _channelTypeForAlert(String alertType) {
    switch (alertType) {
      case AlertType.pendingTransaction:
      case AlertType.largeExpense:
      case AlertType.unusualSpending:
      case AlertType.recurringMerchant:
        return 'transactions';
      case AlertType.cardDue:
        return 'bills';
      case AlertType.emiDue:
        return 'emis';
      case AlertType.splitSettlement:
        return 'splits';
      case AlertType.weeklySummary:
      case AlertType.monthlySummary:
        return 'summaries';
      case AlertType.lowBalance:
      case AlertType.reminder:
      case AlertType.info:
      default:
        return 'alerts';
    }
  }

  bool _isWithinQuietHours(DateTime now, AppSetting settings) {
    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes =
        settings.quietHoursStartHour * 60 + settings.quietHoursStartMinute;
    final endMinutes =
        settings.quietHoursEndHour * 60 + settings.quietHoursEndMinute;

    if (startMinutes == endMinutes) return false;

    if (startMinutes < endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    }
    return currentMinutes >= startMinutes || currentMinutes < endMinutes;
  }

  Future<AppSetting?> _currentSettings() {
    return (_db.select(_db.appSettings)..limit(1)).getSingleOrNull();
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

  double _netSpend(Transaction t) {
    return ((t.personalShareAmount ?? t.amount) - t.cashbackAmount)
        .clamp(0, double.infinity)
        .toDouble();
  }

  Future<double> _spendBetween(DateTime start, DateTime end) async {
    final txns = await _db.select(_db.transactions).get();
    final startTime = DateTime(start.year, start.month, start.day);
    final endTime = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return txns
        .where(
          (t) =>
              !t.transactionDate.isBefore(startTime) &&
              !t.transactionDate.isAfter(endTime) &&
              _isLifestyleSpend(t),
        )
        .fold<double>(0, (sum, t) => sum + _netSpend(t));
  }

  Future<String?> _topCategoryBetween(DateTime start, DateTime end) async {
    final txns = await _db.select(_db.transactions).get();
    final startTime = DateTime(start.year, start.month, start.day);
    final endTime = DateTime(end.year, end.month, end.day, 23, 59, 59);
    final category = <String, double>{};

    for (final t in txns) {
      if (t.transactionDate.isBefore(startTime) ||
          t.transactionDate.isAfter(endTime)) {
        continue;
      }
      if (!_isLifestyleSpend(t)) continue;
      category[t.category] = (category[t.category] ?? 0) + _netSpend(t);
    }
    if (category.isEmpty) return null;
    final sorted = category.entries.toList(growable: false)
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  int _weekOfYear(DateTime date) {
    final firstDay = DateTime(date.year, 1, 1);
    final diff = date.difference(firstDay).inDays;
    return ((diff + firstDay.weekday) / 7).floor() + 1;
  }
}

extension _FirstOrNullExt<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
