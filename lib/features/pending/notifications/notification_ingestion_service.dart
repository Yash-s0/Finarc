import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/formatters.dart';
import '../../expenses/models/transaction_types.dart';
import '../parsing/confidence_level.dart';
import '../parsing/counterparty_normalizer.dart';
import '../parsing/parser_models.dart';
import '../parsing/parser_confidence_scorer.dart';
import '../parsing/parser_text_utils.dart';
import '../parsing/pending_ingestion_service.dart';
import '../parsing/transaction_direction_classifier.dart';
import '../data/pending_service.dart';
import 'card_bill_due_notification_service.dart';
import 'card_payment_notification_service.dart';
import 'notification_burst_limiter.dart';
import 'notification_fingerprint.dart';
import 'notification_keyword_filter.dart';
import 'notification_local_notifier.dart';
import 'notification_payload.dart';
import 'notification_provider_catalog.dart';

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
    this.possibleDuplicateReason,
    this.amountCandidate,
    this.blockedContext,
    this.receivedAtUsed,
    this.transactionDateChosen,
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
  final String? possibleDuplicateReason;
  final String? amountCandidate;
  final String? blockedContext;
  final DateTime? receivedAtUsed;
  final DateTime? transactionDateChosen;
}

class NotificationIngestionService {
  NotificationIngestionService({
    required this.database,
    required this.pendingIngestionService,
    required this.pendingService,
    required this.keywordFilter,
    required this.fingerprint,
    required this.localNotifier,
    required this.isDetectionEnabled,
    bool Function()? areOptionalNotificationSourcesEnabled,
    required this.shouldShowDetectionNotifications,
    required this.appendDebug,
    CardBillDueNotificationService? cardBillDueNotificationService,
    CardPaymentNotificationService? cardPaymentNotificationService,
    NotificationBurstLimiter? burstLimiter,
  }) : cardBillDueNotificationService =
           cardBillDueNotificationService ??
           CardBillDueNotificationService(database: database),
       cardPaymentNotificationService =
           cardPaymentNotificationService ??
           CardPaymentNotificationService(
             database: database,
             pendingService: pendingService,
           ),
       burstLimiter = burstLimiter ?? NotificationBurstLimiter(),
       areOptionalNotificationSourcesEnabled =
           areOptionalNotificationSourcesEnabled ??
           _optionalSourcesEnabledByDefault;

  final AppDatabase database;
  final PendingIngestionService pendingIngestionService;
  final PendingService pendingService;
  final NotificationKeywordFilter keywordFilter;
  final NotificationFingerprint fingerprint;
  final NotificationLocalNotifier localNotifier;
  final bool Function() isDetectionEnabled;
  final bool Function() areOptionalNotificationSourcesEnabled;
  final bool Function() shouldShowDetectionNotifications;
  final void Function(NotificationDebugEntry entry) appendDebug;
  final CardBillDueNotificationService cardBillDueNotificationService;
  final CardPaymentNotificationService cardPaymentNotificationService;
  final NotificationBurstLimiter burstLimiter;
  static const Duration _nearDuplicateWindow = Duration(minutes: 8);
  static const Duration _genericDuplicateWindow = Duration(minutes: 2);
  static bool _optionalSourcesEnabledByDefault() => true;

  Future<List<int>> processPayload(NotificationPayload payload) async {
    final isMessagingSmsNotification =
        payload.sourceType != 'sms' &&
        NotificationProviderCatalog.isMessagingPackage(payload.packageName);

    if (!isDetectionEnabled()) {
      _log(
        payload,
        decision: 'ignored',
        reason: 'detection-disabled',
        parseResult: 'ignored-disabled',
      );
      return const [];
    }

    if (!isMessagingSmsNotification &&
        payload.sourceType != 'sms' &&
        NotificationProviderCatalog.isBlockedPackage(payload.packageName)) {
      return const [];
    }

    if (payload.sourceType != 'sms' &&
        NotificationProviderCatalog.isOptionalPackage(payload.packageName) &&
        !areOptionalNotificationSourcesEnabled()) {
      return const [];
    }

    if (!burstLimiter.isAllowed(
      _burstSourceKey(payload),
      payload.captureTime,
    )) {
      _log(
        payload,
        decision: 'ignored',
        reason: 'rate-limited-notification-burst',
        parseResult: 'rate-limited',
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
      rawText: _parserRawText(payload, isMessagingSmsNotification),
      sourceType: isMessagingSmsNotification
          ? 'sms'
          : (payload.sourceType.isEmpty
                ? 'appNotification'
                : payload.sourceType),
      packageName: payload.packageName,
      sender: _parserSender(payload, isMessagingSmsNotification),
      receivedAt: payload.captureTime,
      postTime: payload.postTime,
      notificationTitle: payload.title,
      notificationBody: payload.body,
    );

    final billDueResult = await cardBillDueNotificationService.handleIfBillDue(
      payload,
    );
    if (billDueResult != null) {
      _log(
        payload,
        decision: billDueResult.action == 'ignoredDuplicate'
            ? 'duplicate'
            : 'parsed',
        reason: 'card-bill-due-${billDueResult.action}',
        parseResult: 'card-bill-due-notification',
        providerName: filterResult.providerName,
        senderFilterResult: filterResult.senderFilterResult,
        candidateCount: 0,
      );
      return const [];
    }

    final cardPaymentResult = await cardPaymentNotificationService
        .handleIfCardPayment(payload);
    if (cardPaymentResult != null) {
      var localNotificationSent = false;
      if (cardPaymentResult.pendingId != null &&
          shouldShowDetectionNotifications()) {
        await localNotifier.showDetected(
          title: 'Card payment detected',
          body:
              '${inr(cardPaymentResult.parsed.amount)} • ${cardPaymentResult.parsed.merchantLabel} • Settlement',
          route: '/pending',
          pendingId: cardPaymentResult.pendingId,
          showActions: true,
        );
        localNotificationSent = true;
      }

      _log(
        payload,
        decision: cardPaymentResult.action == 'mergedIntoPending'
            ? 'duplicate'
            : 'pending-created',
        reason: 'card-payment-${cardPaymentResult.action}',
        parseResult: 'card-payment-notification',
        providerName: filterResult.providerName,
        senderFilterResult: filterResult.senderFilterResult,
        candidateCount: cardPaymentResult.pendingId == null ? 0 : 1,
        localNotificationSent: localNotificationSent,
        confidenceScore: 0.98,
        confidenceLevel: ConfidenceLevel.high.label,
        transactionDateChosen: cardPaymentResult.parsed.transactionDate,
      );
      return cardPaymentResult.pendingId == null
          ? const []
          : [cardPaymentResult.pendingId!];
    }

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

    final bestCandidate = parserResult.candidates.isEmpty
        ? null
        : parserResult.candidates.first;
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
        transactionDateChosen: bestCandidate?.transactionDate,
      );
      return const [];
    }

    final nearDuplicateDecision = await _evaluateNearDuplicate(
      parserResult.candidates,
    );
    if (nearDuplicateDecision.suppress) {
      _log(
        payload,
        decision: 'duplicate',
        reason: nearDuplicateDecision.reason!,
        parseResult: 'duplicate-suppressed',
        providerName: filterResult.providerName,
        senderFilterResult: filterResult.senderFilterResult,
        candidateCount: candidateCount,
        duplicateDecision: nearDuplicateDecision.reason,
        transactionDateChosen: bestCandidate?.transactionDate,
      );
      return const [];
    }

    final fingerprintValue = fingerprint.build(
      payload: payload,
      amount: bestCandidate?.amount,
      merchant: bestCandidate?.merchant,
    );
    if (fingerprint.isDuplicate(fingerprintValue, payload.captureTime)) {
      _log(
        payload,
        decision: 'duplicate',
        reason: 'duplicate-same-notification-body-hash',
        parseResult: 'duplicate-suppressed',
        providerName: filterResult.providerName,
        senderFilterResult: filterResult.senderFilterResult,
        candidateCount: candidateCount,
        duplicateDecision: 'body-hash-fallback',
        transactionDateChosen: bestCandidate?.transactionDate,
      );
      return const [];
    }

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
        transactionDateChosen: bestCandidate.transactionDate,
      );
      return const [];
    }

    final ids = await pendingIngestionService.ingestParserInput(parserInput);
    if (ids.isEmpty) {
      final postIngestNearDuplicate = await _evaluateNearDuplicate(
        parserResult.candidates,
      );
      _log(
        payload,
        decision: postIngestNearDuplicate.suppress ? 'duplicate' : 'parsed',
        reason: postIngestNearDuplicate.suppress
            ? (postIngestNearDuplicate.reason ??
                  'near_duplicate_same_amount_counterparty_8m')
            : 'parser-no-candidate',
        parseResult: postIngestNearDuplicate.suppress
            ? 'duplicate-suppressed'
            : 'parser-failed',
        providerName: filterResult.providerName,
        senderFilterResult: filterResult.senderFilterResult,
        candidateCount: candidateCount,
        duplicateDecision: postIngestNearDuplicate.suppress
            ? (postIngestNearDuplicate.reason ??
                  'near_duplicate_same_amount_counterparty_8m')
            : null,
        transactionDateChosen: bestCandidate?.transactionDate,
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
      possibleDuplicateReason: nearDuplicateDecision.possibleDuplicate
          ? nearDuplicateDecision.reason
          : null,
      transactionDateChosen: bestCandidate?.transactionDate,
    );
    return ids;
  }

  String _parserRawText(
    NotificationPayload payload,
    bool isMessagingSmsNotification,
  ) {
    if (!isMessagingSmsNotification) return payload.combinedText;
    final smsText = [payload.body, payload.bigText, payload.subText]
        .whereType<String>()
        .where((part) => part.trim().isNotEmpty)
        .join(' ')
        .trim();
    return smsText.isEmpty ? payload.combinedText : smsText;
  }

  String? _parserSender(
    NotificationPayload payload,
    bool isMessagingSmsNotification,
  ) {
    if (payload.sender != null && payload.sender!.trim().isNotEmpty) {
      return payload.sender;
    }
    if (isMessagingSmsNotification &&
        payload.title != null &&
        payload.title!.trim().isNotEmpty) {
      return payload.title;
    }
    return payload.appName;
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

  Future<_NearDuplicateDecision> _evaluateNearDuplicate(
    List<DetectedTransactionCandidate> candidates,
  ) async {
    for (final candidate in candidates) {
      final start = candidate.transactionDate.subtract(_nearDuplicateWindow);
      final end = candidate.transactionDate.add(_nearDuplicateWindow);
      final rows =
          await (database.select(database.pendingTransactions)..where(
                (p) =>
                    p.status.equals('pending') &
                    p.amount.equals(candidate.amount) &
                    p.transactionDate.isBiggerOrEqualValue(start) &
                    p.transactionDate.isSmallerOrEqualValue(end),
              ))
              .get();
      final candidateDirection = _directionFromCandidate(candidate);
      final candidateCounterparty = CounterpartyNormalizer.normalize(
        _metadataString(candidate, 'counterparty') ?? candidate.merchant,
      );
      final candidateSource = candidate.paymentSourceTypeSuggestion;
      final candidateSourceHint = _normalizeSourceHint(
        candidate.paymentSourceHint,
      );
      final candidateRef = _extractTransactionReference(
        candidate,
      )?.toLowerCase();

      for (final row in rows) {
        final rowSourceHint = _normalizeSourceHint(
          ParserTextUtils.extractAccountHint(row.rawText),
        );
        final rowRef = _extractTransactionReferenceFromText(
          row.rawText,
        )?.toLowerCase();

        if (_isGenericCrossSourceDuplicate(
          candidateCounterparty: candidateCounterparty,
          rowCounterparty: row.merchant,
          candidateSourceHint: candidateSourceHint,
          rowSourceHint: rowSourceHint,
          candidateRef: candidateRef,
          rowRef: rowRef,
          candidateDate: candidate.transactionDate,
          rowDate: row.transactionDate,
        )) {
          return const _NearDuplicateDecision(
            suppress: true,
            possibleDuplicate: false,
            reason: 'generic_notification_duplicate_within_2m',
          );
        }

        if (_directionFromPending(row) != candidateDirection) continue;
        if (!CounterpartyNormalizer.isSameOrNearMatch(
          candidateCounterparty,
          row.merchant,
        )) {
          continue;
        }
        if (candidateSource != null &&
            row.paymentSourceTypeSuggestion.trim().isNotEmpty &&
            row.paymentSourceTypeSuggestion != candidateSource) {
          continue;
        }
        if (candidateSourceHint != null &&
            rowSourceHint != null &&
            candidateSourceHint != rowSourceHint) {
          continue;
        }
        if (candidateRef != null && rowRef != null && candidateRef != rowRef) {
          return const _NearDuplicateDecision(
            suppress: false,
            possibleDuplicate: true,
            reason: 'possible_duplicate_different_reference_within_8m',
          );
        }
        return const _NearDuplicateDecision(
          suppress: true,
          possibleDuplicate: false,
          reason: 'near_duplicate_same_amount_counterparty_8m',
        );
      }
    }
    return const _NearDuplicateDecision(
      suppress: false,
      possibleDuplicate: false,
      reason: null,
    );
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

  String _directionFromCandidate(DetectedTransactionCandidate candidate) {
    final metadataDirection = _metadataString(candidate, 'direction');
    if (metadataDirection == 'income') return 'income';
    if (metadataDirection == 'expense') return 'expense';
    final direction = PendingDirectionClassifier.detect(
      text: candidate.rawText,
      categoryHint: candidate.categorySuggestion,
    );
    switch (direction) {
      case PendingTransactionDirection.income:
        return 'income';
      case PendingTransactionDirection.expense:
        return 'expense';
      case PendingTransactionDirection.unknown:
        return 'unknown';
    }
  }

  String _directionFromPending(PendingTransaction pending) {
    final direction = PendingDirectionClassifier.detect(
      text: pending.rawText,
      categoryHint: pending.categorySuggestion,
    );
    switch (direction) {
      case PendingTransactionDirection.income:
        return 'income';
      case PendingTransactionDirection.expense:
        return 'expense';
      case PendingTransactionDirection.unknown:
        return 'unknown';
    }
  }

  String? _normalizeSourceHint(String? hint) {
    if (hint == null || hint.trim().isEmpty) return null;
    final digits = RegExp(r'(\d{3,4})(?!.*\d)').firstMatch(hint)?.group(1);
    if (digits != null && digits.isNotEmpty) return digits;
    return hint.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '').trim();
  }

  bool _isGenericCrossSourceDuplicate({
    required String candidateCounterparty,
    required String rowCounterparty,
    required String? candidateSourceHint,
    required String? rowSourceHint,
    required String? candidateRef,
    required String? rowRef,
    required DateTime candidateDate,
    required DateTime rowDate,
  }) {
    if (candidateSourceHint == null ||
        rowSourceHint == null ||
        candidateSourceHint != rowSourceHint) {
      return false;
    }
    if (candidateRef != null && rowRef != null) return false;
    if (!_isWeakCounterparty(candidateCounterparty) &&
        !_isWeakCounterparty(rowCounterparty)) {
      return false;
    }
    return candidateDate.difference(rowDate).abs() <= _genericDuplicateWindow;
  }

  bool _isWeakCounterparty(String value) {
    final normalized = CounterpartyNormalizer.normalize(value);
    if (normalized.isEmpty) return true;
    if (normalized == 'unknown merchant') return true;
    final compact = normalized.replaceAll(' ', '');
    if (RegExp(
      r'^(?:x+|\*+)?\d{3,4}$',
      caseSensitive: false,
    ).hasMatch(compact)) {
      return true;
    }
    const genericTokens = {
      'unknown',
      'merchant',
      'amount',
      'payment',
      'transfer',
      'credited',
      'debited',
      'sent',
      'received',
      'upi',
      'bank',
    };
    final tokens = normalized.split(' ').where((token) => token.isNotEmpty);
    return tokens.every(genericTokens.contains);
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
    String? possibleDuplicateReason,
    String? amountCandidate,
    String? blockedContext,
    DateTime? transactionDateChosen,
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
        receivedAt: payload.captureTime,
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
        possibleDuplicateReason: possibleDuplicateReason,
        amountCandidate: amountCandidate,
        blockedContext: blockedContext,
        receivedAtUsed: payload.captureTime,
        transactionDateChosen: transactionDateChosen,
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

  String _burstSourceKey(NotificationPayload payload) {
    final sourceType = payload.sourceType.isEmpty
        ? 'appNotification'
        : payload.sourceType;
    final packageName = payload.packageName.trim().isNotEmpty
        ? payload.packageName.trim()
        : (payload.appName ?? 'unknown');
    return '$sourceType:$packageName';
  }
}

class _NearDuplicateDecision {
  const _NearDuplicateDecision({
    required this.suppress,
    required this.possibleDuplicate,
    required this.reason,
  });

  final bool suppress;
  final bool possibleDuplicate;
  final String? reason;
}
