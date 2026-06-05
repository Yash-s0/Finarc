import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/core/database/database_providers.dart';
import 'package:finarc/features/dashboard/data/dashboard_providers.dart';
import 'package:finarc/features/expenses/data/transaction_engine.dart';
import 'package:finarc/features/expenses/models/transaction_types.dart';
import 'package:finarc/features/recoverables/data/recoverables_service.dart';
import 'package:finarc/features/split/data/split_service.dart';

void main() {
  late AppDatabase db;
  late TransactionEngine engine;
  late SplitService splitService;
  late int bankId;
  late int cardId;
  late int cashId;
  late RecoverablesService Function({required DateTime Function() now})
  serviceFor;

  Future<void> addRecoverable({
    required String title,
    required String partyName,
    required double amount,
    required DateTime date,
    required String paymentSourceType,
    required int paymentSourceId,
    double cashback = 0,
    double? recoveredAmount,
  }) {
    return engine.addTransaction(
      AddTransactionInput(
        type: paymentSourceType == PaymentSourceType.creditCard
            ? TransactionType.creditCard
            : paymentSourceType,
        amount: amount,
        title: title,
        category: 'General',
        transactionDate: date,
        paymentSourceType: paymentSourceType,
        paymentSourceId: paymentSourceId,
        cashbackAmount: cashback,
        isForOthers: true,
        recoveredAmount: recoveredAmount,
        recoverablePartyName: partyName,
      ),
    );
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    engine = TransactionEngine(db);
    splitService = SplitService(db, engine);
    serviceFor = ({required DateTime Function() now}) =>
        RecoverablesService(db, splitService, engine, now: now);

    bankId = await db
        .into(db.bankAccounts)
        .insert(
          BankAccountsCompanion.insert(
            bankName: 'Test Bank',
            accountName: 'Primary',
            accountType: 'savings',
            currentBalance: const Value(10000),
          ),
        );

    cashId = await db
        .into(db.cashWallets)
        .insert(
          CashWalletsCompanion.insert(
            walletName: 'Cash Wallet',
            currentBalance: const Value(5000),
          ),
        );

    cardId = await db
        .into(db.creditCards)
        .insert(
          CreditCardsCompanion.insert(
            bankName: 'SBI',
            nickname: 'Rewards',
            last4: '1234',
            maskedNumber: '**** **** **** 1234',
            creditLimit: 100000,
            billingDay: DateTime.now().day > 1 ? DateTime.now().day - 1 : 1,
            dueDay: 7,
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  test('person grouping exposes totals and counts', () async {
    await addRecoverable(
      title: 'Lunch',
      partyName: 'Rahul',
      amount: 1000,
      cashback: 100,
      date: DateTime(2026, 5, 24),
      paymentSourceType: PaymentSourceType.bank,
      paymentSourceId: bankId,
    );
    await addRecoverable(
      title: 'Snacks',
      partyName: 'Rahul',
      amount: 700,
      cashback: 50,
      date: DateTime(2026, 5, 23),
      paymentSourceType: PaymentSourceType.bank,
      paymentSourceId: bankId,
    );
    await addRecoverable(
      title: 'Cab',
      partyName: 'Neha',
      amount: 500,
      date: DateTime(2026, 5, 22),
      paymentSourceType: PaymentSourceType.bank,
      paymentSourceId: bankId,
    );

    final snapshot = await serviceFor(
      now: () => DateTime(2026, 5, 25),
    ).buildSnapshot();

    expect(snapshot.groups, hasLength(2));
    final rahul = snapshot.groups.firstWhere((g) => g.partyName == 'Rahul');
    expect(rahul.transactionCount, 2);
    expect(rahul.originalTotal, closeTo(1550, 0.01));
    expect(rahul.recoveredTotal, closeTo(0, 0.01));
    expect(rahul.remainingTotal, closeTo(1550, 0.01));
    expect(snapshot.normalRecoverables, closeTo(2050, 0.01));
  });

  test('nearest due date is selected from related card bills', () async {
    final now = DateTime.now();
    final olderCycle = DateTime(now.year, now.month - 1, 2);
    final newerCycle = DateTime(now.year, now.month, 1);

    await addRecoverable(
      title: 'Older statement',
      partyName: 'Rahul',
      amount: 300,
      date: olderCycle,
      paymentSourceType: PaymentSourceType.creditCard,
      paymentSourceId: cardId,
    );
    await addRecoverable(
      title: 'Newer statement',
      partyName: 'Rahul',
      amount: 450,
      date: newerCycle,
      paymentSourceType: PaymentSourceType.creditCard,
      paymentSourceId: cardId,
    );

    final snapshot = await serviceFor(now: () => now).buildSnapshot();
    final rahul = snapshot.groups.firstWhere((g) => g.partyName == 'Rahul');
    final billedDueDates =
        rahul.items
            .where(
              (item) => item.billingState == RecoverableBillingState.billed,
            )
            .map((item) => item.dueDate)
            .whereType<DateTime>()
            .toList(growable: false)
          ..sort((a, b) => a.compareTo(b));

    expect(billedDueDates, isNotEmpty);
    expect(rahul.nearestDueDate, billedDueDates.first);
  });

  test(
    'unbilled card recoverables stay under person with unbilled state',
    () async {
      final now = DateTime.now();
      final unbilledDate = now.day > 1
          ? DateTime(now.year, now.month, now.day)
          : DateTime(now.year, now.month, 2);

      await addRecoverable(
        title: 'Cycle Shift',
        partyName: 'Rahul',
        amount: 400,
        cashback: 70,
        date: unbilledDate,
        paymentSourceType: PaymentSourceType.creditCard,
        paymentSourceId: cardId,
      );

      final snapshot = await serviceFor(now: () => now).buildSnapshot();
      final rahul = snapshot.groups.firstWhere((g) => g.partyName == 'Rahul');
      final item = rahul.items.single;

      expect(item.bucket, RecoverableBuckets.cardUnbilled);
      expect(item.billingState, RecoverableBillingState.unbilled);
      expect(item.sourceFilter, RecoverableSourceFilter.card);
    },
  );

  test('person-level full recovery settles all open transactions', () async {
    await addRecoverable(
      title: 'Dinner',
      partyName: 'Rahul',
      amount: 1000,
      cashback: 100,
      date: DateTime(2026, 5, 24),
      paymentSourceType: PaymentSourceType.bank,
      paymentSourceId: bankId,
    );
    await addRecoverable(
      title: 'Cab',
      partyName: 'Rahul',
      amount: 500,
      date: DateTime(2026, 5, 23),
      paymentSourceType: PaymentSourceType.cash,
      paymentSourceId: cashId,
    );

    final service = serviceFor(now: () => DateTime(2026, 5, 25));
    final result = await service.recordRecovery(
      partyName: 'Rahul',
      amount: 1400,
    );
    final snapshot = await service.buildSnapshot();

    expect(result.appliedAmount, closeTo(1400, 0.01));
    expect(result.remainingAfter, closeTo(0, 0.01));
    expect(result.updatedTransactionCount, 2);
    expect(snapshot.groups.where((g) => g.partyName == 'Rahul'), isEmpty);
    expect(snapshot.settledRecoverables, closeTo(1400, 0.01));
  });

  test(
    'partial recovery applies billed then bank cash then unbilled',
    () async {
      final now = DateTime.now();
      final billedDate = DateTime(
        now.year,
        now.month,
        now.day > 1 ? now.day - 1 : 1,
      );
      final bankDate = billedDate.subtract(const Duration(days: 4));
      final unbilledDate = now.day > 1
          ? DateTime(now.year, now.month, now.day)
          : DateTime(now.year, now.month, 2);

      await addRecoverable(
        title: 'Billed card',
        partyName: 'Rahul',
        amount: 300,
        date: billedDate,
        paymentSourceType: PaymentSourceType.creditCard,
        paymentSourceId: cardId,
      );
      await addRecoverable(
        title: 'Bank item',
        partyName: 'Rahul',
        amount: 250,
        date: bankDate,
        paymentSourceType: PaymentSourceType.bank,
        paymentSourceId: bankId,
      );
      await addRecoverable(
        title: 'Unbilled card',
        partyName: 'Rahul',
        amount: 400,
        date: unbilledDate,
        paymentSourceType: PaymentSourceType.creditCard,
        paymentSourceId: cardId,
      );

      final service = serviceFor(now: () => now);
      final result = await service.recordRecovery(
        partyName: 'Rahul',
        amount: 450,
      );
      final txns = await (db.select(
        db.transactions,
      )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
      final byTitle = {for (final txn in txns) txn.title: txn};

      expect(result.appliedAmount, closeTo(450, 0.01));
      expect(byTitle['Billed card']!.recoverableStatus, 'recovered');
      expect(byTitle['Billed card']!.recoveredAmount, closeTo(300, 0.01));
      expect(byTitle['Bank item']!.recoverableStatus, 'partial');
      expect(byTitle['Bank item']!.recoveredAmount, closeTo(150, 0.01));
      expect(byTitle['Unbilled card']!.recoverableStatus, 'unpaid');
      expect(byTitle['Unbilled card']!.recoveredAmount, closeTo(0, 0.01));
    },
  );

  test('overpayment is clamped safely', () async {
    await addRecoverable(
      title: 'Lunch',
      partyName: 'Rahul',
      amount: 500,
      date: DateTime(2026, 5, 24),
      paymentSourceType: PaymentSourceType.bank,
      paymentSourceId: bankId,
    );

    final result = await serviceFor(
      now: () => DateTime(2026, 5, 25),
    ).recordRecovery(partyName: 'Rahul', amount: 700);

    expect(result.clamped, isTrue);
    expect(result.appliedAmount, closeTo(500, 0.01));
    expect(result.remainingAfter, closeTo(0, 0.01));
  });

  test('per-transaction mark recovered still works', () async {
    await addRecoverable(
      title: 'Dinner',
      partyName: 'Rahul',
      amount: 1000,
      cashback: 100,
      date: DateTime(2026, 5, 24),
      paymentSourceType: PaymentSourceType.bank,
      paymentSourceId: bankId,
    );

    final service = serviceFor(now: () => DateTime(2026, 5, 25));
    final before = await service.buildSnapshot();
    final txn = await (db.select(
      db.transactions,
    )..where((t) => t.title.equals('Dinner'))).getSingle();
    await service.markRecovered(txn.id);
    final after = await service.buildSnapshot();

    expect(before.normalRecoverables, closeTo(900, 0.01));
    expect(after.normalRecoverables, closeTo(0, 0.01));
    expect(after.settledRecoverables, closeTo(900, 0.01));
  });

  test(
    'dashboard recoverable stays actionable while split receivables stay separate',
    () async {
      final now = DateTime.now();
      final billedDate = DateTime(
        now.year,
        now.month,
        now.day > 1 ? now.day - 1 : 1,
      );

      await addRecoverable(
        title: 'Billed Card',
        partyName: 'Rahul',
        amount: 401,
        cashback: 70,
        date: billedDate,
        paymentSourceType: PaymentSourceType.creditCard,
        paymentSourceId: cardId,
      );
      await addRecoverable(
        title: 'Bank Recoverable',
        partyName: 'Neha',
        amount: 200,
        cashback: 20,
        date: now,
        paymentSourceType: PaymentSourceType.bank,
        paymentSourceId: bankId,
      );

      final groupId = await splitService.createGroup('Trip');
      final youId = await splitService.addMember(
        groupId,
        name: 'You',
        isCurrentUser: true,
      );
      final rahulId = await splitService.addMember(groupId, name: 'Rahul');
      await splitService.addSplitExpense(
        AddSplitExpenseInput(
          groupId: groupId,
          title: 'Villa booking',
          totalAmount: 1000,
          paidByMemberId: youId,
          splitType: 'exact',
          expenseDate: now,
          category: 'Travel',
          shares: [
            SplitShareInput(memberId: youId, exactAmount: 300),
            SplitShareInput(memberId: rahulId, exactAmount: 700),
          ],
          paymentSourceType: PaymentSourceType.bank,
          paymentSourceId: bankId,
        ),
      );

      final recoverables = await serviceFor(now: () => now).buildSnapshot();
      expect(recoverables.actionableRecoverables, closeTo(511, 0.01));
      expect(recoverables.splitReceivables, closeTo(700, 0.01));
      expect(recoverables.normalRecoverables, closeTo(511, 0.01));
      expect(recoverables.totalRecoverable, closeTo(1211, 0.01));

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          seedProvider.overrideWith((ref) async {}),
        ],
      );
      addTearDown(container.dispose);
      final snapshot = await container.read(dashboardProvider.future);
      expect(snapshot.recoverableAmount, closeTo(511, 0.01));
      expect(snapshot.splitReceivableAmount, closeTo(700, 0.01));
    },
  );

  test(
    'split-linked recoverables are not double-counted in person groups',
    () async {
      final now = DateTime.now();
      final groupId = await splitService.createGroup('Goa');
      final youId = await splitService.addMember(
        groupId,
        name: 'You',
        isCurrentUser: true,
      );
      final rahulId = await splitService.addMember(groupId, name: 'Rahul');

      await splitService.addSplitExpense(
        AddSplitExpenseInput(
          groupId: groupId,
          title: 'Resort',
          totalAmount: 1000,
          paidByMemberId: youId,
          splitType: 'exact',
          expenseDate: now,
          category: 'Travel',
          shares: [
            SplitShareInput(memberId: youId, exactAmount: 200),
            SplitShareInput(memberId: rahulId, exactAmount: 800),
          ],
          paymentSourceType: PaymentSourceType.bank,
          paymentSourceId: bankId,
        ),
      );

      final snapshot = await serviceFor(now: () => now).buildSnapshot();
      expect(snapshot.groups, isEmpty);
      expect(snapshot.normalRecoverables, closeTo(0, 0.01));
      expect(snapshot.splitReceivables, closeTo(800, 0.01));
      expect(snapshot.totalRecoverable, closeTo(800, 0.01));
    },
  );

  test('refund-adjusted recoverable base is respected in snapshot', () async {
    await addRecoverable(
      title: 'Shared order',
      partyName: 'Rahul',
      amount: 1000,
      date: DateTime(2026, 5, 24),
      paymentSourceType: PaymentSourceType.creditCard,
      paymentSourceId: cardId,
    );
    final original = await (db.select(
      db.transactions,
    )..where((t) => t.title.equals('Shared order'))).getSingle();

    await engine.addTransaction(
      AddTransactionInput(
        type: TransactionType.refund,
        amount: 400,
        title: 'Shared order refund',
        category: 'Refund',
        transactionDate: DateTime(2026, 5, 25),
        paymentSourceType: PaymentSourceType.creditCard,
        paymentSourceId: cardId,
        relatedTransactionId: original.id,
      ),
    );

    final snapshot = await serviceFor(
      now: () => DateTime(2026, 5, 26),
    ).buildSnapshot();
    final item = snapshot.groups.single.items.single;

    expect(item.recoverableBaseAmount, closeTo(600, 0.01));
    expect(item.remainingRecoverableAmount, closeTo(600, 0.01));
  });

  test('cashback-adjusted recoverable base is respected in snapshot', () async {
    await addRecoverable(
      title: 'Shared meal',
      partyName: 'Rahul',
      amount: 1000,
      cashback: 125,
      date: DateTime(2026, 5, 24),
      paymentSourceType: PaymentSourceType.bank,
      paymentSourceId: bankId,
    );

    final snapshot = await serviceFor(
      now: () => DateTime(2026, 5, 25),
    ).buildSnapshot();
    final item = snapshot.groups.single.items.single;

    expect(item.recoverableBaseAmount, closeTo(875, 0.01));
    expect(item.remainingRecoverableAmount, closeTo(875, 0.01));
  });
}
