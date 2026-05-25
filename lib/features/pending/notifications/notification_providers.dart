import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/router/app_router.dart';
import '../data/pending_providers.dart';
import 'detection_settings.dart';
import 'detection_settings_service.dart';
import 'notification_bridge.dart';
import 'notification_fingerprint.dart';
import 'notification_ingestion_service.dart';
import 'notification_keyword_filter.dart';
import 'notification_local_notifier.dart';
import 'notification_permission_service.dart';
import 'reminder_service.dart';
import 'sms_fingerprint.dart';
import 'sms_ingestion_service.dart';
import 'sms_permission_service.dart';

export 'notification_access_setup_screen.dart';

final notificationPermissionServiceProvider =
    Provider<NotificationPermissionService>((ref) {
      return NotificationPermissionService();
    });

final notificationAccessStatusProvider = FutureProvider<bool>((ref) async {
  return ref.read(notificationPermissionServiceProvider).isAccessEnabled();
});

final smsPermissionServiceProvider = Provider<SmsPermissionService>((ref) {
  return SmsPermissionService();
});

final smsPermissionStatusProvider = FutureProvider<bool>((ref) async {
  return ref.read(smsPermissionServiceProvider).isPermissionGranted();
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
    state = next.take(20).toList(growable: false);
  }
}

final notificationIngestionServiceProvider =
    Provider<NotificationIngestionService>((ref) {
      return NotificationIngestionService(
        database: ref.read(appDatabaseProvider),
        pendingIngestionService: ref.read(pendingIngestionServiceProvider),
        keywordFilter: NotificationKeywordFilter(),
        fingerprint: NotificationFingerprint(),
        localNotifier: ref.read(notificationLocalNotifierProvider),
        isDetectionEnabled: () =>
            ref.read(notificationDetectionEnabledProvider),
        shouldShowDetectionNotifications: () =>
            ref.read(showDetectionNotificationsProvider),
        appendDebug: ref.read(notificationDebugLogProvider.notifier).append,
      );
    });

final smsIngestionServiceProvider = Provider<SmsIngestionService>((ref) {
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
    appendDebug: ref.read(notificationDebugLogProvider.notifier).append,
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
  final bridge = ref.read(notificationBridgeProvider);
  final notificationIngestion = ref.read(notificationIngestionServiceProvider);
  final smsIngestion = ref.read(smsIngestionServiceProvider);
  ref.watch(reminderBootstrapProvider);

  Future<void> refreshSmsPermission() async {
    final granted = await ref
        .read(smsPermissionServiceProvider)
        .isPermissionGranted();
    ref.read(smsPermissionCachedProvider.notifier).state = granted;
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

  unawaited(refreshSmsPermission());

  unawaited(
    bridge.initialize(
      onPayload: (payload) async {
        if (payload.sourceType == 'sms') {
          await smsIngestion.processSmsPayload(payload);
          ref.invalidate(pendingTransactionsProvider);
          ref.invalidate(pendingCountProvider);
          return;
        }
        await notificationIngestion.processPayload(payload);
        ref.invalidate(pendingTransactionsProvider);
        ref.invalidate(pendingCountProvider);
      },
      onRoute: handleRoute,
    ),
  );

  ref.onDispose(() {
    unawaited(bridge.dispose());
  });
});
