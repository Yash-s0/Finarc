import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/features/accounts/data/account_service.dart';
import 'package:finarc/features/cards/data/billing_service.dart';

void main() {
  late AppDatabase db;
  late AccountService service;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    service = AccountService(db);

    await db
        .into(db.bankAccounts)
        .insert(
          BankAccountsCompanion.insert(
            bankName: 'A',
            accountName: 'A1',
            accountType: 'savings',
            currentBalance: const Value(10000),
          ),
        );
    await db
        .into(db.bankAccounts)
        .insert(
          BankAccountsCompanion.insert(
            bankName: 'B',
            accountName: 'B1',
            accountType: 'current',
            currentBalance: const Value(5000),
          ),
        );
    await db
        .into(db.cashWallets)
        .insert(
          CashWalletsCompanion.insert(
            walletName: 'Cash',
            currentBalance: const Value(2000),
          ),
        );
    await db
        .into(db.creditCards)
        .insert(
          CreditCardsCompanion.insert(
            bankName: 'CardBank',
            nickname: 'Card',
            last4: '1234',
            maskedNumber: '**** **** **** 1234',
            creditLimit: 40000,
            billingDay: 10,
            dueDay: 20,
            currentOutstanding: const Value(5000),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  test('transfers bank to bank update balances and history', () async {
    await service.transferBetweenAccounts(
      sourceType: 'bank',
      sourceId: 1,
      destinationType: 'bank',
      destinationId: 2,
      amount: 1000,
      transactionDate: DateTime(2026, 5, 24),
      notes: 'test transfer',
    );

    final a = await (db.select(
      db.bankAccounts,
    )..where((b) => b.id.equals(1))).getSingle();
    final b = await (db.select(
      db.bankAccounts,
    )..where((x) => x.id.equals(2))).getSingle();
    final txns =
        await (db.select(db.transactions)
              ..where((t) => t.transferGroupId.isNotNull())
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get();

    expect(a.currentBalance, 9000);
    expect(b.currentBalance, 6000);
    expect(txns.length, 2);
  });

  test('reconciliation updates balance and creates adjustment txn', () async {
    await service.reconcileBalance(
      accountType: 'cash',
      accountId: 1,
      newBalance: 2500,
      reason: 'physical cash count',
    );

    final cash = await (db.select(
      db.cashWallets,
    )..where((c) => c.id.equals(1))).getSingle();
    final recon = await (db.select(
      db.transactions,
    )..where((t) => t.category.equals('Reconciliation'))).getSingle();

    expect(cash.currentBalance, 2500);
    expect(recon.title, 'Reconciliation Adjustment');
  });

  test('liquid balance totals are correct', () async {
    final bank = await service.getTotalBankBalance();
    final cash = await service.getTotalCashBalance();
    final combined = await service.getCombinedLiquidBalance();

    expect(bank, 15000);
    expect(cash, 2000);
    expect(combined, 17000);
  });

  test('cash and bank transaction effects through transfer engine', () async {
    await service.transferBetweenAccounts(
      sourceType: 'cash',
      sourceId: 1,
      destinationType: 'bank',
      destinationId: 1,
      amount: 500,
      transactionDate: DateTime(2026, 5, 24),
      notes: 'cash deposit',
    );

    final cash = await (db.select(
      db.cashWallets,
    )..where((w) => w.id.equals(1))).getSingle();
    final bank = await (db.select(
      db.bankAccounts,
    )..where((b) => b.id.equals(1))).getSingle();

    expect(cash.currentBalance, 1500);
    expect(bank.currentBalance, 10500);
  });

  test('card payment deductions reduce bank and card outstanding', () async {
    final billId = await db
        .into(db.cardBills)
        .insert(
          CardBillsCompanion.insert(
            cardId: 1,
            cycleStartDate: Value(DateTime(2026, 4, 10)),
            cycleEndDate: Value(DateTime(2026, 5, 10)),
            billingDate: Value(DateTime(2026, 5, 10)),
            dueDate: Value(DateTime(2026, 5, 20)),
            billedAmount: 1200,
            paidAmount: const Value(0),
            status: const Value('billed'),
          ),
        );

    await BillingService(
      db,
      now: () => DateTime(2026, 5, 15),
    ).markBillAsPaid(billId, 1, 1200);

    final bank = await (db.select(
      db.bankAccounts,
    )..where((b) => b.id.equals(1))).getSingle();
    final card = await (db.select(
      db.creditCards,
    )..where((c) => c.id.equals(1))).getSingle();

    expect(bank.currentBalance, 8800);
    expect(card.currentOutstanding, 3800);
  });
}
