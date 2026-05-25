import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/core/database/reset_data_service.dart';

void main() {
  late AppDatabase db;
  late ResetDataService reset;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    reset = ResetDataService(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedUserData() async {
    await db
        .into(db.appSettings)
        .insert(
          AppSettingsCompanion.insert(
            isDarkMode: const Value(true),
            hasCompletedOnboarding: const Value(true),
          ),
        );

    final bankId = await db
        .into(db.bankAccounts)
        .insert(
          BankAccountsCompanion.insert(
            bankName: 'Seed Bank',
            accountName: 'Main',
            accountType: 'savings',
            currentBalance: const Value(1000),
          ),
        );

    await db
        .into(db.cashWallets)
        .insert(
          CashWalletsCompanion.insert(
            walletName: 'Cash',
            currentBalance: const Value(500),
          ),
        );

    final cardId = await db
        .into(db.creditCards)
        .insert(
          CreditCardsCompanion.insert(
            bankName: 'Seed Card',
            nickname: 'Primary',
            last4: '1234',
            maskedNumber: '**** **** **** 1234',
            creditLimit: 10000,
            billingDay: 5,
            dueDay: 20,
            currentOutstanding: const Value(200),
          ),
        );

    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            type: 'bank',
            amount: 100,
            title: 'Txn',
            category: 'General',
            transactionDate: DateTime.now(),
            paymentSourceType: 'bank',
            paymentSourceId: bankId,
          ),
        );

    await db
        .into(db.pendingTransactions)
        .insert(
          PendingTransactionsCompanion.insert(
            amount: 100,
            merchant: 'Shop',
            categorySuggestion: 'General',
            paymentSourceTypeSuggestion: 'bank',
            detectedAt: DateTime.now(),
            transactionDate: DateTime.now(),
            sourceType: 'sms',
            rawText: 'raw',
            confidenceScore: 0.6,
          ),
        );

    await db
        .into(db.cardBills)
        .insert(
          CardBillsCompanion.insert(
            cardId: cardId,
            billedAmount: 100,
            cycleStartDate: Value(
              DateTime.now().subtract(const Duration(days: 30)),
            ),
            cycleEndDate: Value(DateTime.now()),
            billingDate: Value(DateTime.now()),
            dueDate: Value(DateTime.now().add(const Duration(days: 10))),
          ),
        );

    final groupId = await db
        .into(db.splitGroups)
        .insert(
          SplitGroupsCompanion.insert(
            name: 'Trip',
            description: const Value('Test'),
            updatedAt: Value(DateTime.now()),
          ),
        );

    final youId = await db
        .into(db.splitMembers)
        .insert(
          SplitMembersCompanion.insert(
            groupId: groupId,
            name: 'You',
            isCurrentUser: const Value(true),
            updatedAt: Value(DateTime.now()),
          ),
        );

    final friendId = await db
        .into(db.splitMembers)
        .insert(
          SplitMembersCompanion.insert(
            groupId: groupId,
            name: 'Friend',
            isCurrentUser: const Value(false),
            updatedAt: Value(DateTime.now()),
          ),
        );

    final splitExpenseId = await db
        .into(db.splitExpenses)
        .insert(
          SplitExpensesCompanion.insert(
            groupId: groupId,
            title: 'Dinner',
            totalAmount: 300,
            paidByMemberId: youId,
            splitType: 'equal',
            expenseDate: DateTime.now(),
            category: 'Food',
            updatedAt: Value(DateTime.now()),
          ),
        );

    await db
        .into(db.splitExpenseShares)
        .insert(
          SplitExpenseSharesCompanion.insert(
            splitExpenseId: splitExpenseId,
            memberId: youId,
            exactAmount: 150,
            updatedAt: Value(DateTime.now()),
          ),
        );

    await db
        .into(db.splitExpenseShares)
        .insert(
          SplitExpenseSharesCompanion.insert(
            splitExpenseId: splitExpenseId,
            memberId: friendId,
            exactAmount: 150,
            updatedAt: Value(DateTime.now()),
          ),
        );

    await db
        .into(db.splitSettlements)
        .insert(
          SplitSettlementsCompanion.insert(
            groupId: groupId,
            fromMemberId: friendId,
            toMemberId: youId,
            amount: 50,
            settlementDate: DateTime.now(),
            updatedAt: Value(DateTime.now()),
          ),
        );

    await db
        .into(db.loans)
        .insert(
          LoansCompanion.insert(
            title: 'Loan',
            lenderName: 'Loan',
            loanType: const Value('personal'),
            principalAmount: 100,
            currentOutstanding: 100,
          ),
        );
  }

  test(
    'reset deletes all user data, keeps app_settings, sets onboarding false',
    () async {
      await seedUserData();

      final verification = await reset.wipeAllUserDataAndRestartOnboarding();

      expect(verification.accountsCount, 0);
      expect(verification.cardsCount, 0);
      expect(verification.transactionsCount, 0);
      expect(verification.pendingCount, 0);
      expect(verification.splitsCount, 0);
      expect(verification.cardBillsCount, 0);
      expect(verification.loansCount, 0);
      expect(verification.loanPaymentsCount, 0);
      expect(verification.appSettingsExists, true);
      expect(verification.onboardingIncomplete, true);
      expect(verification.isClean, true);

      final settings = await (db.select(
        db.appSettings,
      )..limit(1)).getSingleOrNull();
      expect(settings != null, true);
      expect(settings!.hasCompletedOnboarding, false);
    },
  );
}
