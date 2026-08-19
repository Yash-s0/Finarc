import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/core/database/database_providers.dart';
import 'package:finarc/features/expenses/models/transaction_types.dart';
import 'package:finarc/features/recoverables/presentation/recoverable_person_detail_screen.dart';
import 'package:finarc/shared/widgets/finarc/finarc_contained_list.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('person transaction list scrolls inside the transaction card', (
    tester,
  ) async {
    final cardId = await db
        .into(db.creditCards)
        .insert(
          CreditCardsCompanion.insert(
            bankName: 'ICICI',
            nickname: 'Amazon Pay',
            last4: '9000',
            maskedNumber: '**** **** **** 9000',
            creditLimit: 60000,
            billingDay: DateTime.now().day > 1 ? DateTime.now().day - 1 : 1,
            dueDay: 7,
          ),
        );

    for (var i = 0; i < 12; i += 1) {
      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              type: TransactionType.creditCard,
              amount: 100 + i.toDouble(),
              title: 'Txn ${i + 1}',
              category: 'Shopping',
              transactionDate: DateTime(2026, 8, 1 + i),
              paymentSourceType: PaymentSourceType.creditCard,
              paymentSourceId: cardId,
              isForOthers: const Value(true),
              recoverablePartyName: const Value('Papa'),
              recoverableBaseAmount: Value(100 + i.toDouble()),
              recoverableAmount: Value(100 + i.toDouble()),
              recoveredAmount: const Value(0),
              recoverableStatus: const Value('unpaid'),
            ),
          );
    }

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          seedProvider.overrideWith((ref) async {}),
        ],
        child: const MaterialApp(
          home: RecoverablePersonDetailScreen(partyName: 'Papa'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Txn 1'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Txn 1'),
      240,
      scrollable: find.descendant(
        of: find.byType(FinarcContainedList),
        matching: find.byType(Scrollable),
      ),
    );

    expect(find.text('Txn 1'), findsOneWidget);
  });
}
