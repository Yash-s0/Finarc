import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/features/onboarding/data/onboarding_service.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('app starts without dummy data and app_settings exists', () async {
    await db.seedIfEmpty();

    final banks = await db.select(db.bankAccounts).get();
    final wallets = await db.select(db.cashWallets).get();
    final cards = await db.select(db.creditCards).get();
    final txns = await db.select(db.transactions).get();
    final loans = await db.select(db.loans).get();
    final settings = await db.select(db.appSettings).getSingleOrNull();

    expect(banks, isEmpty);
    expect(wallets, isEmpty);
    expect(cards, isEmpty);
    expect(txns, isEmpty);
    expect(loans, isEmpty);
    expect(settings, isNotNull);
    expect(settings!.hasCompletedOnboarding, false);
  });

  test('onboarding completion persists', () async {
    final service = OnboardingService(db);

    expect(await service.hasCompletedOnboarding(), false);

    await service.setCompleted(true);
    expect(await service.hasCompletedOnboarding(), true);

    await service.setCompleted(false);
    expect(await service.hasCompletedOnboarding(), false);
  });
}
