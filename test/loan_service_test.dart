import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/features/expenses/models/transaction_types.dart';
import 'package:finarc/features/loans/data/loan_service.dart';

void main() {
  late AppDatabase db;
  late LoanService service;
  late int bankId;
  late int cashId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    service = LoanService(db, now: () => DateTime(2026, 6, 20, 10));

    bankId = await db
        .into(db.bankAccounts)
        .insert(
          BankAccountsCompanion.insert(
            bankName: 'HDFC',
            accountName: 'Main',
            accountType: 'savings',
            currentBalance: const Value(100000),
          ),
        );

    cashId = await db
        .into(db.cashWallets)
        .insert(
          CashWalletsCompanion.insert(
            walletName: 'Cash',
            currentBalance: const Value(10000),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> createLoan({
    double outstanding = 50000,
    double principal = 80000,
    double emi = 8500,
    int emiDay = 10,
    String? lenderType,
  }) {
    return service.createLoan(
      title: 'Vehicle Loan',
      lenderName: 'HDFC',
      lenderType: lenderType,
      loanType: LoanType.vehicle,
      principalAmount: principal,
      currentOutstanding: outstanding,
      emiAmount: emi,
      emiDay: emiDay,
      startDate: DateTime(2025, 1, 1),
    );
  }

  test('lender type is stored on the loan record', () async {
    final id = await createLoan(lenderType: LoanLenderType.company);
    final loan = await service.getLoanById(id);

    expect(loan?.lenderType, LoanLenderType.company);
  });

  test('next EMI stays in current month before due date', () async {
    final id = await createLoan(emiDay: 5);
    final loan = await service.getLoanById(id);
    final next = await service.calculateNextEmiDate(
      loan!,
      date: DateTime(2026, 6, 3),
    );

    expect(next, DateTime(2026, 6, 5));
  });

  test('EMI due today stays on the same day', () async {
    final id = await createLoan(emiDay: 5);
    final loan = await service.getLoanById(id);
    final next = await service.calculateNextEmiDate(
      loan!,
      date: DateTime(2026, 6, 5),
    );

    expect(next, DateTime(2026, 6, 5));
  });

  test('current-month unpaid past EMI shows overdue', () async {
    await createLoan(emiDay: 5);

    final overdue = await service.getOverdueEmis(now: DateTime(2026, 6, 20));

    expect(overdue, hasLength(1));
    expect(overdue.first.status, 'overdue');
    expect(overdue.first.nextDate, DateTime(2026, 6, 5));
    expect(overdue.first.remainingAmount, 8500);
  });

  test('paid EMI does not show overdue for that month', () async {
    final loanId = await createLoan(emiDay: 5);
    await service.markEmiPaid(
      loanId: loanId,
      amount: 8500,
      paymentSourceType: PaymentSourceType.bank,
      paymentSourceId: bankId,
      paymentDate: DateTime(2026, 6, 5),
    );

    final overdue = await service.getOverdueEmis(now: DateTime(2026, 6, 20));

    expect(overdue.where((e) => e.loan.id == loanId), isEmpty);
  });

  test('current-month paid EMI projects next month', () async {
    final loanId = await createLoan(emiDay: 5);
    await service.markEmiPaid(
      loanId: loanId,
      amount: 8500,
      paymentSourceType: PaymentSourceType.bank,
      paymentSourceId: bankId,
      paymentDate: DateTime(2026, 6, 5),
    );

    final upcoming = await service.getUpcomingEmis(
      from: DateTime(2026, 6, 20),
      withinDays: 30,
    );
    final schedule = upcoming.singleWhere((e) => e.loan.id == loanId);

    expect(schedule.nextDate, DateTime(2026, 7, 5));
    expect(schedule.status, 'upcoming');
  });

  test('partial EMI payment does not mark month as fully paid', () async {
    final loanId = await createLoan(emi: 10000, emiDay: 10);
    await service.addLoanPayment(
      loanId: loanId,
      amount: 4000,
      paymentDate: DateTime(2026, 6, 5),
      paymentSourceType: PaymentSourceType.bank,
      paymentSourceId: bankId,
    );

    final upcoming = await service.getUpcomingEmis(
      from: DateTime(2026, 6, 8),
      withinDays: 30,
    );
    final schedule = upcoming.singleWhere((e) => e.loan.id == loanId);

    expect(schedule.nextDate, DateTime(2026, 6, 10));
    expect(schedule.remainingAmount, 6000);
    expect(schedule.status, anyOf('partial', 'dueSoon'));
  });

  test('multiple partial payments can fully satisfy EMI', () async {
    final loanId = await createLoan(emi: 10000, emiDay: 10);
    await service.addLoanPayment(
      loanId: loanId,
      amount: 4000,
      paymentDate: DateTime(2026, 6, 5),
      paymentSourceType: PaymentSourceType.bank,
      paymentSourceId: bankId,
    );
    await service.addLoanPayment(
      loanId: loanId,
      amount: 6000,
      paymentDate: DateTime(2026, 6, 10),
      paymentSourceType: PaymentSourceType.bank,
      paymentSourceId: bankId,
    );

    final upcoming = await service.getUpcomingEmis(
      from: DateTime(2026, 6, 20),
      withinDays: 30,
    );
    final schedule = upcoming.singleWhere((e) => e.loan.id == loanId);

    expect(schedule.nextDate, DateTime(2026, 7, 10));
    expect(schedule.remainingAmount, 10000);
  });

  test('EMI day clamps safely for short months', () async {
    final id = await createLoan(emiDay: 31);
    final loan = await service.getLoanById(id);
    final next = await service.calculateNextEmiDate(
      loan!,
      date: DateTime(2026, 6, 1),
    );

    expect(next, DateTime(2026, 6, 30));
  });

  test('closed loan has no upcoming EMI', () async {
    final loanId = await createLoan(emiDay: 5);
    await service.closeLoan(loanId);

    final upcoming = await service.getUpcomingEmis(
      from: DateTime(2026, 6, 20),
      withinDays: 60,
    );

    expect(upcoming.where((e) => e.loan.id == loanId), isEmpty);
  });

  test(
    'company deduction reduces outstanding but does not reduce bank or cash',
    () async {
      final loanId = await createLoan(
        outstanding: 30000,
        lenderType: LoanLenderType.company,
      );

      await service.markEmiPaid(
        loanId: loanId,
        amount: 5000,
        paymentSourceType: PaymentSourceType.salaryDeduction,
        paymentDate: DateTime(2026, 6, 5),
        notes: 'Salary deduction',
      );

      final loan = await service.getLoanById(loanId);
      final bank = await (db.select(
        db.bankAccounts,
      )..where((b) => b.id.equals(bankId))).getSingle();
      final cash = await (db.select(
        db.cashWallets,
      )..where((w) => w.id.equals(cashId))).getSingle();

      expect(loan?.currentOutstanding, 25000);
      expect(bank.currentBalance, 100000);
      expect(cash.currentBalance, 10000);
    },
  );

  test(
    'company deduction creates loan payment history and linked transaction',
    () async {
      final loanId = await createLoan(lenderType: LoanLenderType.company);

      await service.markEmiPaid(
        loanId: loanId,
        amount: 5000,
        paymentSourceType: PaymentSourceType.salaryDeduction,
        paymentDate: DateTime(2026, 6, 5),
        notes: 'Salary deduction',
      );

      final payments = await service.getLoanPaymentHistory(loanId);
      final txn = await (db.select(
        db.transactions,
      )..where((t) => t.type.equals('loanEmi'))).getSingle();

      expect(payments, hasLength(1));
      expect(
        payments.first.paymentSourceType,
        PaymentSourceType.salaryDeduction,
      );
    expect(payments.first.paymentSourceId, null);
      expect(payments.first.linkedTransactionId, txn.id);
      expect(txn.paymentSourceType, PaymentSourceType.salaryDeduction);
      expect(txn.paymentSourceId, 0);
      expect(txn.transactionImpactType, 'loanRepayment');
    },
  );

  test('EMI payment reduces outstanding and creates transaction', () async {
    final loanId = await createLoan(outstanding: 30000, emi: 8500);

    await service.markEmiPaid(
      loanId: loanId,
      amount: 8500,
      paymentSourceType: PaymentSourceType.bank,
      paymentSourceId: bankId,
      paymentDate: DateTime(2026, 6, 25),
      notes: 'June EMI',
    );

    final loan = await service.getLoanById(loanId);
    final payments = await service.getLoanPaymentHistory(loanId);
    final txn = await (db.select(
      db.transactions,
    )..where((t) => t.type.equals('loanEmi'))).getSingle();
    final bank = await (db.select(
      db.bankAccounts,
    )..where((b) => b.id.equals(bankId))).getSingle();

    expect(loan!.currentOutstanding, 21500);
    expect(payments.length, 1);
    expect(payments.first.linkedTransactionId, txn.id);
    expect(bank.currentBalance, 91500);
  });

  test('closed loans excluded from active totals', () async {
    final openId = await createLoan(outstanding: 20000);
    final closedId = await createLoan(outstanding: 15000, emiDay: 20);

    await service.closeLoan(closedId);

    final active = await service.getActiveLoans();
    final closed = await service.getClosedLoans();
    final totalOutstanding = await service.getTotalLoanOutstanding();

    expect(active.map((l) => l.id), contains(openId));
    expect(active.map((l) => l.id), isNot(contains(closedId)));
    expect(closed.map((l) => l.id), contains(closedId));
    expect(totalOutstanding, 20000);
  });

  test('monthly EMI burden sums active EMIs only', () async {
    await createLoan(emi: 5000);
    final secondId = await createLoan(emi: 3500, emiDay: 18);
    await service.closeLoan(secondId);

    final burden = await service.getMonthlyEmiBurden();
    expect(burden, 5000);
  });

  test('debt ratio calculates against liquid assets', () async {
    await createLoan(outstanding: 25000);

    final ratio = await service.calculateDebtRatio(totalLiquidAssets: 100000);
    expect(ratio, closeTo(0.25, 0.0001));
  });

  test('loan create validation rejects invalid EMI day', () async {
    expect(
      () => service.createLoan(
        title: 'Bad EMI Day',
        lenderName: 'HDFC',
        loanType: LoanType.personal,
        principalAmount: 50000,
        currentOutstanding: 40000,
        emiDay: 40,
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('loan create validation rejects negative outstanding', () async {
    expect(
      () => service.createLoan(
        title: 'Bad Outstanding',
        lenderName: 'HDFC',
        loanType: LoanType.personal,
        principalAmount: 50000,
        currentOutstanding: -1,
      ),
      throwsA(isA<ArgumentError>()),
    );
  });
}
