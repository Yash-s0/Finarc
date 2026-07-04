import '../../../core/logging/app_log_service.dart';

class NotificationDiagnosticsEvent {
  const NotificationDiagnosticsEvent({
    required this.timestamp,
    required this.packageName,
    required this.title,
    required this.bodyPreview,
    required this.decision,
    required this.reason,
    required this.parseResult,
    this.providerName,
    this.confidenceScore,
    this.confidenceLevel,
    this.localNotificationSent = false,
    this.sender,
    this.senderFilterResult,
    this.candidateCount,
    this.duplicateDecision,
    this.possibleDuplicateReason,
    this.amountCandidate,
    this.blockedContext,
    this.receivedAtUsed,
    this.transactionDateChosen,
  });

  final DateTime timestamp;
  final String packageName;
  final String title;
  final String bodyPreview;
  final String decision;
  final String reason;
  final String parseResult;
  final String? providerName;
  final double? confidenceScore;
  final String? confidenceLevel;
  final bool localNotificationSent;
  final String? sender;
  final String? senderFilterResult;
  final int? candidateCount;
  final String? duplicateDecision;
  final String? possibleDuplicateReason;
  final String? amountCandidate;
  final String? blockedContext;
  final DateTime? receivedAtUsed;
  final DateTime? transactionDateChosen;
}

class NotificationDiagnosticsSnapshot {
  const NotificationDiagnosticsSnapshot({
    required this.received,
    required this.ignored,
    required this.parsed,
    required this.pendingCreated,
    required this.duplicatesBlocked,
    required this.localNotificationsSent,
    required this.events,
  });

  final int received;
  final int ignored;
  final int parsed;
  final int pendingCreated;
  final int duplicatesBlocked;
  final int localNotificationsSent;
  final List<NotificationDiagnosticsEvent> events;

  NotificationDiagnosticsEvent? get lastEvent =>
      events.isEmpty ? null : events.first;

  static const empty = NotificationDiagnosticsSnapshot(
    received: 0,
    ignored: 0,
    parsed: 0,
    pendingCreated: 0,
    duplicatesBlocked: 0,
    localNotificationsSent: 0,
    events: <NotificationDiagnosticsEvent>[],
  );
}

class NotificationDiagnosticsService {
  const NotificationDiagnosticsService(this._logs);

  final AppLogService _logs;

  Future<NotificationDiagnosticsSnapshot> loadSnapshot() async {
    final all = await _logs.readFromDisk();
    final events = all
        .where((row) => row.category == 'notification_event')
        .map(_toEvent)
        .whereType<NotificationDiagnosticsEvent>()
        .take(100)
        .toList(growable: false);
    if (events.isEmpty) return NotificationDiagnosticsSnapshot.empty;

    var ignored = 0;
    var parsed = 0;
    var pendingCreated = 0;
    var duplicates = 0;
    var localNotificationsSent = 0;

    for (final event in events) {
      switch (event.decision) {
        case 'ignored':
          ignored += 1;
          break;
        case 'parsed':
          parsed += 1;
          break;
        case 'pending-created':
          pendingCreated += 1;
          parsed += 1;
          break;
        case 'duplicate':
          duplicates += 1;
          break;
      }
      if (event.localNotificationSent) {
        localNotificationsSent += 1;
      }
    }

    return NotificationDiagnosticsSnapshot(
      received: events.length,
      ignored: ignored,
      parsed: parsed,
      pendingCreated: pendingCreated,
      duplicatesBlocked: duplicates,
      localNotificationsSent: localNotificationsSent,
      events: events,
    );
  }

  Future<void> clear() async {
    await _logs.clearWhere((entry) => entry.category == 'notification_event');
  }

  NotificationDiagnosticsEvent? _toEvent(AppLogEntry row) {
    final parseResult = (row.meta['parseResult'] as String?) ?? row.message;
    final packageName = (row.meta['package'] as String?) ?? '';
    if (packageName.isEmpty) return null;

    return NotificationDiagnosticsEvent(
      timestamp: _parseTimestamp(
        row.meta['receivedAt'] as String?,
        fallback: row.timestamp,
      ),
      packageName: packageName,
      title: (row.meta['title'] as String?) ?? '—',
      bodyPreview: (row.meta['bodyPreview'] as String?) ?? '',
      decision: (row.meta['decision'] as String?) ?? row.message,
      reason: (row.meta['reason'] as String?) ?? '',
      parseResult: parseResult,
      providerName: row.meta['providerName'] as String?,
      confidenceScore: _toDouble(row.meta['confidenceScore']),
      confidenceLevel: row.meta['confidenceLevel'] as String?,
      localNotificationSent: row.meta['localNotificationSent'] == true,
      sender: row.meta['sender'] as String?,
      senderFilterResult: row.meta['senderFilterResult'] as String?,
      candidateCount: _toInt(row.meta['candidateCount']),
      duplicateDecision: row.meta['duplicateDecision'] as String?,
      possibleDuplicateReason: row.meta['possibleDuplicateReason'] as String?,
      amountCandidate: row.meta['amountCandidate'] as String?,
      blockedContext: row.meta['blockedContext'] as String?,
      receivedAtUsed: _parseTimestamp(
        row.meta['receivedAtUsed'] as String?,
        fallback: _parseTimestamp(
          row.meta['receivedAt'] as String?,
          fallback: row.timestamp,
        ),
      ),
      transactionDateChosen: _parseTimestamp(
        row.meta['transactionDateChosen'] as String?,
        fallback: _parseTimestamp(
          row.meta['receivedAt'] as String?,
          fallback: row.timestamp,
        ),
      ),
    );
  }

  DateTime _parseTimestamp(String? value, {required DateTime fallback}) {
    if (value == null || value.trim().isEmpty) return fallback;
    return DateTime.tryParse(value) ?? fallback;
  }

  double? _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  int? _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
