import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../alerts/data/alerts_providers.dart';
import 'billing_service.dart';

final billingServiceProvider = Provider<BillingService>((ref) {
  return BillingService(ref.read(appDatabaseProvider));
});

final cardsOverviewProvider = FutureProvider((ref) async {
  await ref.watch(seedProvider.future);
  final db = ref.read(appDatabaseProvider);
  final cards = await db.select(db.creditCards).get();

  final totalDues = cards.fold<double>(0, (s, c) => s + c.currentOutstanding);
  final totalLimit = cards.fold<double>(0, (s, c) => s + c.creditLimit);
  final utilization = totalLimit == 0 ? 0.0 : totalDues / totalLimit;

  var unbilled = 0.0;
  for (final card in cards) {
    final cardUnbilled = await ref
        .read(billingServiceProvider)
        .getUnbilledTransactions(card.id);
    unbilled += cardUnbilled.fold<double>(0, (s, t) => s + t.amount);
  }

  return (
    cards: cards,
    totalDues: totalDues,
    totalLimit: totalLimit,
    utilization: utilization,
    unbilled: unbilled,
  );
});

class CardDetailViewModel {
  const CardDetailViewModel({
    required this.card,
    required this.recentTransactions,
    required this.currentBill,
    required this.unbilledTransactions,
    required this.billedTransactions,
    required this.availableLimit,
    required this.utilization,
    required this.billStatus,
    required this.dueCountdownDays,
  });

  final CreditCard card;
  final List<Transaction> recentTransactions;
  final CardBill? currentBill;
  final List<Transaction> unbilledTransactions;
  final List<Transaction> billedTransactions;
  final double availableLimit;
  final double utilization;
  final String billStatus;
  final int dueCountdownDays;
}

final cardDetailProvider = FutureProvider.family<CardDetailViewModel, int>((
  ref,
  cardId,
) async {
  await ref.watch(seedProvider.future);
  final db = ref.read(appDatabaseProvider);
  final billing = ref.read(billingServiceProvider);

  final card = await (db.select(
    db.creditCards,
  )..where((c) => c.id.equals(cardId))).getSingle();
  final currentBill = await billing.generateBillForCard(cardId);
  final unbilledTransactions = await billing.getUnbilledTransactions(cardId);
  final billedTransactions = currentBill == null
      ? <Transaction>[]
      : await billing.getBilledTransactions(cardId, currentBill.id);
  final recentTransactions =
      await (db.select(db.transactions)
            ..where(
              (t) =>
                  t.paymentSourceType.equals('creditCard') &
                  t.paymentSourceId.equals(cardId),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)])
            ..limit(10))
          .get();
  final availableLimit = await billing.calculateAvailableLimit(cardId);
  final utilization = await billing.calculateUtilization(cardId);

  final dueDate = currentBill?.dueDate;
  final dueDays = dueDate == null
      ? 0
      : dueDate.difference(DateTime.now()).inDays;

  return CardDetailViewModel(
    card: card,
    recentTransactions: recentTransactions,
    currentBill: currentBill,
    unbilledTransactions: unbilledTransactions,
    billedTransactions: billedTransactions,
    availableLimit: availableLimit,
    utilization: utilization,
    billStatus: currentBill == null
        ? 'upcoming'
        : billing.getDueStatus(currentBill),
    dueCountdownDays: dueDays,
  );
});

final billDetailProvider = FutureProvider.family((ref, int billId) async {
  await ref.watch(seedProvider.future);
  final db = ref.read(appDatabaseProvider);
  final bill = await (db.select(
    db.cardBills,
  )..where((b) => b.id.equals(billId))).getSingle();
  final txns = await ref
      .read(billingServiceProvider)
      .getBilledTransactions(bill.cardId, billId);
  final accounts = await db.select(db.bankAccounts).get();
  return (bill: bill, txns: txns, accounts: accounts);
});

final markBillPaidProvider = Provider((ref) {
  return (int billId, int? bankAccountId, double amount) async {
    await ref
        .read(billingServiceProvider)
        .markBillAsPaid(billId, bankAccountId, amount);
    await ref.read(alertEvaluationActionsProvider).evaluateAll();
    ref.invalidate(cardsOverviewProvider);
  };
});

class AddCardPayload {
  AddCardPayload({
    required this.bankName,
    required this.nickname,
    required this.last4,
    required this.billingDay,
    required this.dueDay,
    required this.creditLimit,
    required this.currentOutstanding,
  });

  final String bankName;
  final String nickname;
  final String last4;
  final int billingDay;
  final int dueDay;
  final double creditLimit;
  final double currentOutstanding;
}

final addCardProvider = Provider((ref) {
  return (AddCardPayload payload) async {
    if (payload.last4.length != 4 || int.tryParse(payload.last4) == null) {
      throw ArgumentError('Last 4 digits must be exactly 4 numeric digits');
    }
    if (payload.billingDay < 1 || payload.billingDay > 31) {
      throw ArgumentError('Billing day must be between 1 and 31');
    }
    if (payload.dueDay < 1 || payload.dueDay > 31) {
      throw ArgumentError('Due day must be between 1 and 31');
    }
    if (payload.creditLimit <= 0) {
      throw ArgumentError('Credit limit must be greater than 0');
    }
    if (payload.currentOutstanding < 0) {
      throw ArgumentError('Current outstanding cannot be negative');
    }
    if (payload.currentOutstanding > payload.creditLimit) {
      throw ArgumentError('Current outstanding cannot exceed credit limit');
    }

    final db = ref.read(appDatabaseProvider);
    await db
        .into(db.creditCards)
        .insert(
          CreditCardsCompanion.insert(
            bankName: payload.bankName,
            nickname: payload.nickname,
            last4: payload.last4,
            maskedNumber: '**** **** **** ${payload.last4}',
            creditLimit: payload.creditLimit,
            billingDay: payload.billingDay,
            dueDay: payload.dueDay,
            currentOutstanding: Value(payload.currentOutstanding),
          ),
        );
    ref.invalidate(cardsOverviewProvider);
  };
});
