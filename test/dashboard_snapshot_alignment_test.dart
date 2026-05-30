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
}
