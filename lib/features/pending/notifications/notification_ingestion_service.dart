import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../expenses/models/transaction_types.dart';
import '../parsing/confidence_level.dart';
import '../parsing/parser_models.dart';
import '../parsing/parser_confidence_scorer.dart';
import '../parsing/pending_ingestion_service.dart';
import 'notification_fingerprint.dart';
import 'notification_keyword_filter.dart';
import 'notification_local_notifier.dart';
import 'notification_payload.dart';

class NotificationDebugEntry {
  const NotificationDebugEntry({
    required this.receivedAt,
    required this.packageName,
    required this.title,
    required this.bodyPreview,
    required this.decision,
    required this.reason,
    this.result = '',
    this.sourceType = 'appNotification',
    this.providerName,
    this.parseResult,
    this.confidenceScore,
    this.confidenceLevel,
    this.localNotificationSent = false,
    this.sender,
    this.senderFilterResult,
    this.candidateCount,
    this.duplicateDecision,
    this.amountCandidate,
    this.blockedContext,
  });

  final DateTime receivedAt;
  final String packageName;
  final String title;
  final String bodyPreview;
  final String decision;
  final String reason;
  final String sourceType;
  final String? providerName;
  final String? parseResult;
  final double? confidenceScore;
  final String? confidenceLevel;
  final bool localNotificationSent;
  final String result;
  final String? sender;
  final String? senderFilterResult;
  final int? candidateCount;
  final String? duplicateDecision;
  final String? amountCandidate;
  final String? blockedContext;
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
      _log(
        payload,
        decision: 'ignored',
        reason: 'detection-disabled',
        parseResult: 'ignored-disabled',
      );
      return const [];
    }

    final filterResult = keywordFilter.evaluate(payload);
    if (!filterResult.accepted) {
      _log(
        payload,
        decision: 'ignored',
        reason: filterResult.reason,
        parseResult: filterResult.reason,
        providerName: filterResult.providerName,
        senderFilterResult: filterResult.senderFilterResult,
        amountCandidate: filterResult.amountCandidate,
        blockedContext: filterResult.blockedContext,
      );
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

    final parserResult = pendingIngestionService.previewParserInput(
      parserInput,
    );
    final candidateCount = parserResult.candidates.length;
    if (candidateCount == 0) {
      _log(
        payload,
        decision: 'parsed',
        reason: 'parser-no-candidate',
        parseResult: 'parser-failed',
        providerName: filterResult.providerName,
        senderFilterResult: filterResult.senderFilterResult,
        candidateCount: candidateCount,
      );
      return const [];
    }

    final fingerprintValue = fingerprint.build(payload: payload);
    if (fingerprint.isDuplicate(fingerprintValue, payload.receivedAt)) {
      _log(
        payload,
        decision: 'duplicate',
        reason: 'duplicate-same-notification',
        parseResult: 'duplicate-suppressed',
        providerName: filterResult.providerName,
        senderFilterResult: filterResult.senderFilterResult,
        candidateCount: candidateCount,
        duplicateDecision: 'package-title-body-fingerprint',
      );
      return const [];
    }

    final duplicateByReference = await _allCandidatesReferenceDuplicate(
      parserResult.candidates,
    );
    if (duplicateByReference) {
      _log(
        payload,
        decision: 'duplicate',
        reason: 'duplicate-ref',
        parseResult: 'duplicate-suppressed',
        providerName: filterResult.providerName,
        senderFilterResult: filterResult.senderFilterResult,
        candidateCount: candidateCount,
        duplicateDecision: 'ref-plus-amount',
      );
      return const [];
    }

    final bestCandidate = parserResult.candidates.isEmpty
        ? null
        : parserResult.candidates.first;
    final parsedConfidenceLevel =
        bestCandidate?.confidenceLevel ??
        (bestCandidate == null
            ? null
            : ParserConfidenceScorer.confidenceLevelFromScore(
                bestCandidate.confidenceScore,
              ).label);

    if (bestCandidate != null &&
        parsedConfidenceLevel == ConfidenceLevel.low.label) {
      _log(
        payload,
        decision: 'parsed',
        reason: 'confidence-low',
        parseResult: 'parsed-low-confidence',
        confidenceScore: bestCandidate.confidenceScore,
        confidenceLevel: parsedConfidenceLevel,
        providerName: filterResult.providerName,
        senderFilterResult: filterResult.senderFilterResult,
        candidateCount: candidateCount,
      );
      return const [];
    }

    final ids = await pendingIngestionService.ingestParserInput(parserInput);
    if (ids.isEmpty) {
      final duplicateBySignature = await _hasSenderAmountRecipientDuplicate(
        parserResult.candidates,
      );
      _log(
        payload,
        decision: duplicateBySignature ? 'duplicate' : 'parsed',
        reason: duplicateBySignature
            ? 'duplicate-sender-amount-recipient'
            : 'parser-no-candidate',
        parseResult: duplicateBySignature
            ? 'duplicate-suppressed'
            : 'parser-failed',
        providerName: filterResult.providerName,
        senderFilterResult: filterResult.senderFilterResult,
        candidateCount: candidateCount,
        duplicateDecision: duplicateBySignature
            ? 'sender-amount-date-recipient'
            : null,
      );
      return const [];
    }

    final pendingId = ids.first;
    final pending = await (database.select(
      database.pendingTransactions,
    )..where((p) => p.id.equals(pendingId))).getSingleOrNull();
    if (pending == null || await _hasSimilarPending(pending)) {
      _log(
        payload,
        decision: 'duplicate',
        reason: 'duplicate-multi-source-or-existing-pending',
        parseResult: 'duplicate-suppressed',
        confidenceScore: bestCandidate?.confidenceScore,
        confidenceLevel: parsedConfidenceLevel,
        providerName: filterResult.providerName,
        senderFilterResult: filterResult.senderFilterResult,
        candidateCount: candidateCount,
        duplicateDecision: 'existing-pending-similarity',
      );
      return const [];
    }

    var localNotificationSent = false;
    if (shouldShowDetectionNotifications()) {
      final previewAmount = _extractAmountText(payload.combinedText);
      final previewMerchant = _extractMerchantPreview(payload);
      final previewType =
          bestCandidate?.paymentSourceTypeSuggestion ?? PaymentSourceType.bank;
      await localNotifier.showDetected(
        title: 'Transaction detected',
        body: '$previewAmount • $previewMerchant • ${_formatType(previewType)}',
        route: '/pending',
        pendingId: ids.isEmpty ? null : ids.first,
        showActions: true,
      );
      localNotificationSent = true;
    }

    _log(
      payload,
      decision: 'pending-created',
      reason: 'success',
      parseResult: 'parsed-pending-created',
      confidenceScore: bestCandidate?.confidenceScore,
      confidenceLevel: parsedConfidenceLevel,
      providerName: filterResult.providerName,
      senderFilterResult: filterResult.senderFilterResult,
      candidateCount: candidateCount,
      localNotificationSent: localNotificationSent,
    );
    return ids;
  }

  Future<bool> _allCandidatesReferenceDuplicate(
    List<DetectedTransactionCandidate> candidates,
  ) async {
    var referenceCandidateCount = 0;
    for (final candidate in candidates) {
      final reference = _extractTransactionReference(candidate);
      if (reference == null) continue;
      referenceCandidateCount += 1;
      final start = candidate.transactionDate.subtract(const Duration(days: 7));
      final end = candidate.transactionDate.add(const Duration(days: 7));
      final rows =
          await (database.select(database.pendingTransactions)..where(
                (p) =>
                    p.status.equals('pending') &
                    p.amount.equals(candidate.amount) &
                    p.transactionDate.isBiggerOrEqualValue(start) &
                    p.transactionDate.isSmallerOrEqualValue(end),
              ))
              .get();
      final refLower = reference.toLowerCase();
      final hasMatch = rows.any(
        (row) => row.rawText.toLowerCase().contains(refLower),
      );
      if (!hasMatch) {
        return false;
      }
    }
    return referenceCandidateCount > 0;
  }

  Future<bool> _hasSenderAmountRecipientDuplicate(
    List<DetectedTransactionCandidate> candidates,
  ) async {
    for (final candidate in candidates) {
      final sender = _metadataString(candidate, 'sender');
      final recipient = _metadataString(candidate, 'counterparty');
      if (sender == null || recipient == null) {
        continue;
      }
      final start = candidate.transactionDate.subtract(
        const Duration(minutes: 30),
      );
      final end = candidate.transactionDate.add(const Duration(minutes: 30));
      final rows =
          await (database.select(database.pendingTransactions)..where(
                (p) =>
                    p.status.equals('pending') &
                    p.amount.equals(candidate.amount) &
                    p.transactionDate.isBiggerOrEqualValue(start) &
                    p.transactionDate.isSmallerOrEqualValue(end),
              ))
              .get();
      for (final row in rows) {
        final rawLower = row.rawText.toLowerCase();
        final senderLower = sender.toLowerCase();
        final recipientLower = recipient.toLowerCase();
        final candidateRef = _extractTransactionReference(candidate);
        final rowRef = _extractTransactionReferenceFromText(row.rawText);
        if (candidateRef != null &&
            rowRef != null &&
            candidateRef.toLowerCase() != rowRef.toLowerCase()) {
          continue;
        }
        if (_similarity(row.merchant, candidate.merchant) >= 0.8 &&
            rawLower.contains(senderLower) &&
            rawLower.contains(recipientLower)) {
          return true;
        }
      }
    }
    return false;
  }

  String? _extractTransactionReference(DetectedTransactionCandidate candidate) {
    final fromMetadata = _metadataString(candidate, 'transactionRef');
    if (fromMetadata != null && fromMetadata.isNotEmpty) {
      return fromMetadata;
    }
    final match = RegExp(
      r'(?:RRN|UPI\s*Ref(?:erence)?|Txn(?:\s*ID)?|Ref(?:\s*No)?)\s*[:#.-]?\s*([A-Za-z0-9-]{6,})',
      caseSensitive: false,
    ).firstMatch(candidate.rawText);
    final value = match?.group(1)?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  String? _metadataString(DetectedTransactionCandidate candidate, String key) {
    final value = candidate.metadata?[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  String? _extractTransactionReferenceFromText(String rawText) {
    final match = RegExp(
      r'(?:RRN|UPI\s*Ref(?:erence)?|Txn(?:\s*ID)?|Ref(?:\s*No)?)\s*[:#.-]?\s*([A-Za-z0-9-]{6,})',
      caseSensitive: false,
    ).firstMatch(rawText);
    final value = match?.group(1)?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
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
      final pendingRef = _extractTransactionReferenceFromText(pending.rawText);
      final rowRef = _extractTransactionReferenceFromText(row.rawText);
      if (pendingRef != null &&
          rowRef != null &&
          pendingRef.toLowerCase() != rowRef.toLowerCase()) {
        continue;
      }
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

  void _log(
    NotificationPayload payload, {
    required String decision,
    required String reason,
    required String parseResult,
    String? providerName,
    double? confidenceScore,
    String? confidenceLevel,
    bool localNotificationSent = false,
    String? senderFilterResult,
    int? candidateCount,
    String? duplicateDecision,
    String? amountCandidate,
    String? blockedContext,
  }) {
    final title = payload.title?.trim();
    final previewSource = payload.body?.trim().isNotEmpty == true
        ? payload.body!.trim()
        : payload.combinedText.trim();
    final preview = previewSource.length > 120
        ? '${previewSource.substring(0, 120)}...'
        : previewSource;
    appendDebug(
      NotificationDebugEntry(
        receivedAt: payload.receivedAt,
        packageName: payload.packageName,
        title: title?.isNotEmpty == true ? title! : (payload.appName ?? '—'),
        bodyPreview: preview,
        decision: decision,
        reason: reason,
        result: parseResult,
        parseResult: parseResult,
        sourceType: payload.sourceType,
        providerName: providerName,
        confidenceScore: confidenceScore,
        confidenceLevel: confidenceLevel,
        localNotificationSent: localNotificationSent,
        sender: payload.sender ?? payload.title ?? payload.appName,
        senderFilterResult: senderFilterResult,
        candidateCount: candidateCount,
        duplicateDecision: duplicateDecision,
        amountCandidate: amountCandidate,
        blockedContext: blockedContext,
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

  String _formatType(String sourceType) {
    switch (sourceType) {
      case PaymentSourceType.creditCard:
        return 'CARD';
      case PaymentSourceType.upi:
        return 'UPI';
      case PaymentSourceType.bank:
        return 'BANK';
      case PaymentSourceType.cash:
        return 'CASH';
      default:
        return sourceType.toUpperCase();
    }
  }
}
