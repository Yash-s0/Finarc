import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/core/database/database_providers.dart';
import 'package:finarc/features/dashboard/data/dashboard_providers.dart';
import 'package:finarc/features/expenses/data/transaction_engine.dart';
import 'package:finarc/features/expenses/models/transaction_types.dart';
import 'package:finarc/features/split/data/split_service.dart';

void main() {
  late AppDatabase db;
  late TransactionEngine engine;
  late SplitService service;

  late int bankId;
  late int groupId;
  late int youId;
  late int rahulId;
  late int nehaId;

  Future<void> seedBase() async {
    bankId = await db
        .into(db.bankAccounts)
        .insert(
          BankAccountsCompanion.insert(
            bankName: 'HDFC',
            accountName: 'Main',
            accountType: 'savings',
            currentBalance: const Value(10000),
          ),
        );

    groupId = await service.createGroup('Goa Trip');
    youId = await service.addMember(groupId, name: 'You', isCurrentUser: true);
    rahulId = await service.addMember(groupId, name: 'Rahul');
    nehaId = await service.addMember(groupId, name: 'Neha');
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    engine = TransactionEngine(db);
    service = SplitService(db, engine);
    await seedBase();
  });

  tearDown(() async {
    await db.close();
  });

  test('equal split calculation', () {
    final shares = service.calculateEqualSplit(
      memberIds: [youId, rahulId, nehaId],
      totalAmount: 1000,
    );

    final total = shares.fold<double>(0, (sum, s) => sum + s.exactAmount);
    expect(shares.length, 3);
    expect(total, closeTo(1000, 0.01));
  });

  test('percentage split calculation', () {
    final shares = service.calculatePercentageSplit(
      percentagesByMember: {youId: 30, rahulId: 40, nehaId: 30},
      totalAmount: 1000,
    );

    final youShare = shares.firstWhere((s) => s.memberId == youId).exactAmount;
    final total = shares.fold<double>(0, (sum, s) => sum + s.exactAmount);

    expect(youShare, closeTo(300, 0.01));
    expect(total, closeTo(1000, 0.01));
  });

  test('exact split calculation', () {
    final shares = service.calculateExactSplit({
      youId: 250,
      rahulId: 500,
      nehaId: 250,
    });
    final total = shares.fold<double>(0, (sum, s) => sum + s.exactAmount);

    expect(shares.length, 3);
    expect(total, 1000);
  });

  test('invalid percentage total rejected', () {
    expect(
      () => service.calculatePercentageSplit(
        percentagesByMember: {youId: 60, rahulId: 30, nehaId: 20},
        totalAmount: 1000,
      ),
      throwsArgumentError,
    );
  });

  test('invalid exact total rejected', () {
    expect(
      () => service.validateSplitShares(
        splitType: 'exact',
        shares: [
          SplitShareInput(memberId: youId, exactAmount: 100),
          SplitShareInput(memberId: rahulId, exactAmount: 100),
        ],
        totalAmount: 500,
      ),
      throwsArgumentError,
    );
  });

  test('current user paid more than share creates recoverable', () async {
    final shares = service.calculateExactSplit({youId: 300, rahulId: 700});

    final splitExpenseId = await service.addSplitExpense(
      AddSplitExpenseInput(
        groupId: groupId,
        title: 'Villa booking',
        totalAmount: 1000,
        paidByMemberId: youId,
        splitType: 'exact',
        expenseDate: DateTime.now(),
        category: 'Travel',
        shares: shares,
        paymentSourceType: PaymentSourceType.bank,
        paymentSourceId: bankId,
      ),
    );

    final txn = await (db.select(
      db.transactions,
    )..where((t) => t.linkedSplitExpenseId.equals(splitExpenseId))).getSingle();
    final bank = await (db.select(
      db.bankAccounts,
    )..where((b) => b.id.equals(bankId))).getSingle();

    expect(txn.amount, 1000);
    expect(txn.personalShareAmount, 300);
    expect(txn.recoverableAmount, 700);
    expect(bank.currentBalance, 9000);
  });

  test('someone else paid creates payable without personal outflow', () async {
    final shares = service.calculateExactSplit({youId: 300, rahulId: 700});

    await service.addSplitExpense(
      AddSplitExpenseInput(
        groupId: groupId,
        title: 'Dinner',
        totalAmount: 1000,
        paidByMemberId: rahulId,
        splitType: 'exact',
        expenseDate: DateTime.now(),
        category: 'Food',
        shares: shares,
      ),
    );

    final txns = await db.select(db.transactions).get();
    final payable = await service.getCurrentUserPayables();

    expect(txns, isEmpty);
    expect(payable, closeTo(300, 0.01));
  });

  test('settlement paid reduces payable', () async {
    final shares = service.calculateExactSplit({youId: 300, rahulId: 700});
    await service.addSplitExpense(
      AddSplitExpenseInput(
        groupId: groupId,
        title: 'Hotel',
        totalAmount: 1000,
        paidByMemberId: rahulId,
        splitType: 'exact',
        expenseDate: DateTime.now(),
        category: 'Travel',
        shares: shares,
      ),
    );

    await service.addSettlement(
      groupId: groupId,
      fromMemberId: youId,
      toMemberId: rahulId,
      amount: 200,
      settlementDate: DateTime.now(),
      paymentSourceType: PaymentSourceType.bank,
      paymentSourceId: bankId,
      notes: 'partial settle',
    );

    final payable = await service.getCurrentUserPayables();
    final bank = await (db.select(
      db.bankAccounts,
    )..where((b) => b.id.equals(bankId))).getSingle();

    expect(payable, closeTo(100, 0.01));
    expect(bank.currentBalance, 9800);
  });

  test('settlement received reduces receivable', () async {
    final shares = service.calculateExactSplit({youId: 300, rahulId: 700});
    await service.addSplitExpense(
      AddSplitExpenseInput(
        groupId: groupId,
        title: 'Resort',
        totalAmount: 1000,
        paidByMemberId: youId,
        splitType: 'exact',
        expenseDate: DateTime.now(),
        category: 'Travel',
        shares: shares,
        paymentSourceType: PaymentSourceType.bank,
        paymentSourceId: bankId,
      ),
    );

    await service.addSettlement(
      groupId: groupId,
      fromMemberId: rahulId,
      toMemberId: youId,
      amount: 500,
      settlementDate: DateTime.now(),
      paymentSourceType: PaymentSourceType.bank,
      paymentSourceId: bankId,
      notes: 'settle return',
    );

    final receivable = await service.getCurrentUserReceivables();
    final bank = await (db.select(
      db.bankAccounts,
    )..where((b) => b.id.equals(bankId))).getSingle();

    expect(receivable, closeTo(200, 0.01));
    expect(bank.currentBalance, 9500);
  });

  test('group balance and simplified balance calculation', () async {
    await service.addSplitExpense(
      AddSplitExpenseInput(
        groupId: groupId,
        title: 'Cab',
        totalAmount: 900,
        paidByMemberId: youId,
        splitType: 'equal',
        expenseDate: DateTime.now(),
        category: 'Travel',
        shares: service.calculateEqualSplit(
          memberIds: [youId, rahulId, nehaId],
          totalAmount: 900,
        ),
        paymentSourceType: PaymentSourceType.bank,
        paymentSourceId: bankId,
      ),
    );

    final balances = await service.getGroupBalances(groupId);
    final simplified = await service.simplifyGroupBalances(groupId);

    final youNet = balances.firstWhere((b) => b.member.id == youId).net;
    final rahulNet = balances.firstWhere((b) => b.member.id == rahulId).net;

    expect(youNet, closeTo(600, 0.01));
    expect(rahulNet, closeTo(-300, 0.01));
    expect(simplified, isNotEmpty);
    final settledAmount = simplified.fold<double>(
      0,
      (sum, s) => sum + s.amount,
    );
    expect(settledAmount, closeTo(600, 0.01));
  });

  test(
    'dashboard recoverable excludes split receivables and personal share affects spend',
    () async {
      final shares = service.calculateExactSplit({youId: 300, rahulId: 700});
      await service.addSplitExpense(
        AddSplitExpenseInput(
          groupId: groupId,
          title: 'Group dinner',
          totalAmount: 1000,
          paidByMemberId: youId,
          splitType: 'exact',
          expenseDate: DateTime.now(),
          category: 'Food',
          shares: shares,
          paymentSourceType: PaymentSourceType.bank,
          paymentSourceId: bankId,
        ),
      );

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          seedProvider.overrideWith((ref) async {}),
        ],
      );
      addTearDown(container.dispose);

      final snapshot = await container.read(dashboardProvider.future);

      expect(snapshot.splitReceivableAmount, closeTo(700, 0.01));
      expect(snapshot.recoverableAmount, closeTo(0, 0.01));
      expect(snapshot.monthlySpends, closeTo(300, 0.01));
    },
  );
}
