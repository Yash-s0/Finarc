import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router_release.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/logging/logging_providers.dart';
import '../../alerts/data/alerts_providers.dart';
import '../data/pending_providers.dart';
import 'notification_bridge.dart';
import 'notification_fingerprint.dart';
import 'notification_ingestion_service.dart';
import 'notification_keyword_filter.dart';
import 'notification_payload.dart';
import 'notification_providers.dart';
import 'notification_permission_service.dart';

final _notificationPermissionServiceProvider =
    Provider<NotificationPermissionService>((ref) {
      return NotificationPermissionService();
    });

final _notificationBridgeProvider = Provider<NotificationBridge>((ref) {
  return NotificationBridge();
});

final _notificationIngestionServiceProvider =
    Provider<NotificationIngestionService>((ref) {
      void append(NotificationDebugEntry entry) {
        ref.read(notificationDebugLogProvider.notifier).append(entry);
        ref.read(ingestionDiagnosticsProvider.notifier).append(entry);
        unawaited(
          ref
              .read(appLogServiceProvider)
              .log(
                category: 'notification_event',
                message: entry.decision,
                meta: <String, Object?>{
                  'source': entry.sourceType,
                  'package': entry.packageName,
                  'title': entry.title,
                  'bodyPreview': entry.bodyPreview,
                  'decision': entry.decision,
                  'reason': entry.reason,
                  'result': entry.result,
                  'parseResult': entry.parseResult,
                  'providerName': entry.providerName,
                  'sender': entry.sender,
                  'senderFilterResult': entry.senderFilterResult,
                  'confidenceScore': entry.confidenceScore,
                  'confidenceLevel': entry.confidenceLevel,
                  'candidateCount': entry.candidateCount,
                  'duplicateDecision': entry.duplicateDecision,
                  'possibleDuplicateReason': entry.possibleDuplicateReason,
                  'amountCandidate': entry.amountCandidate,
                  'blockedContext': entry.blockedContext,
                  'localNotificationSent': entry.localNotificationSent,
                  'receivedAt': entry.receivedAt.toIso8601String(),
                  'receivedAtUsed': entry.receivedAtUsed?.toIso8601String(),
                  'transactionDateChosen': entry.transactionDateChosen
                      ?.toIso8601String(),
                },
              ),
        );
      }

      return NotificationIngestionService(
        database: ref.read(appDatabaseProvider),
        pendingIngestionService: ref.read(pendingIngestionServiceProvider),
        pendingService: ref.read(pendingServiceProvider),
        keywordFilter: NotificationKeywordFilter(),
        fingerprint: NotificationFingerprint(),
        localNotifier: ref.read(notificationLocalNotifierProvider),
        isDetectionEnabled: () =>
            ref.read(notificationDetectionEnabledProvider),
        areOptionalNotificationSourcesEnabled: () =>
            ref.read(paymentAppNotificationsEnabledProvider),
        shouldShowDetectionNotifications: () =>
            ref.read(showDetectionNotificationsProvider),
        appendDebug: append,
      );
    });

NotificationRouteAction _parseNotificationRouteAction(String route) {
  final uri = Uri.tryParse(route);
  if (uri == null || uri.path != '/pending') {
    return const NotificationRouteAction.none();
  }
  final action = uri.queryParameters['action'];
  final pendingId = int.tryParse(uri.queryParameters['pendingId'] ?? '');
  if (action == null || pendingId == null) {
    return const NotificationRouteAction.none();
  }
  if (action == 'ignore') {
    return NotificationRouteAction.ignore(pendingId: pendingId);
  }
  if (action == 'confirm') {
    return NotificationRouteAction.confirm(pendingId: pendingId);
  }
  return const NotificationRouteAction.none();
}

class NotificationRouteAction {
  const NotificationRouteAction._({
    required this.type,
    required this.pendingId,
  });

  const NotificationRouteAction.none() : this._(type: 'none', pendingId: null);

  const NotificationRouteAction.ignore({required int pendingId})
    : this._(type: 'ignore', pendingId: pendingId);

  const NotificationRouteAction.confirm({required int pendingId})
    : this._(type: 'confirm', pendingId: pendingId);

  final String type;
  final int? pendingId;
}

final notificationListenerBootstrapProvider = Provider<void>((ref) {
  final bridge = ref.read(_notificationBridgeProvider);
  final notificationIngestion = ref.read(_notificationIngestionServiceProvider);

  Future<void> runAlertEvaluation() async {
    await ref.read(alertEvaluationActionsProvider).evaluateAll();
  }

  Future<void> handleRoute(String route) async {
    final action = _parseNotificationRouteAction(route);
    if (action.type == 'ignore' && action.pendingId != null) {
      await ref.read(pendingActionProvider).ignore(action.pendingId!);
      appRouterRelease.go('/pending');
      return;
    }
    if (action.type == 'confirm' && action.pendingId != null) {
      appRouterRelease.go('/pending?openPendingId=${action.pendingId}');
      return;
    }
    appRouterRelease.go(route);
  }

  String pendingAlertTitle(NotificationPayload payload) {
    final text = payload.combinedText;
    final amountMatch = RegExp(
      r'(?:INR|Rs\.?|₹)\s*[0-9][0-9,]*(?:\.[0-9]{1,2})?',
      caseSensitive: false,
    ).firstMatch(text);
    final amount = amountMatch?.group(0)?.replaceAll('INR', '₹') ?? 'Amount';
    final merchant = payload.title?.trim().isNotEmpty == true
        ? payload.title!.trim()
        : (payload.sender?.trim().isNotEmpty == true
              ? payload.sender!.trim()
              : (payload.appName ?? 'merchant'));
    return '$amount detected at $merchant';
  }

  Future<void> initializeBridgeIfAvailable() async {
    final available = await ref
        .read(_notificationPermissionServiceProvider)
        .isListenerComponentAvailable();
    if (!available) return;

    await bridge.initialize(
      onPayload: (payload) async {
        if (payload.sourceType == 'sms') return;

        final ids = await notificationIngestion.processPayload(payload);
        if (ids.isNotEmpty) {
          await ref
              .read(alertEvaluationActionsProvider)
              .onPendingDetected(
                pendingId: ids.first,
                title: pendingAlertTitle(payload),
                body: 'Confirm this transaction in Finarc.',
              );
        }
        ref.invalidate(pendingTransactionsProvider);
        ref.invalidate(pendingCountProvider);
        ref.invalidate(notificationDiagnosticsSnapshotProvider);
      },
      onRoute: handleRoute,
    );
  }

  unawaited(runAlertEvaluation());
  unawaited(initializeBridgeIfAvailable());

  ref.onDispose(() {
    unawaited(bridge.dispose());
  });
});
