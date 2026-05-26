import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../expenses/models/transaction_types.dart';
import '../parsing/parser_models.dart';
import '../parsing/pending_ingestion_service.dart';
import 'notification_fingerprint.dart';
import 'notification_keyword_filter.dart';
import 'notification_local_notifier.dart';
import 'notification_payload.dart';

class NotificationDebugEntry {
  const NotificationDebugEntry({
    required this.receivedAt,
    required this.packageName,
    required this.preview,
    required this.result,
  });

  final DateTime receivedAt;
  final String packageName;
  final String preview;
  final String result;
}

class NotificationIngestionService {
  NotificationIngestionService({
    required this.database,
    required this.pendingIngestionService,
    required this.keywordFilter,
    required this.fingerprint,
    required this.localNotifier,
    required this.isDetectionEnabled,
    required this.shouldShowDetectionNotifications,
    required this.appendDebug,
  });

  final AppDatabase database;
  final PendingIngestionService pendingIngestionService;
  final NotificationKeywordFilter keywordFilter;
  final NotificationFingerprint fingerprint;
  final NotificationLocalNotifier localNotifier;
  final bool Function() isDetectionEnabled;
  final bool Function() shouldShowDetectionNotifications;
  final void Function(NotificationDebugEntry entry) appendDebug;

  Future<List<int>> processPayload(NotificationPayload payload) async {
    if (!isDetectionEnabled()) {
      _log(payload, 'ignored-disabled');
      return const [];
    }

    final filterResult = keywordFilter.evaluate(payload);
    if (!filterResult.accepted) {
      _log(payload, filterResult.reason);
      return const [];
    }

    final parserInput = ParserInput(
      rawText: payload.combinedText,
      sourceType: payload.sourceType.isEmpty
          ? 'appNotification'
          : payload.sourceType,
      packageName: payload.packageName,
      sender: payload.sender ?? payload.appName,
      receivedAt: payload.receivedAt,
      notificationTitle: payload.title,
      notificationBody: payload.body,
    );

    final fingerprintValue = fingerprint.build(payload: payload);
    if (fingerprint.isDuplicate(fingerprintValue, payload.receivedAt)) {
      _log(payload, 'duplicate-suppressed');
      return const [];
    }

    final ids = await pendingIngestionService.ingestParserInput(parserInput);
    if (ids.isEmpty) {
      _log(payload, 'parser-failed');
      return const [];
    }

    final pendingId = ids.first;
    final pending = await (database.select(
      database.pendingTransactions,
    )..where((p) => p.id.equals(pendingId))).getSingleOrNull();
    if (pending == null || await _hasSimilarPending(pending)) {
      _log(payload, 'duplicate-suppressed');
      return const [];
    }

    if (shouldShowDetectionNotifications()) {
      final previewAmount = _extractAmountText(payload.combinedText);
      final previewMerchant = _extractMerchantPreview(payload);
      await localNotifier.showDetected(
        title: '$previewAmount detected at $previewMerchant',
        body: 'Confirm this transaction in Finarc.',
        route: '/pending',
        pendingId: ids.isEmpty ? null : ids.first,
        showActions: true,
      );
    }

    _log(payload, 'parsed-pending-created');
    return ids;
  }

  Future<bool> _hasSimilarPending(PendingTransaction pending) async {
    final start = pending.transactionDate.subtract(const Duration(hours: 24));
    final end = pending.transactionDate.add(const Duration(hours: 24));
    final rows =
        await (database.select(database.pendingTransactions)..where(
              (p) =>
                  p.id.isNotValue(pending.id) &
                  p.status.equals('pending') &
                  p.amount.equals(pending.amount) &
                  p.transactionDate.isBiggerOrEqualValue(start) &
                  p.transactionDate.isSmallerOrEqualValue(end),
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

  void _log(NotificationPayload payload, String result) {
    appendDebug(
      NotificationDebugEntry(
        receivedAt: payload.receivedAt,
        packageName: payload.packageName,
        preview: payload.combinedText.length > 80
            ? '${payload.combinedText.substring(0, 80)}...'
            : payload.combinedText,
        result: result,
      ),
    );
  }

  String _extractAmountText(String raw) {
    final match = RegExp(
      r'(?:INR|Rs\.?|₹)\s*[0-9][0-9,]*(?:\.[0-9]{1,2})?',
      caseSensitive: false,
    ).firstMatch(raw);
    if (match == null) return 'Amount';
    final text = match.group(0) ?? 'Amount';
    return text.replaceAll('Rs.', '₹').replaceAll('INR', '₹').trim();
  }

  String _extractMerchantPreview(NotificationPayload payload) {
    final base = payload.title?.trim();
    if (base != null && base.isNotEmpty) return base;
    final text = payload.body?.trim();
    if (text != null && text.isNotEmpty) {
      final maybe = text.split(RegExp(r'\s+')).take(3).join(' ');
      return maybe;
    }
    return payload.appName ?? PaymentSourceType.bank;
  }
}
