import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('backfill normalizes legacy recoverable statuses and amounts', () async {
    final now = DateTime(2026, 5, 24);

    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            type: 'bank',
            amount: 500,
            title: 'Legacy settled',
            category: 'Food',
            transactionDate: now,
            paymentSourceType: 'bank',
            paymentSourceId: 1,
            cashbackAmount: const Value(50),
            isForOthers: const Value(true),
            recoverableAmount: const Value(300),
            recoverableStatus: const Value('settled'),
          ),
        );
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            type: 'bank',
            amount: 500,
            title: 'Legacy partial',
            category: 'Food',
            transactionDate: now,
            paymentSourceType: 'bank',
            paymentSourceId: 1,
            cashbackAmount: const Value(50),
            isForOthers: const Value(true),
            recoverableAmount: const Value(220),
            recoverableStatus: const Value('partial'),
          ),
        );
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            type: 'bank',
            amount: 500,
            title: 'Legacy unknown',
            category: 'Food',
            transactionDate: now,
            paymentSourceType: 'bank',
            paymentSourceId: 1,
            cashbackAmount: const Value(50),
            isForOthers: const Value(true),
            recoverableStatus: const Value('unknown'),
          ),
        );
    await db
        .into(db.pendingTransactions)
        .insert(
          PendingTransactionsCompanion.insert(
            amount: 400,
            merchant: 'Pending legacy',
            categorySuggestion: 'Food',
            paymentSourceTypeSuggestion: 'bank',
            detectedAt: now,
            transactionDate: now,
            sourceType: 'sms',
            rawText: 'legacy',
            confidenceScore: 0.9,
            isForOthers: const Value(true),
            cashbackAmount: const Value(20),
            recoverableAmount: const Value(180),
          ),
        );

    await db.normalizeRecoverableDataBackfill();

    final txns = await db.select(db.transactions).get();
    final byTitle = {for (final t in txns) t.title: t};

    final settled = byTitle['Legacy settled']!;
    expect(settled.recoverableBaseAmount, closeTo(300, 0.01));
    expect(settled.recoveredAmount, closeTo(300, 0.01));
    expect(settled.recoverableAmount, closeTo(0, 0.01));
    expect(settled.recoverableStatus, 'recovered');

    final partial = byTitle['Legacy partial']!;
    expect(partial.recoverableBaseAmount, closeTo(220, 0.01));
    expect(partial.recoveredAmount, closeTo(0, 0.01));
    expect(partial.recoverableAmount, closeTo(220, 0.01));
    expect(partial.recoverableStatus, 'unpaid');

    final unknown = byTitle['Legacy unknown']!;
    expect(unknown.recoverableBaseAmount, closeTo(450, 0.01));
    expect(unknown.recoveredAmount, closeTo(0, 0.01));
    expect(unknown.recoverableAmount, closeTo(450, 0.01));
    expect(unknown.recoverableStatus, 'unpaid');

    final pending = await db.select(db.pendingTransactions).getSingle();
    expect(pending.recoverableBaseAmount, closeTo(180, 0.01));
    expect(pending.recoveredAmount, closeTo(0, 0.01));
    expect(pending.recoverableAmount, closeTo(180, 0.01));
  });
}
