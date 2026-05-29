import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import 'transaction_engine.dart';

final transactionEngineProvider = Provider<TransactionEngine>((ref) {
  return TransactionEngine(ref.read(appDatabaseProvider));
});

class PaymentSourcesData {
  const PaymentSourcesData({
    required this.banks,
    required this.cards,
    required this.cashWallets,
  });

  final List<BankAccount> banks;
  final List<CreditCard> cards;
  final List<CashWallet> cashWallets;
}

final expenseListProvider = FutureProvider((ref) async {
  await ref.watch(seedProvider.future);
  final db = ref.read(appDatabaseProvider);
  return (db.select(
    db.transactions,
  )..orderBy([(t) => OrderingTerm.desc(t.transactionDate)])).get();
});

final paymentSourcesProvider = FutureProvider((ref) async {
  await ref.watch(seedProvider.future);
  final db = ref.read(appDatabaseProvider);
  final banks = await db.select(db.bankAccounts).get();
  final cards = await db.select(db.creditCards).get();
  final cashWallets = await db.select(db.cashWallets).get();
  return PaymentSourcesData(
    banks: banks,
    cards: cards,
    cashWallets: cashWallets,
  );
});

final recoverablePartySuggestionsProvider = FutureProvider<List<String>>((
  ref,
) async {
  await ref.watch(seedProvider.future);
  final db = ref.read(appDatabaseProvider);
  final txnNames = (await db.select(db.transactions).get())
      .map((t) => t.recoverablePartyName?.trim())
      .whereType<String>()
      .where((name) => name.isNotEmpty)
      .toSet();
  final pendingNames = (await db.select(db.pendingTransactions).get())
      .map((t) => t.recoverablePartyName?.trim())
      .whereType<String>()
      .where((name) => name.isNotEmpty)
      .toSet();
  final names = {...txnNames, ...pendingNames}.toList(growable: false)
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return names;
});
