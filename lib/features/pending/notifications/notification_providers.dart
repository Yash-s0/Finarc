import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/logging/logging_providers.dart';
import '../../../core/router/app_router.dart';
import '../../alerts/data/alerts_providers.dart';
import '../data/pending_providers.dart';
import 'detection_settings.dart';
import 'detection_settings_service.dart';
import 'notification_bridge.dart';
import 'ingestion_diagnostics.dart';
import 'notification_fingerprint.dart';
import 'notification_ingestion_service.dart';
import 'notification_keyword_filter.dart';
import 'notification_local_notifier.dart';
import 'notification_permission_service.dart';
import 'notification_payload.dart';
import 'notification_test_tools_service.dart';
import 'notification_diagnostics_service.dart';
import 'reminder_service.dart';
import 'sms_fingerprint.dart';
import 'sms_ingestion_service.dart';
import 'sms_permission_service.dart';
import 'sms_sender_filter.dart';
import 'real_ingestion_mode_service.dart';

export 'notification_access_setup_screen.dart';

final notificationPermissionServiceProvider =
    Provider<NotificationPermissionService>((ref) {
      return NotificationPermissionService();
    });

final notificationAccessStatusProvider = FutureProvider<bool>((ref) async {
  final ingestionEnabled = await ref.read(
    notificationIngestionAvailableProvider.future,
  );
  if (!ingestionEnabled) return false;
  return ref.read(notificationPermissionServiceProvider).isAccessEnabled();
});

final notificationListenerAvailableProvider = FutureProvider<bool>((ref) async {
  return ref
      .read(notificationPermissionServiceProvider)
      .isListenerComponentAvailable();
});

final postNotificationsPermissionProvider = FutureProvider<bool>((ref) async {
  return ref
      .read(notificationPermissionServiceProvider)
      .isPostNotificationsGranted();
});

final smsPermissionServiceProvider = Provider<SmsPermissionService>((ref) {
  return SmsPermissionService();
});

final smsPermissionStatusProvider = FutureProvider<bool>((ref) async {
  final ingestionEnabled = await ref.read(smsIngestionAvailableProvider.future);
  if (!ingestionEnabled) return false;
  return ref.read(smsPermissionServiceProvider).isPermissionGranted();
});

final smsReceiverAvailableProvider = FutureProvider<bool>((ref) async {
  return ref.read(smsPermissionServiceProvider).isReceiverComponentAvailable();
});

final smsReceiverEnabledProvider = FutureProvider<bool>((ref) async {
  return ref.read(smsPermissionServiceProvider).isReceiverComponentEnabled();
});

final smsPermissionRationaleProvider = FutureProvider<bool>((ref) async {
  return ref.read(smsPermissionServiceProvider).shouldShowPermissionRationale();
});

final smsRuntimeDiagnosticsProvider = FutureProvider<SmsRuntimeDiagnostics>((
  ref,
) async {
  return ref.read(smsPermissionServiceProvider).getRuntimeDiagnostics();
});

final realIngestionModeServiceProvider = Provider<RealIngestionModeService>((
  ref,
) {
  return RealIngestionModeService();
});

final notificationIngestionAvailableProvider = FutureProvider<bool>((
  ref,
) async {
  return ref
      .read(realIngestionModeServiceProvider)
      .isNotificationIngestionAvailable();
});

final smsIngestionAvailableProvider = FutureProvider<bool>((ref) async {
  return ref.read(realIngestionModeServiceProvider).isSmsIngestionAvailable();
});

final realIngestionAvailableProvider = FutureProvider<bool>((ref) async {
  final notification = await ref.read(
    notificationIngestionAvailableProvider.future,
  );
  final sms = await ref.read(smsIngestionAvailableProvider.future);
  return notification || sms;
});

final smsPermissionCachedProvider = StateProvider<bool>((ref) => false);

final detectionSettingsServiceProvider = Provider<DetectionSettingsService>((
  ref,
) {
  return DetectionSettingsService(ref.read(appDatabaseProvider));
});

class DetectionSettingsController extends AsyncNotifier<DetectionSettings> {
  @override
  Future<DetectionSettings> build() async {
    return ref.read(detectionSettingsServiceProvider).load();
  }

  Future<void> applyChanges({
    bool? notificationDetectionEnabled,
    bool? showDetectionNotifications,
    bool? reminderEnabled,
    bool? dailyReminderEnabled,
    bool? weeklyReminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    int? weeklyReminderWeekday,
    bool? cardDueReminderEnabled,
    bool? pendingTransactionReminderEnabled,
    bool? settlementReminderEnabled,
    DateTime? lastReminderShownAt,
    bool? smsDetectionEnabled,
    DateTime? smsPermissionAskedAt,
    bool clearSmsPermissionAskedAt = false,
    bool? smsBackfillEnabled,
    int? smsBackfillDays,
    DateTime? smsLastScannedAt,
    int? quietHoursStartHour,
    int? quietHoursStartMinute,
    int? quietHoursEndHour,
    int? quietHoursEndMinute,
    bool? smartAlertsEnabled,
    bool? lowBalanceAlertsEnabled,
    double? lowBalanceThreshold,
    bool? largeExpenseAlertsEnabled,
    double? largeExpenseThreshold,
    bool? unusualSpendingAlertsEnabled,
    double? unusualSpendingMultiplier,
    bool? recurringMerchantAlertsEnabled,
    bool? weeklySummaryAlertsEnabled,
    bool? monthlySummaryAlertsEnabled,
    bool clearSmsLastScannedAt = false,
    bool clearLastReminderShownAt = false,
  }) async {
    final current = await future;
    final next = current.copyWith(
      notificationDetectionEnabled: notificationDetectionEnabled,
      showDetectionNotifications: showDetectionNotifications,
      reminderEnabled: reminderEnabled,
      dailyReminderEnabled: dailyReminderEnabled,
      weeklyReminderEnabled: weeklyReminderEnabled,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
      weeklyReminderWeekday: weeklyReminderWeekday,
      cardDueReminderEnabled: cardDueReminderEnabled,
      pendingTransactionReminderEnabled: pendingTransactionReminderEnabled,
      settlementReminderEnabled: settlementReminderEnabled,
      lastReminderShownAt: lastReminderShownAt,
      smsDetectionEnabled: smsDetectionEnabled,
      smsPermissionAskedAt: smsPermissionAskedAt,
      clearSmsPermissionAskedAt: clearSmsPermissionAskedAt,
      smsBackfillEnabled: smsBackfillEnabled,
      smsBackfillDays: smsBackfillDays,
      smsLastScannedAt: smsLastScannedAt,
      quietHoursStartHour: quietHoursStartHour,
      quietHoursStartMinute: quietHoursStartMinute,
      quietHoursEndHour: quietHoursEndHour,
      quietHoursEndMinute: quietHoursEndMinute,
      smartAlertsEnabled: smartAlertsEnabled,
      lowBalanceAlertsEnabled: lowBalanceAlertsEnabled,
      lowBalanceThreshold: lowBalanceThreshold,
      largeExpenseAlertsEnabled: largeExpenseAlertsEnabled,
      largeExpenseThreshold: largeExpenseThreshold,
      unusualSpendingAlertsEnabled: unusualSpendingAlertsEnabled,
      unusualSpendingMultiplier: unusualSpendingMultiplier,
      recurringMerchantAlertsEnabled: recurringMerchantAlertsEnabled,
      weeklySummaryAlertsEnabled: weeklySummaryAlertsEnabled,
      monthlySummaryAlertsEnabled: monthlySummaryAlertsEnabled,
      clearSmsLastScannedAt: clearSmsLastScannedAt,
      clearLastReminderShownAt: clearLastReminderShownAt,
    );

    state = AsyncValue.data(next);
    await ref.read(detectionSettingsServiceProvider).save(next);
  }
}

final detectionSettingsProvider =
    AsyncNotifierProvider<DetectionSettingsController, DetectionSettings>(
      DetectionSettingsController.new,
    );

final notificationDetectionEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(detectionSettingsProvider).valueOrNull;
  return settings?.notificationDetectionEnabled ?? true;
});

final showDetectionNotificationsProvider = Provider<bool>((ref) {
  final settings = ref.watch(detectionSettingsProvider).valueOrNull;
  return settings?.showDetectionNotifications ?? true;
});

final smsDetectionEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(detectionSettingsProvider).valueOrNull;
  return settings?.smsDetectionEnabled ?? false;
});

final notificationBridgeProvider = Provider<NotificationBridge>((ref) {
  return NotificationBridge();
});

final notificationLocalNotifierProvider = Provider<NotificationLocalNotifier>((
  ref,
) {
  return NotificationLocalNotifier();
});

final reminderServiceProvider = Provider<ReminderService>((ref) {
  return ReminderService(
    ref.read(appDatabaseProvider),
    ref.read(notificationLocalNotifierProvider),
  );
});

final notificationDiagnosticsServiceProvider =
    Provider<NotificationDiagnosticsService>((ref) {
      return NotificationDiagnosticsService(ref.read(appLogServiceProvider));
    });

final notificationDiagnosticsSnapshotProvider =
    FutureProvider<NotificationDiagnosticsSnapshot>((ref) async {
      return ref.read(notificationDiagnosticsServiceProvider).loadSnapshot();
    });

final notificationDebugLogProvider =
    StateNotifierProvider<
      NotificationDebugLogController,
      List<NotificationDebugEntry>
    >((ref) {
      return NotificationDebugLogController();
    });

class NotificationDebugLogController
    extends StateNotifier<List<NotificationDebugEntry>> {
  NotificationDebugLogController() : super(const []);

  void append(NotificationDebugEntry entry) {
    final next = [entry, ...state];
    state = next.take(100).toList(growable: false);
  }

  void clear() {
    state = const [];
  }
}

final ingestionDiagnosticsProvider =
    StateNotifierProvider<IngestionDiagnosticsController, IngestionDiagnostics>(
      (ref) => IngestionDiagnosticsController(),
    );

class IngestionDiagnosticsController
    extends StateNotifier<IngestionDiagnostics> {
  IngestionDiagnosticsController() : super(IngestionDiagnostics.empty);

  void clear() {
    state = IngestionDiagnostics.empty;
  }

  void append(NotificationDebugEntry entry) {
    final result = entry.parseResult ?? entry.result;
    final package = entry.packageName.toUpperCase();
    final decision = entry.decision;
    final isSms =
        entry.sourceType == 'sms' ||
        package == 'ANDROID.SMS' ||
        package == 'SMS' ||
        package.endsWith('-S') ||
        package.endsWith('-T') ||
        package.endsWith('-P') ||
        RegExp(r'^\+?[0-9\- ]{10,}$').hasMatch(entry.packageName);

    if (isSms) {
      state = state.copyWith(
        smsReceived: state.smsReceived + 1,
        lastSmsEventAt: entry.receivedAt,
        lastSmsSender: entry.packageName,
        lastSmsResult: result,
      );

      if (result == 'allowed-transactional-sender') {
        state = state.copyWith(smsAllowed: state.smsAllowed + 1);
      } else if (result == 'blocked-promotional-sender') {
        state = state.copyWith(
          smsBlockedPromotional: state.smsBlockedPromotional + 1,
        );
      } else if (result == 'blocked-unknown-sender') {
        state = state.copyWith(
          smsBlockedUnknownSender: state.smsBlockedUnknownSender + 1,
        );
      } else if (result == 'blocked-non-transaction-text') {
        state = state.copyWith(
          smsBlockedNonTransaction: state.smsBlockedNonTransaction + 1,
        );
      } else if (decision == 'duplicate') {
        state = state.copyWith(
          smsDuplicateSuppressed: state.smsDuplicateSuppressed + 1,
        );
      } else if (decision == 'pending-created') {
        state = state.copyWith(smsParsedPending: state.smsParsedPending + 1);
      }
      return;
    }

    state = state.copyWith(
      notificationsReceived: state.notificationsReceived + 1,
      lastNotificationEventAt: entry.receivedAt,
      lastNotificationPackage: entry.packageName,
      lastNotificationResult: result,
    );
    if (decision == 'pending-created') {
      state = state.copyWith(
        notificationsParsedPending: state.notificationsParsedPending + 1,
      );
    } else if (decision == 'duplicate') {
      state = state.copyWith(
        notificationsDuplicateSuppressed:
            state.notificationsDuplicateSuppressed + 1,
        notificationsNearDuplicateSuppressed:
            (entry.reason == 'near_duplicate_same_amount_counterparty_8m')
            ? state.notificationsNearDuplicateSuppressed + 1
            : state.notificationsNearDuplicateSuppressed,
      );
    } else {
      state = state.copyWith(
        notificationsIgnored: state.notificationsIgnored + 1,
      );
    }
  }
}

final notificationIngestionServiceProvider =
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
        shouldShowDetectionNotifications: () =>
            ref.read(showDetectionNotificationsProvider),
        appendDebug: append,
      );
    });

final smsIngestionServiceProvider = Provider<SmsIngestionService>((ref) {
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

  return SmsIngestionService(
    database: ref.read(appDatabaseProvider),
    pendingIngestionService: ref.read(pendingIngestionServiceProvider),
    keywordFilter: NotificationKeywordFilter(),
    fingerprint: SmsFingerprint(),
    localNotifier: ref.read(notificationLocalNotifierProvider),
    isSmsDetectionEnabled: () => ref.read(smsDetectionEnabledProvider),
    isSmsPermissionGranted: () => ref.read(smsPermissionCachedProvider),
    shouldShowDetectionNotifications: () =>
        ref.read(showDetectionNotificationsProvider),
    appendDebug: append,
    senderFilter: const SmsSenderFilter(),
  );
});

final notificationTestToolsServiceProvider =
    Provider<NotificationTestToolsService>((ref) {
      return NotificationTestToolsService(
        alertService: ref.read(alertServiceProvider),
        notificationIngestionService: ref.read(
          notificationIngestionServiceProvider,
        ),
        smsIngestionService: ref.read(smsIngestionServiceProvider),
        localNotifier: ref.read(notificationLocalNotifierProvider),
      );
    });

final reminderBootstrapProvider = Provider<void>((ref) {
  final settings = ref.watch(detectionSettingsProvider).valueOrNull;
  if (settings == null) return;
  final reminderService = ref.read(reminderServiceProvider);

  Future<void> apply() async {
    if (!settings.reminderEnabled) {
      await reminderService.cancelDailyReminder();
      await reminderService.cancelWeeklyReminder();
      await reminderService.syncCardDueReminders(enabled: false);
      await reminderService.syncLoanEmiReminders(enabled: false);
      await ref
          .read(notificationLocalNotifierProvider)
          .cancelReminder(ReminderService.pendingReminderId);
      return;
    }

    final time = TimeOfDay(
      hour: settings.reminderHour,
      minute: settings.reminderMinute,
    );

    if (settings.dailyReminderEnabled) {
      await reminderService.scheduleDailyReminder(time);
    } else {
      await reminderService.cancelDailyReminder();
    }

    if (settings.weeklyReminderEnabled) {
      await reminderService.scheduleWeeklyReminder(
        settings.weeklyReminderWeekday,
        time,
      );
    } else {
      await reminderService.cancelWeeklyReminder();
    }

    if (settings.pendingTransactionReminderEnabled) {
      await reminderService.schedulePendingConfirmationReminder();
    } else {
      await ref
          .read(notificationLocalNotifierProvider)
          .cancelReminder(ReminderService.pendingReminderId);
    }

    await reminderService.syncCardDueReminders(
      enabled: settings.cardDueReminderEnabled,
    );
    await reminderService.syncLoanEmiReminders(enabled: true);
  }

  unawaited(apply());
});

NotificationRouteAction parseNotificationRouteAction(String route) {
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

  bool get isNone => type == 'none';
}

final notificationListenerBootstrapProvider = Provider<void>((ref) {
  final notificationIngestionAvailable =
      ref.watch(notificationIngestionAvailableProvider).valueOrNull ?? false;
  final smsIngestionAvailable =
      ref.watch(smsIngestionAvailableProvider).valueOrNull ?? false;
  final realIngestionAvailable =
      notificationIngestionAvailable || smsIngestionAvailable;
  final bridge = ref.read(notificationBridgeProvider);
  final notificationIngestion = ref.read(notificationIngestionServiceProvider);
  final smsIngestion = ref.read(smsIngestionServiceProvider);
  ref.watch(reminderBootstrapProvider);

  Future<void> refreshSmsPermission() async {
    if (!smsIngestionAvailable) {
      ref.read(smsPermissionCachedProvider.notifier).state = false;
      return;
    }
    final granted = await ref
        .read(smsPermissionServiceProvider)
        .isPermissionGranted();
    ref.read(smsPermissionCachedProvider.notifier).state = granted;
  }

  Future<void> runAlertEvaluation() async {
    await ref.read(alertEvaluationActionsProvider).evaluateAll();
  }

  Future<void> handleRoute(String route) async {
    final action = parseNotificationRouteAction(route);
    if (action.type == 'ignore' && action.pendingId != null) {
      await ref.read(pendingActionProvider).ignore(action.pendingId!);
      appRouter.go('/pending');
      return;
    }
    if (action.type == 'confirm' && action.pendingId != null) {
      appRouter.go('/pending?openPendingId=${action.pendingId}');
      return;
    }
    appRouter.go(route);
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

  unawaited(refreshSmsPermission());
  unawaited(runAlertEvaluation());

  if (realIngestionAvailable) {
    unawaited(
      bridge.initialize(
        onPayload: (payload) async {
          if (payload.sourceType == 'sms') {
            if (!smsIngestionAvailable) return;
            final ids = await smsIngestion.processSmsPayload(payload);
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
            return;
          }
          if (!notificationIngestionAvailable) return;
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
        },
        onRoute: handleRoute,
      ),
    );
  }

  ref.onDispose(() {
    unawaited(bridge.dispose());
  });
});
