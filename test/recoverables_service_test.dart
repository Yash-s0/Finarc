import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/core/database/database_providers.dart';
import 'package:finarc/features/dashboard/data/dashboard_providers.dart';
import 'package:finarc/features/cards/data/billing_service.dart';
import 'package:finarc/features/expenses/data/transaction_engine.dart';
import 'package:finarc/features/expenses/models/transaction_types.dart';
import 'package:finarc/features/recoverables/data/recoverables_service.dart';
import 'package:finarc/features/split/data/split_service.dart';

void main() {
  late AppDatabase db;
  late TransactionEngine engine;
  late int bankId;
  late int cardId;
  late RecoverablesService Function({required DateTime Function() now})
  serviceFor;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    engine = TransactionEngine(db);
    serviceFor = ({required DateTime Function() now}) =>
        RecoverablesService(db, SplitService(db, engine), engine, now: now);

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

  test('groups recoverables by person and tracks totals', () async {
    await engine.addTransaction(
      AddTransactionInput(
        type: TransactionType.bank,
        amount: 1000,
        title: 'Lunch',
        category: 'Food',
        transactionDate: DateTime(2026, 5, 24),
        paymentSourceType: PaymentSourceType.bank,
        paymentSourceId: bankId,
        cashbackAmount: 100,
        isForOthers: true,
        recoverablePartyName: 'Rahul',
      ),
    );
    await engine.addTransaction(
      AddTransactionInput(
        type: TransactionType.bank,
        amount: 500,
        title: 'Cab',
        category: 'Travel',
        transactionDate: DateTime(2026, 5, 24),
        paymentSourceType: PaymentSourceType.bank,
        paymentSourceId: bankId,
        isForOthers: true,
        recoverablePartyName: 'Neha',
      ),
    );
    await engine.addTransaction(
      AddTransactionInput(
        type: TransactionType.bank,
        amount: 700,
        title: 'Snacks',
        category: 'Food',
        transactionDate: DateTime(2026, 5, 24),
        paymentSourceType: PaymentSourceType.bank,
        paymentSourceId: bankId,
        cashbackAmount: 50,
        isForOthers: true,
        recoverablePartyName: 'Rahul',
      ),
    );

    final snapshot = await serviceFor(
      now: () => DateTime(2026, 5, 25),
    ).buildSnapshot();

    expect(snapshot.groups, hasLength(2));
    final rahul = snapshot.groups.firstWhere((g) => g.partyName == 'Rahul');
    expect(rahul.items, hasLength(2));
    expect(rahul.openTotal, closeTo(1550, 0.01));
    expect(snapshot.totalRecoverable, closeTo(2050, 0.01));
  });

  test('mark recovered reduces recoverable totals', () async {
    await engine.addTransaction(
      AddTransactionInput(
        type: TransactionType.bank,
        amount: 1000,
        title: 'Dinner',
        category: 'Food',
        transactionDate: DateTime(2026, 5, 24),
        paymentSourceType: PaymentSourceType.bank,
        paymentSourceId: bankId,
        cashbackAmount: 100,
        isForOthers: true,
        recoverablePartyName: 'Rahul',
      ),
    );
    await engine.addTransaction(
      AddTransactionInput(
        type: TransactionType.bank,
        amount: 500,
        title: 'Cab',
        category: 'Travel',
        transactionDate: DateTime(2026, 5, 24),
        paymentSourceType: PaymentSourceType.bank,
        paymentSourceId: bankId,
        isForOthers: true,
        recoverablePartyName: 'Neha',
      ),
    );

    final service = serviceFor(now: () => DateTime(2026, 5, 25));
    final before = await service.buildSnapshot();
    final rahulTxn = await (db.select(
      db.transactions,
    )..where((t) => t.title.equals('Dinner'))).getSingle();
    await service.markRecovered(rahulTxn.id);

    final after = await service.buildSnapshot();
    expect(before.totalRecoverable, closeTo(1400, 0.01));
    expect(after.totalRecoverable, closeTo(500, 0.01));
    expect(after.settledRecoverables, closeTo(900, 0.01));
  });

  test(
    'dashboard recoverable includes billed card + non-card and excludes unbilled card',
    () async {
      final now = DateTime.now();
      final billedDate = DateTime(
        now.year,
        now.month,
        now.day > 1 ? now.day - 1 : 1,
      );
      final unbilledDate = now.day > 1
          ? DateTime(now.year, now.month, now.day)
          : DateTime(now.year, now.month, 2);

      await engine.addTransaction(
        AddTransactionInput(
          type: TransactionType.creditCard,
          amount: 401,
          title: 'Billed Card',
          category: 'Food',
          transactionDate: billedDate,
          paymentSourceType: PaymentSourceType.creditCard,
          paymentSourceId: cardId,
          cashbackAmount: 70,
          isForOthers: true,
          recoverablePartyName: 'Rahul',
        ),
      );
      await engine.addTransaction(
        AddTransactionInput(
          type: TransactionType.creditCard,
          amount: 400,
          title: 'Unbilled Card',
          category: 'Food',
          transactionDate: unbilledDate,
          paymentSourceType: PaymentSourceType.creditCard,
          paymentSourceId: cardId,
          cashbackAmount: 70,
          isForOthers: true,
          recoverablePartyName: 'Rahul',
        ),
      );
      await engine.addTransaction(
        AddTransactionInput(
          type: TransactionType.bank,
          amount: 200,
          title: 'Bank Recoverable',
          category: 'Food',
          transactionDate: now,
          paymentSourceType: PaymentSourceType.bank,
          paymentSourceId: bankId,
          cashbackAmount: 20,
          isForOthers: true,
          recoverablePartyName: 'Neha',
        ),
      );

      final recoverables = await serviceFor(now: () => now).buildSnapshot();
      expect(recoverables.cardBilledRecoverables, closeTo(331, 0.01));
      expect(recoverables.cardUnbilledRecoverables, closeTo(330, 0.01));
      expect(recoverables.bankUpiRecoverables, closeTo(180, 0.01));
      expect(recoverables.actionableRecoverables, closeTo(511, 0.01));

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          seedProvider.overrideWith((ref) async {}),
        ],
      );
      addTearDown(container.dispose);
      final snapshot = await container.read(dashboardProvider.future);
      expect(snapshot.cardDues, closeTo(401, 0.01));
      expect(snapshot.recoverableAmount, closeTo(511, 0.01));
    },
  );

  test(
    'unbilled card recoverable becomes billed after cycle billing',
    () async {
      final now = DateTime.now();
      final dayForCard = now.day > 1 ? now.day - 1 : 1;
      final unbilledDate = now.day > 1
          ? DateTime(now.year, now.month, now.day)
          : DateTime(now.year, now.month, 2);

      await engine.addTransaction(
        AddTransactionInput(
          type: TransactionType.creditCard,
          amount: 400,
          title: 'Cycle Shift',
          category: 'Food',
          transactionDate: unbilledDate,
          paymentSourceType: PaymentSourceType.creditCard,
          paymentSourceId: cardId,
          cashbackAmount: 70,
          isForOthers: true,
          recoverablePartyName: 'Rahul',
        ),
      );

      final before = await serviceFor(now: () => now).buildSnapshot();
      expect(before.cardUnbilledRecoverables, closeTo(330, 0.01));
      expect(before.cardBilledRecoverables, closeTo(0, 0.01));

      final nextCycleNow = DateTime(now.year, now.month + 1, dayForCard + 1);
      await BillingService(
        db,
        now: () => nextCycleNow,
      ).getAllCardBillingSnapshots(now: nextCycleNow);

      final after = await serviceFor(now: () => nextCycleNow).buildSnapshot();
      expect(after.cardUnbilledRecoverables, closeTo(0, 0.01));
      expect(after.cardBilledRecoverables, closeTo(330, 0.01));
      expect(after.actionableRecoverables, closeTo(330, 0.01));
    },
  );
}
