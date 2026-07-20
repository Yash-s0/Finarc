import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/core/database/database_providers.dart';
import 'package:finarc/features/cards/data/cards_providers.dart';
import 'package:finarc/features/cards/presentation/add_card_screen.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpScreen(WidgetTester tester, AddCardScreen screen) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('editing a card preloads and saves card details', (tester) async {
    final cardId = await db
        .into(db.creditCards)
        .insert(
          CreditCardsCompanion.insert(
            bankName: 'HDFC',
            nickname: 'Primary',
            last4: '1111',
            maskedNumber: '**** **** **** 1111',
            network: const Value(CardNetwork.visa),
            creditLimit: 100000,
            billingDay: 10,
            dueDay: 25,
            currentOutstanding: const Value(5000),
          ),
        );

    await pumpScreen(tester, AddCardScreen(editId: cardId));

    expect(find.text('Edit Card'), findsOneWidget);
    expect(find.text('Primary'), findsOneWidget);
    expect(find.text('1111'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Bank name'),
      'ICICI',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Card nickname'),
      'Platinum',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Last 4 digits'),
      '4321',
    );
    await tester.scrollUntilVisible(
      find.text('Save Changes'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    final updated = await (db.select(
      db.creditCards,
    )..where((card) => card.id.equals(cardId))).getSingle();
    expect(updated.bankName, 'ICICI');
    expect(updated.nickname, 'Platinum');
    expect(updated.last4, '4321');
    expect(updated.maskedNumber, '**** **** **** 4321');
  });
}
