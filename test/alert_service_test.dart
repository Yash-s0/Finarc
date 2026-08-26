import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/features/alerts/data/alert_service.dart';
import 'package:finarc/features/alerts/data/alert_types.dart';
import 'package:finarc/features/expenses/data/transaction_engine.dart';
import 'package:finarc/features/pending/data/pending_service.dart';

void main() {
  late AppDatabase db;
  late AlertService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = AlertService(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('alert persistence read state and filtering', () async {
    final alert = await service.createAlert(
      const CreateAlertInput(
        alertType: AlertType.info,
        title: 'Hello',
        body: 'World',
        priority: AlertPriority.info,
      ),
    );
    expect(alert, isNotNull);

    var unread = await service.unreadCount();
    expect(unread, 1);

    await service.markRead(alert!.id);
    unread = await service.unreadCount();
    expect(unread, 0);

    final unreadList = await service.getAlerts(
      query: const AlertQuery(onlyUnread: true),
    );
    expect(unreadList, isEmpty);

    await service.dismiss(alert.id);
    final active = await service.getAlerts();
    expect(active, isEmpty);

    final withDismissed = await service.getAlerts(
      query: const AlertQuery(includeDismissed: true),
    );
    expect(withDismissed.length, 1);
    expect(withDismissed.single.readAt, isNotNull);
    expect(withDismissed.single.dismissedAt, isNotNull);
  });

  test('alert dedupe blocks duplicates in window', () async {
    final first = await service.createAlert(
      const CreateAlertInput(
        alertType: AlertType.largeExpense,
        title: 'Large expense',
        body: '₹12,000 at Amazon',
        priority: AlertPriority.warning,
        dedupeKey: 'large_1',
      ),
    );
    final second = await service.createAlert(
      const CreateAlertInput(
        alertType: AlertType.largeExpense,
        title: 'Large expense',
        body: '₹12,000 at Amazon',
        priority: AlertPriority.warning,
        dedupeKey: 'large_1',
      ),
    );

    expect(first, isNotNull);
    expect(second, isNull);
  });

  test('alert type display labels never expose internal values', () {
    expect(
      AlertType.all.map(AlertTypeDisplay.label),
      containsAll(<String>[
        'Pending transactions',
        'Card bills',
        'EMI reminders',
        'Split settlements',
        'Low balance',
        'Unusual spending',
        'Recurring payments',
        'Large expenses',
        'Weekly summary',
        'Monthly summary',
        'Reminders',
        'Information',
      ]),
    );
    expect(
      AlertType.all.map(AlertTypeDisplay.label),
      isNot(contains('pendingTransaction')),
    );
  });

  test(
    'resolved pending transaction dismisses matching actionable alert',
    () async {
      final pendingService = PendingService(db, TransactionEngine(db));
      final pendingId = await pendingService.createPendingTransaction(
        amount: 450,
        merchant: 'Zepto',
        categorySuggestion: 'Shopping',
        paymentSourceTypeSuggestion: 'bank',
        transactionDate: DateTime(2026, 8, 26, 10, 40),
        sourceType: 'appNotification',
        rawText: 'Your payment of ₹450 to Zepto was successful',
        confidenceScore: 0.96,
      );
      await service.createAlert(
        CreateAlertInput(
          alertType: AlertType.pendingTransaction,
          title: 'Transaction detected',
          body: '₹450.00 paid to Zepto',
          priority: AlertPriority.info,
          actionRoute: '/pending?openPendingId=$pendingId',
          payload: {'pendingId': pendingId},
          dedupeKey: 'pending_detected_$pendingId',
        ),
      );

      await pendingService.ignorePendingTransaction(pendingId);

      final active = await service.getAlerts();
      expect(active, isEmpty);
      final dismissed = await service.getAlerts(
        query: const AlertQuery(includeDismissed: true),
      );
      expect(dismissed.single.readAt, isNotNull);
      expect(dismissed.single.dismissedAt, isNotNull);
    },
  );
}
