import 'package:drift/drift.dart';

import 'app_database.dart';

class ResetVerification {
  const ResetVerification({
    required this.accountsCount,
    required this.cardsCount,
    required this.transactionsCount,
    required this.pendingCount,
    required this.splitsCount,
    required this.cardBillsCount,
    required this.loansCount,
    required this.loanPaymentsCount,
    required this.appSettingsExists,
    required this.onboardingIncomplete,
  });

  final int accountsCount;
  final int cardsCount;
  final int transactionsCount;
  final int pendingCount;
  final int splitsCount;
  final int cardBillsCount;
  final int loansCount;
  final int loanPaymentsCount;
  final bool appSettingsExists;
  final bool onboardingIncomplete;

  bool get isClean =>
      accountsCount == 0 &&
      cardsCount == 0 &&
      transactionsCount == 0 &&
      pendingCount == 0 &&
      splitsCount == 0 &&
      cardBillsCount == 0 &&
      loansCount == 0 &&
      loanPaymentsCount == 0 &&
      appSettingsExists &&
      onboardingIncomplete;
}

class ResetDataService {
  const ResetDataService(this._db);

  final AppDatabase _db;

  Future<ResetVerification> wipeAllUserDataAndRestartOnboarding() async {
    final settings = await (_db.select(
      _db.appSettings,
    )..limit(1)).getSingleOrNull();

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
      await _db.delete(_db.alerts).go();

      if (settings == null) {
        await _db
            .into(_db.appSettings)
            .insert(
              AppSettingsCompanion.insert(
                isDarkMode: const Value(true),
                hasCompletedOnboarding: const Value(false),
              ),
            );
      } else {
        await (_db.update(
          _db.appSettings,
        )..where((t) => t.id.equals(settings.id))).write(
          AppSettingsCompanion(
            hasCompletedOnboarding: const Value(false),
            lastReminderShownAt: const Value(null),
            smsLastScannedAt: const Value(null),
          ),
        );
      }
    });

    return verifyFreshStartState();
  }

  Future<ResetVerification> verifyFreshStartState() async {
    final bankAccounts = await _db.select(_db.bankAccounts).get();
    final wallets = await _db.select(_db.cashWallets).get();
    final cards = await _db.select(_db.creditCards).get();
    final txns = await _db.select(_db.transactions).get();
    final pending = await _db.select(_db.pendingTransactions).get();
    final splitGroups = await _db.select(_db.splitGroups).get();
    final splitMembers = await _db.select(_db.splitMembers).get();
    final splitExpenses = await _db.select(_db.splitExpenses).get();
    final splitShares = await _db.select(_db.splitExpenseShares).get();
    final splitSettlements = await _db.select(_db.splitSettlements).get();
    final bills = await _db.select(_db.cardBills).get();
    final loans = await _db.select(_db.loans).get();
    final loanPayments = await _db.select(_db.loanPayments).get();
    final appSettings = await (_db.select(
      _db.appSettings,
    )..limit(1)).getSingleOrNull();

    return ResetVerification(
      accountsCount: bankAccounts.length + wallets.length,
      cardsCount: cards.length,
      transactionsCount: txns.length,
      pendingCount: pending.length,
      splitsCount:
          splitGroups.length +
          splitMembers.length +
          splitExpenses.length +
          splitShares.length +
          splitSettlements.length,
      cardBillsCount: bills.length,
      loansCount: loans.length,
      loanPaymentsCount: loanPayments.length,
      appSettingsExists: appSettings != null,
      onboardingIncomplete:
          (appSettings?.hasCompletedOnboarding ?? false) == false,
    );
  }
}
