import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../cards/data/cards_providers.dart';
import '../../loans/data/loans_providers.dart';
import '../../pending/notifications/notification_providers.dart';
import '../../split/data/split_providers.dart';
import 'alert_engine.dart';
import 'alert_service.dart';

final alertServiceProvider = Provider<AlertService>((ref) {
  return AlertService(ref.read(appDatabaseProvider));
});

final alertEngineProvider = Provider<AlertEngine>((ref) {
  return AlertEngine(
    database: ref.read(appDatabaseProvider),
    alertService: ref.read(alertServiceProvider),
    notifier: ref.read(notificationLocalNotifierProvider),
    billingService: ref.read(billingServiceProvider),
    loanService: ref.read(loanServiceProvider),
    splitService: ref.read(splitServiceProvider),
  );
});

final alertsOnlyUnreadProvider = StateProvider<bool>((ref) => false);
final alertsIncludeDismissedProvider = StateProvider<bool>((ref) => false);
final alertsTypeFilterProvider = StateProvider<String?>((ref) => null);

final alertsInboxProvider = FutureProvider<List<Alert>>((ref) async {
  await ref.watch(seedProvider.future);
  final onlyUnread = ref.watch(alertsOnlyUnreadProvider);
  final includeDismissed = ref.watch(alertsIncludeDismissedProvider);
  final type = ref.watch(alertsTypeFilterProvider);

  return ref.read(alertServiceProvider).getAlerts(
    query: AlertQuery(
      onlyUnread: onlyUnread,
      includeDismissed: includeDismissed,
      alertType: type,
    ),
  );
});

final alertsUnreadCountProvider = FutureProvider<int>((ref) async {
  await ref.watch(seedProvider.future);
  return ref.read(alertServiceProvider).unreadCount();
});

final latestImportantAlertProvider = FutureProvider<Alert?>((ref) async {
  await ref.watch(seedProvider.future);
  return ref.read(alertServiceProvider).latestImportantAlert();
});

final alertActionsProvider = Provider((ref) {
  Future<void> markRead(int id) async {
    await ref.read(alertServiceProvider).markRead(id);
    ref.invalidate(alertsInboxProvider);
    ref.invalidate(alertsUnreadCountProvider);
    ref.invalidate(latestImportantAlertProvider);
  }

  Future<void> dismiss(int id) async {
    await ref.read(alertServiceProvider).dismiss(id);
    ref.invalidate(alertsInboxProvider);
    ref.invalidate(alertsUnreadCountProvider);
    ref.invalidate(latestImportantAlertProvider);
  }

  Future<void> clearRead() async {
    await ref.read(alertServiceProvider).clearAllRead();
    ref.invalidate(alertsInboxProvider);
    ref.invalidate(alertsUnreadCountProvider);
    ref.invalidate(latestImportantAlertProvider);
  }

  Future<void> markAllRead() async {
    await ref.read(alertServiceProvider).markAllRead();
    ref.invalidate(alertsInboxProvider);
    ref.invalidate(alertsUnreadCountProvider);
    ref.invalidate(latestImportantAlertProvider);
  }

  return (
    markRead: markRead,
    dismiss: dismiss,
    clearRead: clearRead,
    markAllRead: markAllRead,
  );
});

final alertEvaluationActionsProvider = Provider((ref) {
  Future<void> evaluateAll() async {
    final engine = ref.read(alertEngineProvider);
    await engine.evaluateDueAlerts();
    await engine.evaluateSplitAlerts();
    await engine.evaluateSummaryAlerts();
    ref.invalidate(alertsInboxProvider);
    ref.invalidate(alertsUnreadCountProvider);
    ref.invalidate(latestImportantAlertProvider);
  }

  Future<void> evaluateAfterTransaction(Transaction transaction) async {
    await ref.read(alertEngineProvider).evaluateAfterTransaction(transaction);
    ref.invalidate(alertsInboxProvider);
    ref.invalidate(alertsUnreadCountProvider);
    ref.invalidate(latestImportantAlertProvider);
  }

  Future<void> onPendingDetected({
    required int pendingId,
    required String title,
    required String body,
  }) async {
    await ref.read(alertEngineProvider).onPendingDetected(
      pendingId: pendingId,
      title: title,
      body: body,
    );
    ref.invalidate(alertsInboxProvider);
    ref.invalidate(alertsUnreadCountProvider);
    ref.invalidate(latestImportantAlertProvider);
  }

  return (
    evaluateAll: evaluateAll,
    evaluateAfterTransaction: evaluateAfterTransaction,
    onPendingDetected: onPendingDetected,
  );
});
