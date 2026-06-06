import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/core/database/database_providers.dart';
import 'package:finarc/features/accounts/presentation/add_edit_account_screen.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpScreen(
    WidgetTester tester,
    AddEditAccountScreen screen,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('editing a bank account preloads and saves name and last4', (
    tester,
  ) async {
    final accountId = await db
        .into(db.bankAccounts)
        .insert(
          BankAccountsCompanion.insert(
            bankName: 'HDFC',
            accountName: 'Primary',
            accountType: 'savings',
            last4: const Value('1111'),
            currentBalance: const Value(5000),
          ),
        );

    await pumpScreen(
      tester,
      AddEditAccountScreen(editType: 'bank', editId: accountId),
    );

    expect(find.text('Primary'), findsOneWidget);
    expect(find.text('1111'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Account nickname'),
      'Salary',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Account last 4 digits (optional)'),
      '4321',
    );
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    final updated = await (db.select(
      db.bankAccounts,
    )..where((b) => b.id.equals(accountId))).getSingle();
    expect(updated.accountName, 'Salary');
    expect(updated.last4, '4321');
  });

  testWidgets('last4 validation rejects incomplete last4 values', (
    tester,
  ) async {
    await pumpScreen(tester, const AddEditAccountScreen(initialType: 'bank'));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Bank name'),
      'ICICI',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Account nickname'),
      'Main',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Account last 4 digits (optional)'),
      '123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Starting balance'),
      '100',
    );
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Account'));
    await tester.pumpAndSettle();

    expect(find.text('Enter exactly 4 digits'), findsOneWidget);
    expect((await db.select(db.bankAccounts).get()), isEmpty);
  });
}
