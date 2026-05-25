import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import 'account_service.dart';

final accountServiceProvider = Provider<AccountService>((ref) {
  return AccountService(ref.read(appDatabaseProvider));
});

final accountsOverviewProvider = FutureProvider((ref) async {
  await ref.watch(seedProvider.future);
  final db = ref.read(appDatabaseProvider);
  final service = ref.read(accountServiceProvider);

  final banks = await db.select(db.bankAccounts).get();
  final wallets = await db.select(db.cashWallets).get();
  final recent =
      await (db.select(db.transactions)
            ..where(
              (t) =>
                  t.category.equals('Transfer') |
                  t.category.equals('Reconciliation'),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)])
            ..limit(8))
          .get();

  final liquid = await service.getCombinedLiquidBalance();
  final bankTotal = await service.getTotalBankBalance();
  final cashTotal = await service.getTotalCashBalance();

  return (
    banks: banks,
    wallets: wallets,
    recent: recent,
    liquid: liquid,
    bankTotal: bankTotal,
    cashTotal: cashTotal,
  );
});

final accountDetailProvider = FutureProvider.family((
  ref,
  (String, int) key,
) async {
  await ref.watch(seedProvider.future);
  final db = ref.read(appDatabaseProvider);
  final type = key.$1;
  final id = key.$2;

  final txns =
      await (db.select(db.transactions)
            ..where(
              (t) =>
                  t.paymentSourceType.equals(type) &
                  t.paymentSourceId.equals(id),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)])
            ..limit(20))
          .get();

  if (type == 'cash') {
    final wallet = await (db.select(
      db.cashWallets,
    )..where((w) => w.id.equals(id))).getSingle();
    return (
      name: wallet.walletName,
      balance: wallet.currentBalance,
      txns: txns,
    );
  }
  final bank = await (db.select(
    db.bankAccounts,
  )..where((b) => b.id.equals(id))).getSingle();
  return (name: bank.accountName, balance: bank.currentBalance, txns: txns);
});
