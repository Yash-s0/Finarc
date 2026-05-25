import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/features/alerts/data/alert_service.dart';
import 'package:finarc/features/alerts/data/alert_types.dart';

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
}
