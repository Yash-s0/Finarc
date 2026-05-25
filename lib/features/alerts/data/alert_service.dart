import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import 'alert_types.dart';

class CreateAlertInput {
  const CreateAlertInput({
    required this.alertType,
    required this.title,
    required this.body,
    required this.priority,
    this.createdAt,
    this.scheduledAt,
    this.actionRoute,
    this.payload,
    this.dedupeKey,
  });

  final String alertType;
  final String title;
  final String body;
  final AlertPriority priority;
  final DateTime? createdAt;
  final DateTime? scheduledAt;
  final String? actionRoute;
  final Map<String, dynamic>? payload;
  final String? dedupeKey;
}

class AlertQuery {
  const AlertQuery({
    this.onlyUnread = false,
    this.includeDismissed = false,
    this.alertType,
  });

  final bool onlyUnread;
  final bool includeDismissed;
  final String? alertType;
}

class AlertService {
  const AlertService(this._db);

  final AppDatabase _db;

  Future<Alert?> createAlert(
    CreateAlertInput input, {
    Duration dedupeWindow = const Duration(hours: 6),
  }) async {
    final now = input.createdAt ?? DateTime.now();
    final key = input.dedupeKey ??
        '${input.alertType}|${input.title.toLowerCase()}|${input.body.toLowerCase()}';

    final dupCutoff = now.subtract(dedupeWindow);
    final existing = await (_db.select(_db.alerts)
          ..where(
            (a) =>
                a.dedupeKey.equals(key) &
                a.createdAt.isBiggerOrEqualValue(dupCutoff) &
                a.dismissedAt.isNull(),
          )
          ..orderBy([(a) => OrderingTerm.desc(a.createdAt)])
          ..limit(1))
        .getSingleOrNull();
    if (existing != null) return null;

    final id = await _db.into(_db.alerts).insert(
          AlertsCompanion.insert(
            alertType: input.alertType,
            title: input.title,
            body: input.body,
            createdAt: Value(now),
            scheduledAt: Value(input.scheduledAt),
            priority: Value(alertPriorityLabel(input.priority)),
            actionRoute: Value(input.actionRoute),
            payload: Value(
              input.payload == null ? null : jsonEncode(input.payload),
            ),
            dedupeKey: Value(key),
          ),
        );

    return (_db.select(_db.alerts)..where((a) => a.id.equals(id))).getSingle();
  }

  Future<List<Alert>> getAlerts({AlertQuery query = const AlertQuery()}) {
    final stmt = _db.select(_db.alerts)
      ..orderBy([(a) => OrderingTerm.desc(a.createdAt)]);

    if (!query.includeDismissed) {
      stmt.where((a) => a.dismissedAt.isNull());
    }
    if (query.onlyUnread) {
      stmt.where((a) => a.readAt.isNull());
    }
    if (query.alertType != null && query.alertType!.isNotEmpty) {
      stmt.where((a) => a.alertType.equals(query.alertType!));
    }

    return stmt.get();
  }

  Future<int> unreadCount() async {
    final row = await (_db.selectOnly(_db.alerts)
          ..addColumns([_db.alerts.id.count()])
          ..where(_db.alerts.readAt.isNull() & _db.alerts.dismissedAt.isNull()))
        .getSingle();
    return row.read(_db.alerts.id.count()) ?? 0;
  }

  Future<Alert?> latestImportantAlert() async {
    return (_db.select(_db.alerts)
          ..where(
            (a) =>
                a.dismissedAt.isNull() &
                (a.priority.equals('critical') | a.priority.equals('warning')),
          )
          ..orderBy([(a) => OrderingTerm.desc(a.createdAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> markRead(int id) async {
    await (_db.update(_db.alerts)..where((a) => a.id.equals(id))).write(
      AlertsCompanion(readAt: Value(DateTime.now())),
    );
  }

  Future<void> dismiss(int id) async {
    await (_db.update(_db.alerts)..where((a) => a.id.equals(id))).write(
      AlertsCompanion(dismissedAt: Value(DateTime.now())),
    );
  }

  Future<void> clearAllRead() async {
    await (_db.delete(_db.alerts)..where((a) => a.readAt.isNotNull())).go();
  }

  Future<void> markAllRead() async {
    final now = DateTime.now();
    await (_db.update(_db.alerts)..where((a) => a.readAt.isNull())).write(
      AlertsCompanion(readAt: Value(now)),
    );
  }

  Future<Map<String, dynamic>?> parsePayload(Alert alert) async {
    if (alert.payload == null || alert.payload!.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(alert.payload!);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry('$key', value));
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
