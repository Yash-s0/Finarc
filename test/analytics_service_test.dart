import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/features/analytics/data/analytics_models.dart';
import 'package:finarc/features/analytics/data/analytics_service.dart';
import 'package:finarc/features/cards/data/billing_service.dart';
import 'package:finarc/features/expenses/data/transaction_engine.dart';
import 'package:finarc/features/expenses/models/transaction_types.dart';
import 'package:finarc/features/loans/data/loan_service.dart';
import 'package:finarc/features/split/data/split_service.dart';

void main() {
  late AppDatabase db;
  late AnalyticsService service;

  late int bankId;
  late int cashId;
  late int cardA;
  late int cardB;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());

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
            currentBalance: const Value(5000),
          ),
        );

    cardA = await db
        .into(db.creditCards)
        .insert(
          CreditCardsCompanion.insert(
            bankName: 'HDFC',
            nickname: 'Primary',
            last4: '1234',
            maskedNumber: '**** **** **** 1234',
            creditLimit: 100000,
            billingDay: 10,
            dueDay: 20,
            currentOutstanding: const Value(30000),
          ),
        );

    cardB = await db
        .into(db.creditCards)
        .insert(
          CreditCardsCompanion.insert(
            bankName: 'ICICI',
            nickname: 'Travel',
            last4: '9876',
            maskedNumber: '**** **** **** 9876',
            creditLimit: 50000,
            billingDay: 5,
            dueDay: 15,
            currentOutstanding: const Value(10000),
          ),
        );

    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            type: TransactionType.creditCard,
            amount: 1000,
            title: 'Swiggy',
            category: 'Food',
            transactionDate: DateTime(2026, 5, 5),
            paymentSourceType: PaymentSourceType.creditCard,
            paymentSourceId: cardA,
            cashbackAmount: const Value(100),
          ),
        );

    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            type: TransactionType.bank,
            amount: 500,
            title: 'Swiggy',
            category: 'Food',
            transactionDate: DateTime(2026, 5, 8),
            paymentSourceType: PaymentSourceType.bank,
            paymentSourceId: bankId,
          ),
        );

    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            type: TransactionType.upi,
            amount: 700,
            title: 'Uber',
            category: 'Travel',
            transactionDate: DateTime(2026, 5, 12),
            paymentSourceType: PaymentSourceType.upi,
            paymentSourceId: bankId,
          ),
        );

    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            type: TransactionType.bank,
            amount: 1000,
            title: 'Team Lunch',
            category: 'Food',
            transactionDate: DateTime(2026, 5, 20),
            paymentSourceType: PaymentSourceType.bank,
            paymentSourceId: bankId,
            isForOthers: const Value(true),
            recoverableAmount: const Value(700),
          ),
        );

    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            type: TransactionType.transfer,
            amount: 2000,
            title: 'Bank transfer',
            category: 'Transfer',
            transactionDate: DateTime(2026, 5, 15),
            paymentSourceType: PaymentSourceType.bank,
            paymentSourceId: bankId,
          ),
        );

    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            type: TransactionType.cardPayment,
            amount: 3000,
            title: 'Card bill paid',
            category: 'Transfer',
            transactionDate: DateTime(2026, 5, 16),
            paymentSourceType: PaymentSourceType.bank,
            paymentSourceId: bankId,
          ),
        );

    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            type: TransactionType.income,
            amount: 50000,
            title: 'Salary',
            category: 'Income',
            transactionDate: DateTime(2026, 5, 17),
            paymentSourceType: PaymentSourceType.bank,
            paymentSourceId: bankId,
          ),
        );

    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            type: TransactionType.creditCard,
            amount: 2000,
            title: 'Amazon',
            category: 'Shopping',
            transactionDate: DateTime(2026, 4, 10),
            paymentSourceType: PaymentSourceType.creditCard,
            paymentSourceId: cardB,
          ),
        );

    await db
        .into(db.cardBills)
        .insert(
          CardBillsCompanion.insert(
            cardId: cardA,
            cycleStartDate: Value(DateTime(2026, 4, 11)),
            cycleEndDate: Value(DateTime(2026, 5, 10)),
            billingDate: Value(DateTime(2026, 5, 10)),
            dueDate: Value(DateTime(2026, 5, 20)),
            billedAmount: 10000,
            paidAmount: const Value(5000),
            status: const Value('billed'),
          ),
        );

    final loanId = await db
        .into(db.loans)
        .insert(
          LoansCompanion.insert(
            title: 'Vehicle Loan',
            lenderName: 'HDFC',
            loanType: const Value('vehicle'),
            principalAmount: 80000,
            currentOutstanding: 50000,
            emiAmount: const Value(8500),
            emiDay: const Value(10),
          ),
        );

    await db
        .into(db.loanPayments)
        .insert(
          LoanPaymentsCompanion.insert(
            loanId: loanId,
            amount: 8500,
            paymentDate: DateTime(2026, 5, 10),
            paymentSourceType: const Value(PaymentSourceType.bank),
            paymentSourceId: Value(bankId),
          ),
        );

    await db
        .into(db.loanPayments)
        .insert(
          LoanPaymentsCompanion.insert(
            loanId: loanId,
            amount: 8500,
            paymentDate: DateTime(2026, 4, 10),
            paymentSourceType: const Value(PaymentSourceType.bank),
            paymentSourceId: Value(bankId),
          ),
        );

    final groupId = await db
        .into(db.splitGroups)
        .insert(SplitGroupsCompanion.insert(name: 'Goa Trip'));
    final youId = await db
        .into(db.splitMembers)
        .insert(
          SplitMembersCompanion.insert(
            groupId: groupId,
            name: 'You',
            isCurrentUser: const Value(true),
          ),
        );
    final friendId = await db
        .into(db.splitMembers)
        .insert(
          SplitMembersCompanion.insert(
            groupId: groupId,
            name: 'Rahul',
            isCurrentUser: const Value(false),
          ),
        );

    final splitExpenseId = await db
        .into(db.splitExpenses)
        .insert(
          SplitExpensesCompanion.insert(
            groupId: groupId,
            title: 'Dinner',
            totalAmount: 1000,
            paidByMemberId: youId,
            splitType: 'exact',
            expenseDate: DateTime(2026, 5, 18),
            category: 'Food',
          ),
        );

    await db
        .into(db.splitExpenseShares)
        .insert(
          SplitExpenseSharesCompanion.insert(
            splitExpenseId: splitExpenseId,
            memberId: youId,
            exactAmount: 300,
          ),
        );
    await db
        .into(db.splitExpenseShares)
        .insert(
          SplitExpenseSharesCompanion.insert(
            splitExpenseId: splitExpenseId,
            memberId: friendId,
            exactAmount: 700,
          ),
        );

    await db
        .into(db.splitSettlements)
        .insert(
          SplitSettlementsCompanion.insert(
            groupId: groupId,
            fromMemberId: friendId,
            toMemberId: youId,
            amount: 200,
            settlementDate: DateTime(2026, 5, 22),
          ),
        );

    service = AnalyticsService(
      db,
      BillingService(db, now: () => DateTime(2026, 5, 25)),
      LoanService(db, now: () => DateTime(2026, 5, 25)),
      SplitService(db, TransactionEngine(db)),
    );

    expect(cashId, greaterThan(0));
  });

  tearDown(() async {
    await db.close();
  });

  test('monthly aggregation and date filtering work', () async {
    final thisMonth = await service.buildSnapshot(
      period: AnalyticsPeriod.thisMonth,
      now: DateTime(2026, 5, 25),
    );

    final lastMonth = await service.buildSnapshot(
      period: AnalyticsPeriod.lastMonth,
      now: DateTime(2026, 5, 25),
    );

    expect(thisMonth.spending.totalSpending, closeTo(2400, 0.001));
    expect(lastMonth.spending.totalSpending, closeTo(2000, 0.001));
  });

  test('category and merchant aggregation works', () async {
    final snapshot = await service.buildSnapshot(
      period: AnalyticsPeriod.thisMonth,
      now: DateTime(2026, 5, 25),
    );

    expect(snapshot.spending.highestCategory?.name, 'Food');
    expect(snapshot.spending.highestMerchant?.name, 'Swiggy');
    expect(snapshot.spending.recurringMerchants.first.name, 'Swiggy');
    expect(snapshot.spending.recurringMerchants.first.count, 2);
  });

  test(
    'excludes transfers and card payments from lifestyle spending',
    () async {
      final snapshot = await service.buildSnapshot(
        period: AnalyticsPeriod.thisMonth,
        now: DateTime(2026, 5, 25),
      );

      final merchantNames = snapshot.spending.topMerchants
          .map((e) => e.name)
          .toList();
      expect(merchantNames.contains('Bank transfer'), false);
      expect(merchantNames.contains('Card bill paid'), false);
    },
  );

  test(
    'income is included in income analytics and excluded from spending',
    () async {
      final snapshot = await service.buildSnapshot(
        period: AnalyticsPeriod.thisMonth,
        now: DateTime(2026, 5, 25),
      );

      expect(snapshot.income.totalIncome, closeTo(50000, 0.001));
      expect(snapshot.spending.totalSpending, closeTo(2400, 0.001));
    },
  );

  test('card utilization and billed calculations are correct', () async {
    final snapshot = await service.buildSnapshot(
      period: AnalyticsPeriod.thisMonth,
      now: DateTime(2026, 5, 25),
    );

    expect(snapshot.cards.totalUtilization, closeTo(40000 / 150000, 0.0001));
    expect(snapshot.cards.billSummary.billedTotal, 10000);
    expect(snapshot.cards.billSummary.pendingTotal, 5000);
  });

  test('debt ratio trend and EMI trend are generated', () async {
    final snapshot = await service.buildSnapshot(
      period: AnalyticsPeriod.last3Months,
      now: DateTime(2026, 5, 25),
    );

    expect(snapshot.loans.emiTrend, isNotEmpty);
    expect(snapshot.loans.debtRatioTrend, isNotEmpty);
    expect(snapshot.loans.debtRatioTrend.last.value, greaterThan(0));
  });

  test(
    'split analytics recoverable/payable and counterparts are computed',
    () async {
      final snapshot = await service.buildSnapshot(
        period: AnalyticsPeriod.thisMonth,
        now: DateTime(2026, 5, 25),
      );

      expect(snapshot.splits.totalRecoverable, closeTo(500, 0.001));
      expect(snapshot.splits.totalPayable, closeTo(0, 0.001));
      expect(snapshot.splits.owesYou.first.name, 'Rahul');
      expect(snapshot.splits.owesYou.first.amount, closeTo(500, 0.001));
    },
  );
}
