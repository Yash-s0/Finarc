import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../models/transaction_types.dart';

class AddTransactionInput {
  AddTransactionInput({
    required this.type,
    required this.amount,
    required this.title,
    required this.category,
    required this.transactionDate,
    required this.paymentSourceType,
    required this.paymentSourceId,
    this.notes,
    this.cashbackAmount = 0,
    this.isForOthers = false,
    this.recoverableAmount,
    this.confirmed = true,
    this.detectedSourceType,
    this.linkedSplitExpenseId,
    this.personalShareAmount,
    this.splitGroupId,
    this.transactionImpactType,
  });

  final String type;
  final double amount;
  final String title;
  final String category;
  final String? notes;
  final DateTime transactionDate;
  final String paymentSourceType;
  final int? paymentSourceId;
  final double cashbackAmount;
  final bool isForOthers;
  final double? recoverableAmount;
  final bool confirmed;
  final String? detectedSourceType;
  final int? linkedSplitExpenseId;
  final double? personalShareAmount;
  final int? splitGroupId;
  final String? transactionImpactType;
}

class TransactionEngine {
  TransactionEngine(this._db);

  final AppDatabase _db;

  Future<void> addTransaction(AddTransactionInput input) async {
    _validate(input);
    final sourceId = input.paymentSourceId!;

    await _db.transaction(() async {
      if (input.type == TransactionType.income) {
        await _applyIncome(input.paymentSourceType, sourceId, input.amount);
      } else if (input.type == TransactionType.refund) {
        await _applyRefund(input.paymentSourceType, sourceId, input.amount);
      } else {
        await _applyExpense(input.paymentSourceType, sourceId, input.amount);
      }

      await _db
          .into(_db.transactions)
          .insert(
            TransactionsCompanion.insert(
              type: input.type,
              amount: input.amount,
              title: input.title,
              category: input.category,
              notes: Value(input.notes),
              transactionDate: input.transactionDate,
              paymentSourceType: input.paymentSourceType,
              paymentSourceId: sourceId,
              cashbackAmount: Value(input.cashbackAmount),
              isForOthers: Value(input.isForOthers),
              recoverableAmount: Value(input.recoverableAmount),
              confirmed: Value(input.confirmed),
              detectedSourceType: Value(input.detectedSourceType),
              linkedSplitExpenseId: Value(input.linkedSplitExpenseId),
              personalShareAmount: Value(input.personalShareAmount),
              splitGroupId: Value(input.splitGroupId),
              transactionImpactType: Value(input.transactionImpactType),
              updatedAt: Value(DateTime.now()),
            ),
          );
    });
  }

  double netExpense(Transaction txn) {
    return (txn.amount - txn.cashbackAmount).clamp(0, txn.amount);
  }

  void _validate(AddTransactionInput input) {
    if (input.amount <= 0) {
      throw ArgumentError('Amount must be greater than 0');
    }
    if (input.paymentSourceId == null) {
      throw ArgumentError('Payment source is required');
    }
    if (input.recoverableAmount != null &&
        input.recoverableAmount! > input.amount) {
      throw ArgumentError('Recoverable amount cannot exceed total amount');
    }
    if (input.cashbackAmount > input.amount) {
      throw ArgumentError('Cashback cannot exceed total amount');
    }
    if (input.paymentSourceType == PaymentSourceType.creditCard &&
        input.type != TransactionType.creditCard &&
        input.type != TransactionType.refund) {
      throw ArgumentError('Card source must use credit card transaction type');
    }
    if (input.type == TransactionType.creditCard &&
        input.paymentSourceType != PaymentSourceType.creditCard) {
      throw ArgumentError('Card transaction requires card source');
    }
    if ((input.paymentSourceType == PaymentSourceType.upi ||
            input.paymentSourceType == PaymentSourceType.bank) &&
        input.paymentSourceId == null) {
      throw ArgumentError('Bank account required');
    }
  }

  Future<void> _applyExpense(
    String sourceType,
    int sourceId,
    double amount,
  ) async {
    if (sourceType == PaymentSourceType.creditCard) {
      final card = await (_db.select(
        _db.creditCards,
      )..where((c) => c.id.equals(sourceId))).getSingle();
      await (_db.update(
        _db.creditCards,
      )..where((c) => c.id.equals(sourceId))).write(
        CreditCardsCompanion(
          currentOutstanding: Value(card.currentOutstanding + amount),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return;
    }

    if (sourceType == PaymentSourceType.cash) {
      final wallet = await (_db.select(
        _db.cashWallets,
      )..where((w) => w.id.equals(sourceId))).getSingleOrNull();
      if (wallet == null) throw ArgumentError('Cash wallet required');
      await (_db.update(
        _db.cashWallets,
      )..where((w) => w.id.equals(sourceId))).write(
        CashWalletsCompanion(
          currentBalance: Value(wallet.currentBalance - amount),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return;
    }

    final bank = await (_db.select(
      _db.bankAccounts,
    )..where((b) => b.id.equals(sourceId))).getSingleOrNull();
    if (bank == null) throw ArgumentError('Bank account required');
    await (_db.update(
      _db.bankAccounts,
    )..where((b) => b.id.equals(sourceId))).write(
      BankAccountsCompanion(
        currentBalance: Value(bank.currentBalance - amount),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> _applyIncome(
    String sourceType,
    int sourceId,
    double amount,
  ) async {
    if (sourceType == PaymentSourceType.cash) {
      final wallet = await (_db.select(
        _db.cashWallets,
      )..where((w) => w.id.equals(sourceId))).getSingleOrNull();
      if (wallet == null) throw ArgumentError('Cash wallet required');
      await (_db.update(
        _db.cashWallets,
      )..where((w) => w.id.equals(sourceId))).write(
        CashWalletsCompanion(
          currentBalance: Value(wallet.currentBalance + amount),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return;
    }
    final bank = await (_db.select(
      _db.bankAccounts,
    )..where((b) => b.id.equals(sourceId))).getSingleOrNull();
    if (bank == null) throw ArgumentError('Bank account required');
    await (_db.update(
      _db.bankAccounts,
    )..where((b) => b.id.equals(sourceId))).write(
      BankAccountsCompanion(
        currentBalance: Value(bank.currentBalance + amount),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> _applyRefund(
    String sourceType,
    int sourceId,
    double amount,
  ) async {
    if (sourceType == PaymentSourceType.creditCard) {
      final card = await (_db.select(
        _db.creditCards,
      )..where((c) => c.id.equals(sourceId))).getSingle();
      await (_db.update(
        _db.creditCards,
      )..where((c) => c.id.equals(sourceId))).write(
        CreditCardsCompanion(
          currentOutstanding: Value(
            (card.currentOutstanding - amount).clamp(0, card.creditLimit),
          ),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return;
    }
    await _applyIncome(sourceType, sourceId, amount);
  }
}
