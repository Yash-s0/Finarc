import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../alerts/data/alerts_providers.dart';
import '../../dashboard/data/dashboard_providers.dart';
import '../../expenses/data/expenses_providers.dart';
import '../../pending/notifications/notification_runtime_providers.dart';
import 'loan_service.dart';

final loanServiceProvider = Provider<LoanService>((ref) {
  return LoanService(ref.read(appDatabaseProvider));
});

class LoansDashboardSnapshot {
  const LoansDashboardSnapshot({
    required this.totalOutstanding,
    required this.monthlyEmiBurden,
    required this.debtRatio,
    required this.activeLoans,
    required this.closedLoans,
    required this.upcomingEmis,
    required this.recentPayments,
  });

  final double totalOutstanding;
  final double monthlyEmiBurden;
  final double debtRatio;
  final List<Loan> activeLoans;
  final List<Loan> closedLoans;
  final List<EmiSchedule> upcomingEmis;
  final List<LoanPayment> recentPayments;
}

final loansDashboardProvider = FutureProvider<LoansDashboardSnapshot>((
  ref,
) async {
  await ref.watch(seedProvider.future);
  final db = ref.read(appDatabaseProvider);
  final service = ref.read(loanServiceProvider);

  final active = await service.getActiveLoans();
  final closed = await service.getClosedLoans();
  final upcoming = await service.getUpcomingEmis(withinDays: 14);
  final payments =
      await (db.select(db.loanPayments)
            ..orderBy([(p) => OrderingTerm.desc(p.paymentDate)])
            ..limit(10))
          .get();

  final totalOutstanding = await service.getTotalLoanOutstanding();
  final monthlyEmiBurden = await service.getMonthlyEmiBurden();
  final bankTotal = await db
      .select(db.bankAccounts)
      .get()
      .then(
        (rows) =>
            rows.fold<double>(0, (sum, item) => sum + item.currentBalance),
      );
  final cashTotal = await db
      .select(db.cashWallets)
      .get()
      .then(
        (rows) =>
            rows.fold<double>(0, (sum, item) => sum + item.currentBalance),
      );
  final debtRatio = await service.calculateDebtRatio(
    totalLiquidAssets: bankTotal + cashTotal,
  );

  return LoansDashboardSnapshot(
    totalOutstanding: totalOutstanding,
    monthlyEmiBurden: monthlyEmiBurden,
    debtRatio: debtRatio,
    activeLoans: active,
    closedLoans: closed,
    upcomingEmis: upcoming,
    recentPayments: payments,
  );
});

class LoanDetailSnapshot {
  const LoanDetailSnapshot({
    required this.loan,
    required this.nextEmi,
    required this.overdueEmi,
    required this.payments,
    required this.relatedTransactions,
  });

  final Loan loan;
  final EmiSchedule? nextEmi;
  final EmiSchedule? overdueEmi;
  final List<LoanPayment> payments;
  final List<Transaction> relatedTransactions;
}

final loanDetailProvider = FutureProvider.family<LoanDetailSnapshot, int>((
  ref,
  loanId,
) async {
  await ref.watch(seedProvider.future);
  final db = ref.read(appDatabaseProvider);
  final service = ref.read(loanServiceProvider);

  final loan = await service.getLoanById(loanId);
  if (loan == null) {
    throw StateError('Loan not found');
  }

  final payments = await service.getLoanPaymentHistory(loanId);
  final linkedIds = payments
      .map((p) => p.linkedTransactionId)
      .whereType<int>()
      .toList(growable: false);

  final relatedTransactions = linkedIds.isEmpty
      ? const <Transaction>[]
      : await (db.select(db.transactions)
              ..where((t) => t.id.isIn(linkedIds))
              ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
            .get();

  final upcoming = await service.getUpcomingEmis(withinDays: 3650);
  final currentEmi = upcoming
      .where((e) => e.loan.id == loanId)
      .toList(growable: false);
  EmiSchedule? nextEmi;
  EmiSchedule? overdue;
  for (final schedule in currentEmi) {
    if (schedule.status == 'overdue') {
      overdue = schedule;
      break;
    }
  }
  if (overdue == null && currentEmi.isNotEmpty) {
    nextEmi = currentEmi.first;
  }

  return LoanDetailSnapshot(
    loan: loan,
    nextEmi: nextEmi,
    overdueEmi: overdue,
    payments: payments,
    relatedTransactions: relatedTransactions,
  );
});

final loanActionsProvider = Provider((ref) {
  final service = ref.read(loanServiceProvider);
  final reminderService = ref.read(reminderServiceProvider);

  Future<int> createLoan({
    required String title,
    required String lenderName,
    String? lenderType,
    required String loanType,
    required double principalAmount,
    required double currentOutstanding,
    double? interestRate,
    double? emiAmount,
    int? emiDay,
    int? tenureMonths,
    DateTime? startDate,
    DateTime? endDate,
    int? linkedAccountId,
    String? notes,
  }) async {
    final id = await service.createLoan(
      title: title,
      lenderName: lenderName,
      lenderType: lenderType,
      loanType: loanType,
      principalAmount: principalAmount,
      currentOutstanding: currentOutstanding,
      interestRate: interestRate,
      emiAmount: emiAmount,
      emiDay: emiDay,
      tenureMonths: tenureMonths,
      startDate: startDate,
      endDate: endDate,
      linkedAccountId: linkedAccountId,
      notes: notes,
    );
    await reminderService.syncLoanEmiReminders(enabled: true);
    await ref.read(alertEvaluationActionsProvider).evaluateAll();
    ref.invalidate(loansDashboardProvider);
    ref.invalidate(dashboardProvider);
    return id;
  }

  Future<void> updateLoan(
    int id, {
    String? title,
    String? lenderName,
    String? lenderType,
    String? loanType,
    double? principalAmount,
    double? currentOutstanding,
    double? interestRate,
    double? emiAmount,
    int? emiDay,
    int? tenureMonths,
    DateTime? startDate,
    DateTime? endDate,
    int? linkedAccountId,
    String? notes,
  }) async {
    await service.updateLoan(
      id,
      title: title,
      lenderName: lenderName,
      lenderType: lenderType,
      loanType: loanType,
      principalAmount: principalAmount,
      currentOutstanding: currentOutstanding,
      interestRate: interestRate,
      emiAmount: emiAmount,
      emiDay: emiDay,
      tenureMonths: tenureMonths,
      startDate: startDate,
      endDate: endDate,
      linkedAccountId: linkedAccountId,
      notes: notes,
    );
    await reminderService.syncLoanEmiReminders(enabled: true);
    await ref.read(alertEvaluationActionsProvider).evaluateAll();
    ref.invalidate(loansDashboardProvider);
    ref.invalidate(loanDetailProvider(id));
    ref.invalidate(dashboardProvider);
  }

  Future<void> closeLoan(int id) async {
    await service.closeLoan(id);
    await reminderService.syncLoanEmiReminders(enabled: true);
    await ref.read(alertEvaluationActionsProvider).evaluateAll();
    ref.invalidate(loansDashboardProvider);
    ref.invalidate(loanDetailProvider(id));
    ref.invalidate(dashboardProvider);
  }

  Future<int> markEmiPaid({
    required int loanId,
    required double amount,
    required String paymentSourceType,
    int? paymentSourceId,
    DateTime? paymentDate,
    String? notes,
  }) async {
    final paymentId = await service.markEmiPaid(
      loanId: loanId,
      amount: amount,
      paymentSourceType: paymentSourceType,
      paymentSourceId: paymentSourceId,
      paymentDate: paymentDate,
      notes: notes,
    );
    await reminderService.syncLoanEmiReminders(enabled: true);
    await ref.read(alertEvaluationActionsProvider).evaluateAll();
    ref.invalidate(loansDashboardProvider);
    ref.invalidate(loanDetailProvider(loanId));
    ref.invalidate(dashboardProvider);
    ref.invalidate(expenseListProvider);
    return paymentId;
  }

  return (
    createLoan: createLoan,
    updateLoan: updateLoan,
    closeLoan: closeLoan,
    markEmiPaid: markEmiPaid,
  );
});
