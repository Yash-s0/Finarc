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
            last4: const Value('1111'),
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
            last4: const Value('2222'),
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
        .into(db.cashWallets)
        .insert(
          CashWalletsCompanion.insert(
            walletName: 'Amazon Pay',
            walletType: const Value('amazonPay'),
            currentBalance: const Value(800),
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

  test('bank account last4 is persisted on create and update', () async {
    final createdId = await service.createBankAccount(
      bankName: 'Kotak',
      accountName: 'Salary',
      accountType: 'savings',
      currentBalance: 12000,
      last4: '0754',
    );

    await service.updateBankAccount(createdId, last4: '4455');

    final account = await (db.select(
      db.bankAccounts,
    )..where((b) => b.id.equals(createdId))).getSingle();
    expect(account.last4, '4455');
  });

  test(
    'bank account edit updates name, can clear last4, and keeps txn links',
    () async {
      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              type: 'expense',
              amount: 200,
              title: 'Linked txn',
              category: 'Food',
              transactionDate: DateTime(2026, 6, 1),
              paymentSourceType: 'bank',
              paymentSourceId: 1,
            ),
          );

      await service.updateBankAccount(
        1,
        accountName: 'Renamed Account',
        last4: null,
        clearLast4: true,
      );

      final updated = await (db.select(
        db.bankAccounts,
      )..where((b) => b.id.equals(1))).getSingle();
      final linked = await (db.select(
        db.transactions,
      )..where((t) => t.paymentSourceId.equals(1))).getSingle();

      expect(updated.accountName, 'Renamed Account');
      expect(updated.last4, equals(null));
      expect(linked.paymentSourceId, 1);
    },
  );

  test('Amazon Pay wallet type is persisted on create', () async {
    final walletId = await service.createCashWallet(
      walletName: 'Amazon Pay',
      walletType: 'amazonPay',
      currentBalance: 500,
    );

    final wallet = await (db.select(
      db.cashWallets,
    )..where((w) => w.id.equals(walletId))).getSingle();
    expect(wallet.walletType, 'amazonPay');
  });

  test('liquid balance totals are correct', () async {
    final bank = await service.getTotalBankBalance();
    final cash = await service.getTotalCashBalance();
    final combined = await service.getCombinedLiquidBalance();

    expect(bank, 15000);
    expect(cash, 2800);
    expect(combined, 17800);
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

  test('card payment deductions reduce bank and settle billed cycle', () async {
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

    final result = await BillingService(
      db,
      now: () => DateTime(2026, 5, 15),
    ).markBillAsPaid(billId, 1, 1200);

    final bank = await (db.select(
      db.bankAccounts,
    )..where((b) => b.id.equals(1))).getSingle();
    final card = await (db.select(
      db.creditCards,
    )..where((c) => c.id.equals(1))).getSingle();
    final bill = await (db.select(
      db.cardBills,
    )..where((b) => b.id.equals(billId))).getSingle();

    expect(result.appliedAmount, 1200);
    expect(bank.currentBalance, 8800);
    expect(card.currentOutstanding, 3800);
    expect(bill.status, 'paid');
    expect(bill.paidAmount, 1200);
  });

  test('bill overpayment is clamped and only actual due is deducted', () async {
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

    final result = await BillingService(
      db,
      now: () => DateTime(2026, 5, 15),
    ).markBillAsPaid(billId, 1, 2000);

    final bank = await (db.select(
      db.bankAccounts,
    )..where((b) => b.id.equals(1))).getSingle();
    final bill = await (db.select(
      db.cardBills,
    )..where((b) => b.id.equals(billId))).getSingle();

    expect(result.wasClamped, isTrue);
    expect(result.appliedAmount, 1200);
    expect(bank.currentBalance, 8800);
    expect(bill.paidAmount, 1200);
    expect(bill.status, 'paid');
  });

  test('transfer to credit card settles billed due only', () async {
    await (db.update(db.creditCards)..where((c) => c.id.equals(1))).write(
      const CreditCardsCompanion(currentOutstanding: Value(1200)),
    );
    await db
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

    final result = await service.transferBetweenAccounts(
      sourceType: 'bank',
      sourceId: 1,
      destinationType: 'creditCard',
      destinationId: 1,
      amount: 2000,
      transactionDate: DateTime(2026, 5, 24),
      notes: 'card settle',
    );

    final bank = await (db.select(
      db.bankAccounts,
    )..where((b) => b.id.equals(1))).getSingle();
    final card = await (db.select(
      db.creditCards,
    )..where((c) => c.id.equals(1))).getSingle();
    final bill = await (db.select(
      db.cardBills,
    )..where((b) => b.cardId.equals(1) & b.status.equals('paid'))).getSingle();
    final cardPayments = await (db.select(
      db.transactions,
    )..where((t) => t.type.equals('cardPayment'))).get();

    expect(result.transferredAmount, 1200);
    expect(result.message, isA<String>());
    expect(bank.currentBalance, 8800);
    expect(card.currentOutstanding, 0);
    expect(bill.paidAmount, 1200);
    expect(cardPayments, hasLength(1));
    expect(cardPayments.single.amount, 1200);
  });
}
