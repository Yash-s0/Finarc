import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../cards/data/billing_service.dart';
import '../../expenses/data/expenses_providers.dart';
import '../../expenses/data/transaction_engine.dart';
import '../../expenses/models/transaction_types.dart';
import '../../split/data/split_providers.dart';
import '../../split/data/split_service.dart';

class RecoverableBuckets {
  static const cardBilled = 'cardBilled';
  static const cardUnbilled = 'cardUnbilled';
  static const bankUpi = 'bankUpi';
  static const cash = 'cash';
  static const recovered = 'recovered';
}

class RecoverableTransactionItem {
  const RecoverableTransactionItem({
    required this.id,
    required this.title,
    required this.category,
    required this.transactionDate,
    required this.amount,
    required this.cashbackAmount,
    required this.recoverableBaseAmount,
    required this.recoveredAmount,
    required this.remainingRecoverableAmount,
    required this.partyName,
    required this.partyNotes,
    required this.partyPhone,
    required this.status,
    required this.recoveredAt,
    required this.paymentSourceType,
    required this.bucket,
    required this.isActionable,
  });

  final int id;
  final String title;
  final String category;
  final DateTime transactionDate;
  final double amount;
  final double cashbackAmount;
  final double recoverableBaseAmount;
  final double recoveredAmount;
  final double remainingRecoverableAmount;
  final String partyName;
  final String? partyNotes;
  final String? partyPhone;
  final String status;
  final DateTime? recoveredAt;
  final String paymentSourceType;
  final String bucket;
  final bool isActionable;

  bool get isRecovered => status == 'recovered';
  bool get isPartial => status == 'partial';
  double get openAmount => remainingRecoverableAmount;
}

class RecoverablePartyGroup {
  const RecoverablePartyGroup({
    required this.partyName,
    required this.items,
    this.partyNotes,
    this.partyPhone,
  });

  final String partyName;
  final List<RecoverableTransactionItem> items;
  final String? partyNotes;
  final String? partyPhone;

  double get openTotal =>
      items.fold<double>(0, (sum, item) => sum + item.openAmount);
  double get settledTotal =>
      items.fold<double>(0, (sum, item) => sum + item.recoveredAmount);
}

class RecoverablesSnapshot {
  const RecoverablesSnapshot({
    required this.actionableRecoverables,
    required this.totalRecoverable,
    required this.cardBilledRecoverables,
    required this.cardUnbilledRecoverables,
    required this.bankUpiRecoverables,
    required this.cashRecoverables,
    required this.normalRecoverables,
    required this.settledRecoverables,
    required this.splitReceivables,
    required this.groups,
    required this.cardBilledItems,
    required this.cardUnbilledItems,
    required this.bankUpiItems,
    required this.cashItems,
    required this.recoveredItems,
  });

  final double actionableRecoverables;
  final double totalRecoverable;
  final double cardBilledRecoverables;
  final double cardUnbilledRecoverables;
  final double bankUpiRecoverables;
  final double cashRecoverables;
  final double normalRecoverables;
  final double settledRecoverables;
  final double splitReceivables;
  final List<RecoverablePartyGroup> groups;
  final List<RecoverableTransactionItem> cardBilledItems;
  final List<RecoverableTransactionItem> cardUnbilledItems;
  final List<RecoverableTransactionItem> bankUpiItems;
  final List<RecoverableTransactionItem> cashItems;
  final List<RecoverableTransactionItem> recoveredItems;

  // Phase-2 aliases for app-wide consumer alignment.
  double get actionableRecoverableTotal => actionableRecoverables;
  double get allRecoverableTotal => totalRecoverable;
  double get recoveredRecoverables => settledRecoverables;
}

class RecoverablesService {
  RecoverablesService(
    this._db,
    this._splitService,
    this._engine, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final SplitService _splitService;
  final TransactionEngine _engine;
  final DateTime Function() _now;

  Future<RecoverablesSnapshot> buildSnapshot() async {
    // Keep cardBillId assignments up-to-date before bucket classification.
    await BillingService(
      _db,
      now: _now,
    ).getAllCardBillingSnapshots(now: _now());
    final bills = await _db.select(_db.cardBills).get();
    final billById = {for (final bill in bills) bill.id: bill};
    final txns = await _db.select(_db.transactions).get();
    final normalItems = txns
        .where(
          (t) =>
              t.isForOthers &&
              t.linkedSplitExpenseId == null &&
              ((t.recoverableBaseAmount ?? 0) > 0 ||
                  (t.recoverableAmount ?? 0) > 0),
        )
        .map((t) {
          final recoverableBase =
              t.recoverableBaseAmount ??
              (t.amount - t.cashbackAmount).clamp(0, t.amount).toDouble();
          final recoveredAmount = (t.recoveredAmount).clamp(0, recoverableBase);
          final remainingAmount = (recoverableBase - recoveredAmount)
              .clamp(0, recoverableBase)
              .toDouble();
          final status = remainingAmount <= 0.009
              ? 'recovered'
              : recoveredAmount <= 0.009
              ? 'unpaid'
              : 'partial';
          final bucket = _resolveBucket(
            txn: t,
            status: status,
            remainingAmount: remainingAmount,
            billById: billById,
          );
          final actionable = _isActionableBucket(bucket);

          return RecoverableTransactionItem(
            id: t.id,
            title: t.title,
            category: t.category,
            transactionDate: t.transactionDate,
            amount: t.amount,
            cashbackAmount: t.cashbackAmount,
            recoverableBaseAmount: recoverableBase,
            recoveredAmount: recoveredAmount.toDouble(),
            remainingRecoverableAmount: remainingAmount,
            partyName: _partyName(t),
            partyNotes: t.recoverablePartyNotes,
            partyPhone: t.recoverablePartyPhone,
            status: status,
            recoveredAt: t.recoveredAt,
            paymentSourceType: t.paymentSourceType,
            bucket: bucket,
            isActionable: actionable,
          );
        })
        .toList(growable: false);

    final cardBilledItems =
        normalItems
            .where((item) => item.bucket == RecoverableBuckets.cardBilled)
            .toList(growable: false)
          ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    final cardUnbilledItems =
        normalItems
            .where((item) => item.bucket == RecoverableBuckets.cardUnbilled)
            .toList(growable: false)
          ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    final bankUpiItems =
        normalItems
            .where((item) => item.bucket == RecoverableBuckets.bankUpi)
            .toList(growable: false)
          ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    final cashItems =
        normalItems
            .where((item) => item.bucket == RecoverableBuckets.cash)
            .toList(growable: false)
          ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    final recoveredItems =
        normalItems
            .where((item) => item.bucket == RecoverableBuckets.recovered)
            .toList(growable: false)
          ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

    final openItems = normalItems
        .where((item) => !item.isRecovered)
        .toList(growable: false);
    final grouped = <String, List<RecoverableTransactionItem>>{};
    for (final item in openItems) {
      grouped.putIfAbsent(item.partyName, () => []).add(item);
    }

    final groups =
        grouped.entries
            .map(
              (entry) => RecoverablePartyGroup(
                partyName: entry.key,
                items: entry.value
                  ..sort(
                    (a, b) => b.transactionDate.compareTo(a.transactionDate),
                  ),
                partyNotes: entry.value.isEmpty
                    ? null
                    : entry.value.first.partyNotes,
                partyPhone: entry.value.isEmpty
                    ? null
                    : entry.value.first.partyPhone,
              ),
            )
            .toList(growable: false)
          ..sort((a, b) => b.openTotal.compareTo(a.openTotal));

    final openRecoverables = openItems.fold<double>(
      0,
      (sum, item) => sum + item.openAmount,
    );
    final settledRecoverables = normalItems.fold<double>(
      0,
      (sum, item) => sum + item.recoveredAmount,
    );
    final cardBilledRecoverables = cardBilledItems.fold<double>(
      0,
      (sum, item) => sum + item.openAmount,
    );
    final cardUnbilledRecoverables = cardUnbilledItems.fold<double>(
      0,
      (sum, item) => sum + item.openAmount,
    );
    final bankUpiRecoverables = bankUpiItems.fold<double>(
      0,
      (sum, item) => sum + item.openAmount,
    );
    final cashRecoverables = cashItems.fold<double>(
      0,
      (sum, item) => sum + item.openAmount,
    );
    final actionableRecoverables =
        cardBilledRecoverables + bankUpiRecoverables + cashRecoverables;
    final splitReceivables = await _splitService.getCurrentUserReceivables();

    return RecoverablesSnapshot(
      actionableRecoverables: actionableRecoverables,
      totalRecoverable: openRecoverables + splitReceivables,
      cardBilledRecoverables: cardBilledRecoverables,
      cardUnbilledRecoverables: cardUnbilledRecoverables,
      bankUpiRecoverables: bankUpiRecoverables,
      cashRecoverables: cashRecoverables,
      normalRecoverables: openRecoverables,
      settledRecoverables: settledRecoverables,
      splitReceivables: splitReceivables,
      groups: groups,
      cardBilledItems: cardBilledItems,
      cardUnbilledItems: cardUnbilledItems,
      bankUpiItems: bankUpiItems,
      cashItems: cashItems,
      recoveredItems: recoveredItems,
    );
  }

  Future<void> markRecovered(int transactionId) {
    return _engine.markRecovered(transactionId);
  }

  String _partyName(Transaction txn) {
    final raw = txn.recoverablePartyName?.trim();
    if (raw != null && raw.isNotEmpty) return raw;
    return 'Unassigned';
  }

  String _resolveBucket({
    required Transaction txn,
    required String status,
    required double remainingAmount,
    required Map<int, CardBill> billById,
  }) {
    if (status == 'recovered' || remainingAmount <= 0.009) {
      return RecoverableBuckets.recovered;
    }

    if (txn.paymentSourceType == PaymentSourceType.creditCard) {
      final billId = txn.cardBillId;
      if (billId == null) {
        return RecoverableBuckets.cardUnbilled;
      }
      final bill = billById[billId];
      if (bill != null && _isBillStillUnpaid(bill)) {
        return RecoverableBuckets.cardBilled;
      }
      // Card charge was already settled as a bill payment, treat as cash-outflow
      // recoverable (same behavior as bank/UPI recoverables).
      return RecoverableBuckets.bankUpi;
    }

    if (txn.paymentSourceType == PaymentSourceType.cash) {
      return RecoverableBuckets.cash;
    }
    return RecoverableBuckets.bankUpi;
  }

  bool _isActionableBucket(String bucket) =>
      bucket == RecoverableBuckets.cardBilled ||
      bucket == RecoverableBuckets.bankUpi ||
      bucket == RecoverableBuckets.cash;

  bool _isBillStillUnpaid(CardBill bill) =>
      bill.status != 'paid' && (bill.billedAmount - bill.paidAmount) > 0.009;
}

final recoverablesServiceProvider = Provider<RecoverablesService>((ref) {
  return RecoverablesService(
    ref.read(appDatabaseProvider),
    ref.read(splitServiceProvider),
    ref.read(transactionEngineProvider),
  );
});

final recoverablesSnapshotProvider = FutureProvider<RecoverablesSnapshot>((
  ref,
) async {
  await ref.watch(seedProvider.future);
  return ref.read(recoverablesServiceProvider).buildSnapshot();
});
