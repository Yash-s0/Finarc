import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

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

class EmiSchedule {
  const EmiSchedule({
    required this.loan,
    required this.nextDate,
    required this.daysUntilDue,
    required this.status,
  });

  final Loan loan;
  final DateTime nextDate;
  final int daysUntilDue;
  final String status;
}

class LoanService {
  LoanService(this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  Future<int> createLoan({
    required String title,
    required String lenderName,
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
    return _db
        .into(_db.loans)
        .insert(
          LoansCompanion.insert(
            title: title,
            lenderName: lenderName,
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
    return (_db.update(_db.loans)..where((l) => l.id.equals(id))).write(
      LoansCompanion(
        title: title == null ? const Value.absent() : Value(title),
        lenderName: lenderName == null
            ? const Value.absent()
            : Value(lenderName),
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

  DateTime? calculateNextEmiDate(Loan loan, {DateTime? date}) {
    final now = _dateOnly(date ?? _now());
    final day = loan.emiDay;
    final emiAmount = loan.emiAmount;
    if (day == null || emiAmount == null || emiAmount <= 0) return null;

    final thisMonthDue = _withSafeDay(now.year, now.month, day);
    return thisMonthDue;
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
      final dueDate = calculateNextEmiDate(loan, date: now);
      if (dueDate == null) continue;
      final isPaidForMonth = await _isMonthPaid(
        loan.id,
        dueDate.year,
        dueDate.month,
      );
      if (isPaidForMonth) continue;

      if (dueDate.isAfter(horizon)) continue;

      final days = dueDate.difference(now).inDays;
      final status = _emiStatus(days);
      results.add(
        EmiSchedule(
          loan: loan,
          nextDate: dueDate,
          daysUntilDue: days,
          status: status,
        ),
      );
    }

    results.sort((a, b) => a.nextDate.compareTo(b.nextDate));
    return results;
  }

  Future<List<EmiSchedule>> getOverdueEmis({DateTime? now}) async {
    final date = _dateOnly(now ?? _now());
    final all = await getUpcomingEmis(from: date, withinDays: 3650);
    return all.where((e) => e.daysUntilDue < 0).toList(growable: false);
  }

  Future<int> markEmiPaid({
    required int loanId,
    required double amount,
    required String paymentSourceType,
    required int paymentSourceId,
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
    required int paymentSourceId,
    String? notes,
  }) async {
    if (amount <= 0) throw ArgumentError('Amount must be greater than 0');

    return _db.transaction(() async {
      final loan = await (_db.select(
        _db.loans,
      )..where((l) => l.id.equals(loanId))).getSingle();

      await _deductSourceBalance(
        paymentSourceType: paymentSourceType,
        paymentSourceId: paymentSourceId,
        amount: amount,
      );

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
              paymentSourceId: paymentSourceId,
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
    if (schedule.daysUntilDue < 0) {
      return 'overdue';
    }
    if (schedule.daysUntilDue == 0) {
      return 'dueToday';
    }
    if (schedule.daysUntilDue <= 2) {
      return 'dueSoon';
    }
    return 'upcoming';
  }

  String _emiStatus(int daysUntilDue) {
    if (daysUntilDue < 0) return 'overdue';
    if (daysUntilDue == 0) return 'dueToday';
    if (daysUntilDue <= 2) return 'dueSoon';
    return 'upcoming';
  }

  Future<bool> _isMonthPaid(int loanId, int year, int month) async {
    final payment =
        await (_db.select(_db.loanPayments)
              ..where(
                (p) =>
                    p.loanId.equals(loanId) &
                    p.paymentDate.year.equals(year) &
                    p.paymentDate.month.equals(month),
              )
              ..limit(1))
            .getSingleOrNull();
    return payment != null;
  }

  DateTime _withSafeDay(int year, int month, int day) {
    final safeDay = day.clamp(1, 28);
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
