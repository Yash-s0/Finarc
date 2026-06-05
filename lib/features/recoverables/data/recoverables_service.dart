import 'package:drift/drift.dart';
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

class RecoverableBillingState {
  static const none = 'none';
  static const unbilled = 'unbilled';
  static const billed = 'billed';
  static const paid = 'paid';
  static const needsReview = 'needsReview';
}

class RecoverableSourceFilter {
  static const all = 'all';
  static const card = 'card';
  static const bankUpi = 'bankUpi';
  static const cash = 'cash';
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
    required this.sourceFilter,
    required this.billingState,
    required this.dueDate,
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
  final String sourceFilter;
  final String billingState;
  final DateTime? dueDate;
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

  double get originalTotal =>
      items.fold<double>(0, (sum, item) => sum + item.recoverableBaseAmount);
  double get recoveredTotal =>
      items.fold<double>(0, (sum, item) => sum + item.recoveredAmount);
  double get remainingTotal =>
      items.fold<double>(0, (sum, item) => sum + item.openAmount);
  double get openTotal => remainingTotal;
  double get settledTotal => recoveredTotal;
  int get transactionCount => items.length;

  DateTime? get nearestDueDate {
    final dueDates =
        items
            .where(
              (item) =>
                  !item.isRecovered &&
                  (item.billingState == RecoverableBillingState.billed ||
                      item.billingState ==
                          RecoverableBillingState.needsReview) &&
                  item.dueDate != null,
            )
            .map((item) => item.dueDate!)
            .toList(growable: false)
          ..sort((a, b) => a.compareTo(b));
    return dueDates.isEmpty ? null : dueDates.first;
  }

  List<String> get sourceSummary {
    final values = <String>{};
    for (final item in items) {
      switch (item.sourceFilter) {
        case RecoverableSourceFilter.card:
          values.add('Card');
          break;
        case RecoverableSourceFilter.cash:
          values.add('Cash');
          break;
        case RecoverableSourceFilter.bankUpi:
          if (item.paymentSourceType == PaymentSourceType.upi) {
            values.add('UPI');
          } else {
            values.add('Bank');
          }
          break;
      }
    }
    final ordered = values.toList()..sort();
    return ordered;
  }

  List<RecoverableTransactionItem> itemsForFilter(String filter) {
    if (filter == RecoverableSourceFilter.all) return items;
    return items
        .where((item) => item.sourceFilter == filter)
        .toList(growable: false);
  }
}

class RecordRecoveryResult {
  const RecordRecoveryResult({
    required this.partyName,
    required this.requestedAmount,
    required this.appliedAmount,
    required this.remainingAfter,
    required this.openBefore,
    required this.clamped,
    required this.updatedTransactionCount,
  });

  final String partyName;
  final double requestedAmount;
  final double appliedAmount;
  final double remainingAfter;
  final double openBefore;
  final bool clamped;
  final int updatedTransactionCount;
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
    final data = await _loadRecoverableData();
    final normalItems = data.items;

    final cardBilledItems =
        normalItems
            .where((item) => item.bucket == RecoverableBuckets.cardBilled)
            .toList(growable: false)
          ..sort(_sortNewestFirst);
    final cardUnbilledItems =
        normalItems
            .where((item) => item.bucket == RecoverableBuckets.cardUnbilled)
            .toList(growable: false)
          ..sort(_sortNewestFirst);
    final bankUpiItems =
        normalItems
            .where((item) => item.bucket == RecoverableBuckets.bankUpi)
            .toList(growable: false)
          ..sort(_sortNewestFirst);
    final cashItems =
        normalItems
            .where((item) => item.bucket == RecoverableBuckets.cash)
            .toList(growable: false)
          ..sort(_sortNewestFirst);
    final recoveredItems =
        normalItems
            .where((item) => item.bucket == RecoverableBuckets.recovered)
            .toList(growable: false)
          ..sort(_sortNewestFirst);

    final openItems = normalItems
        .where((item) => !item.isRecovered)
        .toList(growable: false);
    final groups = _buildGroups(openItems);

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

  Future<RecoverablePartyGroup?> getPartyGroup(String partyName) async {
    final data = await _loadRecoverableData();
    final items = data.items
        .where((item) => item.partyName == partyName && !item.isRecovered)
        .toList(growable: false);
    if (items.isEmpty) return null;
    return _buildGroup(partyName, items);
  }

  Future<RecordRecoveryResult> recordRecovery({
    required String partyName,
    required double amount,
    DateTime? recoveryDate,
  }) async {
    final data = await _loadRecoverableData();
    final candidates =
        data.items
            .where((item) => item.partyName == partyName && !item.isRecovered)
            .toList(growable: false)
          ..sort(_recoveryPriorityCompare);
    final openBefore = candidates.fold<double>(
      0,
      (sum, item) => sum + item.openAmount,
    );
    final requestedAmount = amount.isFinite ? amount : 0;
    final normalizedRequested = requestedAmount.clamp(0, double.infinity);
    final appliedAmount = normalizedRequested.clamp(0, openBefore).toDouble();
    final now = recoveryDate ?? _now();
    var remainingToApply = appliedAmount;
    var updatedTransactionCount = 0;

    if (appliedAmount > 0.009) {
      await _db.transaction(() async {
        for (final item in candidates) {
          if (remainingToApply <= 0.009) break;
          final apply = remainingToApply.clamp(0, item.openAmount).toDouble();
          if (apply <= 0.009) continue;
          final nextRecovered = (item.recoveredAmount + apply)
              .clamp(0, item.recoverableBaseAmount)
              .toDouble();
          final nextRemaining = (item.recoverableBaseAmount - nextRecovered)
              .clamp(0, item.recoverableBaseAmount)
              .toDouble();
          final nextStatus = nextRemaining <= 0.009
              ? 'recovered'
              : nextRecovered <= 0.009
              ? 'unpaid'
              : 'partial';

          await (_db.update(
            _db.transactions,
          )..where((t) => t.id.equals(item.id))).write(
            TransactionsCompanion(
              recoverableAmount: Value(nextRemaining),
              recoveredAmount: Value(nextRecovered),
              recoverableStatus: Value(nextStatus),
              recoveredAt: nextRecovered > 0.009 && nextRemaining <= 0.009
                  ? Value(now)
                  : const Value.absent(),
              updatedAt: Value(now),
            ),
          );
          remainingToApply -= apply;
          updatedTransactionCount += 1;
        }
      });
    }

    return RecordRecoveryResult(
      partyName: partyName,
      requestedAmount: normalizedRequested.toDouble(),
      appliedAmount: appliedAmount,
      remainingAfter: (openBefore - appliedAmount).clamp(0, openBefore),
      openBefore: openBefore,
      clamped: normalizedRequested > openBefore + 0.009,
      updatedTransactionCount: updatedTransactionCount,
    );
  }

  Future<_RecoverableData> _loadRecoverableData() async {
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
          final bill = t.cardBillId == null ? null : billById[t.cardBillId!];
          final billingState = _resolveBillingState(txn: t, bill: bill);
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
            sourceFilter: _resolveSourceFilter(t.paymentSourceType),
            billingState: billingState,
            dueDate: bill?.dueDate,
            isActionable: actionable,
          );
        })
        .toList(growable: false);
    return _RecoverableData(items: normalItems, billById: billById);
  }

  Future<void> markRecovered(int transactionId) {
    return _engine.markRecovered(transactionId);
  }

  String _partyName(Transaction txn) {
    final raw = txn.recoverablePartyName?.trim();
    if (raw != null && raw.isNotEmpty) return raw;
    return 'Unassigned';
  }

  List<RecoverablePartyGroup> _buildGroups(
    List<RecoverableTransactionItem> openItems,
  ) {
    final grouped = <String, List<RecoverableTransactionItem>>{};
    for (final item in openItems) {
      grouped.putIfAbsent(item.partyName, () => []).add(item);
    }
    final groups =
        grouped.entries
            .map((entry) => _buildGroup(entry.key, entry.value))
            .toList(growable: false)
          ..sort((a, b) {
            final remainingCompare = b.remainingTotal.compareTo(
              a.remainingTotal,
            );
            if (remainingCompare != 0) return remainingCompare;
            return a.partyName.toLowerCase().compareTo(
              b.partyName.toLowerCase(),
            );
          });
    return groups;
  }

  RecoverablePartyGroup _buildGroup(
    String partyName,
    List<RecoverableTransactionItem> items,
  ) {
    final sorted = [...items]..sort(_sortNewestFirst);
    return RecoverablePartyGroup(
      partyName: partyName,
      items: sorted,
      partyNotes: sorted.isEmpty ? null : sorted.first.partyNotes,
      partyPhone: sorted.isEmpty ? null : sorted.first.partyPhone,
    );
  }

  int _sortNewestFirst(
    RecoverableTransactionItem a,
    RecoverableTransactionItem b,
  ) => b.transactionDate.compareTo(a.transactionDate);

  String _resolveSourceFilter(String paymentSourceType) {
    if (paymentSourceType == PaymentSourceType.creditCard) {
      return RecoverableSourceFilter.card;
    }
    if (paymentSourceType == PaymentSourceType.cash) {
      return RecoverableSourceFilter.cash;
    }
    return RecoverableSourceFilter.bankUpi;
  }

  String _resolveBillingState({
    required Transaction txn,
    required CardBill? bill,
  }) {
    if (txn.paymentSourceType != PaymentSourceType.creditCard) {
      return RecoverableBillingState.none;
    }
    if (txn.cardBillId == null || bill == null) {
      return RecoverableBillingState.unbilled;
    }
    if (bill.status == 'needsReview') {
      return RecoverableBillingState.needsReview;
    }
    if (_isBillStillUnpaid(bill)) {
      return RecoverableBillingState.billed;
    }
    return RecoverableBillingState.paid;
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

  int _recoveryPriorityCompare(
    RecoverableTransactionItem a,
    RecoverableTransactionItem b,
  ) {
    final priorityA = _recoveryPriority(a);
    final priorityB = _recoveryPriority(b);
    if (priorityA != priorityB) return priorityA.compareTo(priorityB);

    if (priorityA == 0) {
      final dueCompare = _compareNullableDateAsc(a.dueDate, b.dueDate);
      if (dueCompare != 0) return dueCompare;
    }

    final dateCompare = a.transactionDate.compareTo(b.transactionDate);
    if (dateCompare != 0) return dateCompare;
    return a.id.compareTo(b.id);
  }

  int _recoveryPriority(RecoverableTransactionItem item) {
    if (item.billingState == RecoverableBillingState.billed ||
        item.billingState == RecoverableBillingState.needsReview) {
      return 0;
    }
    if (item.sourceFilter == RecoverableSourceFilter.card &&
        item.billingState == RecoverableBillingState.unbilled) {
      return 2;
    }
    return 1;
  }

  int _compareNullableDateAsc(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }
}

class _RecoverableData {
  const _RecoverableData({required this.items, required this.billById});

  final List<RecoverableTransactionItem> items;
  final Map<int, CardBill> billById;
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
