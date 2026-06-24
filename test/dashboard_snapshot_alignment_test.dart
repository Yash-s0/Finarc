import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/core/database/database_providers.dart';
import 'package:finarc/features/dashboard/data/dashboard_providers.dart';
import 'package:finarc/features/expenses/data/transaction_engine.dart';
import 'package:finarc/features/expenses/models/transaction_types.dart';

void main() {
  late AppDatabase db;
  late TransactionEngine engine;
  late int bankId;
  late int cardId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    engine = TransactionEngine(db);

    bankId = await db
        .into(db.bankAccounts)
        .insert(
          BankAccountsCompanion.insert(
            bankName: 'Test',
            accountName: 'Main',
            accountType: 'savings',
            currentBalance: const Value(10000),
          ),
        );

    final now = DateTime.now();
    cardId = await db
        .into(db.creditCards)
        .insert(
          CreditCardsCompanion.insert(
            bankName: 'SBI',
            nickname: 'Core',
            last4: '1234',
            maskedNumber: '**** **** **** 1234',
            creditLimit: 100000,
            billingDay: now.day > 1 ? now.day - 1 : 1,
            dueDay: 7,
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'dashboard uses billedDue for card dues and actionable recoverables for recoverable metric',
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
          amount: 1000,
          title: 'Billed card',
          category: 'Food',
          transactionDate: billedDate,
          paymentSourceType: PaymentSourceType.creditCard,
          paymentSourceId: cardId,
          cashbackAmount: 100,
          isForOthers: true,
          recoverablePartyName: 'Rahul',
        ),
      );
      await engine.addTransaction(
        AddTransactionInput(
          type: TransactionType.creditCard,
          amount: 500,
          title: 'Unbilled card',
          category: 'Food',
          transactionDate: unbilledDate,
          paymentSourceType: PaymentSourceType.creditCard,
          paymentSourceId: cardId,
          cashbackAmount: 50,
          isForOthers: true,
          recoverablePartyName: 'Rahul',
        ),
      );
      await engine.addTransaction(
        AddTransactionInput(
          type: TransactionType.bank,
          amount: 200,
          title: 'Bank shared',
          category: 'Food',
          transactionDate: now,
          paymentSourceType: PaymentSourceType.bank,
          paymentSourceId: bankId,
          cashbackAmount: 20,
          isForOthers: true,
          recoverablePartyName: 'Neha',
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
      expect(snapshot.cardDues, closeTo(1000, 0.01));
      expect(snapshot.cardOutstanding, closeTo(1500, 0.01));
      expect(snapshot.recoverableAmount, closeTo(1080, 0.01));
    },
  );

  test(
    'dashboard monthly spends use salary cycles and card billing month',
    () async {
      final now = DateTime.now();
      final salaryDay = now.day > 1 ? now.day : 2;
      final currentCycleDate = DateTime(now.year, now.month, salaryDay);
      final previousCycleDate = DateTime(now.year, now.month, salaryDay - 1);

      await db
          .into(db.appSettings)
          .insert(
            AppSettingsCompanion.insert(
              isDarkMode: const Value(true),
              salaryCreditDay: Value(salaryDay),
            ),
          );
      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              type: 'expense',
              amount: 200,
              title: 'Current salary cycle cash',
              category: 'Food',
              transactionDate: currentCycleDate,
              paymentSourceType: 'bank',
              paymentSourceId: bankId,
            ),
          );
      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              type: 'income',
              amount: 1200,
              title: 'Current month salary',
              category: 'Salary',
              transactionDate: currentCycleDate,
              paymentSourceType: 'bank',
              paymentSourceId: bankId,
            ),
          );
      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              type: 'expense',
              amount: 100,
              title: 'Previous salary cycle cash',
              category: 'Food',
              transactionDate: previousCycleDate,
              paymentSourceType: 'bank',
              paymentSourceId: bankId,
            ),
          );

      final billingDate = DateTime(now.year, now.month, salaryDay);
      final cardBillId = await db
          .into(db.cardBills)
          .insert(
            CardBillsCompanion.insert(
              cardId: cardId,
              cycleStartDate: Value(DateTime(now.year, now.month - 1, 20)),
              cycleEndDate: Value(billingDate),
              billingDate: Value(billingDate),
              billedAmount: 300,
              dueDate: Value(DateTime(now.year, now.month + 1, 3)),
              status: const Value('dueSoon'),
            ),
          );
      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              type: 'creditCard',
              amount: 300,
              title: 'Card billed in current month',
              category: 'Food',
              transactionDate: DateTime(now.year, now.month - 1, 25),
              paymentSourceType: 'creditCard',
              paymentSourceId: cardId,
              cardBillId: Value(cardBillId),
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
      expect(snapshot.monthlySpends, closeTo(500, 0.01));
      expect(snapshot.monthlySpendTrend.last.amount, closeTo(500, 0.01));
      expect(snapshot.monthlySpendTrend.last.income, closeTo(1200, 0.01));
    },
  );
}
