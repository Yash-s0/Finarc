import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../expenses/data/transaction_engine.dart';
import '../../expenses/models/transaction_types.dart';

class SplitShareInput {
  const SplitShareInput({
    required this.memberId,
    this.percentage,
    required this.exactAmount,
  });

  final int memberId;
  final double? percentage;
  final double exactAmount;
}

class AddSplitExpenseInput {
  const AddSplitExpenseInput({
    required this.groupId,
    required this.title,
    required this.totalAmount,
    required this.paidByMemberId,
    required this.splitType,
    required this.expenseDate,
    required this.category,
    required this.shares,
    this.notes,
    this.paymentSourceType,
    this.paymentSourceId,
  });

  final int groupId;
  final String title;
  final double totalAmount;
  final int paidByMemberId;
  final String splitType;
  final DateTime expenseDate;
  final String category;
  final String? notes;
  final List<SplitShareInput> shares;
  final String? paymentSourceType;
  final int? paymentSourceId;
}

class GroupMemberBalance {
  const GroupMemberBalance({required this.member, required this.net});

  final SplitMember member;
  final double net;
}

class BalanceTransfer {
  const BalanceTransfer({
    required this.fromMemberId,
    required this.toMemberId,
    required this.amount,
  });

  final int fromMemberId;
  final int toMemberId;
  final double amount;
}

class SplitService {
  SplitService(this._db, this._engine);

  final AppDatabase _db;
  final TransactionEngine _engine;

  Future<int> createGroup(String name, {String? description}) async {
    final id = await _db
        .into(_db.splitGroups)
        .insert(
          SplitGroupsCompanion.insert(
            name: name,
            description: Value(description),
            updatedAt: Value(DateTime.now()),
          ),
        );
    return id;
  }

  Future<void> updateGroup(
    int groupId, {
    String? name,
    String? description,
  }) async {
    await (_db.update(
      _db.splitGroups,
    )..where((g) => g.id.equals(groupId))).write(
      SplitGroupsCompanion(
        name: name == null ? const Value.absent() : Value(name),
        description: Value(description),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> archiveGroup(int groupId) async {
    await (_db.update(
      _db.splitGroups,
    )..where((g) => g.id.equals(groupId))).write(
      SplitGroupsCompanion(
        archivedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> addMember(
    int groupId, {
    required String name,
    String? contact,
    bool isCurrentUser = false,
  }) async {
    return _db
        .into(_db.splitMembers)
        .insert(
          SplitMembersCompanion.insert(
            groupId: groupId,
            name: name,
            contact: Value(contact),
            isCurrentUser: Value(isCurrentUser),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> updateMember(
    int memberId, {
    String? name,
    String? contact,
    bool? isCurrentUser,
  }) async {
    await (_db.update(
      _db.splitMembers,
    )..where((m) => m.id.equals(memberId))).write(
      SplitMembersCompanion(
        name: name == null ? const Value.absent() : Value(name),
        contact: contact == null ? const Value.absent() : Value(contact),
        isCurrentUser: isCurrentUser == null
            ? const Value.absent()
            : Value(isCurrentUser),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> removeMember(int memberId) async {
    await (_db.delete(
      _db.splitMembers,
    )..where((m) => m.id.equals(memberId))).go();
  }

  List<SplitShareInput> calculateEqualSplit({
    required List<int> memberIds,
    required double totalAmount,
  }) {
    if (memberIds.isEmpty) throw ArgumentError('At least one member required');
    final each = double.parse(
      (totalAmount / memberIds.length).toStringAsFixed(2),
    );
    var running = 0.0;
    final shares = <SplitShareInput>[];
    for (var i = 0; i < memberIds.length; i++) {
      final amount = i == memberIds.length - 1
          ? double.parse((totalAmount - running).toStringAsFixed(2))
          : each;
      running += amount;
      shares.add(SplitShareInput(memberId: memberIds[i], exactAmount: amount));
    }
    return shares;
  }

  List<SplitShareInput> calculatePercentageSplit({
    required Map<int, double> percentagesByMember,
    required double totalAmount,
  }) {
    final totalPct = percentagesByMember.values.fold<double>(
      0,
      (a, b) => a + b,
    );
    if ((totalPct - 100).abs() > 0.001) {
      throw ArgumentError('Percentage total must be 100');
    }
    var running = 0.0;
    var index = 0;
    final entries = percentagesByMember.entries.toList(growable: false);
    final shares = <SplitShareInput>[];
    for (final entry in entries) {
      index += 1;
      final amount = index == entries.length
          ? double.parse((totalAmount - running).toStringAsFixed(2))
          : double.parse(
              (totalAmount * (entry.value / 100)).toStringAsFixed(2),
            );
      running += amount;
      shares.add(
        SplitShareInput(
          memberId: entry.key,
          percentage: entry.value,
          exactAmount: amount,
        ),
      );
    }
    return shares;
  }

  List<SplitShareInput> calculateExactSplit(
    Map<int, double> exactAmountsByMember,
  ) {
    return exactAmountsByMember.entries
        .map((e) => SplitShareInput(memberId: e.key, exactAmount: e.value))
        .toList(growable: false);
  }

  void validateSplitShares({
    required String splitType,
    required List<SplitShareInput> shares,
    required double totalAmount,
  }) {
    if (shares.isEmpty) throw ArgumentError('Shares cannot be empty');
    final total = shares.fold<double>(0, (s, x) => s + x.exactAmount);
    if ((total - totalAmount).abs() > 0.01) {
      throw ArgumentError('Share amounts must equal total amount');
    }
    if (splitType == 'percentage') {
      final pct = shares.fold<double>(0, (s, x) => s + (x.percentage ?? 0));
      if ((pct - 100).abs() > 0.001) {
        throw ArgumentError('Percentage split must total 100%');
      }
    }
  }

  Future<int> addSplitExpense(AddSplitExpenseInput input) async {
    validateSplitShares(
      splitType: input.splitType,
      shares: input.shares,
      totalAmount: input.totalAmount,
    );

    final currentUser = await _currentUserMember(input.groupId);
    final userShare = input.shares
        .where((s) => s.memberId == currentUser?.id)
        .fold<double>(0, (s, x) => s + x.exactAmount);

    return _db.transaction(() async {
      final splitExpenseId = await _db
          .into(_db.splitExpenses)
          .insert(
            SplitExpensesCompanion.insert(
              groupId: input.groupId,
              title: input.title,
              totalAmount: input.totalAmount,
              paidByMemberId: input.paidByMemberId,
              splitType: input.splitType,
              expenseDate: input.expenseDate,
              category: input.category,
              notes: Value(input.notes),
              linkedTransactionId: const Value(null),
              updatedAt: Value(DateTime.now()),
            ),
          );

      for (final share in input.shares) {
        await _db
            .into(_db.splitExpenseShares)
            .insert(
              SplitExpenseSharesCompanion.insert(
                splitExpenseId: splitExpenseId,
                memberId: share.memberId,
                percentage: Value(share.percentage),
                exactAmount: share.exactAmount,
                updatedAt: Value(DateTime.now()),
              ),
            );
      }

      int? linkedTxnId;
      final isCurrentUserPayer =
          currentUser != null && currentUser.id == input.paidByMemberId;
      if (isCurrentUserPayer) {
        if (input.paymentSourceType == null || input.paymentSourceId == null) {
          throw ArgumentError('Payment source required when current user paid');
        }
        final transactionType =
            input.paymentSourceType == PaymentSourceType.creditCard
            ? TransactionType.creditCard
            : input.paymentSourceType!;
        final recoverable = (input.totalAmount - userShare)
            .clamp(0, input.totalAmount)
            .toDouble();

        await _engine.addTransaction(
          AddTransactionInput(
            type: transactionType,
            amount: input.totalAmount,
            title: input.title,
            category: input.category,
            notes: input.notes,
            transactionDate: input.expenseDate,
            paymentSourceType: input.paymentSourceType!,
            paymentSourceId: input.paymentSourceId,
            isForOthers: recoverable > 0,
            recoverableAmount: recoverable > 0 ? recoverable : null,
            linkedSplitExpenseId: splitExpenseId,
            personalShareAmount: userShare,
            splitGroupId: input.groupId,
            transactionImpactType: 'splitPersonalShare',
          ),
        );
        final inserted =
            await (_db.select(_db.transactions)
                  ..orderBy([(t) => OrderingTerm.desc(t.id)])
                  ..limit(1))
                .getSingle();
        linkedTxnId = inserted.id;
      }

      if (linkedTxnId != null) {
        await (_db.update(
          _db.splitExpenses,
        )..where((s) => s.id.equals(splitExpenseId))).write(
          SplitExpensesCompanion(
            linkedTransactionId: Value(linkedTxnId),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }

      return splitExpenseId;
    });
  }

  Future<void> updateSplitExpense(
    int splitExpenseId,
    AddSplitExpenseInput input,
  ) async {
    // For safety in phase 10, only metadata edits are supported.
    await (_db.update(
      _db.splitExpenses,
    )..where((s) => s.id.equals(splitExpenseId))).write(
      SplitExpensesCompanion(
        title: Value(input.title),
        category: Value(input.category),
        notes: Value(input.notes),
        expenseDate: Value(input.expenseDate),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteSplitExpense(int splitExpenseId) async {
    await (_db.delete(
      _db.splitExpenseShares,
    )..where((s) => s.splitExpenseId.equals(splitExpenseId))).go();
    await (_db.delete(
      _db.splitExpenses,
    )..where((s) => s.id.equals(splitExpenseId))).go();
  }

  Future<List<GroupMemberBalance>> getGroupBalances(int groupId) async {
    final members = await (_db.select(
      _db.splitMembers,
    )..where((m) => m.groupId.equals(groupId))).get();
    final net = await _groupNetByMember(groupId);
    return members
        .map((m) => GroupMemberBalance(member: m, net: net[m.id] ?? 0))
        .toList(growable: false);
  }

  Future<double> getMemberBalance(int groupId, int memberId) async {
    final net = await _groupNetByMember(groupId);
    return net[memberId] ?? 0;
  }

  Future<double> getCurrentUserReceivables() async {
    final value = await _currentUserReceivablePayable();
    return value.$1;
  }

  Future<double> getCurrentUserPayables() async {
    final value = await _currentUserReceivablePayable();
    return value.$2;
  }

  Future<double> getTotalRecoverableAmount() => getCurrentUserReceivables();

  Future<double> getTotalPayableAmount() => getCurrentUserPayables();

  Future<List<BalanceTransfer>> simplifyGroupBalances(int groupId) async {
    final net = await _groupNetByMember(groupId);
    final debtors = <MapEntry<int, double>>[];
    final creditors = <MapEntry<int, double>>[];

    net.forEach((memberId, balance) {
      if (balance > 0.009) {
        creditors.add(MapEntry(memberId, balance));
      } else if (balance < -0.009) {
        debtors.add(MapEntry(memberId, balance.abs()));
      }
    });

    final transfers = <BalanceTransfer>[];
    var i = 0;
    var j = 0;
    while (i < debtors.length && j < creditors.length) {
      final d = debtors[i];
      final c = creditors[j];
      final amount = d.value < c.value ? d.value : c.value;
      transfers.add(
        BalanceTransfer(
          fromMemberId: d.key,
          toMemberId: c.key,
          amount: double.parse(amount.toStringAsFixed(2)),
        ),
      );
      debtors[i] = MapEntry(d.key, d.value - amount);
      creditors[j] = MapEntry(c.key, c.value - amount);
      if (debtors[i].value <= 0.009) i += 1;
      if (creditors[j].value <= 0.009) j += 1;
    }
    return transfers;
  }

  Future<int> addSettlement({
    required int groupId,
    required int fromMemberId,
    required int toMemberId,
    required double amount,
    required DateTime settlementDate,
    String? paymentSourceType,
    int? paymentSourceId,
    String? notes,
  }) async {
    final currentUser = await _currentUserMember(groupId);
    int? linkedTxnId;

    if (currentUser != null &&
        (currentUser.id == fromMemberId || currentUser.id == toMemberId) &&
        paymentSourceType != null &&
        paymentSourceId != null) {
      if (currentUser.id == fromMemberId) {
        await _engine.addTransaction(
          AddTransactionInput(
            type: paymentSourceType == PaymentSourceType.creditCard
                ? TransactionType.creditCard
                : paymentSourceType,
            amount: amount,
            title: 'Split settlement payment',
            category: 'Split Settlement',
            notes: notes,
            transactionDate: settlementDate,
            paymentSourceType: paymentSourceType,
            paymentSourceId: paymentSourceId,
            splitGroupId: groupId,
            transactionImpactType: 'splitSettlementPaid',
          ),
        );
      } else {
        await _engine.addTransaction(
          AddTransactionInput(
            type: TransactionType.income,
            amount: amount,
            title: 'Split settlement received',
            category: 'Split Settlement',
            notes: notes,
            transactionDate: settlementDate,
            paymentSourceType: paymentSourceType,
            paymentSourceId: paymentSourceId,
            splitGroupId: groupId,
            transactionImpactType: 'splitSettlementReceived',
          ),
        );
      }
      final inserted =
          await (_db.select(_db.transactions)
                ..orderBy([(t) => OrderingTerm.desc(t.id)])
                ..limit(1))
              .getSingle();
      linkedTxnId = inserted.id;
    }

    final id = await _db
        .into(_db.splitSettlements)
        .insert(
          SplitSettlementsCompanion.insert(
            groupId: groupId,
            fromMemberId: fromMemberId,
            toMemberId: toMemberId,
            amount: amount,
            paymentSourceType: Value(paymentSourceType),
            paymentSourceId: Value(paymentSourceId),
            settlementDate: settlementDate,
            linkedTransactionId: Value(linkedTxnId),
            notes: Value(notes),
            updatedAt: Value(DateTime.now()),
          ),
        );

    return id;
  }

  Future<void> markShareSettled(int shareId, bool isSettled) async {
    await (_db.update(
      _db.splitExpenseShares,
    )..where((s) => s.id.equals(shareId))).write(
      SplitExpenseSharesCompanion(
        isSettled: Value(isSettled),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<SplitSettlement>> getSettlementHistory(int groupId) {
    return (_db.select(_db.splitSettlements)
          ..where((s) => s.groupId.equals(groupId))
          ..orderBy([(s) => OrderingTerm.desc(s.settlementDate)]))
        .get();
  }

  Future<Map<int, double>> _groupNetByMember(int groupId) async {
    final members = await (_db.select(
      _db.splitMembers,
    )..where((m) => m.groupId.equals(groupId))).get();
    final expenses = await (_db.select(
      _db.splitExpenses,
    )..where((e) => e.groupId.equals(groupId))).get();
    final settlements = await (_db.select(
      _db.splitSettlements,
    )..where((s) => s.groupId.equals(groupId))).get();
    final net = <int, double>{for (final m in members) m.id: 0};

    for (final expense in expenses) {
      final shares = await (_db.select(
        _db.splitExpenseShares,
      )..where((s) => s.splitExpenseId.equals(expense.id))).get();
      for (final share in shares) {
        net[share.memberId] = (net[share.memberId] ?? 0) - share.exactAmount;
        net[expense.paidByMemberId] =
            (net[expense.paidByMemberId] ?? 0) + share.exactAmount;
      }
    }

    for (final settlement in settlements) {
      net[settlement.fromMemberId] =
          (net[settlement.fromMemberId] ?? 0) + settlement.amount;
      net[settlement.toMemberId] =
          (net[settlement.toMemberId] ?? 0) - settlement.amount;
    }

    return net;
  }

  Future<(double, double)> _currentUserReceivablePayable() async {
    final groups = await (_db.select(
      _db.splitGroups,
    )..where((g) => g.archivedAt.isNull())).get();
    var receivable = 0.0;
    var payable = 0.0;
    for (final group in groups) {
      final currentUser = await _currentUserMember(group.id);
      if (currentUser == null) continue;
      final balance = await getMemberBalance(group.id, currentUser.id);
      if (balance > 0) {
        receivable += balance;
      } else {
        payable += balance.abs();
      }
    }
    return (receivable, payable);
  }

  Future<SplitMember?> _currentUserMember(int groupId) async {
    return (_db.select(_db.splitMembers)..where(
          (m) => m.groupId.equals(groupId) & m.isCurrentUser.equals(true),
        ))
        .getSingleOrNull();
  }
}
