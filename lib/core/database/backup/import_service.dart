import 'dart:convert';

import 'package:drift/drift.dart';

import '../app_database.dart';
import 'backup_models.dart';
import 'backup_service.dart';

class ImportService {
  const ImportService(this._db);

  final AppDatabase _db;

  BackupValidationResult validateBackupJson(String jsonText) {
    Map<String, dynamic> payload;
    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is! Map<String, dynamic>) {
        return const BackupValidationResult(
          isValid: false,
          message: 'Invalid JSON structure.',
        );
      }
      payload = decoded;
    } catch (_) {
      return const BackupValidationResult(
        isValid: false,
        message: 'Invalid JSON. Could not parse file.',
      );
    }

    if (payload['app'] != BackupService.appName) {
      return const BackupValidationResult(
        isValid: false,
        message: 'Backup app name mismatch.',
      );
    }

    final version = _int(payload['backupVersion']);
    if (version == null) {
      return const BackupValidationResult(
        isValid: false,
        message: 'Missing backupVersion.',
      );
    }
    if (version > BackupService.backupVersion) {
      return BackupValidationResult(
        isValid: false,
        message:
            'Unsupported backup version: $version. Please update Finarc first.',
      );
    }
    if (version < 1) {
      return BackupValidationResult(
        isValid: false,
        message: 'Unsupported backup version: $version.',
      );
    }

    final data = payload['data'];
    if (data is! Map<String, dynamic>) {
      return const BackupValidationResult(
        isValid: false,
        message: 'Missing data section in backup.',
      );
    }

    final requiredCollections = [
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
    ];

    for (final key in requiredCollections) {
      final value = data[key];
      if (value == null) continue;
      if (value is! List) {
        return BackupValidationResult(
          isValid: false,
          message: 'Invalid data.$key format. Expected an array.',
        );
      }
    }

    return BackupValidationResult(
      isValid: true,
      message: 'Backup is valid.',
      parsed: payload,
    );
  }

  BackupPreview previewBackup(String jsonText) {
    final validation = validateBackupJson(jsonText);
    if (!validation.isValid || validation.parsed == null) {
      throw FormatException(validation.message);
    }

    final payload = validation.parsed!;
    final data = payload['data'] as Map<String, dynamic>;
    final settings = _list(data, 'settings');
    final onboarding = settings.whereType<Map<String, dynamic>>().any(
      (s) => _bool(s['hasCompletedOnboarding']) == true,
    );

    return BackupPreview(
      createdAt: _date(payload['createdAt']),
      schemaVersion: _int(payload['schemaVersion']) ?? 0,
      backupVersion: _int(payload['backupVersion']) ?? 0,
      hasCompletedOnboarding: onboarding,
      counts: {
        'settings': _list(data, 'settings').length,
        'bankAccounts': _list(data, 'bankAccounts').length,
        'cashWallets': _list(data, 'cashWallets').length,
        'creditCards': _list(data, 'creditCards').length,
        'transactions': _list(data, 'transactions').length,
        'cardBills': _list(data, 'cardBills').length,
        'pendingTransactions': _list(data, 'pendingTransactions').length,
        'splitGroups': _list(data, 'splitGroups').length,
        'splitMembers': _list(data, 'splitMembers').length,
        'splitExpenses': _list(data, 'splitExpenses').length,
        'splitExpenseShares': _list(data, 'splitExpenseShares').length,
        'splitSettlements': _list(data, 'splitSettlements').length,
        'loans': _list(data, 'loans').length,
        'loanPayments': _list(data, 'loanPayments').length,
      },
    );
  }

  Future<ImportResult> importBackupReplaceAll(String jsonText) async {
    final validation = validateBackupJson(jsonText);
    if (!validation.isValid || validation.parsed == null) {
      throw FormatException(validation.message);
    }

    final payload = validation.parsed!;
    final data = payload['data'] as Map<String, dynamic>;

    await _db.transaction(() async {
      await _db.delete(_db.transactions).go();
      await _db.delete(_db.pendingTransactions).go();
      await _db.delete(_db.cardBills).go();
      await _db.delete(_db.splitExpenseShares).go();
      await _db.delete(_db.splitSettlements).go();
      await _db.delete(_db.splitExpenses).go();
      await _db.delete(_db.splitMembers).go();
      await _db.delete(_db.splitGroups).go();
      await _db.delete(_db.creditCards).go();
      await _db.delete(_db.bankAccounts).go();
      await _db.delete(_db.cashWallets).go();
      await _db.delete(_db.loanPayments).go();
      await _db.delete(_db.loans).go();
      await _db.delete(_db.appSettings).go();

      for (final raw in _list(data, 'settings')) {
        final row = _asMap(raw);
        await _db
            .into(_db.appSettings)
            .insert(
              AppSettingsCompanion(
                id: Value(_int(row['id']) ?? 0),
                isDarkMode: Value(_bool(row['isDarkMode']) ?? true),
                appLockEnabled: Value(_bool(row['appLockEnabled']) ?? false),
                notificationDetectionEnabled: Value(
                  _bool(row['notificationDetectionEnabled']) ?? true,
                ),
                showDetectionNotifications: Value(
                  _bool(row['showDetectionNotifications']) ?? true,
                ),
                reminderEnabled: Value(_bool(row['reminderEnabled']) ?? false),
                dailyReminderEnabled: Value(
                  _bool(row['dailyReminderEnabled']) ?? false,
                ),
                weeklyReminderEnabled: Value(
                  _bool(row['weeklyReminderEnabled']) ?? false,
                ),
                reminderHour: Value(_int(row['reminderHour']) ?? 20),
                reminderMinute: Value(_int(row['reminderMinute']) ?? 0),
                weeklyReminderWeekday: Value(
                  _int(row['weeklyReminderWeekday']) ?? DateTime.monday,
                ),
                cardDueReminderEnabled: Value(
                  _bool(row['cardDueReminderEnabled']) ?? true,
                ),
                pendingTransactionReminderEnabled: Value(
                  _bool(row['pendingTransactionReminderEnabled']) ?? true,
                ),
                settlementReminderEnabled: Value(
                  _bool(row['settlementReminderEnabled']) ?? false,
                ),
                lastReminderShownAt: Value(_date(row['lastReminderShownAt'])),
                smsDetectionEnabled: Value(
                  _bool(row['smsDetectionEnabled']) ?? false,
                ),
                smsPermissionAskedAt: Value(_date(row['smsPermissionAskedAt'])),
                smsBackfillEnabled: Value(
                  _bool(row['smsBackfillEnabled']) ?? false,
                ),
                smsBackfillDays: Value(_int(row['smsBackfillDays']) ?? 7),
                smsLastScannedAt: Value(_date(row['smsLastScannedAt'])),
                hasCompletedOnboarding: Value(
                  _bool(row['hasCompletedOnboarding']) ?? false,
                ),
              ),
            );
      }

      if ((await _db.select(_db.appSettings).get()).isEmpty) {
        await _db
            .into(_db.appSettings)
            .insert(
              AppSettingsCompanion.insert(
                isDarkMode: const Value(true),
                hasCompletedOnboarding: const Value(false),
              ),
            );
      }

      for (final raw in _list(data, 'bankAccounts')) {
        final row = _asMap(raw);
        await _db
            .into(_db.bankAccounts)
            .insert(
              BankAccountsCompanion(
                id: Value(_int(row['id']) ?? 0),
                bankName: Value(_string(row['bankName'])),
                accountName: Value(_string(row['accountName'])),
                accountType: Value(_string(row['accountType'])),
                last4: Value(_stringOrNull(row['last4'])),
                currentBalance: Value(_double(row['currentBalance']) ?? 0),
                colorOrIcon: Value(_stringOrNull(row['colorOrIcon'])),
                createdAt: Value(_date(row['createdAt']) ?? DateTime.now()),
                updatedAt: Value(_date(row['updatedAt']) ?? DateTime.now()),
              ),
            );
      }

      for (final raw in _list(data, 'cashWallets')) {
        final row = _asMap(raw);
        await _db
            .into(_db.cashWallets)
            .insert(
              CashWalletsCompanion(
                id: Value(_int(row['id']) ?? 0),
                walletName: Value(_string(row['walletName'])),
                currentBalance: Value(_double(row['currentBalance']) ?? 0),
                createdAt: Value(_date(row['createdAt']) ?? DateTime.now()),
                updatedAt: Value(_date(row['updatedAt']) ?? DateTime.now()),
              ),
            );
      }

      for (final raw in _list(data, 'creditCards')) {
        final row = _asMap(raw);
        await _db
            .into(_db.creditCards)
            .insert(
              CreditCardsCompanion(
                id: Value(_int(row['id']) ?? 0),
                bankName: Value(_string(row['bankName'])),
                nickname: Value(_string(row['nickname'])),
                last4: Value(_string(row['last4'])),
                maskedNumber: Value(_string(row['maskedNumber'])),
                creditLimit: Value(_double(row['creditLimit']) ?? 0),
                billingDay: Value(_int(row['billingDay']) ?? 1),
                dueDay: Value(_int(row['dueDay']) ?? 1),
                currentOutstanding: Value(
                  _double(row['currentOutstanding']) ?? 0,
                ),
                createdAt: Value(_date(row['createdAt']) ?? DateTime.now()),
                updatedAt: Value(_date(row['updatedAt']) ?? DateTime.now()),
              ),
            );
      }

      for (final raw in _list(data, 'transactions')) {
        final row = _asMap(raw);
        final normalizedRecoverable = _normalizeRecoverableAmounts(
          isForOthers: _bool(row['isForOthers']) ?? false,
          amount: _double(row['amount']) ?? 0,
          cashbackAmount: _double(row['cashbackAmount']) ?? 0,
          recoverableAmount: _double(row['recoverableAmount']),
          recoverableBaseAmount: _double(row['recoverableBaseAmount']),
          recoveredAmount: _double(row['recoveredAmount']) ?? 0,
          recoverableStatus: _stringOrNull(row['recoverableStatus']),
        );
        await _db
            .into(_db.transactions)
            .insert(
              TransactionsCompanion(
                id: Value(_int(row['id']) ?? 0),
                type: Value(_string(row['type'])),
                amount: Value(_double(row['amount']) ?? 0),
                title: Value(_string(row['title'])),
                category: Value(_string(row['category'])),
                notes: Value(_stringOrNull(row['notes'])),
                transactionDate: Value(
                  _date(row['transactionDate']) ?? DateTime.now(),
                ),
                paymentSourceType: Value(_string(row['paymentSourceType'])),
                paymentSourceId: Value(_int(row['paymentSourceId']) ?? 0),
                cashbackAmount: Value(_double(row['cashbackAmount']) ?? 0),
                isForOthers: Value(_bool(row['isForOthers']) ?? false),
                recoverableAmount: Value(normalizedRecoverable.remaining),
                recoverableBaseAmount: Value(normalizedRecoverable.base),
                recoveredAmount: Value(normalizedRecoverable.recovered),
                recoverablePartyName: Value(
                  _stringOrNull(row['recoverablePartyName']),
                ),
                recoverablePartyNotes: Value(
                  _stringOrNull(row['recoverablePartyNotes']),
                ),
                recoverablePartyPhone: Value(
                  _stringOrNull(row['recoverablePartyPhone']),
                ),
                recoverableStatus: Value(normalizedRecoverable.status),
                recoveredAt: Value(_date(row['recoveredAt'])),
                confirmed: Value(_bool(row['confirmed']) ?? true),
                detectedSourceType: Value(
                  _stringOrNull(row['detectedSourceType']),
                ),
                cardBillId: Value(_int(row['cardBillId'])),
                transferGroupId: Value(_stringOrNull(row['transferGroupId'])),
                sourceAccountId: Value(_int(row['sourceAccountId'])),
                destinationAccountId: Value(_int(row['destinationAccountId'])),
                linkedSplitExpenseId: Value(_int(row['linkedSplitExpenseId'])),
                personalShareAmount: Value(_double(row['personalShareAmount'])),
                splitGroupId: Value(_int(row['splitGroupId'])),
                transactionImpactType: Value(
                  _stringOrNull(row['transactionImpactType']),
                ),
                cashbackDestinationType: Value(
                  _stringOrNull(row['cashbackDestinationType']),
                ),
                cashbackDestinationId: Value(
                  _int(row['cashbackDestinationId']),
                ),
                relatedTransactionId: Value(_int(row['relatedTransactionId'])),
                createdAt: Value(_date(row['createdAt']) ?? DateTime.now()),
                updatedAt: Value(_date(row['updatedAt']) ?? DateTime.now()),
              ),
            );
      }

      for (final raw in _list(data, 'cardBills')) {
        final row = _asMap(raw);
        await _db
            .into(_db.cardBills)
            .insert(
              CardBillsCompanion(
                id: Value(_int(row['id']) ?? 0),
                cardId: Value(_int(row['cardId']) ?? 0),
                cycleStartDate: Value(
                  _date(row['cycleStartDate']) ?? DateTime.now(),
                ),
                cycleEndDate: Value(
                  _date(row['cycleEndDate']) ?? DateTime.now(),
                ),
                billingDate: Value(_date(row['billingDate']) ?? DateTime.now()),
                billedAmount: Value(_double(row['billedAmount']) ?? 0),
                paidAmount: Value(_double(row['paidAmount']) ?? 0),
                dueDate: Value(_date(row['dueDate']) ?? DateTime.now()),
                status: Value(_string(row['status'], fallback: 'upcoming')),
                createdAt: Value(_date(row['createdAt']) ?? DateTime.now()),
                paidAt: Value(_date(row['paidAt'])),
              ),
            );
      }

      for (final raw in _list(data, 'pendingTransactions')) {
        final row = _asMap(raw);
        final normalizedRecoverable = _normalizeRecoverableAmounts(
          isForOthers: _bool(row['isForOthers']) ?? false,
          amount: _double(row['amount']) ?? 0,
          cashbackAmount: _double(row['cashbackAmount']) ?? 0,
          recoverableAmount: _double(row['recoverableAmount']),
          recoverableBaseAmount: _double(row['recoverableBaseAmount']),
          recoveredAmount: _double(row['recoveredAmount']) ?? 0,
          recoverableStatus: null,
        );
        await _db
            .into(_db.pendingTransactions)
            .insert(
              PendingTransactionsCompanion(
                id: Value(_int(row['id']) ?? 0),
                amount: Value(_double(row['amount']) ?? 0),
                merchant: Value(_string(row['merchant'])),
                categorySuggestion: Value(_string(row['categorySuggestion'])),
                paymentSourceTypeSuggestion: Value(
                  _string(row['paymentSourceTypeSuggestion']),
                ),
                paymentSourceIdSuggestion: Value(
                  _int(row['paymentSourceIdSuggestion']),
                ),
                detectedAt: Value(_date(row['detectedAt']) ?? DateTime.now()),
                transactionDate: Value(
                  _date(row['transactionDate']) ?? DateTime.now(),
                ),
                sourceType: Value(_string(row['sourceType'])),
                rawText: Value(_string(row['rawText'])),
                confidenceScore: Value(_double(row['confidenceScore']) ?? 0),
                status: Value(_string(row['status'], fallback: 'pending')),
                cashbackAmount: Value(_double(row['cashbackAmount'])),
                isForOthers: Value(_bool(row['isForOthers']) ?? false),
                recoverableAmount: Value(normalizedRecoverable.remaining),
                recoverableBaseAmount: Value(normalizedRecoverable.base),
                recoveredAmount: Value(normalizedRecoverable.recovered),
                recoverablePartyName: Value(
                  _stringOrNull(row['recoverablePartyName']),
                ),
                recoverablePartyNotes: Value(
                  _stringOrNull(row['recoverablePartyNotes']),
                ),
                recoverablePartyPhone: Value(
                  _stringOrNull(row['recoverablePartyPhone']),
                ),
                notes: Value(_stringOrNull(row['notes'])),
                duplicateOfTransactionId: Value(
                  _int(row['duplicateOfTransactionId']),
                ),
                createdAt: Value(_date(row['createdAt']) ?? DateTime.now()),
                updatedAt: Value(_date(row['updatedAt']) ?? DateTime.now()),
              ),
            );
      }

      for (final raw in _list(data, 'splitGroups')) {
        final row = _asMap(raw);
        await _db
            .into(_db.splitGroups)
            .insert(
              SplitGroupsCompanion(
                id: Value(_int(row['id']) ?? 0),
                name: Value(_string(row['name'])),
                description: Value(_stringOrNull(row['description'])),
                createdAt: Value(_date(row['createdAt']) ?? DateTime.now()),
                updatedAt: Value(_date(row['updatedAt']) ?? DateTime.now()),
                archivedAt: Value(_date(row['archivedAt'])),
              ),
            );
      }

      for (final raw in _list(data, 'splitMembers')) {
        final row = _asMap(raw);
        await _db
            .into(_db.splitMembers)
            .insert(
              SplitMembersCompanion(
                id: Value(_int(row['id']) ?? 0),
                groupId: Value(_int(row['groupId']) ?? 0),
                name: Value(_string(row['name'])),
                contact: Value(_stringOrNull(row['contact'])),
                isCurrentUser: Value(_bool(row['isCurrentUser']) ?? false),
                createdAt: Value(_date(row['createdAt']) ?? DateTime.now()),
                updatedAt: Value(_date(row['updatedAt']) ?? DateTime.now()),
              ),
            );
      }

      for (final raw in _list(data, 'splitExpenses')) {
        final row = _asMap(raw);
        await _db
            .into(_db.splitExpenses)
            .insert(
              SplitExpensesCompanion(
                id: Value(_int(row['id']) ?? 0),
                groupId: Value(_int(row['groupId']) ?? 0),
                title: Value(_string(row['title'])),
                totalAmount: Value(_double(row['totalAmount']) ?? 0),
                paidByMemberId: Value(_int(row['paidByMemberId']) ?? 0),
                splitType: Value(_string(row['splitType'])),
                expenseDate: Value(_date(row['expenseDate']) ?? DateTime.now()),
                category: Value(_string(row['category'])),
                notes: Value(_stringOrNull(row['notes'])),
                linkedTransactionId: Value(_int(row['linkedTransactionId'])),
                createdAt: Value(_date(row['createdAt']) ?? DateTime.now()),
                updatedAt: Value(_date(row['updatedAt']) ?? DateTime.now()),
              ),
            );
      }

      for (final raw in _list(data, 'splitExpenseShares')) {
        final row = _asMap(raw);
        await _db
            .into(_db.splitExpenseShares)
            .insert(
              SplitExpenseSharesCompanion(
                id: Value(_int(row['id']) ?? 0),
                splitExpenseId: Value(_int(row['splitExpenseId']) ?? 0),
                memberId: Value(_int(row['memberId']) ?? 0),
                percentage: Value(_double(row['percentage'])),
                exactAmount: Value(_double(row['exactAmount']) ?? 0),
                isSettled: Value(_bool(row['isSettled']) ?? false),
                createdAt: Value(_date(row['createdAt']) ?? DateTime.now()),
                updatedAt: Value(_date(row['updatedAt']) ?? DateTime.now()),
              ),
            );
      }

      for (final raw in _list(data, 'splitSettlements')) {
        final row = _asMap(raw);
        await _db
            .into(_db.splitSettlements)
            .insert(
              SplitSettlementsCompanion(
                id: Value(_int(row['id']) ?? 0),
                groupId: Value(_int(row['groupId']) ?? 0),
                fromMemberId: Value(_int(row['fromMemberId']) ?? 0),
                toMemberId: Value(_int(row['toMemberId']) ?? 0),
                amount: Value(_double(row['amount']) ?? 0),
                paymentSourceType: Value(
                  _stringOrNull(row['paymentSourceType']),
                ),
                paymentSourceId: Value(_int(row['paymentSourceId'])),
                settlementDate: Value(
                  _date(row['settlementDate']) ?? DateTime.now(),
                ),
                linkedTransactionId: Value(_int(row['linkedTransactionId'])),
                notes: Value(_stringOrNull(row['notes'])),
                createdAt: Value(_date(row['createdAt']) ?? DateTime.now()),
                updatedAt: Value(_date(row['updatedAt']) ?? DateTime.now()),
              ),
            );
      }

      for (final raw in _list(data, 'loans')) {
        final row = _asMap(raw);
        await _db
            .into(_db.loans)
            .insert(
              LoansCompanion(
                id: Value(_int(row['id']) ?? 0),
                title: Value(_string(row['title'])),
                lenderName: Value(_string(row['lenderName'])),
                loanType: Value(_string(row['loanType'], fallback: 'other')),
                principalAmount: Value(_double(row['principalAmount']) ?? 0),
                currentOutstanding: Value(
                  _double(row['currentOutstanding']) ?? 0,
                ),
                interestRate: Value(_double(row['interestRate'])),
                emiAmount: Value(_double(row['emiAmount'])),
                emiDay: Value(_int(row['emiDay'])),
                tenureMonths: Value(_int(row['tenureMonths'])),
                startDate: Value(_date(row['startDate'])),
                endDate: Value(_date(row['endDate'])),
                linkedAccountId: Value(_int(row['linkedAccountId'])),
                notes: Value(_stringOrNull(row['notes'])),
                createdAt: Value(_date(row['createdAt']) ?? DateTime.now()),
                updatedAt: Value(_date(row['updatedAt']) ?? DateTime.now()),
                closedAt: Value(_date(row['closedAt'])),
              ),
            );
      }

      for (final raw in _list(data, 'loanPayments')) {
        final row = _asMap(raw);
        await _db
            .into(_db.loanPayments)
            .insert(
              LoanPaymentsCompanion(
                id: Value(_int(row['id']) ?? 0),
                loanId: Value(_int(row['loanId']) ?? 0),
                amount: Value(_double(row['amount']) ?? 0),
                paymentDate: Value(_date(row['paymentDate']) ?? DateTime.now()),
                paymentSourceType: Value(
                  _stringOrNull(row['paymentSourceType']),
                ),
                paymentSourceId: Value(_int(row['paymentSourceId'])),
                linkedTransactionId: Value(_int(row['linkedTransactionId'])),
                notes: Value(_stringOrNull(row['notes'])),
                createdAt: Value(_date(row['createdAt']) ?? DateTime.now()),
              ),
            );
      }
    });

    final preview = previewBackup(jsonText);
    return ImportResult(
      onboardingCompleted: preview.hasCompletedOnboarding,
      counts: preview.counts,
    );
  }

  List<dynamic> _list(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is List) return value;
    return const [];
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((k, v) => MapEntry('$k', v));
    }
    throw const FormatException('Invalid backup row format.');
  }

  static int? _int(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }

  static double? _double(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }

  static bool? _bool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
    }
    return null;
  }

  static DateTime? _date(dynamic value) {
    final text = _stringOrNull(value);
    if (text == null || text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  static String _string(dynamic value, {String fallback = ''}) {
    final result = _stringOrNull(value);
    return result ?? fallback;
  }

  static String? _stringOrNull(dynamic value) {
    if (value == null) return null;
    final text = '$value';
    return text.isEmpty ? null : text;
  }

  static ({double? remaining, double? base, double recovered, String status})
  _normalizeRecoverableAmounts({
    required bool isForOthers,
    required double amount,
    required double cashbackAmount,
    required double? recoverableAmount,
    required double? recoverableBaseAmount,
    required double recoveredAmount,
    required String? recoverableStatus,
  }) {
    if (!isForOthers) {
      return (remaining: null, base: null, recovered: 0.0, status: 'unpaid');
    }

    final normalizedStatus = (recoverableStatus ?? '').trim().toLowerCase();
    final recoveredLike = <String>{'recovered', 'settled', 'paid', 'complete'};
    final openLike = <String>{
      'open',
      'pending',
      'unpaid',
      'partial',
      'unknown',
      'missing',
    };
    final base =
        (recoverableBaseAmount ??
                ((recoverableAmount ?? 0) > 0
                    ? (recoverableAmount ?? 0)
                    : (amount - cashbackAmount)))
            .clamp(0, amount)
            .toDouble();
    final legacyRecovered =
        normalizedStatus.isNotEmpty &&
        (recoveredLike.contains(normalizedStatus) ||
            openLike.contains(normalizedStatus));
    final recovered =
        (legacyRecovered
                ? (recoveredLike.contains(normalizedStatus) ? base : 0)
                : recoveredAmount)
            .clamp(0, base)
            .toDouble();
    final remaining = (base - recovered).clamp(0, base).toDouble();
    final status = recovered <= 0.009
        ? 'unpaid'
        : recovered >= base - 0.009
        ? 'recovered'
        : 'partial';
    return (
      remaining: remaining,
      base: base,
      recovered: recovered,
      status: status,
    );
  }
}
