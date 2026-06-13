import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../cards/data/billing_service.dart';
import '../models/cashback_destination_types.dart';
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
    this.recoveredAmount,
    this.recoverablePartyName,
    this.recoverablePartyNotes,
    this.recoverablePartyPhone,
    this.recoverableStatus,
    this.recoveredAt,
    this.confirmed = true,
    this.detectedSourceType,
    this.linkedSplitExpenseId,
    this.personalShareAmount,
    this.splitGroupId,
    this.transactionImpactType,
    this.cashbackDestinationType,
    this.cashbackDestinationId,
    this.relatedTransactionId,
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
  final double? recoveredAmount;
  final String? recoverablePartyName;
  final String? recoverablePartyNotes;
  final String? recoverablePartyPhone;
  final String? recoverableStatus;
  final DateTime? recoveredAt;
  final bool confirmed;
  final String? detectedSourceType;
  final int? linkedSplitExpenseId;
  final double? personalShareAmount;
  final int? splitGroupId;
  final String? transactionImpactType;
  final String? cashbackDestinationType;
  final int? cashbackDestinationId;
  final int? relatedTransactionId;
}

class TransactionEngine {
  TransactionEngine(this._db);

  final AppDatabase _db;

  BillingService get _billing => BillingService(_db);

  Future<void> addTransaction(AddTransactionInput input) async {
    _validate(input);
    final sourceId = input.paymentSourceId!;

    int? insertedId;
    await _db.transaction(() async {
      if (_mutatesLiveBalances(input.transactionImpactType)) {
        if (input.type == TransactionType.income) {
          await _applyIncome(input.paymentSourceType, sourceId, input.amount);
        } else if (input.type == TransactionType.refund) {
          await _applyRefund(input.paymentSourceType, sourceId, input.amount);
        } else {
          await _applyExpense(input.paymentSourceType, sourceId, input.amount);
        }
        await _applyCashbackDestinationEffect(input);
      }

      final recoverableBase = _resolveRecoverableBase(input);
      final recoveredAmount = _resolveRecoveredAmount(input, recoverableBase);
      final remainingRecoverable = _resolveRemainingRecoverable(
        recoverableBase,
        recoveredAmount,
      );
      final recoverableStatus = _resolveRecoverableStatus(
        isForOthers: input.isForOthers,
        recoverableBase: recoverableBase,
        recoveredAmount: recoveredAmount,
      );
      insertedId = await _db
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
              recoverableAmount: Value(
                input.isForOthers ? remainingRecoverable : null,
              ),
              recoverableBaseAmount: Value(
                input.isForOthers ? recoverableBase : null,
              ),
              recoveredAmount: Value(recoveredAmount),
              recoverablePartyName: Value(input.recoverablePartyName),
              recoverablePartyNotes: Value(input.recoverablePartyNotes),
              recoverablePartyPhone: Value(input.recoverablePartyPhone),
              recoverableStatus: Value(recoverableStatus),
              recoveredAt: Value(
                recoveredAmount > 0
                    ? (input.recoveredAt ?? DateTime.now())
                    : null,
              ),
              confirmed: Value(input.confirmed),
              detectedSourceType: Value(input.detectedSourceType),
              linkedSplitExpenseId: Value(input.linkedSplitExpenseId),
              personalShareAmount: Value(input.personalShareAmount),
              splitGroupId: Value(input.splitGroupId),
              transactionImpactType: Value(input.transactionImpactType),
              cashbackDestinationType: Value(input.cashbackDestinationType),
              cashbackDestinationId: Value(input.cashbackDestinationId),
              relatedTransactionId: Value(input.relatedTransactionId),
              updatedAt: Value(DateTime.now()),
            ),
          );
      if (insertedId != null && input.type == TransactionType.refund) {
        await _adjustLinkedRecoverableAfterRefund(
          refundTransactionId: insertedId!,
          relatedTransactionId: input.relatedTransactionId,
          refundAmount: input.amount,
        );
      }
    });

    if (insertedId != null) {
      final inserted = await (_db.select(
        _db.transactions,
      )..where((t) => t.id.equals(insertedId!))).getSingleOrNull();
      if (inserted != null) {
        await _billing.reconcileCardAfterMutation(current: inserted);
      }
    }
  }

  bool isEditable(Transaction txn) {
    if (txn.type == TransactionType.transfer ||
        txn.type == TransactionType.cardPayment ||
        txn.type == TransactionType.loanEmi) {
      return false;
    }
    if (txn.linkedSplitExpenseId != null || txn.splitGroupId != null) {
      return false;
    }
    return true;
  }

  Future<void> updateTransaction(
    int transactionId,
    AddTransactionInput input,
  ) async {
    _validate(input);
    final existing = await (_db.select(
      _db.transactions,
    )..where((t) => t.id.equals(transactionId))).getSingleOrNull();
    if (existing == null) {
      throw ArgumentError('Transaction not found');
    }
    if (!isEditable(existing)) {
      throw ArgumentError('This transaction type cannot be edited safely');
    }

    await _db.transaction(() async {
      if (_mutatesLiveBalances(existing.transactionImpactType)) {
        await _reverseTransactionEffect(existing);
      }
      if (_mutatesLiveBalances(input.transactionImpactType)) {
        await _applyTransactionEffect(input);
      }
      final sourceId = input.paymentSourceId!;
      final recoverableBase = _resolveRecoverableBase(input);
      final recoveredAmount = _resolveRecoveredAmount(
        input,
        recoverableBase,
        fallbackRecovered: existing.recoveredAmount,
      );
      final remainingRecoverable = _resolveRemainingRecoverable(
        recoverableBase,
        recoveredAmount,
      );
      final recoverableStatus = _resolveRecoverableStatus(
        isForOthers: input.isForOthers,
        recoverableBase: recoverableBase,
        recoveredAmount: recoveredAmount,
      );
      await (_db.update(
        _db.transactions,
      )..where((t) => t.id.equals(transactionId))).write(
        TransactionsCompanion(
          type: Value(input.type),
          amount: Value(input.amount),
          title: Value(input.title),
          category: Value(input.category),
          notes: Value(input.notes),
          transactionDate: Value(input.transactionDate),
          paymentSourceType: Value(input.paymentSourceType),
          paymentSourceId: Value(sourceId),
          cashbackAmount: Value(input.cashbackAmount),
          isForOthers: Value(input.isForOthers),
          recoverableAmount: Value(
            input.isForOthers ? remainingRecoverable : null,
          ),
          recoverableBaseAmount: Value(
            input.isForOthers ? recoverableBase : null,
          ),
          recoveredAmount: Value(recoveredAmount),
          recoverablePartyName: Value(input.recoverablePartyName),
          recoverablePartyNotes: Value(input.recoverablePartyNotes),
          recoverablePartyPhone: Value(input.recoverablePartyPhone),
          recoverableStatus: Value(recoverableStatus),
          recoveredAt: Value(
            recoveredAmount > 0
                ? (input.recoveredAt ?? existing.recoveredAt ?? DateTime.now())
                : null,
          ),
          cashbackDestinationType: Value(input.cashbackDestinationType),
          cashbackDestinationId: Value(input.cashbackDestinationId),
          relatedTransactionId: Value(input.relatedTransactionId),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });

    final updated = await (_db.select(
      _db.transactions,
    )..where((t) => t.id.equals(transactionId))).getSingleOrNull();
    await _billing.reconcileCardAfterMutation(
      previous: existing,
      current: updated,
    );
  }

  Future<void> deleteTransaction(int transactionId) async {
    final existing = await (_db.select(
      _db.transactions,
    )..where((t) => t.id.equals(transactionId))).getSingleOrNull();
    if (existing == null) return;
    if (!isEditable(existing)) {
      throw ArgumentError('This transaction type cannot be deleted safely');
    }

    await _db.transaction(() async {
      if (_mutatesLiveBalances(existing.transactionImpactType)) {
        await _reverseTransactionEffect(existing);
      }
      await (_db.delete(
        _db.transactions,
      )..where((t) => t.id.equals(transactionId))).go();
    });

    await _billing.reconcileCardAfterMutation(previous: existing);
  }

  double netExpense(Transaction txn) {
    return (txn.amount - txn.cashbackAmount).clamp(0, txn.amount);
  }

  Future<void> markRecovered(int transactionId) async {
    final existing = await (_db.select(
      _db.transactions,
    )..where((t) => t.id.equals(transactionId))).getSingleOrNull();
    if (existing == null) {
      throw ArgumentError('Transaction not found');
    }
    final recoverableBase =
        existing.recoverableBaseAmount ??
        (existing.amount - existing.cashbackAmount).clamp(0, existing.amount);
    if (!existing.isForOthers || recoverableBase <= 0) {
      throw ArgumentError('Transaction is not recoverable');
    }

    await (_db.update(
      _db.transactions,
    )..where((t) => t.id.equals(transactionId))).write(
      TransactionsCompanion(
        recoverableAmount: const Value(0),
        recoveredAmount: Value(recoverableBase.toDouble()),
        recoverableStatus: const Value('recovered'),
        recoveredAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  void _validate(AddTransactionInput input) {
    if (input.amount <= 0) {
      throw ArgumentError('Amount must be greater than 0');
    }
    if (input.paymentSourceId == null) {
      throw ArgumentError('Payment source is required');
    }
    final recoverableBase = _resolveRecoverableBase(input);
    final recoveredAmount = _resolveRecoveredAmount(input, recoverableBase);
    if (recoveredAmount > recoverableBase) {
      throw ArgumentError('Recovered amount cannot exceed recoverable base');
    }
    if (input.cashbackAmount > input.amount) {
      throw ArgumentError('Cashback cannot exceed total amount');
    }
    if (CashbackDestinationType.requiresDestinationId(
          input.cashbackDestinationType,
        ) &&
        input.cashbackDestinationId == null) {
      throw ArgumentError('Cashback destination is incomplete');
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

  Future<void> _applyTransactionEffect(AddTransactionInput input) async {
    final sourceId = input.paymentSourceId!;
    if (input.type == TransactionType.income) {
      await _applyIncome(input.paymentSourceType, sourceId, input.amount);
    } else if (input.type == TransactionType.refund) {
      await _applyRefund(input.paymentSourceType, sourceId, input.amount);
    } else {
      await _applyExpense(input.paymentSourceType, sourceId, input.amount);
    }
    await _applyCashbackDestinationEffect(input);
  }

  bool _mutatesLiveBalances(String? transactionImpactType) {
    return transactionImpactType != TransactionImpactType.historicalNoBalance;
  }

  double _resolveRecoverableBase(AddTransactionInput input) {
    if (!input.isForOthers) return 0;
    // Split expenses carry an explicit receivable (others' share only).
    if (input.transactionImpactType == 'splitPersonalShare' &&
        input.recoverableAmount != null) {
      return input.recoverableAmount!.clamp(0, input.amount).toDouble();
    }
    return (input.amount - input.cashbackAmount)
        .clamp(0, input.amount)
        .toDouble();
  }

  double _resolveRecoveredAmount(
    AddTransactionInput input,
    double recoverableBase, {
    double? fallbackRecovered,
  }) {
    if (!input.isForOthers) return 0;
    final recovered = input.recoveredAmount ?? fallbackRecovered ?? 0;
    return recovered.clamp(0, recoverableBase).toDouble();
  }

  double _resolveRemainingRecoverable(
    double recoverableBase,
    double recoveredAmount,
  ) {
    return (recoverableBase - recoveredAmount)
        .clamp(0, recoverableBase)
        .toDouble();
  }

  String _resolveRecoverableStatus({
    required bool isForOthers,
    required double recoverableBase,
    required double recoveredAmount,
  }) {
    if (!isForOthers || recoverableBase <= 0) return 'unpaid';
    if (recoveredAmount <= 0.009) return 'unpaid';
    if (recoveredAmount >= recoverableBase - 0.009) return 'recovered';
    return 'partial';
  }

  Future<void> _reverseTransactionEffect(Transaction txn) async {
    await _reverseCashbackDestinationEffect(txn);
    final sourceId = txn.paymentSourceId;
    if (txn.type == TransactionType.income) {
      await _applyExpense(txn.paymentSourceType, sourceId, txn.amount);
      return;
    }
    if (txn.type == TransactionType.refund) {
      if (txn.paymentSourceType == PaymentSourceType.creditCard) {
        await _applyExpense(PaymentSourceType.creditCard, sourceId, txn.amount);
      } else {
        await _applyExpense(txn.paymentSourceType, sourceId, txn.amount);
      }
      return;
    }
    await _applyIncome(txn.paymentSourceType, sourceId, txn.amount);
  }

  Future<void> _applyCashbackDestinationEffect(
    AddTransactionInput input,
  ) async {
    if (input.cashbackAmount <= 0) return;
    if (!CashbackDestinationType.appliesBalanceMutation(
      input.cashbackDestinationType,
    )) {
      return;
    }
    final destinationType = CashbackDestinationType.toPaymentSourceType(
      input.cashbackDestinationType,
    );
    final destinationId = input.cashbackDestinationId;
    if (destinationType == null || destinationId == null) return;
    await _applyIncome(destinationType, destinationId, input.cashbackAmount);
  }

  Future<void> _reverseCashbackDestinationEffect(Transaction txn) async {
    if (txn.cashbackAmount <= 0) return;
    if (!CashbackDestinationType.appliesBalanceMutation(
      txn.cashbackDestinationType,
    )) {
      return;
    }
    final destinationType = CashbackDestinationType.toPaymentSourceType(
      txn.cashbackDestinationType,
    );
    final destinationId = txn.cashbackDestinationId;
    if (destinationType == null || destinationId == null) return;
    await _applyExpense(destinationType, destinationId, txn.cashbackAmount);
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
    if (sourceType == PaymentSourceType.creditCard) return;
    await _applyIncome(sourceType, sourceId, amount);
  }

  Future<void> _adjustLinkedRecoverableAfterRefund({
    required int refundTransactionId,
    required int? relatedTransactionId,
    required double refundAmount,
  }) async {
    if (relatedTransactionId == null) return;
    final original = await (_db.select(
      _db.transactions,
    )..where((t) => t.id.equals(relatedTransactionId))).getSingleOrNull();
    if (original == null || !original.isForOthers) return;

    final originalBase =
        original.recoverableBaseAmount ??
        (original.amount - original.cashbackAmount)
            .clamp(0, original.amount)
            .toDouble();
    final nextBase = (originalBase - refundAmount)
        .clamp(0, originalBase)
        .toDouble();
    final overRecovered = original.recoveredAmount > nextBase + 0.009;
    final nextRecovered = original.recoveredAmount
        .clamp(0, nextBase)
        .toDouble();
    final nextRemaining = (nextBase - nextRecovered)
        .clamp(0, nextBase)
        .toDouble();
    final nextStatus = nextRemaining <= 0.009
        ? 'recovered'
        : nextRecovered <= 0.009
        ? 'unpaid'
        : 'partial';

    await (_db.update(
      _db.transactions,
    )..where((t) => t.id.equals(original.id))).write(
      TransactionsCompanion(
        recoverableBaseAmount: Value(nextBase),
        recoverableAmount: Value(nextRemaining),
        recoveredAmount: Value(nextRecovered),
        recoverableStatus: Value(nextStatus),
        recoveredAt: Value(nextRecovered > 0 ? original.recoveredAt : null),
        notes: Value(
          overRecovered
              ? _appendReviewNote(
                  original.notes,
                  'Refund reduced recoverable below already recovered amount.',
                )
              : original.notes,
        ),
        updatedAt: Value(DateTime.now()),
      ),
    );

    if (!overRecovered) return;
    final refund = await (_db.select(
      _db.transactions,
    )..where((t) => t.id.equals(refundTransactionId))).getSingleOrNull();
    if (refund == null) return;
    await (_db.update(
      _db.transactions,
    )..where((t) => t.id.equals(refund.id))).write(
      TransactionsCompanion(
        notes: Value(
          _appendReviewNote(
            refund.notes,
            'Refund caused recoverable over-recovery review on linked transaction.',
          ),
        ),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  String _appendReviewNote(String? existing, String note) {
    final trimmed = existing?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return '[Review] $note';
    }
    if (trimmed.contains(note)) return trimmed;
    return '$trimmed\n[Review] $note';
  }
}
