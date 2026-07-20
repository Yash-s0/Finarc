import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/core/database/database_providers.dart';
import 'package:finarc/features/expenses/presentation/add_expense_screen.dart';
import 'package:finarc/features/expenses/presentation/add_income_screen.dart';
import 'package:finarc/features/expenses/presentation/entry_date_time_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AppDatabase> createDb({
    int cashWallets = 1,
    int banks = 1,
    int cards = 1,
  }) async {
    final db = AppDatabase(NativeDatabase.memory());
    for (var i = 0; i < cashWallets; i++) {
      await db
          .into(db.cashWallets)
          .insert(
            CashWalletsCompanion.insert(
              walletName: 'Cash Wallet ${i + 1}',
              currentBalance: const drift.Value(5000),
            ),
          );
    }
    for (var i = 0; i < banks; i++) {
      await db
          .into(db.bankAccounts)
          .insert(
            BankAccountsCompanion.insert(
              bankName: 'Kotak',
              accountName: 'Kotak Salary ${i + 1}',
              accountType: 'Savings',
              currentBalance: const drift.Value(25000),
            ),
          );
    }
    for (var i = 0; i < cards; i++) {
      await db
          .into(db.creditCards)
          .insert(
            CreditCardsCompanion.insert(
              bankName: 'HDFC',
              nickname: 'HDFC Millennia ${i + 1}',
              last4: '${1234 + i}',
              maskedNumber: '**** **** **** ${1234 + i}',
              creditLimit: 100000,
              billingDay: 20,
              dueDay: 5,
            ),
          );
    }
    return db;
  }

  Widget wrap(AppDatabase db, Widget child) {
    return ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp(home: child),
    );
  }

  Future<Transaction?> latestTransaction(AppDatabase db) {
    return (db.select(db.transactions)
          ..orderBy([(t) => drift.OrderingTerm.desc(t.id)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> enterAmount(WidgetTester tester, String value) async {
    await tester.enterText(find.byType(TextFormField).first, value);
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.dragUntilVisible(
      finder,
      find.byType(ListView).first,
      const Offset(0, -220),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Add Expense renders square payment mode options without wallet',
    (tester) async {
      final db = await createDb();
      addTearDown(() async => db.close());

      await tester.pumpWidget(wrap(db, const AddExpenseScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('expense-mode-cash')), findsOneWidget);
      expect(find.byKey(const Key('expense-mode-upi')), findsOneWidget);
      expect(find.byKey(const Key('expense-mode-creditCard')), findsOneWidget);
      expect(find.byKey(const Key('expense-mode-bank')), findsOneWidget);
      expect(find.byKey(const Key('expense-mode-wallet')), findsNothing);
    },
  );

  testWidgets('Cash mode still maps to cash wallet source', (tester) async {
    final db = await createDb(cashWallets: 1, banks: 1, cards: 1);
    addTearDown(() async => db.close());

    await tester.pumpWidget(wrap(db, const AddExpenseScreen()));
    await tester.pumpAndSettle();

    await enterAmount(tester, '300');
    await tester.tap(find.text('Save Expense'));
    await tester.pumpAndSettle();

    final saved = await latestTransaction(db);
    expect(saved, isNotNull);
    expect(saved!.paymentSourceType, 'cash');
    expect(saved.paymentSourceId, isNotNull);
  });

  testWidgets('Amazon Pay wallet can be used as cash source', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await db
        .into(db.cashWallets)
        .insert(
          CashWalletsCompanion.insert(
            walletName: 'Amazon Pay',
            walletType: const drift.Value('amazonPay'),
            currentBalance: const drift.Value(5000),
          ),
        );
    addTearDown(() async => db.close());

    await tester.pumpWidget(wrap(db, const AddExpenseScreen()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Amazon Pay'), findsOneWidget);
    await enterAmount(tester, '300');
    await tester.tap(find.text('Save Expense'));
    await tester.pumpAndSettle();

    final saved = await latestTransaction(db);
    expect(saved, isNotNull);
    expect(saved!.paymentSourceType, 'cash');
  });

  testWidgets('Add Expense default category remains General when untouched', (
    tester,
  ) async {
    final db = await createDb();
    addTearDown(() async => db.close());

    await tester.pumpWidget(wrap(db, const AddExpenseScreen()));
    await tester.pumpAndSettle();

    await enterAmount(tester, '110');
    await scrollTo(tester, find.text('Save Expense'));
    await tester.tap(find.text('Save Expense'));
    await tester.pumpAndSettle();

    final saved = await latestTransaction(db);
    expect(saved, isNotNull);
    expect(saved!.category, 'General');
  });

  testWidgets(
    'Add Expense allows empty merchant/title and saves fallback title',
    (tester) async {
      final db = await createDb(cashWallets: 1);
      addTearDown(() async => db.close());

      await tester.pumpWidget(wrap(db, const AddExpenseScreen()));
      await tester.pumpAndSettle();

      await enterAmount(tester, '250');
      await scrollTo(tester, find.text('Save Expense'));
      await tester.tap(find.text('Save Expense'));
      await tester.pumpAndSettle();

      final saved = await latestTransaction(db);
      expect(saved, isNotNull);
      expect(saved!.title, 'General Expense');
      expect(saved.category, 'General');
    },
  );

  testWidgets('For Others field empty means not for others', (tester) async {
    final db = await createDb(cashWallets: 1);
    addTearDown(() async => db.close());

    await tester.pumpWidget(wrap(db, const AddExpenseScreen()));
    await tester.pumpAndSettle();

    await enterAmount(tester, '250');
    await tester.tap(find.text('Save Expense'));
    await tester.pumpAndSettle();

    final saved = await latestTransaction(db);
    expect(saved, isNotNull);
    expect(saved!.isForOthers, false);
    expect(saved.recoverablePartyName, isNull);
    expect(saved.recoverableAmount, isNull);
  });

  testWidgets('For Others name creates recoverable', (tester) async {
    final db = await createDb(cashWallets: 1);
    addTearDown(() async => db.close());

    await tester.pumpWidget(wrap(db, const AddExpenseScreen()));
    await tester.pumpAndSettle();

    await enterAmount(tester, '1000');
    await scrollTo(tester, find.text('For others?'));
    final personInput = find.byKey(const Key('expense-for-others-person'));
    await tester.enterText(personInput, 'Riya');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Expense'));
    await tester.pumpAndSettle();

    final saved = await latestTransaction(db);
    expect(saved, isNotNull);
    expect(saved!.isForOthers, true);
    expect(saved.recoverablePartyName, 'Riya');
    expect(saved.recoverableAmount, 1000);
  });

  testWidgets('Clearing For Others removes recoverable metadata', (
    tester,
  ) async {
    final db = await createDb(cashWallets: 1);
    addTearDown(() async => db.close());

    await tester.pumpWidget(wrap(db, const AddExpenseScreen()));
    await tester.pumpAndSettle();

    await enterAmount(tester, '900');
    await scrollTo(tester, find.text('For others?'));
    final personField = find.byKey(const Key('expense-for-others-person'));
    await tester.enterText(personField, 'Aman');
    await tester.pumpAndSettle();
    await tester.enterText(personField, '');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Expense'));
    await tester.pumpAndSettle();

    final saved = await latestTransaction(db);
    expect(saved, isNotNull);
    expect(saved!.isForOthers, false);
    expect(saved.recoverablePartyName, isNull);
    expect(saved.recoverableAmount, isNull);
  });

  testWidgets('Add Expense bottom button is visible and bottom-aligned', (
    tester,
  ) async {
    final db = await createDb();
    addTearDown(() async => db.close());
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(390, 844));

    await tester.pumpWidget(wrap(db, const AddExpenseScreen()));
    await tester.pumpAndSettle();

    final buttonFinder = find.text('Save Expense');
    expect(buttonFinder, findsOneWidget);
    final buttonRect = tester.getRect(buttonFinder);
    expect(buttonRect.bottom, greaterThan(760));
  });

  testWidgets(
    'Add Expense transaction time uses current timestamp, not midnight',
    (tester) async {
      final db = await createDb();
      addTearDown(() async => db.close());

      final seededNow = DateTime(2026, 5, 31, 14, 37, 10);
      await tester.pumpWidget(
        wrap(db, AddExpenseScreen(initialDateTime: seededNow)),
      );
      await tester.pumpAndSettle();

      await enterAmount(tester, '100');
      await scrollTo(tester, find.text('Save Expense'));
      await tester.tap(find.text('Save Expense'));
      await tester.pumpAndSettle();

      final saved = await latestTransaction(db);
      expect(saved, isNotNull);
      expect(saved!.transactionDate.hour, 14);
      expect(saved.transactionDate.minute, 37);
    },
  );

  test('changing date preserves existing time components', () {
    final existing = DateTime(2026, 5, 10, 14, 35, 21, 120, 450);
    final pickedDate = DateTime(2026, 6, 12);
    final merged = mergeDateWithExistingTime(
      pickedDate: pickedDate,
      existing: existing,
    );

    expect(merged.year, 2026);
    expect(merged.month, 6);
    expect(merged.day, 12);
    expect(merged.hour, 14);
    expect(merged.minute, 35);
    expect(merged.second, 21);
    expect(merged.millisecond, 120);
    expect(merged.microsecond, 450);
  });

  testWidgets('Add Income empty title can save and uses fallback title', (
    tester,
  ) async {
    final db = await createDb();
    addTearDown(() async => db.close());

    await tester.pumpWidget(
      wrap(
        db,
        AddIncomeScreen(
          initialDateTime: DateTime.now().add(const Duration(minutes: 5)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await enterAmount(tester, '500');
    await scrollTo(tester, find.text('Save Income'));
    await tester.tap(find.text('Save Income'));
    await tester.pumpAndSettle();

    final saved = await latestTransaction(db);
    expect(saved, isNotNull);
    expect(saved!.title, 'Income');
    expect(saved.type, 'income');
  });

  testWidgets('Add Income uses destination selector with card refund mode', (
    tester,
  ) async {
    final db = await createDb();
    addTearDown(() async => db.close());

    await tester.pumpWidget(wrap(db, const AddIncomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('RECEIVE INTO'), findsOneWidget);
    expect(find.byKey(const Key('income-mode-cash')), findsOneWidget);
    expect(find.byKey(const Key('income-mode-upi')), findsOneWidget);
    expect(find.byKey(const Key('income-mode-bank')), findsOneWidget);
    expect(find.byKey(const Key('income-mode-creditCard')), findsOneWidget);
    expect(find.byKey(const Key('income-mode-wallet')), findsNothing);
    expect(find.text('Category'), findsNothing);
  });

  testWidgets(
    'Add Income card destination saves refund and reduces outstanding',
    (tester) async {
      final db = await createDb();
      addTearDown(() async => db.close());
      final card = await db.select(db.creditCards).getSingle();
      await (db.update(
        db.creditCards,
      )..where((c) => c.id.equals(card.id))).write(
        const CreditCardsCompanion(currentOutstanding: drift.Value(1000)),
      );

      await tester.pumpWidget(wrap(db, const AddIncomeScreen()));
      await tester.pumpAndSettle();

      await enterAmount(tester, '250');
      await tester.tap(find.byKey(const Key('income-mode-creditCard')));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('Save Income'));
      await tester.tap(find.text('Save Income'));
      await tester.pumpAndSettle();

      final saved = await latestTransaction(db);
      final updatedCard = await (db.select(
        db.creditCards,
      )..where((c) => c.id.equals(card.id))).getSingle();
      expect(saved, isNotNull);
      expect(saved!.type, 'refund');
      expect(saved.paymentSourceType, 'creditCard');
      expect(saved.transactionImpactType, isNull);
      expect(saved.title, 'Card Refund');
      expect(updatedCard.currentOutstanding, 750);
    },
  );
}
