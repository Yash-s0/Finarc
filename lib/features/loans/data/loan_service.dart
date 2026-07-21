import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../expenses/models/transaction_types.dart';

class LoanType {
  static const personal = 'personal';
  static const home = 'home';
  static const vehicle = 'vehicle';
  static const education = 'education';
  static const creditLine = 'credit_line';
  static const friendFamily = 'friend_family';
  static const other = 'other';

  static const all = [
    personal,
    home,
    vehicle,
    education,
    creditLine,
    friendFamily,
    other,
  ];
}

class LoanLenderType {
  static const company = 'company';
  static const bankNbfc = 'bank_nbfc';
  static const person = 'person';
  static const other = 'other';

  static const all = [company, bankNbfc, person, other];
}

class EmiSchedule {
  const EmiSchedule({
    required this.loan,
    required this.nextDate,
    required this.daysUntilDue,
    required this.status,
    required this.remainingAmount,
  });

  final Loan loan;
  final DateTime nextDate;
  final int daysUntilDue;
  final String status;
  final double remainingAmount;
}

class LoanService {
  LoanService(this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

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
  }) {
    if (!principalAmount.isFinite || principalAmount <= 0) {
      throw ArgumentError('Principal amount must be greater than 0');
    }
    if (!currentOutstanding.isFinite || currentOutstanding < 0) {
      throw ArgumentError('Current outstanding cannot be negative');
    }
    if (interestRate != null && (!interestRate.isFinite || interestRate < 0)) {
      throw ArgumentError('Interest rate cannot be negative');
    }
    if (emiAmount != null && (!emiAmount.isFinite || emiAmount < 0)) {
      throw ArgumentError('EMI amount cannot be negative');
    }
    if (emiDay != null && (emiDay < 1 || emiDay > 31)) {
      throw ArgumentError('EMI day must be between 1 and 31');
    }
    return _db
        .into(_db.loans)
        .insert(
          LoansCompanion.insert(
            title: title,
            lenderName: lenderName,
            lenderType: Value(lenderType),
            loanType: Value(loanType),
            principalAmount: principalAmount,
            currentOutstanding: currentOutstanding,
            interestRate: Value(interestRate),
            emiAmount: Value(emiAmount),
            emiDay: Value(emiDay),
            tenureMonths: Value(tenureMonths),
            startDate: Value(startDate),
            endDate: Value(endDate),
            linkedAccountId: Value(linkedAccountId),
            notes: Value(notes),
            updatedAt: Value(_now()),
          ),
        );
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
  }) {
    if (principalAmount != null &&
        (!principalAmount.isFinite || principalAmount <= 0)) {
      throw ArgumentError('Principal amount must be greater than 0');
    }
    if (currentOutstanding != null &&
        (!currentOutstanding.isFinite || currentOutstanding < 0)) {
      throw ArgumentError('Current outstanding cannot be negative');
    }
    if (interestRate != null && (!interestRate.isFinite || interestRate < 0)) {
      throw ArgumentError('Interest rate cannot be negative');
    }
    if (emiAmount != null && (!emiAmount.isFinite || emiAmount < 0)) {
      throw ArgumentError('EMI amount cannot be negative');
    }
    if (emiDay != null && (emiDay < 1 || emiDay > 31)) {
      throw ArgumentError('EMI day must be between 1 and 31');
    }
    return (_db.update(_db.loans)..where((l) => l.id.equals(id))).write(
      LoansCompanion(
        title: title == null ? const Value.absent() : Value(title),
        lenderName: lenderName == null
            ? const Value.absent()
            : Value(lenderName),
        lenderType: lenderType == null
            ? const Value.absent()
            : Value(lenderType),
        loanType: loanType == null ? const Value.absent() : Value(loanType),
        principalAmount: principalAmount == null
            ? const Value.absent()
            : Value(principalAmount),
        currentOutstanding: currentOutstanding == null
            ? const Value.absent()
            : Value(currentOutstanding),
        interestRate: interestRate == null
            ? const Value.absent()
            : Value(interestRate),
        emiAmount: emiAmount == null ? const Value.absent() : Value(emiAmount),
        emiDay: emiDay == null ? const Value.absent() : Value(emiDay),
        tenureMonths: tenureMonths == null
            ? const Value.absent()
            : Value(tenureMonths),
        startDate: startDate == null ? const Value.absent() : Value(startDate),
        endDate: endDate == null ? const Value.absent() : Value(endDate),
        linkedAccountId: linkedAccountId == null
            ? const Value.absent()
            : Value(linkedAccountId),
        notes: notes == null ? const Value.absent() : Value(notes),
        updatedAt: Value(_now()),
      ),
    );
  }

  Future<void> closeLoan(int id, {DateTime? closedAt}) async {
    await (_db.update(_db.loans)..where((l) => l.id.equals(id))).write(
      LoansCompanion(
        currentOutstanding: const Value(0),
        closedAt: Value(closedAt ?? _now()),
        updatedAt: Value(_now()),
      ),
    );
  }

  Future<List<Loan>> getActiveLoans() {
    return (_db.select(_db.loans)
          ..where((l) => l.closedAt.isNull())
          ..orderBy([(l) => OrderingTerm.desc(l.updatedAt)]))
        .get();
  }

  Future<List<Loan>> getClosedLoans() {
    return (_db.select(_db.loans)
          ..where((l) => l.closedAt.isNotNull())
          ..orderBy([(l) => OrderingTerm.desc(l.closedAt)]))
        .get();
  }

  Future<Loan?> getLoanById(int id) {
    return (_db.select(
      _db.loans,
    )..where((l) => l.id.equals(id))).getSingleOrNull();
  }

  Future<DateTime?> calculateNextEmiDate(Loan loan, {DateTime? date}) async {
    return (await _calculateEmiSchedule(loan, date: date))?.nextDate;
  }

  Future<List<EmiSchedule>> getUpcomingEmis({
    DateTime? from,
    int withinDays = 30,
  }) async {
    final now = _dateOnly(from ?? _now());
    final horizon = now.add(Duration(days: withinDays));
    final loans = await getActiveLoans();

    final results = <EmiSchedule>[];
    for (final loan in loans) {
      final schedule = await _calculateEmiSchedule(loan, date: now);
      if (schedule == null || schedule.nextDate.isAfter(horizon)) continue;
      results.add(schedule);
    }

    results.sort((a, b) => a.nextDate.compareTo(b.nextDate));
    return results;
  }

  Future<List<EmiSchedule>> getOverdueEmis({DateTime? now}) async {
    final date = _dateOnly(now ?? _now());
    final all = await getUpcomingEmis(from: date, withinDays: 3650);
    return all.where((e) => e.status == 'overdue').toList(growable: false);
  }

  Future<int> markEmiPaid({
    required int loanId,
    required double amount,
    required String paymentSourceType,
    int? paymentSourceId,
    DateTime? paymentDate,
    String? notes,
  }) {
    return addLoanPayment(
      loanId: loanId,
      amount: amount,
      paymentDate: paymentDate ?? _now(),
      paymentSourceType: paymentSourceType,
      paymentSourceId: paymentSourceId,
      notes: notes,
    );
  }

  Future<int> addLoanPayment({
    required int loanId,
    required double amount,
    required DateTime paymentDate,
    required String paymentSourceType,
    int? paymentSourceId,
    String? notes,
  }) async {
    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError('Amount must be greater than 0');
    }

    return _db.transaction(() async {
      final loan = await (_db.select(
        _db.loans,
      )..where((l) => l.id.equals(loanId))).getSingle();
      if (loan.closedAt != null || loan.currentOutstanding <= 0) {
        throw ArgumentError('Loan is already closed');
      }
      if (amount > loan.currentOutstanding + _amountTolerance) {
        throw ArgumentError('Amount cannot exceed outstanding balance');
      }

      final usesSalaryDeduction =
          paymentSourceType == PaymentSourceType.salaryDeduction;

      if (!usesSalaryDeduction) {
        final resolvedSourceId = paymentSourceId;
        if (resolvedSourceId == null) {
          throw ArgumentError('Payment source is required');
        }
        await _deductSourceBalance(
          paymentSourceType: paymentSourceType,
          paymentSourceId: resolvedSourceId,
          amount: amount,
        );
      }

      final transactionId = await _db
          .into(_db.transactions)
          .insert(
            TransactionsCompanion.insert(
              type: 'loanEmi',
              amount: amount,
              title: '${loan.title} EMI Payment',
              category: 'Loan EMI',
              notes: Value(notes),
              transactionDate: paymentDate,
              paymentSourceType: paymentSourceType,
              paymentSourceId: paymentSourceId ?? 0,
              transactionImpactType: const Value('loanRepayment'),
            ),
          );

      final paymentId = await _db
          .into(_db.loanPayments)
          .insert(
            LoanPaymentsCompanion.insert(
              loanId: loanId,
              amount: amount,
              paymentDate: paymentDate,
              paymentSourceType: Value(paymentSourceType),
              paymentSourceId: Value(paymentSourceId),
              linkedTransactionId: Value(transactionId),
              notes: Value(notes),
            ),
          );

      final nextOutstanding = (loan.currentOutstanding - amount).clamp(
        0,
        loan.principalAmount,
      );
      await (_db.update(_db.loans)..where((l) => l.id.equals(loanId))).write(
        LoansCompanion(
          currentOutstanding: Value(nextOutstanding.toDouble()),
          closedAt: nextOutstanding <= 0
              ? Value(_dateOnly(paymentDate))
              : const Value.absent(),
          updatedAt: Value(_now()),
        ),
      );

      return paymentId;
    });
  }

  Future<double> getTotalLoanOutstanding() async {
    final loans = await getActiveLoans();
    return loans.fold<double>(0, (sum, loan) => sum + loan.currentOutstanding);
  }

  Future<double> getMonthlyEmiBurden() async {
    final loans = await getActiveLoans();
    return loans.fold<double>(0, (sum, loan) => sum + (loan.emiAmount ?? 0));
  }

  Future<double> calculateDebtRatio({required double totalLiquidAssets}) async {
    final outstanding = await getTotalLoanOutstanding();
    if (totalLiquidAssets <= 0) return outstanding > 0 ? 1 : 0;
    return outstanding / totalLiquidAssets;
  }

  Future<double> calculateNetWorthLiabilities() async {
    return getTotalLoanOutstanding();
  }

  Future<List<LoanPayment>> getLoanPaymentHistory(int loanId) {
    return (_db.select(_db.loanPayments)
          ..where((p) => p.loanId.equals(loanId))
          ..orderBy([(p) => OrderingTerm.desc(p.paymentDate)]))
        .get();
  }

  String emiDueLabel(EmiSchedule schedule) {
    if (schedule.status == 'overdue') {
      return 'overdue';
    }
    if (schedule.status == 'dueToday') {
      return 'dueToday';
    }
    if (schedule.status == 'partial') {
      return 'partial';
    }
    if (schedule.status == 'dueSoon') {
      return 'dueSoon';
    }
    return 'upcoming';
  }

  String _emiStatus(int daysUntilDue, {required bool isPartial}) {
    if (daysUntilDue < 0) return 'overdue';
    if (daysUntilDue == 0) return 'dueToday';
    if (isPartial) return 'partial';
    if (daysUntilDue <= 2) return 'dueSoon';
    return 'upcoming';
  }

  Future<EmiSchedule?> _calculateEmiSchedule(
    Loan loan, {
    DateTime? date,
  }) async {
    final now = _dateOnly(date ?? _now());
    final day = loan.emiDay;
    final emiAmount = loan.emiAmount;
    if (loan.closedAt != null || loan.currentOutstanding <= 0) return null;
    if (day == null || emiAmount == null || emiAmount <= 0) return null;

    final thisMonthDue = _withSafeDay(now.year, now.month, day);
    final thisMonthPaid = await _monthPaidAmount(loan.id, now.year, now.month);
    final thisMonthRemaining = _remainingForEmi(
      emiAmount: emiAmount,
      paidAmount: thisMonthPaid,
      outstanding: loan.currentOutstanding,
    );

    if (!_isZero(thisMonthRemaining)) {
      final days = thisMonthDue.difference(now).inDays;
      return EmiSchedule(
        loan: loan,
        nextDate: thisMonthDue,
        daysUntilDue: days,
        status: _emiStatus(days, isPartial: thisMonthPaid > 0),
        remainingAmount: thisMonthRemaining,
      );
    }

    final nextMonthDate = DateTime(now.year, now.month + 1, 1);
    final nextDue = _withSafeDay(nextMonthDate.year, nextMonthDate.month, day);
    final nextMonthRemaining = emiAmount
        .clamp(0, loan.currentOutstanding)
        .toDouble();
    if (_isZero(nextMonthRemaining)) return null;

    final days = nextDue.difference(now).inDays;
    return EmiSchedule(
      loan: loan,
      nextDate: nextDue,
      daysUntilDue: days,
      status: _emiStatus(days, isPartial: false),
      remainingAmount: nextMonthRemaining,
    );
  }

  Future<double> _monthPaidAmount(int loanId, int year, int month) async {
    final payments =
        await (_db.select(_db.loanPayments)..where(
              (p) =>
                  p.loanId.equals(loanId) &
                  p.paymentDate.year.equals(year) &
                  p.paymentDate.month.equals(month),
            ))
            .get();
    return payments.fold<double>(0, (sum, p) => sum + p.amount);
  }

  double _remainingForEmi({
    required double emiAmount,
    required double paidAmount,
    required double outstanding,
  }) {
    final cappedDue = emiAmount.clamp(0, outstanding).toDouble();
    final remaining = cappedDue - paidAmount;
    return remaining <= _amountTolerance ? 0 : remaining;
  }

  bool _isZero(double value) => value.abs() <= _amountTolerance;

  static const double _amountTolerance = 0.01;

  DateTime _withSafeDay(int year, int month, int day) {
    final safeDay = day.clamp(1, DateTime(year, month + 1, 0).day);
    return DateTime(year, month, safeDay);
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
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
          updatedAt: Value(_now()),
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
        updatedAt: Value(_now()),
      ),
    );
  }
}
