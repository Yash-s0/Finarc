import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/core/database/database_providers.dart';
import 'package:finarc/features/alerts/data/alert_service.dart';
import 'package:finarc/features/alerts/data/alert_types.dart';
import 'package:finarc/features/alerts/data/alerts_providers.dart';
import 'package:finarc/features/dashboard/data/dashboard_providers.dart';
import 'package:finarc/features/pending/data/pending_providers.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late AlertService alerts;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    alerts = AlertService(db);
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> createAlert({
    String type = AlertType.cardDue,
    AlertPriority priority = AlertPriority.warning,
    String title = 'Card bill due',
    String body = 'Due today',
    String dedupeKey = 'alert-key',
  }) async {
    await alerts.createAlert(
      CreateAlertInput(
        alertType: type,
        title: title,
        body: body,
        priority: priority,
        actionRoute: '/alerts',
        dedupeKey: dedupeKey,
      ),
    );
    container.invalidate(alertsInboxProvider);
    container.invalidate(alertsUnreadCountProvider);
    container.invalidate(latestImportantAlertProvider);
  }

  test(
    'dashboard unread count follows alert read dismiss and mark-all actions',
    () async {
      await db.seedIfEmpty();
      expect(
        (await container.read(dashboardProvider.future)).unreadAlertsCount,
        0,
      );

      await createAlert();
      var snapshot = await container.read(dashboardProvider.future);
      expect(snapshot.unreadAlertsCount, 1);
      expect(snapshot.latestImportantAlert?.title, 'Card bill due');

      final first = (await alerts.getAlerts()).single;
      await container.read(alertActionsProvider).markRead(first.id);
      snapshot = await container.read(dashboardProvider.future);
      expect(snapshot.unreadAlertsCount, 0);
      expect(snapshot.latestImportantAlert?.title, 'Card bill due');

      await container.read(alertActionsProvider).dismiss(first.id);
      snapshot = await container.read(dashboardProvider.future);
      expect(snapshot.unreadAlertsCount, 0);
      expect(snapshot.latestImportantAlert, isNull);

      await createAlert(dedupeKey: 'alert-key-2');
      await createAlert(
        type: AlertType.emiDue,
        title: 'EMI due soon',
        body: 'Due tomorrow',
        dedupeKey: 'alert-key-3',
      );
      snapshot = await container.read(dashboardProvider.future);
      expect(snapshot.unreadAlertsCount, 2);

      await container.read(alertActionsProvider).markAllRead();
      snapshot = await container.read(dashboardProvider.future);
      expect(snapshot.unreadAlertsCount, 0);
    },
  );

  test(
    'pending resolution refreshes alerts and dashboard after restart',
    () async {
      await db.seedIfEmpty();
      final pendingId = await db
          .into(db.pendingTransactions)
          .insert(
            PendingTransactionsCompanion.insert(
              amount: 450,
              merchant: 'Zepto',
              categorySuggestion: 'Shopping',
              paymentSourceTypeSuggestion: 'bank',
              detectedAt: DateTime(2026, 8, 26, 10, 40),
              transactionDate: DateTime(2026, 8, 26, 10, 40),
              sourceType: 'appNotification',
              rawText: 'Your payment of ₹450 to Zepto was successful',
              confidenceScore: 0.96,
            ),
          );

      await container
          .read(alertEvaluationActionsProvider)
          .onPendingDetected(
            pendingId: pendingId,
            title: 'Transaction detected',
            body: 'Confirm this transaction in Finarc.',
          );
      var snapshot = await container.read(dashboardProvider.future);
      expect(snapshot.unreadAlertsCount, 1);

      await container.read(pendingActionProvider).ignore(pendingId);
      snapshot = await container.read(dashboardProvider.future);
      expect(snapshot.unreadAlertsCount, 0);
      expect(await alerts.getAlerts(), isEmpty);

      container.dispose();
      container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      snapshot = await container.read(dashboardProvider.future);
      expect(snapshot.unreadAlertsCount, 0);
      final history = await alerts.getAlerts(
        query: const AlertQuery(includeDismissed: true),
      );
      expect(history.single.dismissedAt, isNot(null));
    },
  );
}
