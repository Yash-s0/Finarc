import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/features/expenses/data/transaction_engine.dart';
import 'package:finarc/features/expenses/models/transaction_types.dart';
import 'package:finarc/features/profile/data/transaction_import_service.dart';

void main() {
  late AppDatabase db;
  late TransactionEngine engine;
  late TransactionImportService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    engine = TransactionEngine(db);
    service = TransactionImportService(db, engine);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> seedBank({String name = 'Main Bank'}) {
    return db
        .into(db.bankAccounts)
        .insert(
          BankAccountsCompanion.insert(
            bankName: 'HDFC',
            accountName: name,
            accountType: 'savings',
            currentBalance: const Value(10000),
          ),
        );
  }

  Future<int> seedWallet({String name = 'Cash Wallet'}) {
    return db
        .into(db.cashWallets)
        .insert(
          CashWalletsCompanion.insert(
            walletName: name,
            currentBalance: const Value(5000),
          ),
        );
  }

  Future<int> seedAmazonPayWallet() {
    return db
        .into(db.cashWallets)
        .insert(
          CashWalletsCompanion.insert(
            walletName: 'Amazon Pay',
            walletType: const Value('amazonPay'),
            currentBalance: const Value(2500),
          ),
        );
  }

  Future<int> seedCard({String nickname = 'Amazon'}) {
    return db
        .into(db.creditCards)
        .insert(
          CreditCardsCompanion.insert(
            bankName: 'ICICI',
            nickname: nickname,
            last4: '1234',
            maskedNumber: '**** **** **** 1234',
            creditLimit: 100000,
            billingDay: 15,
            dueDay: 25,
            currentOutstanding: const Value(1000),
          ),
        );
  }

  test('valid JSON parses successfully', () async {
    await seedWallet();
    final jsonText = jsonEncode({
      'transactions': [
        {
          'date': '2026-05-31T14:30:00',
          'amount': 401,
          'type': 'expense',
          'title': 'Amazon',
          'paymentMode': 'cash',
          'sourceName': 'Cash Wallet',
        },
      ],
    });

    final result = await service.parsePreview(jsonText);

    expect(result.isValidJson, true);
    expect(result.preview, isNotNull);
    expect(result.preview!.validRows, 1);
    expect(result.preview!.invalidRows, 0);
  });

  test('invalid JSON is rejected', () async {
    final result = await service.parsePreview('{broken json');

    expect(result.isValidJson, false);
    expect(result.preview, isNull);
  });

  test('missing sourceName with multiple sources is invalid', () async {
    await seedBank(name: 'Primary');
    await seedBank(name: 'Secondary');
    final jsonText = jsonEncode({
      'transactions': [
        {
          'date': '2026-05-31T14:30:00',
          'amount': 120,
          'type': 'expense',
          'title': 'UPI Pay',
          'paymentMode': 'bank',
        },
      ],
    });

    final result = await service.parsePreview(jsonText);

    expect(result.preview!.validRows, 0);
    expect(
      result.preview!.rows.first.issues.any(
        (issue) => issue.message.contains('sourceName is required'),
      ),
      true,
    );
  });

  test('missing sourceName with one source auto-selects it', () async {
    final walletId = await seedWallet();
    final jsonText = jsonEncode({
      'transactions': [
        {
          'date': '2026-05-31T14:30:00',
          'amount': 70,
          'type': 'expense',
          'title': 'Snacks',
          'paymentMode': 'cash',
        },
      ],
    });

    final result = await service.parsePreview(jsonText);
    final row = result.preview!.rows.first;

    expect(row.isValid, true);
    expect(row.resolved!.sourceId, walletId);
    expect(
      row.issues.any((issue) => issue.message.contains('auto-selected')),
      true,
    );
  });

  test(
    'historical card import preserves live card outstanding and records transaction',
    () async {
      final cardId = await seedCard();
      final jsonText = jsonEncode({
        'transactions': [
          {
            'date': '2026-05-31T14:30:00',
            'amount': 400,
            'type': 'expense',
            'title': 'Amazon',
            'paymentMode': 'card',
            'sourceName': 'ICICI Amazon',
          },
        ],
      });

      final preview = (await service.parsePreview(jsonText)).preview!;
      final execution = await service.importValidRows(preview);

      final card = await (db.select(
        db.creditCards,
      )..where((c) => c.id.equals(cardId))).getSingle();
      final txns = await db.select(db.transactions).get();

      expect(execution.importedCount, 1);
      expect(card.currentOutstanding, closeTo(1000, 0.01));
      expect(txns.single.type, 'creditCard');
      expect(txns.single.paymentSourceId, cardId);
      expect(
        txns.single.transactionImpactType,
        TransactionImpactType.historicalNoBalance,
      );
    },
  );

  test('historical cash import preserves live wallet balance', () async {
    final walletId = await seedWallet();
    final jsonText = jsonEncode({
      'transactions': [
        {
          'date': '2026-05-31T14:30:00',
          'amount': 200,
          'type': 'expense',
          'title': 'Groceries',
          'paymentMode': 'cash',
          'sourceName': 'Cash Wallet',
        },
      ],
    });

    final preview = (await service.parsePreview(jsonText)).preview!;
    await service.importValidRows(preview);

    final wallet = await (db.select(
      db.cashWallets,
    )..where((w) => w.id.equals(walletId))).getSingle();
    final txn = await db.select(db.transactions).getSingle();
    expect(wallet.currentBalance, closeTo(5000, 0.01));
    expect(
      txn.transactionImpactType,
      TransactionImpactType.historicalNoBalance,
    );
  });

  test('historical bank import preserves live bank balance', () async {
    final bankId = await seedBank(name: 'Main Account');
    final jsonText = jsonEncode({
      'transactions': [
        {
          'date': '2026-05-31T14:30:00',
          'amount': 300,
          'type': 'expense',
          'title': 'Fuel',
          'paymentMode': 'bank',
          'sourceName': 'Main Account',
        },
      ],
    });

    final preview = (await service.parsePreview(jsonText)).preview!;
    await service.importValidRows(preview);

    final bank = await (db.select(
      db.bankAccounts,
    )..where((b) => b.id.equals(bankId))).getSingle();
    final txn = await db.select(db.transactions).getSingle();
    expect(bank.currentBalance, closeTo(10000, 0.01));
    expect(
      txn.transactionImpactType,
      TransactionImpactType.historicalNoBalance,
    );
  });

  test('historical income import preserves live destination balance', () async {
    final bankId = await seedBank(name: 'Salary Account');
    final jsonText = jsonEncode({
      'transactions': [
        {
          'date': '2026-05-31T10:00:00',
          'amount': 5000,
          'type': 'income',
          'title': 'Salary',
          'paymentMode': 'bank',
          'sourceName': 'Salary Account',
        },
      ],
    });

    final preview = (await service.parsePreview(jsonText)).preview!;
    await service.importValidRows(preview);

    final bank = await (db.select(
      db.bankAccounts,
    )..where((b) => b.id.equals(bankId))).getSingle();
    final txn = await db.select(db.transactions).getSingle();
    expect(bank.currentBalance, closeTo(10000, 0.01));
    expect(
      txn.transactionImpactType,
      TransactionImpactType.historicalNoBalance,
    );
  });

  test('forOthers import creates recoverable values', () async {
    await seedBank(name: 'Main Account');
    final jsonText = jsonEncode({
      'transactions': [
        {
          'date': '2026-05-31T14:30:00',
          'amount': 1000,
          'type': 'expense',
          'title': 'Dinner',
          'paymentMode': 'bank',
          'sourceName': 'Main Account',
          'forOthers': true,
          'personName': 'Rahul',
          'cashback': 100,
          'recoveredAmount': 200,
        },
      ],
    });

    final preview = (await service.parsePreview(jsonText)).preview!;
    await service.importValidRows(preview);

    final txn = await db.select(db.transactions).getSingle();
    expect(txn.isForOthers, true);
    expect(txn.recoverableBaseAmount, closeTo(900, 0.01));
    expect(txn.recoveredAmount, closeTo(200, 0.01));
    expect(txn.recoverableAmount, closeTo(700, 0.01));
    expect(txn.recoverablePartyName, 'Rahul');
  });

  test(
    'duplicate warning appears for existing same date/amount/title/source',
    () async {
      final bankId = await seedBank(name: 'Main Account');
      await engine.addTransaction(
        AddTransactionInput(
          type: 'bank',
          amount: 250,
          title: 'Food Court',
          category: 'Food',
          transactionDate: DateTime.parse('2026-05-31T12:00:00'),
          paymentSourceType: 'bank',
          paymentSourceId: bankId,
        ),
      );

      final jsonText = jsonEncode({
        'transactions': [
          {
            'date': '2026-05-31T20:00:00',
            'amount': 250,
            'type': 'expense',
            'title': 'Food Court',
            'paymentMode': 'bank',
            'sourceName': 'Main Account',
          },
        ],
      });

      final result = await service.parsePreview(jsonText);
      final row = result.preview!.rows.single;

      expect(row.isValid, true);
      expect(
        row.issues.any((issue) => issue.message.contains('Possible duplicate')),
        true,
      );
    },
  );

  test('preview reports valid and invalid row counts', () async {
    await seedWallet();
    final jsonText = jsonEncode({
      'transactions': [
        {
          'date': '2026-05-31T14:30:00',
          'amount': 100,
          'type': 'expense',
          'title': 'Tea',
          'paymentMode': 'cash',
          'sourceName': 'Cash Wallet',
        },
        {
          'date': 'invalid-date',
          'amount': -5,
          'type': 'expense',
          'title': '',
          'paymentMode': 'cash',
        },
      ],
    });

    final result = await service.parsePreview(jsonText);

    expect(result.preview!.totalRows, 2);
    expect(result.preview!.validRows, 1);
    expect(result.preview!.invalidRows, 1);
  });

  test(
    'historical Amazon Pay import preserves wallet balance and stores cashback destination',
    () async {
      final walletId = await seedAmazonPayWallet();
      final jsonText = jsonEncode({
        'transactions': [
          {
            'date': '2026-05-31T14:30:00',
            'amount': 300,
            'type': 'expense',
            'title': 'Amazon Order',
            'paymentMode': 'amazonPay',
            'sourceName': 'Amazon Pay',
            'cashback': 50,
            'cashbackDestinationType': 'amazonPay',
            'cashbackDestinationName': 'Amazon Pay',
          },
        ],
      });

      final preview = (await service.parsePreview(jsonText)).preview!;
      expect(preview.validRows, 1);
      await service.importValidRows(preview);

      final wallet = await (db.select(
        db.cashWallets,
      )..where((w) => w.id.equals(walletId))).getSingle();
      final txn = await db.select(db.transactions).getSingle();
      expect(wallet.currentBalance, closeTo(2500, 0.01));
      expect(txn.cashbackDestinationType, 'amazonPay');
      expect(txn.cashbackDestinationId, walletId);
      expect(
        txn.transactionImpactType,
        TransactionImpactType.historicalNoBalance,
      );
    },
  );

  test(
    'card statement income rows become card payments or refunds with Amazon Pay cashback adjustments',
    () async {
      final walletId = await seedAmazonPayWallet();
      final cardId = await seedCard(nickname: 'Amazon Pay');
      final futureDate = DateTime.now().add(const Duration(days: 1));
      final jsonText = jsonEncode([
        {
          'date': '2026-06-02T00:00:00',
          'amount': 1489.01,
          'type': 'income',
          'title': 'Amazon',
          'category': 'Groceries',
          'paymentMode': 'card',
          'sourceName': 'Amazon Pay',
          'cashback': 0,
          'notes': 'BBPS Payment Received',
        },
        {
          'date': futureDate.toIso8601String(),
          'amount': 1203,
          'type': 'income',
          'title': 'Amazon',
          'category': 'Groceries',
          'paymentMode': 'card',
          'sourceName': 'Amazon Pay',
          'cashback': -60,
          'notes': 'Refund (reward points deducted)',
        },
      ]);

      final preview = (await service.parsePreview(jsonText)).preview!;
      expect(preview.validRows, 2);
      expect(
        preview.rows.first.resolved!.input.type,
        TransactionType.cardPayment,
      );
      expect(preview.rows.last.resolved!.input.type, TransactionType.refund);
      expect(preview.rows.last.resolved!.input.cashbackAmount, -60);
      expect(
        preview.rows.last.resolved!.input.cashbackDestinationType,
        'amazonPay',
      );
      expect(preview.rows.last.resolved!.input.cashbackDestinationId, walletId);

      await service.importValidRows(preview);

      final txns = await db.select(db.transactions).get();
      final wallet = await (db.select(
        db.cashWallets,
      )..where((w) => w.id.equals(walletId))).getSingle();
      final card = await (db.select(
        db.creditCards,
      )..where((c) => c.id.equals(cardId))).getSingle();

      expect(
        txns.map((txn) => txn.type),
        contains(TransactionType.cardPayment),
      );
      expect(txns.map((txn) => txn.type), contains(TransactionType.refund));
      expect(wallet.currentBalance, closeTo(2440, 0.01));
      expect(card.currentOutstanding, closeTo(1000, 0.01));
    },
  );

  test(
    'unresolved cashback destination becomes warning without blocking import',
    () async {
      await seedBank(name: 'Main Account');
      final jsonText = jsonEncode({
        'transactions': [
          {
            'date': '2026-05-31T14:30:00',
            'amount': 300,
            'type': 'expense',
            'title': 'Fuel',
            'paymentMode': 'bank',
            'sourceName': 'Main Account',
            'cashback': 25,
            'cashbackDestinationType': 'bank',
            'cashbackDestinationName': 'Missing Account',
          },
        ],
      });

      final result = await service.parsePreview(jsonText);
      final row = result.preview!.rows.single;
      expect(row.isValid, true);
      expect(
        row.issues.any(
          (issue) => issue.message.contains(
            'cashback destination could not be resolved',
          ),
        ),
        true,
      );
      expect(row.resolved!.input.cashbackDestinationType, 'unknown');
      expect(row.resolved!.input.cashbackDestinationId, isNull);
    },
  );
}
