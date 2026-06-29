import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../parsing/parser_models.dart';
import '../parsing/pending_ingestion_service.dart';
import 'card_bill_due_notification_service.dart';
import 'notification_ingestion_service.dart';
import 'notification_burst_limiter.dart';
import 'notification_keyword_filter.dart';
import 'notification_local_notifier.dart';
import 'notification_payload.dart';
import 'sms_fingerprint.dart';
import 'sms_sender_filter.dart';

class SmsIngestionService {
  factory SmsIngestionService({
    required AppDatabase database,
    required PendingIngestionService pendingIngestionService,
    required NotificationKeywordFilter keywordFilter,
    required SmsFingerprint fingerprint,
    required NotificationLocalNotifier localNotifier,
    required bool Function() isSmsDetectionEnabled,
    required bool Function() isSmsPermissionGranted,
    required bool Function() shouldShowDetectionNotifications,
    required void Function(NotificationDebugEntry entry) appendDebug,
    required SmsSenderFilter senderFilter,
    CardBillDueNotificationService? cardBillDueNotificationService,
    NotificationBurstLimiter? burstLimiter,
  }) {
    return SmsIngestionService._(
      database: database,
      pendingIngestionService: pendingIngestionService,
      keywordFilter: keywordFilter,
      fingerprint: fingerprint,
      localNotifier: localNotifier,
      isSmsDetectionEnabled: isSmsDetectionEnabled,
      isSmsPermissionGranted: isSmsPermissionGranted,
      shouldShowDetectionNotifications: shouldShowDetectionNotifications,
      appendDebug: appendDebug,
      senderFilter: senderFilter,
      cardBillDueNotificationService:
          cardBillDueNotificationService ??
          CardBillDueNotificationService(database: database),
      burstLimiter: burstLimiter ?? NotificationBurstLimiter(),
    );
  }

  SmsIngestionService._({
    required AppDatabase database,
    required this._pendingIngestionService,
    required this._keywordFilter,
    required this._fingerprint,
    required this._localNotifier,
    required this._isSmsDetectionEnabled,
    required this._isSmsPermissionGranted,
    required this._shouldShowDetectionNotifications,
    required this._appendDebug,
    required this._senderFilter,
    required this._cardBillDueNotificationService,
    required this._burstLimiter,
  }) : _db = database;

  final AppDatabase _db;
  final PendingIngestionService _pendingIngestionService;
  final NotificationKeywordFilter _keywordFilter;
  final SmsFingerprint _fingerprint;
  final NotificationLocalNotifier _localNotifier;
  final bool Function() _isSmsDetectionEnabled;
  final bool Function() _isSmsPermissionGranted;
  final bool Function() _shouldShowDetectionNotifications;
  final void Function(NotificationDebugEntry entry) _appendDebug;
  final SmsSenderFilter _senderFilter;
  final CardBillDueNotificationService _cardBillDueNotificationService;
  final NotificationBurstLimiter _burstLimiter;

  Future<List<int>> processSmsPayload(
    NotificationPayload payload, {
    bool bypassSenderFilter = false,
  }) async {
    if (!_isSmsDetectionEnabled()) {
      _log(payload, 'blocked-sms-detection-disabled');
      return const [];
    }
    if (!_isSmsPermissionGranted()) {
      _log(payload, 'blocked-sms-permission-missing');
      return const [];
    }

    if (!bypassSenderFilter) {
      final senderResult = _senderFilter.evaluate(payload.sender);
      if (!senderResult.accepted) {
        _log(payload, senderResult.reason);
        return const [];
      }
      _log(payload, senderResult.reason);
    }

    final senderKey = payload.sender ?? payload.appName ?? payload.packageName;
    if (!_burstLimiter.isAllowed('sms:$senderKey', payload.receivedAt)) {
      _log(payload, 'rate-limited-notification-burst');
      return const [];
    }

    final filterResult = _keywordFilter.evaluate(payload);
    if (!filterResult.accepted) {
      _log(payload, 'blocked-non-transaction-text');
      return const [];
    }

    final billDueResult = await _cardBillDueNotificationService.handleIfBillDue(
      payload,
    );
    if (billDueResult != null) {
      _log(payload, 'card-bill-due-${billDueResult.action}');
      return const [];
    }

    final sender = payload.sender ?? payload.appName ?? 'SMS';
    final body = payload.combinedText;
    final fingerprint = _fingerprint.build(
      sender: sender,
      body: body,
      receivedAt: payload.receivedAt,
    );
    if (_fingerprint.isDuplicate(fingerprint, payload.receivedAt)) {
      _log(payload, 'duplicate-suppressed');
      return const [];
    }

    final parserInput = toParserInput(payload);
    final ids = await _pendingIngestionService.ingestParserInput(parserInput);
    if (ids.isEmpty) {
      _log(payload, 'parser-failed');
      return const [];
    }

    final pendingId = ids.first;
    final pending = await (_db.select(
      _db.pendingTransactions,
    )..where((p) => p.id.equals(pendingId))).getSingleOrNull();

    if (pending == null) {
      _log(payload, 'duplicate-suppressed');
      return const [];
    }
    if (await _hasSimilarPending(pending)) {
      await (_db.delete(
        _db.pendingTransactions,
      )..where((p) => p.id.equals(pendingId))).go();
      _log(payload, 'duplicate-suppressed');
      return const [];
    }

    if (_shouldShowDetectionNotifications()) {
      await _localNotifier.showDetected(
        title: '${_extractAmountText(body)} detected from SMS',
        body: 'Confirm this transaction in Finarc.',
        route: '/pending',
        pendingId: pendingId,
        showActions: true,
      );
    }

    _log(payload, 'parsed-pending-created');
    return ids;
  }

  ParserInput toParserInput(NotificationPayload payload) {
    return ParserInput(
      rawText: payload.combinedText,
      sourceType: 'sms',
      packageName: payload.packageName,
      sender: payload.sender ?? payload.appName,
      receivedAt: payload.captureTime,
      postTime: payload.postTime,
      notificationTitle: payload.title,
      notificationBody: payload.body,
    );
  }

  Future<bool> _hasSimilarPending(PendingTransaction pending) async {
    final rangeStart = pending.transactionDate.subtract(
      const Duration(minutes: 10),
    );
    final rangeEnd = pending.transactionDate.add(const Duration(minutes: 10));
    final rows =
        await (_db.select(_db.pendingTransactions)..where(
              (p) =>
                  p.id.isNotValue(pending.id) &
                  p.status.equals('pending') &
                  p.amount.equals(pending.amount) &
                  p.transactionDate.isBiggerOrEqualValue(rangeStart) &
                  p.transactionDate.isSmallerOrEqualValue(rangeEnd),
            ))
            .get();

    for (final row in rows) {
      if (_similarity(row.merchant, pending.merchant) >= 0.6) {
        return true;
      }
    }
    return false;
  }

  double _similarity(String a, String b) {
    final xa = a.toLowerCase().split(RegExp(r'\s+')).toSet();
    final xb = b.toLowerCase().split(RegExp(r'\s+')).toSet();
    if (xa.isEmpty || xb.isEmpty) return 0;
    return xa.intersection(xb).length / xa.union(xb).length;
  }

  String _extractAmountText(String raw) {
    final match = RegExp(
      r'(?:INR|Rs\.?|₹)\s*[0-9][0-9,]*(?:\.[0-9]{1,2})?',
      caseSensitive: false,
    ).firstMatch(raw);
    if (match == null) return 'Amount';
    return (match.group(0) ?? 'Amount')
        .replaceAll('Rs.', '₹')
        .replaceAll('INR', '₹')
        .trim();
  }

  void _log(NotificationPayload payload, String result) {
    final sender = (payload.sender ?? payload.appName ?? 'sms').trim();
    final decision = switch (result) {
      'duplicate-suppressed' => 'duplicate',
      'parsed-pending-created' => 'pending-created',
      'parser-failed' => 'parsed',
      'rate-limited-notification-burst' => 'ignored',
      _ => result.startsWith('blocked') ? 'ignored' : 'parsed',
    };
    final preview = payload.combinedText.length > 120
        ? '${payload.combinedText.substring(0, 120)}...'
        : payload.combinedText;
    _appendDebug(
      NotificationDebugEntry(
        receivedAt: payload.receivedAt,
        packageName: sender.isEmpty ? 'sms' : sender,
        title: sender.isEmpty ? 'SMS' : sender,
        bodyPreview: preview,
        decision: decision,
        reason: result,
        sourceType: 'sms',
        result: result,
        parseResult: result,
        localNotificationSent: result == 'parsed-pending-created',
      ),
    );
  }
}
