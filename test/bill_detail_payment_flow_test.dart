import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/core/database/database_providers.dart';
import 'package:finarc/features/cards/presentation/bill_detail_screen.dart';
import 'package:finarc/shared/widgets/finarc/finarc_primary_button.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> createCard({double currentOutstanding = 1200}) {
    return db
        .into(db.creditCards)
        .insert(
          CreditCardsCompanion.insert(
            bankName: 'Axis',
            nickname: 'Rewards',
            last4: '0374',
            maskedNumber: '**** **** **** 0374',
            creditLimit: 50000,
            billingDay: 10,
            dueDay: 20,
            currentOutstanding: Value(currentOutstanding),
          ),
        );
  }

  Future<int> createBill(int cardId, {double billedAmount = 1200}) {
    return db
        .into(db.cardBills)
        .insert(
          CardBillsCompanion.insert(
            cardId: cardId,
            cycleStartDate: Value(DateTime(2026, 4, 11)),
            cycleEndDate: Value(DateTime(2026, 5, 10)),
            billingDate: Value(DateTime(2026, 5, 10)),
            dueDate: Value(DateTime(2026, 5, 20)),
            billedAmount: billedAmount,
            paidAmount: const Value(0),
            status: const Value('billed'),
          ),
        );
  }

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        seedProvider.overrideWith((ref) async {}),
      ],
      child: MaterialApp(home: child),
    );
  }

  testWidgets(
    'bill detail shows payment action and full payment defaults to remaining due',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await db
          .into(db.bankAccounts)
          .insert(
            BankAccountsCompanion.insert(
              bankName: 'HDFC',
              accountName: 'Main',
              accountType: 'savings',
              currentBalance: const Value(5000),
            ),
          );
      final cardId = await createCard();
      final billId = await createBill(cardId);

      await tester.pumpWidget(
        wrap(BillDetailScreen(cardId: cardId, billId: billId)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Record Payment'), findsOneWidget);

      await tester.tap(find.text('Record Payment'));
      await tester.pumpAndSettle();

      expect(find.text('1200.00'), findsOneWidget);

      await tester.ensureVisible(find.text('Confirm'));
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      final bill = await (db.select(
        db.cardBills,
      )..where((b) => b.id.equals(billId))).getSingle();
      final payments = await (db.select(
        db.transactions,
      )..where((t) => t.type.equals('cardPayment'))).get();

      expect(bill.status, 'paid');
      expect(bill.paidAmount, 1200);
      expect(payments, hasLength(2));
      expect(payments.every((t) => t.amount == 1200), isTrue);
    },
  );

  testWidgets('bill detail shows bill mismatch review context', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final cardId = await createCard();
    final billId = await createBill(cardId);

    await tester.pumpWidget(
      wrap(
        BillDetailScreen(
          cardId: cardId,
          billId: billId,
          reviewContext: const BillReviewContext(
            kind: 'billMismatch',
            appAmount: 1200,
            notificationAmount: 1250,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bill Amount Review'), findsOneWidget);
    expect(find.text('App bill amount'), findsOneWidget);
    expect(find.text('Notification amount'), findsOneWidget);
    expect(find.text('Difference'), findsOneWidget);
    expect(find.text('₹1,250.00'), findsOneWidget);
    expect(find.text('₹50.00'), findsOneWidget);
  });

  testWidgets(
    'partial payment reduces remaining due and supports cash wallet source',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await db
          .into(db.cashWallets)
          .insert(
            CashWalletsCompanion.insert(
              walletName: 'Cash',
              currentBalance: const Value(2500),
            ),
          );
      final cardId = await createCard();
      final billId = await createBill(cardId);

      await tester.pumpWidget(
        wrap(BillDetailScreen(cardId: cardId, billId: billId)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Record Payment'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Partial Payment'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Payment amount'),
        '200.00',
      );

      await tester.ensureVisible(find.text('Confirm'));
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      final bill = await (db.select(
        db.cardBills,
      )..where((b) => b.id.equals(billId))).getSingle();
      final wallet = await (db.select(
        db.cashWallets,
      )..where((w) => w.id.equals(1))).getSingle();
      final payments = await (db.select(
        db.transactions,
      )..where((t) => t.type.equals('cardPayment'))).get();

      expect(bill.paidAmount, 200);
      expect(wallet.currentBalance, 2300);
      expect(payments, hasLength(2));
      expect(payments.every((t) => t.amount == 200), isTrue);
    },
  );

  testWidgets('overpayment is blocked in the payment form', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await db
        .into(db.bankAccounts)
        .insert(
          BankAccountsCompanion.insert(
            bankName: 'ICICI',
            accountName: 'Salary',
            accountType: 'savings',
            currentBalance: const Value(5000),
          ),
        );
    final cardId = await createCard();
    final billId = await createBill(cardId);

    await tester.pumpWidget(
      wrap(BillDetailScreen(cardId: cardId, billId: billId)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Record Payment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Partial Payment'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Payment amount'),
      '1300.00',
    );

    await tester.ensureVisible(find.text('Confirm'));
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(
      find.text('Payment amount cannot exceed remaining due'),
      findsOneWidget,
    );

    final bill = await (db.select(
      db.cardBills,
    )..where((b) => b.id.equals(billId))).getSingle();
    expect(bill.paidAmount, 0);
  });

  testWidgets(
    'paid bill disables payment action and keeps paid status visible',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await db
          .into(db.bankAccounts)
          .insert(
            BankAccountsCompanion.insert(
              bankName: 'HDFC',
              accountName: 'Main',
              accountType: 'savings',
              currentBalance: const Value(5000),
            ),
          );
      final cardId = await createCard(currentOutstanding: 0);
      final billId = await createBill(cardId, billedAmount: 8384.59);
      await (db.update(db.cardBills)..where((b) => b.id.equals(billId))).write(
        const CardBillsCompanion(
          paidAmount: Value(8384.59),
          status: Value('paid'),
        ),
      );

      await tester.pumpWidget(
        wrap(BillDetailScreen(cardId: cardId, billId: billId)),
      );
      await tester.pumpAndSettle();

      expect(find.text('₹8,384.59'), findsAtLeastNWidgets(2));
      final paidButton = tester.widget<FinarcPrimaryButton>(
        find.byType(FinarcPrimaryButton),
      );
      expect(paidButton.label, 'Paid');
      expect(paidButton.onPressed == null, isTrue);
    },
  );
}
