import 'notification_ingestion_service.dart';

const _redacted = '<redacted>';

Map<String, Object?> notificationDiskLogMeta(NotificationDebugEntry entry) {
  final hasTitle = entry.title.trim().isNotEmpty;
  final hasBodyPreview = entry.bodyPreview.trim().isNotEmpty;
  final hasSender = entry.sender?.trim().isNotEmpty == true;
  final hasAmountCandidate = entry.amountCandidate?.trim().isNotEmpty == true;
  final hasBlockedContext = entry.blockedContext?.trim().isNotEmpty == true;

  return <String, Object?>{
    'source': entry.sourceType,
    'package': entry.packageName,
    'title': hasTitle ? _redacted : null,
    'bodyPreview': hasBodyPreview ? _redacted : null,
    'decision': entry.decision,
    'reason': entry.reason,
    'result': entry.result,
    'parseResult': entry.parseResult,
    'providerName': entry.providerName,
    'sender': hasSender ? _redacted : null,
    'senderFilterResult': entry.senderFilterResult,
    'confidenceScore': entry.confidenceScore,
    'confidenceLevel': entry.confidenceLevel,
    'candidateCount': entry.candidateCount,
    'duplicateDecision': entry.duplicateDecision,
    'possibleDuplicateReason': entry.possibleDuplicateReason,
    'hasAmountCandidate': hasAmountCandidate,
    'amountCandidate': hasAmountCandidate ? _redacted : null,
    'blockedContext': hasBlockedContext ? _redacted : null,
    'localNotificationSent': entry.localNotificationSent,
    'receivedAt': entry.receivedAt.toIso8601String(),
    'receivedAtUsed': entry.receivedAtUsed?.toIso8601String(),
    'transactionDateChosen': entry.transactionDateChosen?.toIso8601String(),
  };
}
