import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../alerts/data/alerts_providers.dart';
import 'billing_service.dart';

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

class CardOverviewSummary {
  const CardOverviewSummary({
    required this.card,
    required this.billedDue,
    required this.unbilledSpends,
    required this.totalOutstanding,
    required this.availableLimit,
    required this.utilization,
    required this.nextUnpaidDueDate,
  });

  final CreditCard card;
  final double billedDue;
  final double unbilledSpends;
  final double totalOutstanding;
  final double availableLimit;
  final double utilization;
  final DateTime? nextUnpaidDueDate;
}

final billingServiceProvider = Provider<BillingService>((ref) {
  return BillingService(ref.read(appDatabaseProvider));
});

final cardsOverviewProvider = FutureProvider((ref) async {
  await ref.watch(seedProvider.future);
  final db = ref.read(appDatabaseProvider);
  final cards = await db.select(db.creditCards).get();
  final billing = ref.read(billingServiceProvider);

  var billedDue = 0.0;
  var unbilled = 0.0;
  var totalOutstanding = 0.0;
  var totalLimit = 0.0;
  final summaries = <CardOverviewSummary>[];
  for (final card in cards) {
    final snapshot = await billing.getCardBillingSnapshot(card);

    billedDue += snapshot.billedDue;
    unbilled += snapshot.unbilledSpends;
    totalOutstanding += snapshot.totalOutstanding;
    totalLimit += card.creditLimit;
    summaries.add(
      CardOverviewSummary(
        card: card,
        billedDue: snapshot.billedDue,
        unbilledSpends: snapshot.unbilledSpends,
        totalOutstanding: snapshot.totalOutstanding,
        availableLimit: snapshot.availableLimit,
        utilization: snapshot.utilizationPercent,
        nextUnpaidDueDate: snapshot.latestUnpaidBill?.dueDate,
      ),
    );
  }
  final utilization = totalLimit == 0 ? 0.0 : totalOutstanding / totalLimit;

  return (
    cards: cards,
    billedDue: billedDue,
    totalOutstanding: totalOutstanding,
    totalLimit: totalLimit,
    utilization: utilization,
    unbilled: unbilled,
    cardSummaries: summaries,
  );
});

class CardDetailViewModel {
  const CardDetailViewModel({
    required this.card,
    required this.recentTransactions,
    required this.currentBill,
    required this.currentDueAmount,
    required this.unbilledAmount,
    required this.unbilledTransactions,
    required this.billedTransactions,
    required this.totalOutstanding,
    required this.availableLimit,
    required this.utilization,
    required this.billStatus,
    required this.dueCountdownDays,
  });

  final CreditCard card;
  final List<Transaction> recentTransactions;
  final CardBill? currentBill;
  final double currentDueAmount;
  final double unbilledAmount;
  final List<Transaction> unbilledTransactions;
  final List<Transaction> billedTransactions;
  final double totalOutstanding;
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
  final snapshot = await billing.getCardBillingSnapshot(card);
  final currentBill = snapshot.latestUnpaidBill;
  final currentDueAmount = snapshot.billedDue;
  final unbilledTransactions = snapshot.unbilledTransactions;
  final unbilledAmount = snapshot.unbilledSpends;
  final billedTransactions = snapshot.billedTransactions;
  final recentTransactions = snapshot.recentTransactions;
  final availableLimit = snapshot.availableLimit;
  final utilization = snapshot.utilizationPercent;
  final totalOutstanding = snapshot.totalOutstanding;

  final dueDate = currentBill?.dueDate;
  final dueDays = dueDate == null
      ? 0
      : _dateOnly(dueDate).difference(_dateOnly(DateTime.now())).inDays;

  return CardDetailViewModel(
    card: card,
    recentTransactions: recentTransactions,
    currentBill: currentBill,
    currentDueAmount: currentDueAmount,
    unbilledAmount: unbilledAmount,
    unbilledTransactions: unbilledTransactions,
    billedTransactions: billedTransactions,
    totalOutstanding: totalOutstanding,
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
  final wallets = await db.select(db.cashWallets).get();
  return (bill: bill, txns: txns, accounts: accounts, wallets: wallets);
});

final markBillPaidProvider = Provider((ref) {
  return ({
    required int billId,
    required int? paymentSourceId,
    required String paymentSourceType,
    required double amount,
    DateTime? paymentDate,
    String? notes,
  }) async {
    final result = await ref
        .read(billingServiceProvider)
        .markBillAsPaid(
          billId,
          paymentSourceId,
          amount,
          paymentSourceType: paymentSourceType,
          transactionDate: paymentDate,
          notes: notes,
        );
    await ref.read(alertEvaluationActionsProvider).evaluateAll();
    ref.invalidate(cardsOverviewProvider);
    ref.invalidate(cardDetailProvider(result.cardId));
    if (result.billId != null) {
      ref.invalidate(billDetailProvider(result.billId!));
    }
    return result;
  };
});

class AddCardPayload {
  AddCardPayload({
    required this.bankName,
    required this.nickname,
    required this.last4,
    required this.network,
    required this.billingDay,
    required this.dueDay,
    required this.creditLimit,
    required this.currentOutstanding,
  });

  final String bankName;
  final String nickname;
  final String last4;
  final String network;
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
    if (!CardNetwork.values.contains(payload.network)) {
      throw ArgumentError('Unsupported card network');
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
            network: Value(payload.network),
            creditLimit: payload.creditLimit,
            billingDay: payload.billingDay,
            dueDay: payload.dueDay,
            currentOutstanding: Value(payload.currentOutstanding),
          ),
        );
    ref.invalidate(cardsOverviewProvider);
  };
});

final cardEditorProvider = FutureProvider.family<CreditCard, int>((
  ref,
  cardId,
) async {
  await ref.watch(seedProvider.future);
  final db = ref.read(appDatabaseProvider);
  return (db.select(
    db.creditCards,
  )..where((card) => card.id.equals(cardId))).getSingle();
});

final updateCardProvider = Provider((ref) {
  return (int cardId, AddCardPayload payload) async {
    if (payload.last4.length != 4 || int.tryParse(payload.last4) == null) {
      throw ArgumentError('Last 4 digits must be exactly 4 numeric digits');
    }
    if (!CardNetwork.values.contains(payload.network)) {
      throw ArgumentError('Unsupported card network');
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
    await (db.update(
      db.creditCards,
    )..where((card) => card.id.equals(cardId))).write(
      CreditCardsCompanion(
        bankName: Value(payload.bankName),
        nickname: Value(payload.nickname),
        last4: Value(payload.last4),
        maskedNumber: Value('**** **** **** ${payload.last4}'),
        network: Value(payload.network),
        creditLimit: Value(payload.creditLimit),
        billingDay: Value(payload.billingDay),
        dueDay: Value(payload.dueDay),
        currentOutstanding: Value(payload.currentOutstanding),
      ),
    );
    ref.invalidate(cardsOverviewProvider);
    ref.invalidate(cardDetailProvider(cardId));
    ref.invalidate(cardEditorProvider(cardId));
  };
});

class CardNetwork {
  const CardNetwork._();

  static const visa = 'visa';
  static const mastercard = 'mastercard';
  static const rupay = 'rupay';
  static const amex = 'amex';

  static const values = [visa, mastercard, rupay, amex];

  static String label(String value) {
    switch (value) {
      case mastercard:
        return 'Mastercard';
      case rupay:
        return 'RuPay';
      case amex:
        return 'Amex';
      case visa:
      default:
        return 'Visa';
    }
  }
}
