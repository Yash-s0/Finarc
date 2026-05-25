import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

class AccountService {
  AccountService(this._db);

  final AppDatabase _db;

  Future<int> createBankAccount({
    required String bankName,
    required String accountName,
    required String accountType,
    required double currentBalance,
    String? colorOrIcon,
  }) {
    return _db
        .into(_db.bankAccounts)
        .insert(
          BankAccountsCompanion.insert(
            bankName: bankName,
            accountName: accountName,
            accountType: accountType,
            currentBalance: Value(currentBalance),
            colorOrIcon: Value(colorOrIcon),
          ),
        );
  }

  Future<void> updateBankAccount(
    int id, {
    String? bankName,
    String? accountName,
    String? accountType,
    double? currentBalance,
    String? colorOrIcon,
  }) {
    return (_db.update(_db.bankAccounts)..where((b) => b.id.equals(id))).write(
      BankAccountsCompanion(
        bankName: bankName == null ? const Value.absent() : Value(bankName),
        accountName: accountName == null
            ? const Value.absent()
            : Value(accountName),
        accountType: accountType == null
            ? const Value.absent()
            : Value(accountType),
        currentBalance: currentBalance == null
            ? const Value.absent()
            : Value(currentBalance),
        colorOrIcon: colorOrIcon == null
            ? const Value.absent()
            : Value(colorOrIcon),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteBankAccount(int id) {
    return (_db.delete(_db.bankAccounts)..where((b) => b.id.equals(id))).go();
  }

  Future<int> createCashWallet({
    required String walletName,
    required double currentBalance,
  }) {
    return _db
        .into(_db.cashWallets)
        .insert(
          CashWalletsCompanion.insert(
            walletName: walletName,
            currentBalance: Value(currentBalance),
          ),
        );
  }

  Future<void> updateCashWallet(
    int id, {
    String? walletName,
    double? currentBalance,
  }) {
    return (_db.update(_db.cashWallets)..where((c) => c.id.equals(id))).write(
      CashWalletsCompanion(
        walletName: walletName == null
            ? const Value.absent()
            : Value(walletName),
        currentBalance: currentBalance == null
            ? const Value.absent()
            : Value(currentBalance),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<double> getTotalBankBalance() async {
    final banks = await _db.select(_db.bankAccounts).get();
    return banks.fold<double>(0, (s, b) => s + b.currentBalance);
  }

  Future<double> getTotalCashBalance() async {
    final wallets = await _db.select(_db.cashWallets).get();
    return wallets.fold<double>(0, (s, w) => s + w.currentBalance);
  }

  Future<double> getCombinedLiquidBalance() async {
    return await getTotalBankBalance() + await getTotalCashBalance();
  }

  Future<void> transferBetweenAccounts({
    required String sourceType,
    required int sourceId,
    required String destinationType,
    required int destinationId,
    required double amount,
    required DateTime transactionDate,
    String? notes,
  }) async {
    final transferGroupId = 'tr_${DateTime.now().microsecondsSinceEpoch}';

    await _db.transaction(() async {
      await _changeBalance(sourceType, sourceId, -amount);
      if (destinationType == 'creditCard') {
        final card = await (_db.select(
          _db.creditCards,
        )..where((c) => c.id.equals(destinationId))).getSingle();
        await (_db.update(
          _db.creditCards,
        )..where((c) => c.id.equals(destinationId))).write(
          CreditCardsCompanion(
            currentOutstanding: Value(
              (card.currentOutstanding - amount).clamp(0, card.creditLimit),
            ),
            updatedAt: Value(DateTime.now()),
          ),
        );
      } else {
        await _changeBalance(destinationType, destinationId, amount);
      }

      await _db
          .into(_db.transactions)
          .insert(
            TransactionsCompanion.insert(
              type: destinationType == 'creditCard'
                  ? 'cardPayment'
                  : 'transfer',
              amount: amount,
              title: 'Transfer Out',
              category: 'Transfer',
              notes: Value(notes),
              transactionDate: transactionDate,
              paymentSourceType: sourceType,
              paymentSourceId: sourceId,
              transferGroupId: Value(transferGroupId),
              sourceAccountId: Value(sourceId),
              destinationAccountId: Value(destinationId),
            ),
          );

      await _db
          .into(_db.transactions)
          .insert(
            TransactionsCompanion.insert(
              type: destinationType == 'creditCard'
                  ? 'cardPayment'
                  : 'transfer',
              amount: amount,
              title: destinationType == 'creditCard'
                  ? 'Card Payment In'
                  : 'Transfer In',
              category: 'Transfer',
              notes: Value(notes),
              transactionDate: transactionDate,
              paymentSourceType: destinationType,
              paymentSourceId: destinationId,
              transferGroupId: Value(transferGroupId),
              sourceAccountId: Value(sourceId),
              destinationAccountId: Value(destinationId),
            ),
          );
    });
  }

  Future<void> reconcileBalance({
    required String accountType,
    required int accountId,
    required double newBalance,
    required String reason,
    DateTime? at,
  }) async {
    final old = await _getBalance(accountType, accountId);
    final delta = newBalance - old;
    await _setBalance(accountType, accountId, newBalance);

    await _db
        .into(_db.transactions)
        .insert(
          TransactionsCompanion.insert(
            type: 'transfer',
            amount: delta.abs(),
            title: 'Reconciliation Adjustment',
            category: 'Reconciliation',
            notes: Value(reason),
            transactionDate: at ?? DateTime.now(),
            paymentSourceType: accountType,
            paymentSourceId: accountId,
            sourceAccountId: Value(accountId),
            destinationAccountId: Value(accountId),
          ),
        );
  }

  Future<double> calculateNetWorthLiquidAssets() => getCombinedLiquidBalance();

  Future<void> _changeBalance(String type, int id, double delta) async {
    final current = await _getBalance(type, id);
    await _setBalance(type, id, current + delta);
  }

  Future<double> _getBalance(String type, int id) async {
    if (type == 'bank' || type == 'upi') {
      final b = await (_db.select(
        _db.bankAccounts,
      )..where((x) => x.id.equals(id))).getSingle();
      return b.currentBalance;
    }
    if (type == 'cash') {
      final c = await (_db.select(
        _db.cashWallets,
      )..where((x) => x.id.equals(id))).getSingle();
      return c.currentBalance;
    }
    throw ArgumentError('Unsupported account type $type');
  }

  Future<void> _setBalance(String type, int id, double balance) async {
    if (type == 'bank' || type == 'upi') {
      await (_db.update(_db.bankAccounts)..where((x) => x.id.equals(id))).write(
        BankAccountsCompanion(
          currentBalance: Value(balance),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return;
    }
    if (type == 'cash') {
      await (_db.update(_db.cashWallets)..where((x) => x.id.equals(id))).write(
        CashWalletsCompanion(
          currentBalance: Value(balance),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return;
    }
    throw ArgumentError('Unsupported account type $type');
  }
}
