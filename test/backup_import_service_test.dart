import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/core/database/backup/backup_service.dart';
import 'package:finarc/core/database/backup/import_service.dart';

void main() {
  late AppDatabase db;
  late BackupService backupService;
  late ImportService importService;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    backupService = BackupService(db);
    importService = ImportService(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedSampleData() async {
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
            bankName: 'HDFC',
            accountName: 'Main',
            accountType: 'savings',
            last4: const Value('7788'),
            currentBalance: const Value(25000),
          ),
        );

    final walletId = await db
        .into(db.cashWallets)
        .insert(
          CashWalletsCompanion.insert(
            walletName: 'Amazon Pay',
            walletType: const Value('amazonPay'),
            currentBalance: const Value(1200),
          ),
        );

    final cardId = await db
        .into(db.creditCards)
        .insert(
          CreditCardsCompanion.insert(
            bankName: 'ICICI',
            nickname: 'Travel',
            last4: '1234',
            maskedNumber: '**** **** **** 1234',
            creditLimit: 100000,
            billingDay: 10,
            dueDay: 20,
            currentOutstanding: const Value(20000),
          ),
        );

    final txnId = await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            type: 'creditCard',
            amount: 1499,
            title: 'Swiggy',
            category: 'Food',
            transactionDate: DateTime(2026, 5, 25),
            paymentSourceType: 'creditCard',
            paymentSourceId: cardId,
            cashbackAmount: const Value(99),
            cashbackDestinationType: const Value('amazonPay'),
            cashbackDestinationId: Value(walletId),
            isForOthers: const Value(true),
            recoverableAmount: const Value(300),
            detectedSourceType: const Value('sms'),
          ),
        );

    final billId = await db
        .into(db.cardBills)
        .insert(
          CardBillsCompanion.insert(
            cardId: cardId,
            cycleStartDate: Value(DateTime(2026, 4, 11)),
            cycleEndDate: Value(DateTime(2026, 5, 10)),
            billingDate: Value(DateTime(2026, 5, 10)),
            dueDate: Value(DateTime(2026, 5, 20)),
            billedAmount: 1499,
            paidAmount: const Value(0),
            status: const Value('billed'),
          ),
        );

    await (db.update(db.transactions)..where((t) => t.id.equals(txnId))).write(
      TransactionsCompanion(cardBillId: Value(billId)),
    );

    await db
        .into(db.pendingTransactions)
        .insert(
          PendingTransactionsCompanion.insert(
            amount: 700,
            merchant: 'Rahul',
            categorySuggestion: 'Transfer',
            paymentSourceTypeSuggestion: 'bank',
            paymentSourceIdSuggestion: Value(bankId),
            detectedAt: DateTime(2026, 5, 25),
            transactionDate: DateTime(2026, 5, 25),
            sourceType: 'sms',
            rawText: 'Rs 700 debited',
            confidenceScore: 0.82,
          ),
        );

    final splitGroupId = await db
        .into(db.splitGroups)
        .insert(
          SplitGroupsCompanion.insert(
            name: 'Goa Trip',
            description: const Value('Friends trip'),
            updatedAt: Value(DateTime(2026, 5, 25)),
          ),
        );

    final youId = await db
        .into(db.splitMembers)
        .insert(
          SplitMembersCompanion.insert(
            groupId: splitGroupId,
            name: 'You',
            isCurrentUser: const Value(true),
            updatedAt: Value(DateTime(2026, 5, 25)),
          ),
        );

    final friendId = await db
        .into(db.splitMembers)
        .insert(
          SplitMembersCompanion.insert(
            groupId: splitGroupId,
            name: 'Rahul',
            isCurrentUser: const Value(false),
            updatedAt: Value(DateTime(2026, 5, 25)),
          ),
        );

    final splitExpenseId = await db
        .into(db.splitExpenses)
        .insert(
          SplitExpensesCompanion.insert(
            groupId: splitGroupId,
            title: 'Dinner',
            totalAmount: 2000,
            paidByMemberId: youId,
            splitType: 'equal',
            expenseDate: DateTime(2026, 5, 24),
            category: 'Food',
            linkedTransactionId: Value(txnId),
            updatedAt: Value(DateTime(2026, 5, 24)),
          ),
        );

    await db
        .into(db.splitExpenseShares)
        .insert(
          SplitExpenseSharesCompanion.insert(
            splitExpenseId: splitExpenseId,
            memberId: youId,
            exactAmount: 1000,
            updatedAt: Value(DateTime(2026, 5, 24)),
          ),
        );

    await db
        .into(db.splitExpenseShares)
        .insert(
          SplitExpenseSharesCompanion.insert(
            splitExpenseId: splitExpenseId,
            memberId: friendId,
            exactAmount: 1000,
            updatedAt: Value(DateTime(2026, 5, 24)),
          ),
        );

    await db
        .into(db.splitSettlements)
        .insert(
          SplitSettlementsCompanion.insert(
            groupId: splitGroupId,
            fromMemberId: friendId,
            toMemberId: youId,
            amount: 400,
            settlementDate: DateTime(2026, 5, 25),
            updatedAt: Value(DateTime(2026, 5, 25)),
          ),
        );

    final loanId = await db
        .into(db.loans)
        .insert(
          LoansCompanion.insert(
            title: 'Vehicle Loan',
            lenderName: 'HDFC',
            lenderType: const Value('company'),
            loanType: const Value('vehicle'),
            principalAmount: 80000,
            currentOutstanding: 50000,
            emiAmount: const Value(8500),
            emiDay: const Value(10),
            linkedAccountId: Value(bankId),
          ),
        );

    await db
        .into(db.loanPayments)
        .insert(
          LoanPaymentsCompanion.insert(
            loanId: loanId,
            amount: 8500,
            paymentDate: DateTime(2026, 5, 10),
            paymentSourceType: const Value('bank'),
            paymentSourceId: Value(bankId),
            linkedTransactionId: Value(txnId),
          ),
        );

    expect(walletId, greaterThan(0));
  }

  test(
    'backup JSON includes all tables and excludes forbidden fields',
    () async {
      await seedSampleData();

      final backup = await backupService.createBackupJson();
      final decoded = jsonDecode(backup) as Map<String, dynamic>;
      final data = decoded['data'] as Map<String, dynamic>;

      expect(decoded['app'], 'Finarc');
      expect(
        data.keys,
        containsAll(<String>[
          'settings',
          'bankAccounts',
          'cashWallets',
          'creditCards',
          'transactions',
          'cardBills',
          'pendingTransactions',
          'splitGroups',
          'splitMembers',
          'splitExpenses',
          'splitExpenseShares',
          'splitSettlements',
          'loans',
          'loanPayments',
        ]),
      );

      expect(backup.toLowerCase().contains('cvv'), false);
      expect(backup.toLowerCase().contains('expiry'), false);
      expect((data['bankAccounts'] as List).single['last4'], '7788');
      expect((data['loans'] as List).single['lenderType'], 'company');
      expect((data['cashWallets'] as List).single['walletType'], 'amazonPay');
      expect(
        (data['transactions'] as List).single['cashbackDestinationType'],
        'amazonPay',
      );
    },
  );

  test('backup validation accepts valid backup', () async {
    await seedSampleData();
    final backup = await backupService.createBackupJson();

    final result = importService.validateBackupJson(backup);
    expect(result.isValid, true);
  });

  test('backup validation rejects invalid app name', () {
    final invalid = jsonEncode({
      'app': 'OtherApp',
      'backupVersion': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'schemaVersion': 10,
      'data': {},
    });

    final result = importService.validateBackupJson(invalid);
    expect(result.isValid, false);
  });

  test('backup validation rejects unsupported future version', () {
    final invalid = jsonEncode({
      'app': 'Finarc',
      'backupVersion': 99,
      'createdAt': DateTime.now().toIso8601String(),
      'schemaVersion': 10,
      'data': {},
    });

    final result = importService.validateBackupJson(invalid);
    expect(result.isValid, false);
  });

  test('preview counts are correct', () async {
    await seedSampleData();
    final backup = await backupService.createBackupJson();

    final preview = importService.previewBackup(backup);
    expect(preview.counts['bankAccounts'], 1);
    expect(preview.counts['cashWallets'], 1);
    expect(preview.counts['creditCards'], 1);
    expect(preview.counts['transactions'], 1);
    expect(preview.counts['loans'], 1);
  });

  test('replace import clears old data and restores backup data', () async {
    await seedSampleData();
    final backup = await backupService.createBackupJson();

    await db
        .into(db.bankAccounts)
        .insert(
          BankAccountsCompanion.insert(
            bankName: 'Extra',
            accountName: 'Should clear',
            accountType: 'savings',
            currentBalance: const Value(1),
          ),
        );

    final result = await importService.importBackupReplaceAll(backup);

    final banks = await db.select(db.bankAccounts).get();
    final wallets = await db.select(db.cashWallets).get();
    final txns = await db.select(db.transactions).get();
    final cards = await db.select(db.creditCards).get();

    expect(result.counts['bankAccounts'], 1);
    expect(banks.length, 1);
    expect(banks.single.last4, '7788');
    expect(wallets.single.walletType, 'amazonPay');
    expect(txns.length, 1);
    expect(txns.single.cashbackDestinationType, 'amazonPay');
    expect(cards.length, 1);
    final loans = await db.select(db.loans).get();
    expect(loans.single.lenderType, 'company');
  });

  test('import handles missing optional arrays', () async {
    final minimal = jsonEncode({
      'app': 'Finarc',
      'backupVersion': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'schemaVersion': 10,
      'data': {
        'settings': [
          {
            'id': 1,
            'isDarkMode': true,
            'appLockEnabled': false,
            'notificationDetectionEnabled': true,
            'paymentAppNotificationsEnabled': false,
            'showDetectionNotifications': true,
            'reminderEnabled': false,
            'dailyReminderEnabled': false,
            'weeklyReminderEnabled': false,
            'reminderHour': 20,
            'reminderMinute': 0,
            'weeklyReminderWeekday': 1,
            'cardDueReminderEnabled': true,
            'pendingTransactionReminderEnabled': true,
            'settlementReminderEnabled': false,
            'smsDetectionEnabled': false,
            'smsBackfillEnabled': false,
            'smsBackfillDays': 7,
            'hasCompletedOnboarding': false,
          },
        ],
      },
    });

    final result = await importService.importBackupReplaceAll(minimal);
    expect(result.onboardingCompleted, false);

    final settings = await db.select(db.appSettings).get();
    expect(settings.length, 1);
  });

  test('CSV exports contain headers and rows', () async {
    await seedSampleData();

    final txCsv = await backupService.exportTransactionsCsv();
    final expensesCsv = await backupService.exportExpensesCsv();
    final cardsCsv = await backupService.exportCardsCsv();
    final accountsCsv = await backupService.exportAccountsCsv();

    expect(txCsv.contains('id,type,amount,title,category'), true);
    expect(txCsv.contains('Swiggy'), true);

    expect(expensesCsv.contains('id,type,amount,netAmount,title'), true);
    expect(expensesCsv.contains('Swiggy'), true);

    expect(cardsCsv.contains('id,bankName,nickname,last4,maskedNumber'), true);
    expect(cardsCsv.contains('ICICI'), true);

    expect(
      accountsCsv.contains('entityType,id,name,bankName,accountType,last4'),
      true,
    );
    expect(accountsCsv.contains('HDFC'), true);
    expect(accountsCsv.contains('7788'), true);
  });

  test('import/export normalizes and preserves recoverable fields', () async {
    final backupJson = jsonEncode({
      'app': 'Finarc',
      'backupVersion': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'schemaVersion': 16,
      'data': {
        'settings': [
          {
            'id': 1,
            'isDarkMode': true,
            'appLockEnabled': false,
            'notificationDetectionEnabled': true,
            'paymentAppNotificationsEnabled': false,
            'showDetectionNotifications': true,
            'reminderEnabled': false,
            'dailyReminderEnabled': false,
            'weeklyReminderEnabled': false,
            'reminderHour': 20,
            'reminderMinute': 0,
            'weeklyReminderWeekday': 1,
            'cardDueReminderEnabled': true,
            'pendingTransactionReminderEnabled': true,
            'settlementReminderEnabled': false,
            'smsDetectionEnabled': false,
            'smsBackfillEnabled': false,
            'smsBackfillDays': 7,
            'hasCompletedOnboarding': true,
          },
        ],
        'bankAccounts': [
          {
            'id': 1,
            'bankName': 'HDFC',
            'accountName': 'Main',
            'accountType': 'savings',
            'currentBalance': 10000,
          },
        ],
        'cashWallets': [],
        'creditCards': [],
        'transactions': [
          {
            'id': 1,
            'type': 'bank',
            'amount': 1000,
            'title': 'Legacy recoverable',
            'category': 'Food',
            'transactionDate': DateTime(2026, 5, 25).toIso8601String(),
            'paymentSourceType': 'bank',
            'paymentSourceId': 1,
            'cashbackAmount': 100,
            'isForOthers': true,
            'recoverableAmount': 300,
            'recoverableStatus': 'settled',
            'recoverablePartyName': 'Rahul',
            'confirmed': true,
          },
        ],
        'cardBills': [],
        'pendingTransactions': [],
        'splitGroups': [],
        'splitMembers': [],
        'splitExpenses': [],
        'splitExpenseShares': [],
        'splitSettlements': [],
        'loans': [],
        'loanPayments': [],
      },
    });

    await importService.importBackupReplaceAll(backupJson);
    final txn = await db.select(db.transactions).getSingle();
    expect(txn.recoverableBaseAmount, closeTo(300, 0.01));
    expect(txn.recoveredAmount, closeTo(300, 0.01));
    expect(txn.recoverableAmount, closeTo(0, 0.01));
    expect(txn.recoverableStatus, 'recovered');

    final exported = await backupService.createBackupJson();
    final decoded = jsonDecode(exported) as Map<String, dynamic>;
    final txns =
        (decoded['data'] as Map<String, dynamic>)['transactions'] as List;
    final row = txns.first as Map<String, dynamic>;
    expect(row['recoverableBaseAmount'], closeTo(300, 0.01));
    expect(row['recoveredAmount'], closeTo(300, 0.01));
    expect(row['recoverableAmount'], closeTo(0, 0.01));
  });
}
