import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final seedProvider = FutureProvider<void>((ref) async {
  await ref.read(appDatabaseProvider).seedIfEmpty();
});

final cardsProvider = FutureProvider((ref) async {
  await ref.watch(seedProvider.future);
  return ref
      .read(appDatabaseProvider)
      .select(ref.read(appDatabaseProvider).creditCards)
      .get();
});

final transactionsProvider = FutureProvider((ref) async {
  await ref.watch(seedProvider.future);
  final db = ref.read(appDatabaseProvider);
  return (db.select(db.transactions)
        ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)])
        ..limit(20))
      .get();
});
