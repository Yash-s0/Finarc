import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/features/dashboard/data/net_worth_service.dart';
import 'package:finarc/features/cards/data/billing_service.dart';
import 'package:finarc/features/expenses/data/transaction_engine.dart';
import 'package:finarc/features/expenses/models/transaction_types.dart';
import 'package:finarc/features/loans/data/loan_service.dart';
import 'package:finarc/features/split/data/split_service.dart';

void main() {
  late AppDatabase db;
  late TransactionEngine engine;
  late SplitService splitService;
  late LoanService loanService;
  late BillingService billingService;
  late NetWorthService netWorthService;

  late int bankId;
  late int groupId;
  late int youId;
  late int rahulId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    engine = TransactionEngine(db);
    splitService = SplitService(db, engine);
    loanService = LoanService(db, now: () => DateTime(2026, 5, 25));
    billingService = BillingService(db, now: () => DateTime(2026, 5, 25));
    netWorthService = NetWorthService(
      db,
      loanService,
      splitService,
      billingService,
    );

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

    await db
        .into(db.cashWallets)
        .insert(
          CashWalletsCompanion.insert(
            walletName: 'Wallet',
            currentBalance: const Value(5000),
          ),
        );
    await db
        .into(db.cashWallets)
        .insert(
          CashWalletsCompanion.insert(
            walletName: 'Amazon Pay',
            walletType: const Value('amazonPay'),
            currentBalance: const Value(1500),
          ),
        );

    await db
        .into(db.creditCards)
        .insert(
          CreditCardsCompanion.insert(
            bankName: 'SBI',
            nickname: 'Core',
            last4: '1234',
            maskedNumber: '**** **** **** 1234',
            creditLimit: 120000,
            billingDay: 5,
            dueDay: 20,
            currentOutstanding: const Value(20000),
          ),
        );
    await db
        .into(db.cardBills)
        .insert(
          CardBillsCompanion.insert(
            cardId: 1,
            billedAmount: 20000,
            billingDate: Value(DateTime(2026, 5, 5)),
            dueDate: Value(DateTime(2026, 5, 20)),
          ),
        );

    await loanService.createLoan(
      title: 'Vehicle Loan',
      lenderName: 'HDFC',
      loanType: LoanType.vehicle,
      principalAmount: 300000,
      currentOutstanding: 120000,
      emiAmount: 8500,
      emiDay: 10,
    );

    await engine.addTransaction(
      AddTransactionInput(
        type: TransactionType.bank,
        amount: 1000,
        title: 'Paid for friend',
        category: 'General',
        transactionDate: DateTime(2026, 5, 25),
        paymentSourceType: PaymentSourceType.bank,
        paymentSourceId: bankId,
        isForOthers: true,
        recoverableAmount: 300,
      ),
    );

    groupId = await splitService.createGroup('Trip');
    youId = await splitService.addMember(
      groupId,
      name: 'You',
      isCurrentUser: true,
    );
    rahulId = await splitService.addMember(groupId, name: 'Rahul');

    await splitService.addSplitExpense(
      AddSplitExpenseInput(
        groupId: groupId,
        title: 'Hotel',
        totalAmount: 1000,
        paidByMemberId: youId,
        splitType: 'exact',
        expenseDate: DateTime(2026, 5, 24),
        category: 'Travel',
        shares: [
          SplitShareInput(memberId: youId, exactAmount: 300),
          SplitShareInput(memberId: rahulId, exactAmount: 700),
        ],
        paymentSourceType: PaymentSourceType.bank,
        paymentSourceId: bankId,
      ),
    );

    await splitService.addSplitExpense(
      AddSplitExpenseInput(
        groupId: groupId,
        title: 'Cab',
        totalAmount: 500,
        paidByMemberId: rahulId,
        splitType: 'exact',
        expenseDate: DateTime(2026, 5, 24),
        category: 'Travel',
        shares: [
          SplitShareInput(memberId: youId, exactAmount: 200),
          SplitShareInput(memberId: rahulId, exactAmount: 300),
        ],
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('net worth formula includes assets and liabilities correctly', () async {
    final breakdown = await netWorthService.calculate();

    // Banks: 100000 - 1000 - 1000 = 98000
    // Cash + wallets: 6500
    // Recoverables: 1000
    // Split receivable/payable net from group: receivable 500, payable 0
    // Assets = 98000 + 6500 + 1000 + 500 = 106000
    // Liabilities = card 20000 + loans 120000 + split payables 0 = 140000
    // Net worth = -34000
    expect(breakdown.bankBalance, closeTo(98000, 0.01));
    expect(breakdown.cashBalance, closeTo(6500, 0.01));
    expect(breakdown.recoverables, closeTo(1000, 0.01));
    expect(breakdown.splitReceivables, closeTo(500, 0.01));
    expect(breakdown.splitPayables, closeTo(0, 0.01));
    expect(breakdown.cardDues, closeTo(20000, 0.01));
    expect(breakdown.loanOutstanding, closeTo(120000, 0.01));
    expect(breakdown.totalAssets, closeTo(106000, 0.01));
    expect(breakdown.totalLiabilities, closeTo(140000, 0.01));
    expect(breakdown.netWorth, closeTo(-34000, 0.01));
  });

  test('debt ratio and monthly EMI burden are calculated', () async {
    final breakdown = await netWorthService.calculate();

    expect(breakdown.monthlyEmiBurden, closeTo(8500, 0.01));
    expect(breakdown.debtRatio, closeTo(140000 / 106000, 0.0001));
  });

  test(
    'card dues and split balances are included in liabilities formula',
    () async {
      final breakdown = await netWorthService.calculate();

      expect(breakdown.cardDues, 20000);
      expect(breakdown.totalLiabilities, 140000);
    },
  );

  test('card liability includes billed plus unbilled outstanding', () async {
    await engine.addTransaction(
      AddTransactionInput(
        type: TransactionType.creditCard,
        amount: 1500,
        title: 'Unbilled swipe',
        category: 'Shopping',
        transactionDate: DateTime(2026, 5, 25),
        paymentSourceType: PaymentSourceType.creditCard,
        paymentSourceId: 1,
      ),
    );

    final breakdown = await netWorthService.calculate();
    expect(breakdown.cardLiability, closeTo(21500, 0.01));
    expect(breakdown.totalLiabilities, closeTo(141500, 0.01));
  });

  test('loan payments reduce outstanding and affect liabilities', () async {
    final loan = (await loanService.getActiveLoans()).first;

    await loanService.markEmiPaid(
      loanId: loan.id,
      amount: 10000,
      paymentSourceType: PaymentSourceType.bank,
      paymentSourceId: bankId,
      paymentDate: DateTime(2026, 5, 25),
    );

    final breakdown = await netWorthService.calculate();
    final payments = await loanService.getLoanPaymentHistory(loan.id);

    expect(payments, hasLength(1));
    expect(breakdown.loanOutstanding, 110000);
  });
}
