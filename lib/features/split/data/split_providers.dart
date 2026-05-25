import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../alerts/data/alerts_providers.dart';
import '../../expenses/data/expenses_providers.dart';
import 'split_service.dart';

final splitServiceProvider = Provider<SplitService>((ref) {
  return SplitService(
    ref.read(appDatabaseProvider),
    ref.read(transactionEngineProvider),
  );
});

class SplitDashboardSnapshot {
  const SplitDashboardSnapshot({
    required this.receivable,
    required this.payable,
    required this.groups,
    required this.groupNetById,
    required this.groupMemberCountById,
    required this.recentExpenses,
    required this.recentSettlements,
  });

  final double receivable;
  final double payable;
  final List<SplitGroup> groups;
  final Map<int, double> groupNetById;
  final Map<int, int> groupMemberCountById;
  final List<SplitExpense> recentExpenses;
  final List<SplitSettlement> recentSettlements;
}

final splitDashboardProvider = FutureProvider<SplitDashboardSnapshot>((
  ref,
) async {
  await ref.watch(seedProvider.future);
  final db = ref.read(appDatabaseProvider);
  final service = ref.read(splitServiceProvider);
  final groups =
      await (db.select(db.splitGroups)
            ..where((g) => g.archivedAt.isNull())
            ..orderBy([(g) => OrderingTerm.desc(g.updatedAt)]))
          .get();
  final expenses =
      await (db.select(db.splitExpenses)
            ..orderBy([(e) => OrderingTerm.desc(e.expenseDate)])
            ..limit(12))
          .get();
  final settlements =
      await (db.select(db.splitSettlements)
            ..orderBy([(s) => OrderingTerm.desc(s.settlementDate)])
            ..limit(12))
          .get();

  final receivable = await service.getCurrentUserReceivables();
  final payable = await service.getCurrentUserPayables();
  final groupNetById = <int, double>{};
  final groupMemberCountById = <int, int>{};
  for (final group in groups) {
    final members = await (db.select(
      db.splitMembers,
    )..where((m) => m.groupId.equals(group.id))).get();
    groupMemberCountById[group.id] = members.length;
    final you = members.where((m) => m.isCurrentUser).firstOrNull;
    if (you != null) {
      groupNetById[group.id] = await service.getMemberBalance(group.id, you.id);
    }
  }

  return SplitDashboardSnapshot(
    receivable: receivable,
    payable: payable,
    groups: groups,
    groupNetById: groupNetById,
    groupMemberCountById: groupMemberCountById,
    recentExpenses: expenses,
    recentSettlements: settlements,
  );
});

class SplitGroupDetail {
  const SplitGroupDetail({
    required this.group,
    required this.members,
    required this.expenses,
    required this.settlements,
    required this.memberBalances,
    required this.simplifiedTransfers,
  });

  final SplitGroup group;
  final List<SplitMember> members;
  final List<SplitExpense> expenses;
  final List<SplitSettlement> settlements;
  final List<GroupMemberBalance> memberBalances;
  final List<BalanceTransfer> simplifiedTransfers;
}

final splitGroupDetailProvider = FutureProvider.family<SplitGroupDetail, int>((
  ref,
  groupId,
) async {
  await ref.watch(seedProvider.future);
  final db = ref.read(appDatabaseProvider);
  final service = ref.read(splitServiceProvider);
  final group = await (db.select(
    db.splitGroups,
  )..where((g) => g.id.equals(groupId))).getSingle();
  final members = await (db.select(
    db.splitMembers,
  )..where((m) => m.groupId.equals(groupId))).get();
  final expenses =
      await (db.select(db.splitExpenses)
            ..where((e) => e.groupId.equals(groupId))
            ..orderBy([(e) => OrderingTerm.desc(e.expenseDate)]))
          .get();
  final settlements =
      await (db.select(db.splitSettlements)
            ..where((s) => s.groupId.equals(groupId))
            ..orderBy([(s) => OrderingTerm.desc(s.settlementDate)]))
          .get();
  final balances = await service.getGroupBalances(groupId);
  final simplified = await service.simplifyGroupBalances(groupId);

  return SplitGroupDetail(
    group: group,
    members: members,
    expenses: expenses,
    settlements: settlements,
    memberBalances: balances,
    simplifiedTransfers: simplified,
  );
});

final splitActionsProvider = Provider((ref) {
  final db = ref.read(appDatabaseProvider);
  final service = ref.read(splitServiceProvider);

  Future<int> createGroup(String name, {String? description}) async {
    final id = await service.createGroup(name, description: description);
    final currentUserMember =
        await (db.select(db.splitMembers)..where(
              (m) => m.groupId.equals(id) & m.isCurrentUser.equals(true),
            ))
            .getSingleOrNull();
    if (currentUserMember == null) {
      await service.addMember(id, name: 'You', isCurrentUser: true);
    }
    ref.invalidate(splitDashboardProvider);
    return id;
  }

  Future<int> addMember(
    int groupId, {
    required String name,
    String? contact,
    bool isCurrentUser = false,
  }) async {
    final id = await service.addMember(
      groupId,
      name: name,
      contact: contact,
      isCurrentUser: isCurrentUser,
    );
    ref.invalidate(splitGroupDetailProvider(groupId));
    ref.invalidate(splitDashboardProvider);
    return id;
  }

  Future<int> addExpense(AddSplitExpenseInput input) async {
    final id = await service.addSplitExpense(input);
    await ref.read(alertEvaluationActionsProvider).evaluateAll();
    ref.invalidate(splitGroupDetailProvider(input.groupId));
    ref.invalidate(splitDashboardProvider);
    return id;
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
    final id = await service.addSettlement(
      groupId: groupId,
      fromMemberId: fromMemberId,
      toMemberId: toMemberId,
      amount: amount,
      settlementDate: settlementDate,
      paymentSourceType: paymentSourceType,
      paymentSourceId: paymentSourceId,
      notes: notes,
    );
    await ref.read(alertEvaluationActionsProvider).evaluateAll();
    ref.invalidate(splitGroupDetailProvider(groupId));
    ref.invalidate(splitDashboardProvider);
    return id;
  }

  Future<List<BalanceTransfer>> simplify(int groupId) async {
    return service.simplifyGroupBalances(groupId);
  }

  return (
    createGroup: createGroup,
    addMember: addMember,
    addExpense: addExpense,
    addSettlement: addSettlement,
    simplify: simplify,
  );
});
