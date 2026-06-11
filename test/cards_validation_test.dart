import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/core/database/database_providers.dart';
import 'package:finarc/features/cards/data/cards_providers.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('add card rejects invalid last4 digits', () async {
    final addCard = container.read(addCardProvider);

    expect(
      () => addCard(
        AddCardPayload(
          bankName: 'HDFC',
          nickname: 'Primary',
          last4: '12A4',
          network: CardNetwork.visa,
          billingDay: 10,
          dueDay: 22,
          creditLimit: 100000,
          currentOutstanding: 5000,
        ),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('add card rejects outstanding above credit limit', () async {
    final addCard = container.read(addCardProvider);

    expect(
      () => addCard(
        AddCardPayload(
          bankName: 'HDFC',
          nickname: 'Primary',
          last4: '1234',
          network: CardNetwork.visa,
          billingDay: 10,
          dueDay: 22,
          creditLimit: 10000,
          currentOutstanding: 12000,
        ),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('add card saves selected card network', () async {
    final addCard = container.read(addCardProvider);

    await addCard(
      AddCardPayload(
        bankName: 'HDFC',
        nickname: 'Primary',
        last4: '1234',
        network: CardNetwork.rupay,
        billingDay: 10,
        dueDay: 22,
        creditLimit: 10000,
        currentOutstanding: 1200,
      ),
    );

    final cards = await db.select(db.creditCards).get();
    expect(cards.single.network, CardNetwork.rupay);
  });

  test('add card saves amex network', () async {
    final addCard = container.read(addCardProvider);

    await addCard(
      AddCardPayload(
        bankName: 'AMEX',
        nickname: 'Gold',
        last4: '0005',
        network: CardNetwork.amex,
        billingDay: 15,
        dueDay: 5,
        creditLimit: 200000,
        currentOutstanding: 0,
      ),
    );

    final cards = await db.select(db.creditCards).get();
    expect(cards.single.network, CardNetwork.amex);
  });
}
