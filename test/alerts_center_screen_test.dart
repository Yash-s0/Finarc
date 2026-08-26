import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/core/database/database_providers.dart';
import 'package:finarc/core/theme/app_theme.dart';
import 'package:finarc/features/alerts/data/alert_service.dart';
import 'package:finarc/features/alerts/data/alert_types.dart';
import 'package:finarc/features/alerts/presentation/alerts_center_screen.dart';

void main() {
  late AppDatabase db;
  late AlertService alertService;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    alertService = AlertService(db);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('type filter sheet shows readable labels, not alert keys', (
    tester,
  ) async {
    await alertService.createAlert(
      const CreateAlertInput(
        alertType: AlertType.cardDue,
        title: 'Card bill due soon',
        body: '₹1,200.00 due today.',
        priority: AlertPriority.warning,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const AlertsCenterScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('All types'));
    await tester.pumpAndSettle();

    expect(find.text('Card bills'), findsOneWidget);
    expect(find.text('Pending transactions'), findsOneWidget);
    expect(find.text('cardDue'), findsNothing);
    expect(find.text('pendingTransaction'), findsNothing);
  });
}
