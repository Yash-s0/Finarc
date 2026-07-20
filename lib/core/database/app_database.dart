import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../logging/app_log_service.dart';

part 'app_database.g.dart';

class BankAccounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get bankName => text()();
  TextColumn get accountName => text()();
  TextColumn get accountType => text()();
  TextColumn get last4 => text().withLength(min: 4, max: 4).nullable()();
  RealColumn get currentBalance => real().withDefault(const Constant(0))();
  TextColumn get colorOrIcon => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class CashWallets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get walletName => text()();
  TextColumn get walletType => text().withDefault(const Constant('cash'))();
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
  TextColumn get network => text().withDefault(const Constant('visa'))();
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
  RealColumn get recoverableBaseAmount => real().nullable()();
  RealColumn get recoveredAmount => real().withDefault(const Constant(0))();
  TextColumn get recoverablePartyName => text().nullable()();
  TextColumn get recoverablePartyNotes => text().nullable()();
  TextColumn get recoverablePartyPhone => text().nullable()();
  TextColumn get recoverableStatus =>
      text().withDefault(const Constant('unpaid'))();
  DateTimeColumn get recoveredAt => dateTime().nullable()();
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
  TextColumn get cashbackDestinationType => text().nullable()();
  IntColumn get cashbackDestinationId => integer().nullable()();
  IntColumn get relatedTransactionId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class TransactionSourceEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transactionId => integer().nullable()();
  TextColumn get sourceType => text()();
  TextColumn get sourceFingerprint => text()();
  TextColumn get status => text()();
  TextColumn get sender => text().nullable()();
  DateTimeColumn get sourceReceivedAt => dateTime().nullable()();
  TextColumn get parserName => text().nullable()();
  RealColumn get amount => real().nullable()();
  TextColumn get merchant => text().nullable()();
  DateTimeColumn get transactionDate => dateTime().nullable()();
  TextColumn get rawText => text()();
  TextColumn get metaJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {sourceFingerprint},
  ];
}

class MissedMessageSamples extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get fingerprint => text()();
  TextColumn get sampleType => text()();
  TextColumn get sourceType => text()();
  TextColumn get packageName => text()();
  TextColumn get sender => text().nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get sampleText => text()();
  TextColumn get decision => text()();
  TextColumn get reason => text()();
  TextColumn get parseResult => text()();
  TextColumn get providerName => text().nullable()();
  RealColumn get confidenceScore => real().nullable()();
  TextColumn get confidenceLevel => text().nullable()();
  IntColumn get candidateCount => integer().nullable()();
  TextColumn get amountCandidate => text().nullable()();
  TextColumn get blockedContext => text().nullable()();
  TextColumn get duplicateDecision => text().nullable()();
  TextColumn get possibleDuplicateReason => text().nullable()();
  DateTimeColumn get transactionDateChosen => dateTime().nullable()();
  IntColumn get createdPendingCount =>
      integer().withDefault(const Constant(0))();
  IntColumn get seenCount => integer().withDefault(const Constant(1))();
  DateTimeColumn get lastSeenAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {fingerprint},
  ];
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
  RealColumn get recoverableBaseAmount => real().nullable()();
  RealColumn get recoveredAmount => real().withDefault(const Constant(0))();
  TextColumn get recoverablePartyName => text().nullable()();
  TextColumn get recoverablePartyNotes => text().nullable()();
  TextColumn get recoverablePartyPhone => text().nullable()();
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
  TextColumn get lenderType => text().nullable()();
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
  BoolColumn get paymentAppNotificationsEnabled =>
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
    TransactionSourceEvents,
    MissedMessageSamples,
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
  int get schemaVersion => 25;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => m.createAll(),
    onUpgrade: (m, from, to) async {
      await globalAppLogService.log(
        category: 'migration',
        message: 'starting-upgrade',
        meta: <String, Object?>{'from': from, 'to': to},
      );
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
      if (from < 13) {
        await m.addColumn(transactions, transactions.recoverablePartyName);
        await m.addColumn(transactions, transactions.recoverablePartyNotes);
        await m.addColumn(transactions, transactions.recoverablePartyPhone);
        await m.addColumn(transactions, transactions.recoverableStatus);
        await m.addColumn(transactions, transactions.recoveredAt);
        await m.addColumn(
          pendingTransactions,
          pendingTransactions.recoverablePartyName,
        );
        await m.addColumn(
          pendingTransactions,
          pendingTransactions.recoverablePartyNotes,
        );
        await m.addColumn(
          pendingTransactions,
          pendingTransactions.recoverablePartyPhone,
        );
      }
      if (from < 14) {
        await _backfillCardOpeningBills();
      }
      if (from < 15) {
        await m.addColumn(transactions, transactions.recoverableBaseAmount);
        await m.addColumn(transactions, transactions.recoveredAmount);
        await m.addColumn(
          pendingTransactions,
          pendingTransactions.recoverableBaseAmount,
        );
        await m.addColumn(
          pendingTransactions,
          pendingTransactions.recoveredAmount,
        );
        await normalizeRecoverableDataBackfill();
      }
      if (from < 16) {
        await normalizeRecoverableDataBackfill();
      }
      if (from < 17) {
        await m.addColumn(transactions, transactions.cashbackDestinationType);
        await m.addColumn(transactions, transactions.cashbackDestinationId);
        await m.addColumn(transactions, transactions.relatedTransactionId);
      }
      if (from < 18) {
        await m.addColumn(bankAccounts, bankAccounts.last4);
      }
      if (from < 19) {
        await m.addColumn(loans, loans.lenderType);
      }
      if (from < 20) {
        await m.addColumn(cashWallets, cashWallets.walletType);
      }
      if (from < 21) {
        await m.addColumn(
          appSettings,
          appSettings.paymentAppNotificationsEnabled,
        );
      }
      if (from < 22) {
        await m.addColumn(creditCards, creditCards.network);
      }
      if (from < 23) {
        await customUpdate(
          'UPDATE app_settings '
          'SET payment_app_notifications_enabled = 1 '
          'WHERE notification_detection_enabled = 1',
        );
      }
      if (from < 24) {
        await m.createTable(transactionSourceEvents);
      }
      if (from < 25) {
        await m.createTable(missedMessageSamples);
      }
      await globalAppLogService.log(
        category: 'migration',
        message: 'upgrade-complete',
        meta: <String, Object?>{'from': from, 'to': to},
      );
    },
    beforeOpen: (details) async {
      await _healAppSettingsRows();
      await _healCriticalNullRows();
    },
  );

  Future<void> seedIfEmpty() async {
    await _healAppSettingsRows();
    await _healCriticalNullRows();
    final settings = await (select(appSettings)..limit(1)).getSingleOrNull();
    if (settings == null) {
      await into(
        appSettings,
      ).insert(AppSettingsCompanion.insert(isDarkMode: const Value(true)));
    }
  }

  Future<void> _healAppSettingsRows() async {
    final rows = await (select(appSettings)).get();
    if (rows.length <= 1) return;
    final sorted = [...rows]..sort((a, b) => a.id.compareTo(b.id));
    final survivor = sorted.first;
    final idsToDelete = sorted
        .skip(1)
        .map((row) => row.id)
        .toList(growable: false);
    await (delete(appSettings)..where((t) => t.id.isIn(idsToDelete))).go();
    await globalAppLogService.log(
      category: 'migration',
      message: 'healed-duplicate-settings',
      meta: <String, Object?>{
        'keptId': survivor.id,
        'deletedCount': idsToDelete.length,
      },
    );
  }

  Future<void> _healCriticalNullRows() async {
    final txnNullCount = await customSelect('''
SELECT COUNT(*) AS c
FROM transactions
WHERE recoverable_status IS NULL
   OR recovered_amount IS NULL
   OR cashback_amount IS NULL
   OR is_for_others IS NULL
   OR confirmed IS NULL
''').getSingle().then((r) => r.read<int>('c'));
    if (txnNullCount > 0) {
      await customStatement('''
UPDATE transactions
SET recoverable_status = COALESCE(recoverable_status, 'unpaid'),
    recovered_amount = COALESCE(recovered_amount, 0),
    cashback_amount = COALESCE(cashback_amount, 0),
    is_for_others = COALESCE(is_for_others, 0),
    confirmed = COALESCE(confirmed, 1)
WHERE recoverable_status IS NULL
   OR recovered_amount IS NULL
   OR cashback_amount IS NULL
   OR is_for_others IS NULL
   OR confirmed IS NULL
''');
      await globalAppLogService.log(
        category: 'migration',
        message: 'healed-transaction-nulls',
        meta: <String, Object?>{'rows': txnNullCount},
      );
    }

    final pendingNullCount = await customSelect('''
SELECT COUNT(*) AS c
FROM pending_transactions
WHERE recovered_amount IS NULL
''').getSingle().then((r) => r.read<int>('c'));
    if (pendingNullCount > 0) {
      await customStatement('''
UPDATE pending_transactions
SET recovered_amount = COALESCE(recovered_amount, 0)
WHERE recovered_amount IS NULL
''');
      await globalAppLogService.log(
        category: 'migration',
        message: 'healed-pending-nulls',
        meta: <String, Object?>{'rows': pendingNullCount},
      );
    }

    final billNullCount = await customSelect('''
SELECT COUNT(*) AS c
FROM card_bills
WHERE status IS NULL
   OR paid_amount IS NULL
''').getSingle().then((r) => r.read<int>('c'));
    if (billNullCount > 0) {
      await customStatement('''
UPDATE card_bills
SET status = COALESCE(status, 'upcoming'),
    paid_amount = COALESCE(paid_amount, 0)
WHERE status IS NULL
   OR paid_amount IS NULL
''');
      await globalAppLogService.log(
        category: 'migration',
        message: 'healed-card-bill-nulls',
        meta: <String, Object?>{'rows': billNullCount},
      );
    }
  }

  Future<void> _backfillCardOpeningBills() async {
    final cards = await select(creditCards).get();
    for (final card in cards) {
      final opening =
          await (select(cardBills)..where(
                (b) => b.cardId.equals(card.id) & b.status.equals('opening'),
              ))
              .getSingleOrNull();
      if (opening != null) continue;

      final bills =
          await (select(cardBills)..where(
                (b) => b.cardId.equals(card.id) & b.status.isNotValue('paid'),
              ))
              .get();
      final billedDue = bills.fold<double>(
        0,
        (sum, bill) =>
            sum +
            (bill.billedAmount - bill.paidAmount).clamp(0, bill.billedAmount),
      );

      final unbilledTransactions =
          await (select(transactions)..where(
                (t) =>
                    t.paymentSourceType.equals('creditCard') &
                    t.paymentSourceId.equals(card.id) &
                    (t.type.equals('creditCard') | t.type.equals('refund')) &
                    t.cardBillId.isNull(),
              ))
              .get();
      final unbilledSpends = unbilledTransactions.fold<double>(
        0,
        (sum, t) => sum + (t.type == 'refund' ? -t.amount : t.amount),
      );

      final representedOutstanding = billedDue + unbilledSpends;
      final delta = (card.currentOutstanding - representedOutstanding)
          .toDouble();
      if (delta <= 0.009) continue;

      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final dueDay = card.dueDay.clamp(1, 31);
      final dueDate = DateTime(todayDate.year, todayDate.month, dueDay);
      await into(cardBills).insert(
        CardBillsCompanion.insert(
          cardId: card.id,
          cycleStartDate: Value(todayDate),
          cycleEndDate: Value(todayDate),
          billingDate: Value(todayDate),
          dueDate: Value(
            dueDate.isAfter(todayDate)
                ? dueDate
                : DateTime(todayDate.year, todayDate.month + 1, dueDay),
          ),
          billedAmount: delta,
          status: const Value('opening'),
        ),
      );
    }
  }

  Future<void> normalizeRecoverableDataBackfill() async {
    const recoveredStatuses = {'recovered', 'settled', 'paid', 'complete'};
    const openStatuses = {
      'open',
      'pending',
      'unpaid',
      'partial',
      'unknown',
      'missing',
    };

    final txns = await select(transactions).get();
    for (final txn in txns) {
      final statusRaw = txn.recoverableStatus.trim().toLowerCase();
      final statusIsRecovered = recoveredStatuses.contains(statusRaw);
      final statusIsOpen = openStatuses.contains(statusRaw);
      final hasParty = (txn.recoverablePartyName?.trim().isNotEmpty ?? false);
      final hasRecoverableValues =
          (txn.recoverableBaseAmount ?? 0) > 0 ||
          (txn.recoverableAmount ?? 0) > 0 ||
          txn.recoveredAmount > 0;
      final isRecoverable =
          txn.isForOthers ||
          hasParty ||
          hasRecoverableValues ||
          statusIsRecovered;

      if (!isRecoverable) {
        await (update(transactions)..where((t) => t.id.equals(txn.id))).write(
          const TransactionsCompanion(
            recoverableBaseAmount: Value(null),
            recoveredAmount: Value(0),
            recoverableAmount: Value(null),
            recoverableStatus: Value('unpaid'),
            recoveredAt: Value(null),
          ),
        );
        continue;
      }

      final legacyLike =
          txn.recoverableBaseAmount == null ||
          statusIsRecovered ||
          statusIsOpen;
      final baseFromLegacyAmount = (txn.recoverableAmount ?? 0) > 0
          ? txn.recoverableAmount
          : null;
      final base = (baseFromLegacyAmount ?? (txn.amount - txn.cashbackAmount))
          .clamp(0, txn.amount)
          .toDouble();
      final recovered =
          (legacyLike ? (statusIsRecovered ? base : 0) : txn.recoveredAmount)
              .clamp(0, base)
              .toDouble();
      final remaining = (base - recovered).clamp(0, base).toDouble();
      final nextStatus = recovered <= 0.009
          ? 'unpaid'
          : recovered >= base - 0.009
          ? 'recovered'
          : 'partial';

      await (update(transactions)..where((t) => t.id.equals(txn.id))).write(
        TransactionsCompanion(
          recoverableBaseAmount: Value(base),
          recoveredAmount: Value(recovered),
          recoverableAmount: Value(remaining),
          recoverableStatus: Value(nextStatus),
          recoveredAt: Value(
            recovered > 0 ? (txn.recoveredAt ?? DateTime.now()) : null,
          ),
        ),
      );
    }

    final pending = await select(pendingTransactions).get();
    for (final row in pending) {
      final hasParty = (row.recoverablePartyName?.trim().isNotEmpty ?? false);
      final hasRecoverableValues =
          (row.recoverableBaseAmount ?? 0) > 0 ||
          (row.recoverableAmount ?? 0) > 0 ||
          row.recoveredAmount > 0;
      final isRecoverable = row.isForOthers || hasParty || hasRecoverableValues;
      final baseFromLegacyAmount = (row.recoverableAmount ?? 0) > 0
          ? row.recoverableAmount
          : null;
      final base = isRecoverable
          ? (baseFromLegacyAmount ?? (row.amount - (row.cashbackAmount ?? 0)))
                .clamp(0, row.amount)
                .toDouble()
          : 0.0;
      final recovered = isRecoverable
          ? row.recoveredAmount.clamp(0, base).toDouble()
          : 0.0;
      final remaining = isRecoverable
          ? (base - recovered).clamp(0, base).toDouble()
          : 0.0;
      await (update(
        pendingTransactions,
      )..where((p) => p.id.equals(row.id))).write(
        PendingTransactionsCompanion(
          recoverableBaseAmount: Value(isRecoverable ? base : null),
          recoveredAmount: Value(recovered),
          recoverableAmount: Value(isRecoverable ? remaining : null),
        ),
      );
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
