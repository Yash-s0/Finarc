import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/features/expenses/data/transaction_engine.dart';
import 'package:finarc/features/expenses/models/transaction_types.dart';
import 'package:finarc/features/split/data/split_service.dart';

void main() {
  late AppDatabase db;
  late TransactionEngine engine;
  late SplitService splitService;
  late int bankId;
  late int cardId;
  late int cashId;
  late int amazonPayId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    engine = TransactionEngine(db);
    splitService = SplitService(db, engine);

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
    amazonPayId = await db
        .into(db.cashWallets)
        .insert(
          CashWalletsCompanion.insert(
            walletName: 'Amazon Pay',
            walletType: const Value('amazonPay'),
            currentBalance: const Value(1500),
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

  test('Amazon Pay expense reduces wallet balance', () async {
    await engine.addTransaction(
      AddTransactionInput(
        type: TransactionType.cash,
        amount: 200,
        title: 'Amazon Pay spend',
        category: 'Shopping',
        transactionDate: DateTime(2026, 5, 24),
        paymentSourceType: PaymentSourceType.cash,
        paymentSourceId: amazonPayId,
      ),
    );

    final wallet = await (db.select(
      db.cashWallets,
    )..where((w) => w.id.equals(amazonPayId))).getSingle();
    expect(wallet.currentBalance, 1300);
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

  test('cashback destination metadata is persisted', () async {
    await engine.addTransaction(
      AddTransactionInput(
        type: TransactionType.creditCard,
        amount: 1000,
        title: 'Order',
        category: 'Shopping',
        transactionDate: DateTime(2026, 5, 24),
        paymentSourceType: PaymentSourceType.creditCard,
        paymentSourceId: cardId,
        cashbackAmount: 100,
        cashbackDestinationType: 'bank',
        cashbackDestinationId: bankId,
      ),
    );

    final txn = await (db.select(db.transactions)..limit(1)).getSingle();
    expect(txn.cashbackDestinationType, 'bank');
    expect(txn.cashbackDestinationId, bankId);
  });

  test('cashback to Amazon Pay increases selected wallet balance', () async {
    await engine.addTransaction(
      AddTransactionInput(
        type: TransactionType.creditCard,
        amount: 1000,
        title: 'Order',
        category: 'Shopping',
        transactionDate: DateTime(2026, 5, 24),
        paymentSourceType: PaymentSourceType.creditCard,
        paymentSourceId: cardId,
        cashbackAmount: 100,
        cashbackDestinationType: 'amazonPay',
        cashbackDestinationId: amazonPayId,
      ),
    );

    final wallet = await (db.select(
      db.cashWallets,
    )..where((w) => w.id.equals(amazonPayId))).getSingle();
    expect(wallet.currentBalance, 1600);
  });

  test(
    'cashback to same credit card stores metadata without bill mutation',
    () async {
      await engine.addTransaction(
        AddTransactionInput(
          type: TransactionType.creditCard,
          amount: 1000,
          title: 'Card cashback',
          category: 'Shopping',
          transactionDate: DateTime(2026, 5, 24),
          paymentSourceType: PaymentSourceType.creditCard,
          paymentSourceId: cardId,
          cashbackAmount: 100,
          cashbackDestinationType: 'creditCard',
          cashbackDestinationId: cardId,
        ),
      );

      final card = await (db.select(
        db.creditCards,
      )..where((c) => c.id.equals(cardId))).getSingle();
      final txn = await (db.select(db.transactions)..limit(1)).getSingle();
      expect(card.currentOutstanding, 6000);
      expect(txn.cashbackDestinationType, 'creditCard');
      expect(txn.cashbackDestinationId, cardId);
    },
  );

  test(
    'historical ledger-only expense does not mutate live source balance',
    () async {
      await engine.addTransaction(
        AddTransactionInput(
          type: TransactionType.bank,
          amount: 1200,
          title: 'Imported old utility',
          category: 'Bills',
          transactionDate: DateTime(2026, 5, 1),
          paymentSourceType: PaymentSourceType.bank,
          paymentSourceId: bankId,
          transactionImpactType: TransactionImpactType.historicalNoBalance,
        ),
      );

      final bank = await (db.select(
        db.bankAccounts,
      )..where((b) => b.id.equals(bankId))).getSingle();
      final txn = await (db.select(db.transactions)..limit(1)).getSingle();

      expect(bank.currentBalance, 10000);
      expect(
        txn.transactionImpactType,
        TransactionImpactType.historicalNoBalance,
      );
    },
  );

  test(
    'historical ledger-only update does not mutate live source balance',
    () async {
      await engine.addTransaction(
        AddTransactionInput(
          type: TransactionType.bank,
          amount: 500,
          title: 'Today expense',
          category: 'Bills',
          transactionDate: DateTime(2026, 5, 24),
          paymentSourceType: PaymentSourceType.bank,
          paymentSourceId: bankId,
        ),
      );

      final before = await (db.select(db.transactions)..limit(1)).getSingle();
      await engine.updateTransaction(
        before.id,
        AddTransactionInput(
          type: TransactionType.bank,
          amount: 500,
          title: 'Backdated expense',
          category: 'Bills',
          transactionDate: DateTime(2026, 5, 1),
          paymentSourceType: PaymentSourceType.bank,
          paymentSourceId: bankId,
          transactionImpactType: TransactionImpactType.historicalNoBalance,
        ),
      );

      final bank = await (db.select(
        db.bankAccounts,
      )..where((b) => b.id.equals(bankId))).getSingle();
      expect(bank.currentBalance, 10000);
    },
  );

  test('for-others transaction auto-calculates recoverable amount', () async {
    await engine.addTransaction(
      AddTransactionInput(
        type: TransactionType.bank,
        amount: 800,
        title: 'Shared taxi',
        category: 'Travel',
        transactionDate: DateTime(2026, 5, 24),
        paymentSourceType: PaymentSourceType.bank,
        paymentSourceId: bankId,
        cashbackAmount: 50,
        isForOthers: true,
        recoverablePartyName: 'Rahul',
      ),
    );
    final txn = await (db.select(db.transactions)..limit(1)).getSingle();
    expect(txn.isForOthers, true);
    expect(txn.recoverableAmount, 750);
    expect(txn.recoverablePartyName, 'Rahul');
    expect(txn.recoverableStatus, 'unpaid');
    expect(txn.recoverableBaseAmount, 750);
    expect(txn.recoveredAmount, 0);
  });

  test('editing recoverable transaction recalculates amount', () async {
    await engine.addTransaction(
      AddTransactionInput(
        type: TransactionType.bank,
        amount: 1000,
        title: 'Team lunch',
        category: 'Food',
        transactionDate: DateTime(2026, 5, 24),
        paymentSourceType: PaymentSourceType.bank,
        paymentSourceId: bankId,
        cashbackAmount: 100,
        isForOthers: true,
        recoverablePartyName: 'Neha',
      ),
    );
    final txn = await (db.select(db.transactions)..limit(1)).getSingle();

    await engine.updateTransaction(
      txn.id,
      AddTransactionInput(
        type: TransactionType.bank,
        amount: 1200,
        title: 'Team lunch updated',
        category: 'Food',
        transactionDate: DateTime(2026, 5, 24),
        paymentSourceType: PaymentSourceType.bank,
        paymentSourceId: bankId,
        cashbackAmount: 200,
        isForOthers: true,
        recoverablePartyName: 'Neha',
      ),
    );

    final updated = await (db.select(db.transactions)..limit(1)).getSingle();
    expect(updated.amount, 1200);
    expect(updated.cashbackAmount, 200);
    expect(updated.recoverableAmount, 1000);
    expect(updated.recoverablePartyName, 'Neha');
  });

  test('mark recovered updates settlement status', () async {
    await engine.addTransaction(
      AddTransactionInput(
        type: TransactionType.bank,
        amount: 600,
        title: 'Shared dinner',
        category: 'Food',
        transactionDate: DateTime(2026, 5, 24),
        paymentSourceType: PaymentSourceType.bank,
        paymentSourceId: bankId,
        isForOthers: true,
        recoverablePartyName: 'Aman',
      ),
    );
    final txn = await (db.select(db.transactions)..limit(1)).getSingle();

    await engine.markRecovered(txn.id);

    final recovered = await (db.select(db.transactions)..limit(1)).getSingle();
    expect(recovered.recoverableStatus, 'recovered');
    expect(recovered.recoveredAt != null, true);
  });

  test('deleting recoverable transaction reverses impact safely', () async {
    await engine.addTransaction(
      AddTransactionInput(
        type: TransactionType.bank,
        amount: 900,
        title: 'Shared ride',
        category: 'Travel',
        transactionDate: DateTime(2026, 5, 24),
        paymentSourceType: PaymentSourceType.bank,
        paymentSourceId: bankId,
        cashbackAmount: 100,
        isForOthers: true,
        recoverablePartyName: 'Roommate',
      ),
    );

    final bankBeforeDelete = await (db.select(
      db.bankAccounts,
    )..where((b) => b.id.equals(bankId))).getSingle();
    expect(bankBeforeDelete.currentBalance, 9100);

    final txn = await (db.select(db.transactions)..limit(1)).getSingle();
    await engine.deleteTransaction(txn.id);

    final bankAfterDelete = await (db.select(
      db.bankAccounts,
    )..where((b) => b.id.equals(bankId))).getSingle();
    expect(bankAfterDelete.currentBalance, 10000);
    expect(await (db.select(db.transactions)).get(), isEmpty);
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

  test('income increases selected bank account', () async {
    await engine.addTransaction(
      AddTransactionInput(
        type: TransactionType.income,
        amount: 2000,
        title: 'Salary',
        category: 'Salary',
        transactionDate: DateTime(2026, 5, 24),
        paymentSourceType: PaymentSourceType.bank,
        paymentSourceId: bankId,
      ),
    );

    final bank = await (db.select(
      db.bankAccounts,
    )..where((b) => b.id.equals(bankId))).getSingle();
    expect(bank.currentBalance, 12000);
  });

  test('income increases selected cash wallet', () async {
    await engine.addTransaction(
      AddTransactionInput(
        type: TransactionType.income,
        amount: 1000,
        title: 'Cash gift',
        category: 'Gift',
        transactionDate: DateTime(2026, 5, 24),
        paymentSourceType: PaymentSourceType.cash,
        paymentSourceId: cashId,
      ),
    );

    final wallet = await (db.select(
      db.cashWallets,
    )..where((w) => w.id.equals(cashId))).getSingle();
    expect(wallet.currentBalance, 4000);
  });

  test('income increases Amazon Pay wallet', () async {
    await engine.addTransaction(
      AddTransactionInput(
        type: TransactionType.income,
        amount: 300,
        title: 'Amazon Pay refund',
        category: 'Refund',
        transactionDate: DateTime(2026, 5, 24),
        paymentSourceType: PaymentSourceType.cash,
        paymentSourceId: amazonPayId,
      ),
    );

    final wallet = await (db.select(
      db.cashWallets,
    )..where((w) => w.id.equals(amazonPayId))).getSingle();
    expect(wallet.currentBalance, 1800);
  });

  test('income does not affect card outstanding', () async {
    await engine.addTransaction(
      AddTransactionInput(
        type: TransactionType.income,
        amount: 1500,
        title: 'Refund',
        category: 'Refund',
        transactionDate: DateTime(2026, 5, 24),
        paymentSourceType: PaymentSourceType.bank,
        paymentSourceId: bankId,
      ),
    );

    final card = await (db.select(
      db.creditCards,
    )..where((c) => c.id.equals(cardId))).getSingle();
    expect(card.currentOutstanding, 5000);
  });

  test(
    'linked refund reduces recoverable amount on original transaction',
    () async {
      await engine.addTransaction(
        AddTransactionInput(
          type: TransactionType.creditCard,
          amount: 1000,
          title: 'Shared order',
          category: 'Shopping',
          transactionDate: DateTime(2026, 5, 24),
          paymentSourceType: PaymentSourceType.creditCard,
          paymentSourceId: cardId,
          isForOthers: true,
          recoverablePartyName: 'Rahul',
        ),
      );
      final original = await (db.select(
        db.transactions,
      )..where((t) => t.title.equals('Shared order'))).getSingle();

      await engine.addTransaction(
        AddTransactionInput(
          type: TransactionType.refund,
          amount: 400,
          title: 'Shared order refund',
          category: 'Refund',
          transactionDate: DateTime(2026, 5, 25),
          paymentSourceType: PaymentSourceType.creditCard,
          paymentSourceId: cardId,
          relatedTransactionId: original.id,
        ),
      );

      final updated = await (db.select(
        db.transactions,
      )..where((t) => t.id.equals(original.id))).getSingle();

      expect(updated.recoverableBaseAmount, closeTo(600, 0.01));
      expect(updated.recoverableAmount, closeTo(600, 0.01));
      expect(updated.recoveredAmount, 0);
      expect(updated.recoverableStatus, 'unpaid');
    },
  );

  test('split-linked transaction is not editable', () async {
    final groupId = await splitService.createGroup('Trip');
    final youId = await splitService.addMember(
      groupId,
      name: 'You',
      isCurrentUser: true,
    );
    final rahulId = await splitService.addMember(groupId, name: 'Rahul');

    final splitExpenseId = await splitService.addSplitExpense(
      AddSplitExpenseInput(
        groupId: groupId,
        title: 'Stay',
        totalAmount: 1000,
        paidByMemberId: youId,
        splitType: 'exact',
        expenseDate: DateTime(2026, 5, 24),
        category: 'Travel',
        shares: [
          SplitShareInput(memberId: youId, exactAmount: 300),
          SplitShareInput(memberId: rahulId, exactAmount: 700),
        ],
        paymentSourceType: PaymentSourceType.bank,
        paymentSourceId: bankId,
      ),
    );

    final txn = await (db.select(
      db.transactions,
    )..where((t) => t.linkedSplitExpenseId.equals(splitExpenseId))).getSingle();

    expect(engine.isEditable(txn), isFalse);
  });
}
