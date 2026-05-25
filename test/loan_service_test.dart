import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/features/loans/data/loan_service.dart';

void main() {
  late AppDatabase db;
  late LoanService service;
  late int bankId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    service = LoanService(db, now: () => DateTime(2026, 5, 25, 10));

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
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> createLoan({
    double outstanding = 50000,
    double principal = 80000,
    double emi = 8500,
    int emiDay = 10,
  }) {
    return service.createLoan(
      title: 'Vehicle Loan',
      lenderName: 'HDFC',
      loanType: LoanType.vehicle,
      principalAmount: principal,
      currentOutstanding: outstanding,
      emiAmount: emi,
      emiDay: emiDay,
      startDate: DateTime(2025, 1, 1),
    );
  }

  test('EMI next-date calculation uses configured day', () async {
    final id = await createLoan(emiDay: 12);
    final loan = await service.getLoanById(id);
    final next = service.calculateNextEmiDate(
      loan!,
      date: DateTime(2026, 5, 5),
    );

    expect(next, DateTime(2026, 5, 12));
  });

  test('overdue EMI detection works', () async {
    await createLoan(emiDay: 10);

    final overdue = await service.getOverdueEmis(now: DateTime(2026, 5, 25));
    expect(overdue, isNotEmpty);
    expect(overdue.first.status, 'overdue');
  });

  test('EMI payment reduces outstanding and creates transaction', () async {
    final loanId = await createLoan(outstanding: 30000, emi: 8500);

    await service.markEmiPaid(
      loanId: loanId,
      amount: 8500,
      paymentSourceType: 'bank',
      paymentSourceId: bankId,
      paymentDate: DateTime(2026, 5, 25),
      notes: 'May EMI',
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
}
