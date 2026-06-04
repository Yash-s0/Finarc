import 'dart:convert';
import 'dart:io';

import '../app_database.dart';
import 'backup_models.dart';

class BackupService {
  const BackupService(this._db);

  final AppDatabase _db;

  static const String appName = 'Finarc';
  static const int backupVersion = 1;

  Future<String> createBackupJson({String? deviceNote}) async {
    final settings = await _db.select(_db.appSettings).get();
    final bankAccounts = await _db.select(_db.bankAccounts).get();
    final cashWallets = await _db.select(_db.cashWallets).get();
    final creditCards = await _db.select(_db.creditCards).get();
    final transactions = await _db.select(_db.transactions).get();
    final cardBills = await _db.select(_db.cardBills).get();
    final pendingTransactions = await _db.select(_db.pendingTransactions).get();
    final splitGroups = await _db.select(_db.splitGroups).get();
    final splitMembers = await _db.select(_db.splitMembers).get();
    final splitExpenses = await _db.select(_db.splitExpenses).get();
    final splitExpenseShares = await _db.select(_db.splitExpenseShares).get();
    final splitSettlements = await _db.select(_db.splitSettlements).get();
    final loans = await _db.select(_db.loans).get();
    final loanPayments = await _db.select(_db.loanPayments).get();

    final manifest = BackupManifest(
      app: appName,
      backupVersion: backupVersion,
      createdAt: DateTime.now(),
      schemaVersion: _db.schemaVersion,
      deviceNote: deviceNote,
      data: BackupData(
        settings: settings.map(_mapAppSetting).toList(growable: false),
        bankAccounts: bankAccounts.map(_mapBankAccount).toList(growable: false),
        cashWallets: cashWallets.map(_mapCashWallet).toList(growable: false),
        creditCards: creditCards.map(_mapCreditCard).toList(growable: false),
        transactions: transactions.map(_mapTransaction).toList(growable: false),
        cardBills: cardBills.map(_mapCardBill).toList(growable: false),
        pendingTransactions: pendingTransactions
            .map(_mapPendingTransaction)
            .toList(growable: false),
        splitGroups: splitGroups.map(_mapSplitGroup).toList(growable: false),
        splitMembers: splitMembers.map(_mapSplitMember).toList(growable: false),
        splitExpenses: splitExpenses
            .map(_mapSplitExpense)
            .toList(growable: false),
        splitExpenseShares: splitExpenseShares
            .map(_mapSplitExpenseShare)
            .toList(growable: false),
        splitSettlements: splitSettlements
            .map(_mapSplitSettlement)
            .toList(growable: false),
        loans: loans.map(_mapLoan).toList(growable: false),
        loanPayments: loanPayments.map(_mapLoanPayment).toList(growable: false),
      ),
    );

    return const JsonEncoder.withIndent('  ').convert(manifest.toJson());
  }

  Future<File> exportBackupToFile({
    required String filePath,
    String? deviceNote,
  }) async {
    final content = await createBackupJson(deviceNote: deviceNote);
    return writeStringToFile(filePath: filePath, content: content);
  }

  Future<String> exportTransactionsCsv() async {
    final rows = await _db.select(_db.transactions).get();
    final headers = [
      'id',
      'type',
      'amount',
      'title',
      'category',
      'notes',
      'transactionDate',
      'paymentSourceType',
      'paymentSourceId',
      'cashbackAmount',
      'isForOthers',
      'recoverableAmount',
      'recoverableBaseAmount',
      'recoveredAmount',
      'recoverablePartyName',
      'recoverablePartyNotes',
      'recoverablePartyPhone',
      'recoverableStatus',
      'recoveredAt',
      'confirmed',
      'detectedSourceType',
      'cardBillId',
      'transferGroupId',
      'sourceAccountId',
      'destinationAccountId',
      'linkedSplitExpenseId',
      'personalShareAmount',
      'splitGroupId',
      'transactionImpactType',
      'cashbackDestinationType',
      'cashbackDestinationId',
      'relatedTransactionId',
      'createdAt',
      'updatedAt',
    ];

    final csvRows = rows.map((row) {
      final normalizedRecoverable = _normalizeRecoverableAmounts(
        isForOthers: row.isForOthers,
        amount: row.amount,
        cashbackAmount: row.cashbackAmount,
        recoverableAmount: row.recoverableAmount,
        recoverableBaseAmount: row.recoverableBaseAmount,
        recoveredAmount: row.recoveredAmount,
      );
      return [
        row.id,
        row.type,
        row.amount,
        row.title,
        row.category,
        row.notes,
        _iso(row.transactionDate),
        row.paymentSourceType,
        row.paymentSourceId,
        row.cashbackAmount,
        row.isForOthers,
        normalizedRecoverable.remaining,
        normalizedRecoverable.base,
        normalizedRecoverable.recovered,
        row.recoverablePartyName,
        row.recoverablePartyNotes,
        row.recoverablePartyPhone,
        row.recoverableStatus,
        _iso(row.recoveredAt),
        row.confirmed,
        row.detectedSourceType,
        row.cardBillId,
        row.transferGroupId,
        row.sourceAccountId,
        row.destinationAccountId,
        row.linkedSplitExpenseId,
        row.personalShareAmount,
        row.splitGroupId,
        row.transactionImpactType,
        row.cashbackDestinationType,
        row.cashbackDestinationId,
        row.relatedTransactionId,
        _iso(row.createdAt),
        _iso(row.updatedAt),
      ];
    });

    return _toCsv(headers, csvRows);
  }

  Future<String> exportExpensesCsv() async {
    final rows = await _db.select(_db.transactions).get();
    final headers = [
      'id',
      'type',
      'amount',
      'netAmount',
      'title',
      'category',
      'paymentSourceType',
      'paymentSourceId',
      'isForOthers',
      'recoverableAmount',
      'recoverableBaseAmount',
      'recoveredAmount',
      'recoverablePartyName',
      'recoverablePartyNotes',
      'recoverablePartyPhone',
      'cashbackAmount',
      'transactionDate',
    ];

    final csvRows = rows
        .where((row) {
          return row.type != 'transfer' && row.type != 'cardPayment';
        })
        .map((row) {
          final normalizedRecoverable = _normalizeRecoverableAmounts(
            isForOthers: row.isForOthers,
            amount: row.amount,
            cashbackAmount: row.cashbackAmount,
            recoverableAmount: row.recoverableAmount,
            recoverableBaseAmount: row.recoverableBaseAmount,
            recoveredAmount: row.recoveredAmount,
          );
          final netAmount = (row.amount - row.cashbackAmount).clamp(
            0,
            double.infinity,
          );
          return [
            row.id,
            row.type,
            row.amount,
            netAmount,
            row.title,
            row.category,
            row.paymentSourceType,
            row.paymentSourceId,
            row.isForOthers,
            normalizedRecoverable.remaining,
            normalizedRecoverable.base,
            normalizedRecoverable.recovered,
            row.recoverablePartyName,
            row.recoverablePartyNotes,
            row.recoverablePartyPhone,
            row.cashbackAmount,
            _iso(row.transactionDate),
          ];
        });

    return _toCsv(headers, csvRows);
  }

  Future<String> exportCardsCsv() async {
    final cards = await _db.select(_db.creditCards).get();
    final headers = [
      'id',
      'bankName',
      'nickname',
      'last4',
      'maskedNumber',
      'creditLimit',
      'billingDay',
      'dueDay',
      'currentOutstanding',
      'createdAt',
      'updatedAt',
    ];

    final csvRows = cards.map((row) {
      return [
        row.id,
        row.bankName,
        row.nickname,
        row.last4,
        row.maskedNumber,
        row.creditLimit,
        row.billingDay,
        row.dueDay,
        row.currentOutstanding,
        _iso(row.createdAt),
        _iso(row.updatedAt),
      ];
    });

    return _toCsv(headers, csvRows);
  }

  Future<String> exportAccountsCsv() async {
    final banks = await _db.select(_db.bankAccounts).get();
    final wallets = await _db.select(_db.cashWallets).get();

    final headers = [
      'entityType',
      'id',
      'name',
      'bankName',
      'accountType',
      'last4',
      'currentBalance',
      'colorOrIcon',
      'createdAt',
      'updatedAt',
    ];

    final bankRows = banks.map((row) {
      return [
        'bank',
        row.id,
        row.accountName,
        row.bankName,
        row.accountType,
        row.last4,
        row.currentBalance,
        row.colorOrIcon,
        _iso(row.createdAt),
        _iso(row.updatedAt),
      ];
    });

    final walletRows = wallets.map((row) {
      return [
        'cashWallet',
        row.id,
        row.walletName,
        null,
        'cash',
        row.currentBalance,
        null,
        _iso(row.createdAt),
        _iso(row.updatedAt),
      ];
    });

    return _toCsv(headers, [...bankRows, ...walletRows]);
  }

  Future<File> writeStringToFile({
    required String filePath,
    required String content,
  }) async {
    final file = File(filePath);
    await file.parent.create(recursive: true);
    return file.writeAsString(content, flush: true);
  }

  static String _toCsv(List<String> headers, Iterable<List<Object?>> rows) {
    final lines = <String>[];
    lines.add(headers.map(_csvCell).join(','));
    for (final row in rows) {
      lines.add(row.map(_csvCell).join(','));
    }
    return lines.join('\n');
  }

  static String _csvCell(Object? value) {
    final text = value == null ? '' : '$value';
    final escaped = text.replaceAll('"', '""');
    final needsQuotes =
        escaped.contains(',') ||
        escaped.contains('"') ||
        escaped.contains('\n') ||
        escaped.contains('\r');
    return needsQuotes ? '"$escaped"' : escaped;
  }

  static String _iso(DateTime? value) => value?.toIso8601String() ?? '';

  static Map<String, dynamic> _mapAppSetting(AppSetting row) => {
    'id': row.id,
    'isDarkMode': row.isDarkMode,
    'appLockEnabled': row.appLockEnabled,
    'notificationDetectionEnabled': row.notificationDetectionEnabled,
    'showDetectionNotifications': row.showDetectionNotifications,
    'reminderEnabled': row.reminderEnabled,
    'dailyReminderEnabled': row.dailyReminderEnabled,
    'weeklyReminderEnabled': row.weeklyReminderEnabled,
    'reminderHour': row.reminderHour,
    'reminderMinute': row.reminderMinute,
    'weeklyReminderWeekday': row.weeklyReminderWeekday,
    'cardDueReminderEnabled': row.cardDueReminderEnabled,
    'pendingTransactionReminderEnabled': row.pendingTransactionReminderEnabled,
    'settlementReminderEnabled': row.settlementReminderEnabled,
    'lastReminderShownAt': _iso(row.lastReminderShownAt),
    'smsDetectionEnabled': row.smsDetectionEnabled,
    'smsPermissionAskedAt': _iso(row.smsPermissionAskedAt),
    'smsBackfillEnabled': row.smsBackfillEnabled,
    'smsBackfillDays': row.smsBackfillDays,
    'smsLastScannedAt': _iso(row.smsLastScannedAt),
    'hasCompletedOnboarding': row.hasCompletedOnboarding,
  };

  static Map<String, dynamic> _mapBankAccount(BankAccount row) => {
    'id': row.id,
    'bankName': row.bankName,
    'accountName': row.accountName,
    'accountType': row.accountType,
    'last4': row.last4,
    'currentBalance': row.currentBalance,
    'colorOrIcon': row.colorOrIcon,
    'createdAt': _iso(row.createdAt),
    'updatedAt': _iso(row.updatedAt),
  };

  static Map<String, dynamic> _mapCashWallet(CashWallet row) => {
    'id': row.id,
    'walletName': row.walletName,
    'currentBalance': row.currentBalance,
    'createdAt': _iso(row.createdAt),
    'updatedAt': _iso(row.updatedAt),
  };

  static Map<String, dynamic> _mapCreditCard(CreditCard row) => {
    'id': row.id,
    'bankName': row.bankName,
    'nickname': row.nickname,
    'last4': row.last4,
    'maskedNumber': row.maskedNumber,
    'creditLimit': row.creditLimit,
    'billingDay': row.billingDay,
    'dueDay': row.dueDay,
    'currentOutstanding': row.currentOutstanding,
    'createdAt': _iso(row.createdAt),
    'updatedAt': _iso(row.updatedAt),
  };

  static Map<String, dynamic> _mapTransaction(Transaction row) {
    final normalizedRecoverable = _normalizeRecoverableAmounts(
      isForOthers: row.isForOthers,
      amount: row.amount,
      cashbackAmount: row.cashbackAmount,
      recoverableAmount: row.recoverableAmount,
      recoverableBaseAmount: row.recoverableBaseAmount,
      recoveredAmount: row.recoveredAmount,
    );
    return {
      'id': row.id,
      'type': row.type,
      'amount': row.amount,
      'title': row.title,
      'category': row.category,
      'notes': row.notes,
      'transactionDate': _iso(row.transactionDate),
      'paymentSourceType': row.paymentSourceType,
      'paymentSourceId': row.paymentSourceId,
      'cashbackAmount': row.cashbackAmount,
      'isForOthers': row.isForOthers,
      'recoverableAmount': normalizedRecoverable.remaining,
      'recoverableBaseAmount': normalizedRecoverable.base,
      'recoveredAmount': normalizedRecoverable.recovered,
      'recoverablePartyName': row.recoverablePartyName,
      'recoverablePartyNotes': row.recoverablePartyNotes,
      'recoverablePartyPhone': row.recoverablePartyPhone,
      'recoverableStatus': row.recoverableStatus,
      'recoveredAt': _iso(row.recoveredAt),
      'confirmed': row.confirmed,
      'detectedSourceType': row.detectedSourceType,
      'cardBillId': row.cardBillId,
      'transferGroupId': row.transferGroupId,
      'sourceAccountId': row.sourceAccountId,
      'destinationAccountId': row.destinationAccountId,
      'linkedSplitExpenseId': row.linkedSplitExpenseId,
      'personalShareAmount': row.personalShareAmount,
      'splitGroupId': row.splitGroupId,
      'transactionImpactType': row.transactionImpactType,
      'cashbackDestinationType': row.cashbackDestinationType,
      'cashbackDestinationId': row.cashbackDestinationId,
      'relatedTransactionId': row.relatedTransactionId,
      'createdAt': _iso(row.createdAt),
      'updatedAt': _iso(row.updatedAt),
    };
  }

  static Map<String, dynamic> _mapCardBill(CardBill row) => {
    'id': row.id,
    'cardId': row.cardId,
    'cycleStartDate': _iso(row.cycleStartDate),
    'cycleEndDate': _iso(row.cycleEndDate),
    'billingDate': _iso(row.billingDate),
    'dueDate': _iso(row.dueDate),
    'billedAmount': row.billedAmount,
    'paidAmount': row.paidAmount,
    'status': row.status,
    'createdAt': _iso(row.createdAt),
    'paidAt': _iso(row.paidAt),
  };

  static Map<String, dynamic> _mapPendingTransaction(PendingTransaction row) =>
      () {
        final normalizedRecoverable = _normalizeRecoverableAmounts(
          isForOthers: row.isForOthers,
          amount: row.amount,
          cashbackAmount: row.cashbackAmount ?? 0,
          recoverableAmount: row.recoverableAmount,
          recoverableBaseAmount: row.recoverableBaseAmount,
          recoveredAmount: row.recoveredAmount,
        );
        return {
          'id': row.id,
          'amount': row.amount,
          'merchant': row.merchant,
          'categorySuggestion': row.categorySuggestion,
          'paymentSourceTypeSuggestion': row.paymentSourceTypeSuggestion,
          'paymentSourceIdSuggestion': row.paymentSourceIdSuggestion,
          'detectedAt': _iso(row.detectedAt),
          'transactionDate': _iso(row.transactionDate),
          'sourceType': row.sourceType,
          'rawText': row.rawText,
          'confidenceScore': row.confidenceScore,
          'status': row.status,
          'cashbackAmount': row.cashbackAmount,
          'isForOthers': row.isForOthers,
          'recoverableAmount': normalizedRecoverable.remaining,
          'recoverableBaseAmount': normalizedRecoverable.base,
          'recoveredAmount': normalizedRecoverable.recovered,
          'recoverablePartyName': row.recoverablePartyName,
          'recoverablePartyNotes': row.recoverablePartyNotes,
          'recoverablePartyPhone': row.recoverablePartyPhone,
          'notes': row.notes,
          'duplicateOfTransactionId': row.duplicateOfTransactionId,
          'createdAt': _iso(row.createdAt),
          'updatedAt': _iso(row.updatedAt),
        };
      }();

  static Map<String, dynamic> _mapSplitGroup(SplitGroup row) => {
    'id': row.id,
    'name': row.name,
    'description': row.description,
    'createdAt': _iso(row.createdAt),
    'updatedAt': _iso(row.updatedAt),
    'archivedAt': _iso(row.archivedAt),
  };

  static Map<String, dynamic> _mapSplitMember(SplitMember row) => {
    'id': row.id,
    'groupId': row.groupId,
    'name': row.name,
    'contact': row.contact,
    'isCurrentUser': row.isCurrentUser,
    'createdAt': _iso(row.createdAt),
    'updatedAt': _iso(row.updatedAt),
  };

  static Map<String, dynamic> _mapSplitExpense(SplitExpense row) => {
    'id': row.id,
    'groupId': row.groupId,
    'title': row.title,
    'totalAmount': row.totalAmount,
    'paidByMemberId': row.paidByMemberId,
    'splitType': row.splitType,
    'expenseDate': _iso(row.expenseDate),
    'category': row.category,
    'notes': row.notes,
    'linkedTransactionId': row.linkedTransactionId,
    'createdAt': _iso(row.createdAt),
    'updatedAt': _iso(row.updatedAt),
  };

  static Map<String, dynamic> _mapSplitExpenseShare(SplitExpenseShare row) => {
    'id': row.id,
    'splitExpenseId': row.splitExpenseId,
    'memberId': row.memberId,
    'percentage': row.percentage,
    'exactAmount': row.exactAmount,
    'isSettled': row.isSettled,
    'createdAt': _iso(row.createdAt),
    'updatedAt': _iso(row.updatedAt),
  };

  static Map<String, dynamic> _mapSplitSettlement(SplitSettlement row) => {
    'id': row.id,
    'groupId': row.groupId,
    'fromMemberId': row.fromMemberId,
    'toMemberId': row.toMemberId,
    'amount': row.amount,
    'paymentSourceType': row.paymentSourceType,
    'paymentSourceId': row.paymentSourceId,
    'settlementDate': _iso(row.settlementDate),
    'linkedTransactionId': row.linkedTransactionId,
    'notes': row.notes,
    'createdAt': _iso(row.createdAt),
    'updatedAt': _iso(row.updatedAt),
  };

  static Map<String, dynamic> _mapLoan(Loan row) => {
    'id': row.id,
    'title': row.title,
    'lenderName': row.lenderName,
    'loanType': row.loanType,
    'principalAmount': row.principalAmount,
    'currentOutstanding': row.currentOutstanding,
    'interestRate': row.interestRate,
    'emiAmount': row.emiAmount,
    'emiDay': row.emiDay,
    'tenureMonths': row.tenureMonths,
    'startDate': _iso(row.startDate),
    'endDate': _iso(row.endDate),
    'linkedAccountId': row.linkedAccountId,
    'notes': row.notes,
    'createdAt': _iso(row.createdAt),
    'updatedAt': _iso(row.updatedAt),
    'closedAt': _iso(row.closedAt),
  };

  static Map<String, dynamic> _mapLoanPayment(LoanPayment row) => {
    'id': row.id,
    'loanId': row.loanId,
    'amount': row.amount,
    'paymentDate': _iso(row.paymentDate),
    'paymentSourceType': row.paymentSourceType,
    'paymentSourceId': row.paymentSourceId,
    'linkedTransactionId': row.linkedTransactionId,
    'notes': row.notes,
    'createdAt': _iso(row.createdAt),
  };

  static ({double? remaining, double? base, double recovered})
  _normalizeRecoverableAmounts({
    required bool isForOthers,
    required double amount,
    required double cashbackAmount,
    required double? recoverableAmount,
    required double? recoverableBaseAmount,
    required double recoveredAmount,
  }) {
    if (!isForOthers) {
      return (remaining: null, base: null, recovered: 0.0);
    }
    final base =
        (recoverableBaseAmount ??
                ((recoverableAmount ?? 0) > 0
                    ? (recoverableAmount ?? 0)
                    : (amount - cashbackAmount)))
            .clamp(0, amount)
            .toDouble();
    final recovered = recoveredAmount.clamp(0, base).toDouble();
    final remaining = (base - recovered).clamp(0, base).toDouble();
    return (remaining: remaining, base: base, recovered: recovered);
  }
}
