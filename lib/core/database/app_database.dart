import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class BankAccounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get bankName => text()();
  TextColumn get accountName => text()();
  TextColumn get accountType => text()();
  RealColumn get currentBalance => real().withDefault(const Constant(0))();
  TextColumn get colorOrIcon => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class CashWallets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get walletName => text()();
  RealColumn get currentBalance => real().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class CreditCards extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get bankName => text()();
  TextColumn get nickname => text()();
  TextColumn get last4 => text().withLength(min: 4, max: 4)();
  TextColumn get maskedNumber => text()();
  RealColumn get creditLimit => real()();
  IntColumn get billingDay => integer()();
  IntColumn get dueDay => integer()();
  RealColumn get currentOutstanding => real().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()();
  RealColumn get amount => real()();
  TextColumn get title => text()();
  TextColumn get category => text()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get transactionDate => dateTime()();
  TextColumn get paymentSourceType => text()();
  IntColumn get paymentSourceId => integer()();
  RealColumn get cashbackAmount => real().withDefault(const Constant(0))();
  BoolColumn get isForOthers => boolean().withDefault(const Constant(false))();
  RealColumn get recoverableAmount => real().nullable()();
  BoolColumn get confirmed => boolean().withDefault(const Constant(true))();
  TextColumn get detectedSourceType => text().nullable()();
  IntColumn get cardBillId => integer().nullable()();
  TextColumn get transferGroupId => text().nullable()();
  IntColumn get sourceAccountId => integer().nullable()();
  IntColumn get destinationAccountId => integer().nullable()();
  IntColumn get linkedSplitExpenseId => integer().nullable()();
  RealColumn get personalShareAmount => real().nullable()();
  IntColumn get splitGroupId => integer().nullable()();
  TextColumn get transactionImpactType => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class PendingTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  TextColumn get merchant => text()();
  TextColumn get categorySuggestion => text()();
  TextColumn get paymentSourceTypeSuggestion => text()();
  IntColumn get paymentSourceIdSuggestion => integer().nullable()();
  DateTimeColumn get detectedAt => dateTime()();
  DateTimeColumn get transactionDate => dateTime()();
  TextColumn get sourceType => text()();
  TextColumn get rawText => text()();
  RealColumn get confidenceScore => real()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  RealColumn get cashbackAmount => real().nullable()();
  BoolColumn get isForOthers => boolean().withDefault(const Constant(false))();
  RealColumn get recoverableAmount => real().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get duplicateOfTransactionId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class CardBills extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cardId => integer()();
  DateTimeColumn get cycleStartDate =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get cycleEndDate =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get billingDate =>
      dateTime().withDefault(currentDateAndTime)();
  RealColumn get billedAmount => real()();
  RealColumn get paidAmount => real().withDefault(const Constant(0))();
  DateTimeColumn get dueDate => dateTime().withDefault(currentDateAndTime)();
  TextColumn get status => text().withDefault(const Constant('upcoming'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get paidAt => dateTime().nullable()();
}

class SplitGroups extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get archivedAt => dateTime().nullable()();
}

class SplitMembers extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get groupId => integer()();
  TextColumn get name => text()();
  TextColumn get contact => text().nullable()();
  BoolColumn get isCurrentUser =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class SplitExpenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get groupId => integer()();
  TextColumn get title => text()();
  RealColumn get totalAmount => real()();
  IntColumn get paidByMemberId => integer()();
  TextColumn get splitType => text()();
  DateTimeColumn get expenseDate => dateTime()();
  TextColumn get category => text()();
  TextColumn get notes => text().nullable()();
  IntColumn get linkedTransactionId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class SplitExpenseShares extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get splitExpenseId => integer()();
  IntColumn get memberId => integer()();
  RealColumn get percentage => real().nullable()();
  RealColumn get exactAmount => real()();
  BoolColumn get isSettled => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class SplitSettlements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get groupId => integer()();
  IntColumn get fromMemberId => integer()();
  IntColumn get toMemberId => integer()();
  RealColumn get amount => real()();
  TextColumn get paymentSourceType => text().nullable()();
  IntColumn get paymentSourceId => integer().nullable()();
  DateTimeColumn get settlementDate => dateTime()();
  IntColumn get linkedTransactionId => integer().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Loans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get lenderName => text()();
  TextColumn get loanType => text().withDefault(const Constant('other'))();
  RealColumn get principalAmount => real()();
  RealColumn get currentOutstanding => real()();
  RealColumn get interestRate => real().nullable()();
  RealColumn get emiAmount => real().nullable()();
  IntColumn get emiDay => integer().nullable()();
  IntColumn get tenureMonths => integer().nullable()();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();
  IntColumn get linkedAccountId => integer().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get closedAt => dateTime().nullable()();
}

class LoanPayments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get loanId => integer()();
  RealColumn get amount => real()();
  DateTimeColumn get paymentDate => dateTime()();
  TextColumn get paymentSourceType => text().nullable()();
  IntColumn get paymentSourceId => integer().nullable()();
  IntColumn get linkedTransactionId => integer().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Alerts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get alertType => text()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get scheduledAt => dateTime().nullable()();
  TextColumn get priority => text().withDefault(const Constant('info'))();
  DateTimeColumn get readAt => dateTime().nullable()();
  TextColumn get actionRoute => text().nullable()();
  TextColumn get payload => text().nullable()();
  DateTimeColumn get dismissedAt => dateTime().nullable()();
  TextColumn get dedupeKey => text().nullable()();
}

class AppSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  BoolColumn get isDarkMode => boolean().withDefault(const Constant(false))();
  BoolColumn get appLockEnabled =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get notificationDetectionEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get showDetectionNotifications =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get reminderEnabled =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get dailyReminderEnabled =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get weeklyReminderEnabled =>
      boolean().withDefault(const Constant(false))();
  IntColumn get reminderHour => integer().withDefault(const Constant(20))();
  IntColumn get reminderMinute => integer().withDefault(const Constant(0))();
  IntColumn get weeklyReminderWeekday =>
      integer().withDefault(const Constant(DateTime.monday))();
  BoolColumn get cardDueReminderEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get pendingTransactionReminderEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get settlementReminderEnabled =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastReminderShownAt => dateTime().nullable()();
  BoolColumn get smsDetectionEnabled =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get smsPermissionAskedAt => dateTime().nullable()();
  BoolColumn get smsBackfillEnabled =>
      boolean().withDefault(const Constant(false))();
  IntColumn get smsBackfillDays => integer().withDefault(const Constant(7))();
  DateTimeColumn get smsLastScannedAt => dateTime().nullable()();
  BoolColumn get hasCompletedOnboarding =>
      boolean().withDefault(const Constant(false))();
  IntColumn get quietHoursStartHour =>
      integer().withDefault(const Constant(22))();
  IntColumn get quietHoursStartMinute =>
      integer().withDefault(const Constant(0))();
  IntColumn get quietHoursEndHour => integer().withDefault(const Constant(7))();
  IntColumn get quietHoursEndMinute =>
      integer().withDefault(const Constant(0))();
  BoolColumn get smartAlertsEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get lowBalanceAlertsEnabled =>
      boolean().withDefault(const Constant(true))();
  RealColumn get lowBalanceThreshold =>
      real().withDefault(const Constant(2000))();
  BoolColumn get largeExpenseAlertsEnabled =>
      boolean().withDefault(const Constant(true))();
  RealColumn get largeExpenseThreshold =>
      real().withDefault(const Constant(10000))();
  BoolColumn get unusualSpendingAlertsEnabled =>
      boolean().withDefault(const Constant(true))();
  RealColumn get unusualSpendingMultiplier =>
      real().withDefault(const Constant(1.8))();
  BoolColumn get recurringMerchantAlertsEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get weeklySummaryAlertsEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get monthlySummaryAlertsEnabled =>
      boolean().withDefault(const Constant(true))();
  TextColumn get userName => text().nullable()();
  RealColumn get monthlySalary => real().nullable()();
  IntColumn get salaryCreditDay => integer().nullable()();
  TextColumn get companyName => text().nullable()();
}

@DriftDatabase(
  tables: [
    BankAccounts,
    CashWallets,
    CreditCards,
    Transactions,
    PendingTransactions,
    CardBills,
    SplitGroups,
    SplitMembers,
    SplitExpenses,
    SplitExpenseShares,
    SplitSettlements,
    Loans,
    LoanPayments,
    Alerts,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 12;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(transactions, transactions.cardBillId);
        await m.addColumn(cardBills, cardBills.cycleStartDate);
        await m.addColumn(cardBills, cardBills.cycleEndDate);
        await m.addColumn(cardBills, cardBills.billingDate);
        await m.addColumn(cardBills, cardBills.status);
        await m.addColumn(cardBills, cardBills.createdAt);
        await m.addColumn(cardBills, cardBills.paidAt);
      }
      if (from < 3) {
        // Phase 3 introduces a redesigned transactions model and cash wallets.
        await m.createTable(cashWallets);
        await m.deleteTable('transactions');
        await m.createTable(transactions);
      }
      if (from < 4) {
        await m.addColumn(transactions, transactions.detectedSourceType);
        await m.createTable(pendingTransactions);
      }
      if (from < 5) {
        await m.deleteTable('bank_accounts');
        await m.createTable(bankAccounts);
        await m.deleteTable('cash_wallets');
        await m.createTable(cashWallets);
        await m.addColumn(transactions, transactions.transferGroupId);
        await m.addColumn(transactions, transactions.sourceAccountId);
        await m.addColumn(transactions, transactions.destinationAccountId);
      }
      if (from < 6) {
        await m.addColumn(
          appSettings,
          appSettings.notificationDetectionEnabled,
        );
        await m.addColumn(appSettings, appSettings.showDetectionNotifications);
        await m.addColumn(appSettings, appSettings.reminderEnabled);
        await m.addColumn(appSettings, appSettings.dailyReminderEnabled);
        await m.addColumn(appSettings, appSettings.weeklyReminderEnabled);
        await m.addColumn(appSettings, appSettings.reminderHour);
        await m.addColumn(appSettings, appSettings.reminderMinute);
        await m.addColumn(appSettings, appSettings.weeklyReminderWeekday);
        await m.addColumn(appSettings, appSettings.cardDueReminderEnabled);
        await m.addColumn(
          appSettings,
          appSettings.pendingTransactionReminderEnabled,
        );
        await m.addColumn(appSettings, appSettings.settlementReminderEnabled);
        await m.addColumn(appSettings, appSettings.lastReminderShownAt);
      }
      if (from < 7) {
        await m.addColumn(appSettings, appSettings.smsDetectionEnabled);
        await m.addColumn(appSettings, appSettings.smsPermissionAskedAt);
        await m.addColumn(appSettings, appSettings.smsBackfillEnabled);
        await m.addColumn(appSettings, appSettings.smsBackfillDays);
        await m.addColumn(appSettings, appSettings.smsLastScannedAt);
      }
      if (from < 8) {
        await m.addColumn(transactions, transactions.linkedSplitExpenseId);
        await m.addColumn(transactions, transactions.personalShareAmount);
        await m.addColumn(transactions, transactions.splitGroupId);
        await m.addColumn(transactions, transactions.transactionImpactType);

        await m.deleteTable('split_expenses');
        await m.deleteTable('split_members');
        await m.deleteTable('split_groups');
        await m.createTable(splitGroups);
        await m.createTable(splitMembers);
        await m.createTable(splitExpenses);
        await m.createTable(splitExpenseShares);
        await m.createTable(splitSettlements);
      }
      if (from < 9) {
        await m.addColumn(appSettings, appSettings.hasCompletedOnboarding);
      }
      if (from < 10) {
        final hasOldLoans = await customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'loans'",
        ).get();

        if (hasOldLoans.isNotEmpty) {
          await customStatement('ALTER TABLE loans RENAME TO loans_old');
          await m.createTable(loans);
          await customStatement('''
            INSERT INTO loans (
              id,
              title,
              lender_name,
              loan_type,
              principal_amount,
              current_outstanding,
              created_at,
              updated_at
            )
            SELECT
              id,
              lender_or_borrower,
              lender_or_borrower,
              CASE WHEN is_borrowed = 1 THEN 'personal' ELSE 'other' END,
              outstanding_amount,
              outstanding_amount,
              CURRENT_TIMESTAMP,
              CURRENT_TIMESTAMP
            FROM loans_old
          ''');
          await customStatement('DROP TABLE loans_old');
        } else {
          await m.createTable(loans);
        }

        final hasLoanPayments = await customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'loan_payments'",
        ).get();
        if (hasLoanPayments.isEmpty) {
          await m.createTable(loanPayments);
        }
      }
      if (from < 11) {
        await m.createTable(alerts);
        await m.addColumn(appSettings, appSettings.quietHoursStartHour);
        await m.addColumn(appSettings, appSettings.quietHoursStartMinute);
        await m.addColumn(appSettings, appSettings.quietHoursEndHour);
        await m.addColumn(appSettings, appSettings.quietHoursEndMinute);
        await m.addColumn(appSettings, appSettings.smartAlertsEnabled);
        await m.addColumn(appSettings, appSettings.lowBalanceAlertsEnabled);
        await m.addColumn(appSettings, appSettings.lowBalanceThreshold);
        await m.addColumn(appSettings, appSettings.largeExpenseAlertsEnabled);
        await m.addColumn(appSettings, appSettings.largeExpenseThreshold);
        await m.addColumn(
          appSettings,
          appSettings.unusualSpendingAlertsEnabled,
        );
        await m.addColumn(appSettings, appSettings.unusualSpendingMultiplier);
        await m.addColumn(
          appSettings,
          appSettings.recurringMerchantAlertsEnabled,
        );
        await m.addColumn(appSettings, appSettings.weeklySummaryAlertsEnabled);
        await m.addColumn(appSettings, appSettings.monthlySummaryAlertsEnabled);
      }
      if (from < 12) {
        await m.addColumn(appSettings, appSettings.userName);
        await m.addColumn(appSettings, appSettings.monthlySalary);
        await m.addColumn(appSettings, appSettings.salaryCreditDay);
        await m.addColumn(appSettings, appSettings.companyName);
      }
    },
  );

  Future<void> seedIfEmpty() async {
    final settings = await (select(appSettings)..limit(1)).getSingleOrNull();
    if (settings == null) {
      await into(
        appSettings,
      ).insert(AppSettingsCompanion.insert(isDarkMode: const Value(true)));
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'finarc.db'));
    return NativeDatabase.createInBackground(file);
  });
}
