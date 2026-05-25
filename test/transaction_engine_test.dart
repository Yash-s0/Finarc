import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/features/expenses/data/transaction_engine.dart';
import 'package:finarc/features/expenses/models/transaction_types.dart';

void main() {
  late AppDatabase db;
  late TransactionEngine engine;
  late int bankId;
  late int cardId;
  late int cashId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    engine = TransactionEngine(db);

    bankId = await db
        .into(db.bankAccounts)
        .insert(
          BankAccountsCompanion.insert(
            bankName: 'Test Bank',
            accountName: 'Primary',
            accountType: 'savings',
            currentBalance: const Value(10000),
          ),
        );
    cardId = await db
        .into(db.creditCards)
        .insert(
          CreditCardsCompanion.insert(
            bankName: 'CardBank',
            nickname: 'Main',
            last4: '1234',
            maskedNumber: '**** **** **** 1234',
            creditLimit: 50000,
            billingDay: 10,
            dueDay: 20,
            currentOutstanding: const Value(5000),
          ),
        );
    cashId = await db
        .into(db.cashWallets)
        .insert(
          CashWalletsCompanion.insert(
            walletName: 'Cash',
            currentBalance: const Value(3000),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  test('cash expense reduces cash', () async {
    await engine.addTransaction(
      AddTransactionInput(
        type: TransactionType.cash,
        amount: 500,
        title: 'Tea',
        category: 'Food',
        transactionDate: DateTime(2026, 5, 24),
        paymentSourceType: PaymentSourceType.cash,
        paymentSourceId: cashId,
      ),
    );

    final wallet = await (db.select(
      db.cashWallets,
    )..where((w) => w.id.equals(cashId))).getSingle();
    expect(wallet.currentBalance, 2500);
  });

  test('UPI expense reduces selected bank', () async {
    await engine.addTransaction(
      AddTransactionInput(
        type: TransactionType.upi,
        amount: 600,
        title: 'UPI Pay',
        category: 'Food',
        transactionDate: DateTime(2026, 5, 24),
        paymentSourceType: PaymentSourceType.upi,
        paymentSourceId: bankId,
      ),
    );
    final bank = await (db.select(
      db.bankAccounts,
    )..where((b) => b.id.equals(bankId))).getSingle();
    expect(bank.currentBalance, 9400);
  });

  test('bank expense reduces selected bank', () async {
    await engine.addTransaction(
      AddTransactionInput(
        type: TransactionType.bank,
        amount: 1200,
        title: 'Utility',
        category: 'Bills',
        transactionDate: DateTime(2026, 5, 24),
        paymentSourceType: PaymentSourceType.bank,
        paymentSourceId: bankId,
      ),
    );
    final bank = await (db.select(
      db.bankAccounts,
    )..where((b) => b.id.equals(bankId))).getSingle();
    expect(bank.currentBalance, 8800);
  });

  test('credit card expense increases outstanding', () async {
    await engine.addTransaction(
      AddTransactionInput(
        type: TransactionType.creditCard,
        amount: 1500,
        title: 'Flight',
        category: 'Travel',
        transactionDate: DateTime(2026, 5, 24),
        paymentSourceType: PaymentSourceType.creditCard,
        paymentSourceId: cardId,
      ),
    );
    final card = await (db.select(
      db.creditCards,
    )..where((c) => c.id.equals(cardId))).getSingle();
    expect(card.currentOutstanding, 6500);
  });

  test('cashback calculates net spend correctly', () async {
    await engine.addTransaction(
      AddTransactionInput(
        type: TransactionType.upi,
        amount: 1000,
        title: 'Order',
        category: 'Shopping',
        transactionDate: DateTime(2026, 5, 24),
        paymentSourceType: PaymentSourceType.upi,
        paymentSourceId: bankId,
        cashbackAmount: 100,
      ),
    );
    final txn = await (db.select(db.transactions)..limit(1)).getSingle();
    expect(engine.netExpense(txn), 900);
  });

  test('for-others transaction tracks recoverable amount', () async {
    await engine.addTransaction(
      AddTransactionInput(
        type: TransactionType.bank,
        amount: 800,
        title: 'Shared taxi',
        category: 'Travel',
        transactionDate: DateTime(2026, 5, 24),
        paymentSourceType: PaymentSourceType.bank,
        paymentSourceId: bankId,
        isForOthers: true,
        recoverableAmount: 500,
      ),
    );
    final txn = await (db.select(db.transactions)..limit(1)).getSingle();
    expect(txn.isForOthers, true);
    expect(txn.recoverableAmount, 500);
  });

  test('invalid amount fails', () async {
    expect(
      () => engine.addTransaction(
        AddTransactionInput(
          type: TransactionType.cash,
          amount: 0,
          title: 'Invalid',
          category: 'Misc',
          transactionDate: DateTime(2026, 5, 24),
          paymentSourceType: PaymentSourceType.cash,
          paymentSourceId: cashId,
        ),
      ),
      throwsArgumentError,
    );
  });
}
