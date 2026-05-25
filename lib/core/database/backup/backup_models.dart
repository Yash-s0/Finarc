class BackupManifest {
  const BackupManifest({
    required this.app,
    required this.backupVersion,
    required this.createdAt,
    required this.schemaVersion,
    required this.deviceNote,
    required this.data,
  });

  final String app;
  final int backupVersion;
  final DateTime createdAt;
  final int schemaVersion;
  final String? deviceNote;
  final BackupData data;

  Map<String, dynamic> toJson() {
    return {
      'app': app,
      'backupVersion': backupVersion,
      'createdAt': createdAt.toIso8601String(),
      'schemaVersion': schemaVersion,
      'deviceNote': deviceNote,
      'data': data.toJson(),
    };
  }
}

class BackupData {
  const BackupData({
    required this.settings,
    required this.bankAccounts,
    required this.cashWallets,
    required this.creditCards,
    required this.transactions,
    required this.cardBills,
    required this.pendingTransactions,
    required this.splitGroups,
    required this.splitMembers,
    required this.splitExpenses,
    required this.splitExpenseShares,
    required this.splitSettlements,
    required this.loans,
    required this.loanPayments,
  });

  final List<Map<String, dynamic>> settings;
  final List<Map<String, dynamic>> bankAccounts;
  final List<Map<String, dynamic>> cashWallets;
  final List<Map<String, dynamic>> creditCards;
  final List<Map<String, dynamic>> transactions;
  final List<Map<String, dynamic>> cardBills;
  final List<Map<String, dynamic>> pendingTransactions;
  final List<Map<String, dynamic>> splitGroups;
  final List<Map<String, dynamic>> splitMembers;
  final List<Map<String, dynamic>> splitExpenses;
  final List<Map<String, dynamic>> splitExpenseShares;
  final List<Map<String, dynamic>> splitSettlements;
  final List<Map<String, dynamic>> loans;
  final List<Map<String, dynamic>> loanPayments;

  Map<String, dynamic> toJson() {
    return {
      'settings': settings,
      'bankAccounts': bankAccounts,
      'cashWallets': cashWallets,
      'creditCards': creditCards,
      'transactions': transactions,
      'cardBills': cardBills,
      'pendingTransactions': pendingTransactions,
      'splitGroups': splitGroups,
      'splitMembers': splitMembers,
      'splitExpenses': splitExpenses,
      'splitExpenseShares': splitExpenseShares,
      'splitSettlements': splitSettlements,
      'loans': loans,
      'loanPayments': loanPayments,
    };
  }
}

class BackupValidationResult {
  const BackupValidationResult({
    required this.isValid,
    required this.message,
    this.parsed,
  });

  final bool isValid;
  final String message;
  final Map<String, dynamic>? parsed;
}

class BackupPreview {
  const BackupPreview({
    required this.createdAt,
    required this.schemaVersion,
    required this.backupVersion,
    required this.counts,
    required this.hasCompletedOnboarding,
  });

  final DateTime? createdAt;
  final int schemaVersion;
  final int backupVersion;
  final Map<String, int> counts;
  final bool hasCompletedOnboarding;
}

class ImportResult {
  const ImportResult({required this.onboardingCompleted, required this.counts});

  final bool onboardingCompleted;
  final Map<String, int> counts;
}
