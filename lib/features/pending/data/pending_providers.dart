import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../alerts/data/alerts_providers.dart';
import '../../expenses/data/expenses_providers.dart';
import '../models/pending_models.dart';
import '../parsing/parsing.dart';
import 'pending_service.dart';

final pendingFilterProvider = StateProvider<String>((ref) => 'All');

final pendingServiceProvider = Provider<PendingService>((ref) {
  return PendingService(
    ref.read(appDatabaseProvider),
    ref.read(transactionEngineProvider),
  );
});

final pendingParserRegistryProvider = Provider<TransactionParserRegistry>((
  ref,
) {
  return TransactionParserRegistry(
    parsers: [
      UpiNotificationParser(),
      CardNotificationParser(),
      GenericBankSmsParser(),
    ],
    fallbackParser: GenericFallbackParser(),
  );
});

final pendingIngestionServiceProvider = Provider<PendingIngestionService>((
  ref,
) {
  return PendingIngestionService(
    ref.read(appDatabaseProvider),
    ref.read(pendingServiceProvider),
    ref.read(pendingParserRegistryProvider),
  );
});

final pendingTransactionsProvider = FutureProvider<List<PendingTransaction>>((
  ref,
) async {
  await ref.watch(seedProvider.future);
  final filter = ref.watch(pendingFilterProvider);
  final db = ref.read(appDatabaseProvider);

  final base = db.select(db.pendingTransactions)
    ..where((p) => p.status.equals('pending'))
    ..orderBy([
      (p) => OrderingTerm.desc(p.transactionDate),
      (p) => OrderingTerm.desc(p.detectedAt),
    ]);

  if (filter != 'All') {
    base.where((p) => p.sourceType.equals(filter));
  }

  return base.get();
});

final pendingHistoryProvider = FutureProvider<List<PendingTransaction>>((
  ref,
) async {
  await ref.watch(seedProvider.future);
  final db = ref.read(appDatabaseProvider);
  return (db.select(db.pendingTransactions)
        ..where(
          (p) =>
              p.status.equals('ignored') |
              p.status.equals('duplicate') |
              p.status.equals('merged'),
        )
        ..orderBy([(p) => OrderingTerm.desc(p.updatedAt)])
        ..limit(20))
      .get();
});

final pendingCountProvider = FutureProvider<int>((ref) async {
  await ref.watch(seedProvider.future);
  final db = ref.read(appDatabaseProvider);
  final rows =
      await (db.selectOnly(db.pendingTransactions)
            ..addColumns([db.pendingTransactions.id.count()])
            ..where(db.pendingTransactions.status.equals('pending')))
          .getSingle();
  return rows.read(db.pendingTransactions.id.count()) ?? 0;
});

final pendingActionProvider = Provider((ref) {
  final service = ref.read(pendingServiceProvider);
  final ingestion = ref.read(pendingIngestionServiceProvider);

  Future<void> confirm(int pendingId, PendingEditData editedData) async {
    await service.confirmPendingTransaction(pendingId, editedData);
    await ref.read(alertEvaluationActionsProvider).evaluateAll();
    ref.invalidate(pendingTransactionsProvider);
    ref.invalidate(expenseListProvider);
    ref.invalidate(pendingCountProvider);
    ref.invalidate(pendingHistoryProvider);
  }

  Future<void> ignore(int pendingId) async {
    await service.ignorePendingTransaction(pendingId);
    ref.invalidate(pendingTransactionsProvider);
    ref.invalidate(pendingCountProvider);
    ref.invalidate(pendingHistoryProvider);
  }

  Future<void> seedDemo() async {
    await service.seedDemoPendingTransactions();
    ref.invalidate(pendingTransactionsProvider);
    ref.invalidate(pendingCountProvider);
  }

  Future<void> update(int pendingId, PendingEditData editedData) async {
    await service.updatePendingTransaction(pendingId, editedData);
    ref.invalidate(pendingTransactionsProvider);
    ref.invalidate(pendingHistoryProvider);
  }

  Future<Transaction?> detectDuplicate(PendingTransaction txn) {
    return service.detectPossibleDuplicate(txn);
  }

  Future<void> markDuplicate(int pendingId, int existingTransactionId) async {
    await service.markPendingAsDuplicate(pendingId, existingTransactionId);
    ref.invalidate(pendingTransactionsProvider);
    ref.invalidate(pendingCountProvider);
    ref.invalidate(pendingHistoryProvider);
  }

  Future<void> mergeDuplicate(int pendingId, int existingTransactionId) async {
    await service.mergeDuplicatePendingTransaction(
      pendingId,
      existingTransactionId,
    );
    ref.invalidate(pendingTransactionsProvider);
    ref.invalidate(pendingCountProvider);
    ref.invalidate(pendingHistoryProvider);
  }

  Future<List<int>> ingestParsedInput(ParserInput input) async {
    final ids = await ingestion.ingestParserInput(input);
    ref.invalidate(pendingTransactionsProvider);
    ref.invalidate(pendingCountProvider);
    return ids;
  }

  ParserResult previewParsedInput(ParserInput input) {
    return ingestion.previewParserInput(input);
  }

  return (
    confirm: confirm,
    ignore: ignore,
    seedDemo: seedDemo,
    update: update,
    detectDuplicate: detectDuplicate,
    markDuplicate: markDuplicate,
    mergeDuplicate: mergeDuplicate,
    ingestParsedInput: ingestParsedInput,
    previewParsedInput: previewParsedInput,
  );
});
