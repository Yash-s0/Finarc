import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import 'detection_settings.dart';

class DetectionSettingsService {
  const DetectionSettingsService(this._db);

  final AppDatabase _db;

  Future<DetectionSettings> load() async {
    final row = await _ensureSettingsRow();
    return _mapRow(row);
  }

  Future<void> save(DetectionSettings settings) async {
    final row = await _ensureSettingsRow();
    await (_db.update(
      _db.appSettings,
    )..where((t) => t.id.equals(row.id))).write(
      AppSettingsCompanion(
        notificationDetectionEnabled: Value(
          settings.notificationDetectionEnabled,
        ),
        paymentAppNotificationsEnabled: Value(
          settings.paymentAppNotificationsEnabled,
        ),
        showDetectionNotifications: Value(settings.showDetectionNotifications),
        reminderEnabled: Value(settings.reminderEnabled),
        dailyReminderEnabled: Value(settings.dailyReminderEnabled),
        weeklyReminderEnabled: Value(settings.weeklyReminderEnabled),
        reminderHour: Value(settings.reminderHour),
        reminderMinute: Value(settings.reminderMinute),
        weeklyReminderWeekday: Value(settings.weeklyReminderWeekday),
        cardDueReminderEnabled: Value(settings.cardDueReminderEnabled),
        pendingTransactionReminderEnabled: Value(
          settings.pendingTransactionReminderEnabled,
        ),
        settlementReminderEnabled: Value(settings.settlementReminderEnabled),
        lastReminderShownAt: Value(settings.lastReminderShownAt),
        smsDetectionEnabled: Value(settings.smsDetectionEnabled),
        smsPermissionAskedAt: Value(settings.smsPermissionAskedAt),
        smsBackfillEnabled: Value(settings.smsBackfillEnabled),
        smsBackfillDays: Value(settings.smsBackfillDays),
        smsLastScannedAt: Value(settings.smsLastScannedAt),
        quietHoursStartHour: Value(settings.quietHoursStartHour),
        quietHoursStartMinute: Value(settings.quietHoursStartMinute),
        quietHoursEndHour: Value(settings.quietHoursEndHour),
        quietHoursEndMinute: Value(settings.quietHoursEndMinute),
        smartAlertsEnabled: Value(settings.smartAlertsEnabled),
        lowBalanceAlertsEnabled: Value(settings.lowBalanceAlertsEnabled),
        lowBalanceThreshold: Value(settings.lowBalanceThreshold),
        largeExpenseAlertsEnabled: Value(settings.largeExpenseAlertsEnabled),
        largeExpenseThreshold: Value(settings.largeExpenseThreshold),
        unusualSpendingAlertsEnabled: Value(
          settings.unusualSpendingAlertsEnabled,
        ),
        unusualSpendingMultiplier: Value(settings.unusualSpendingMultiplier),
        recurringMerchantAlertsEnabled: Value(
          settings.recurringMerchantAlertsEnabled,
        ),
        weeklySummaryAlertsEnabled: Value(settings.weeklySummaryAlertsEnabled),
        monthlySummaryAlertsEnabled: Value(
          settings.monthlySummaryAlertsEnabled,
        ),
      ),
    );
  }

  Future<void> patch({
    bool? notificationDetectionEnabled,
    bool? paymentAppNotificationsEnabled,
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
    final current = await load();
    await save(
      current.copyWith(
        notificationDetectionEnabled: notificationDetectionEnabled,
        paymentAppNotificationsEnabled: paymentAppNotificationsEnabled,
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
      ),
    );
  }

  Future<AppSetting> _ensureSettingsRow() async {
    final rows = await (_db.select(
      _db.appSettings,
    )..orderBy([(t) => OrderingTerm.desc(t.id)])).get();
    if (rows.isNotEmpty) {
      final primary = rows.first;
      if (rows.length > 1) {
        final extraIds = rows.skip(1).map((e) => e.id).toList(growable: false);
        await (_db.delete(
          _db.appSettings,
        )..where((t) => t.id.isIn(extraIds))).go();
      }
      return primary;
    }

    final id = await _db
        .into(_db.appSettings)
        .insert(
          AppSettingsCompanion.insert(
            isDarkMode: const Value(true),
            appLockEnabled: const Value(false),
          ),
        );
    return (_db.select(
      _db.appSettings,
    )..where((t) => t.id.equals(id))).getSingle();
  }

  DetectionSettings _mapRow(AppSetting row) {
    return DetectionSettings(
      notificationDetectionEnabled: row.notificationDetectionEnabled,
      paymentAppNotificationsEnabled: row.paymentAppNotificationsEnabled,
      showDetectionNotifications: row.showDetectionNotifications,
      reminderEnabled: row.reminderEnabled,
      dailyReminderEnabled: row.dailyReminderEnabled,
      weeklyReminderEnabled: row.weeklyReminderEnabled,
      reminderHour: row.reminderHour,
      reminderMinute: row.reminderMinute,
      weeklyReminderWeekday: row.weeklyReminderWeekday,
      cardDueReminderEnabled: row.cardDueReminderEnabled,
      pendingTransactionReminderEnabled: row.pendingTransactionReminderEnabled,
      settlementReminderEnabled: row.settlementReminderEnabled,
      lastReminderShownAt: row.lastReminderShownAt,
      smsDetectionEnabled: row.smsDetectionEnabled,
      smsPermissionAskedAt: row.smsPermissionAskedAt,
      smsBackfillEnabled: row.smsBackfillEnabled,
      smsBackfillDays: row.smsBackfillDays,
      smsLastScannedAt: row.smsLastScannedAt,
      quietHoursStartHour: row.quietHoursStartHour,
      quietHoursStartMinute: row.quietHoursStartMinute,
      quietHoursEndHour: row.quietHoursEndHour,
      quietHoursEndMinute: row.quietHoursEndMinute,
      smartAlertsEnabled: row.smartAlertsEnabled,
      lowBalanceAlertsEnabled: row.lowBalanceAlertsEnabled,
      lowBalanceThreshold: row.lowBalanceThreshold,
      largeExpenseAlertsEnabled: row.largeExpenseAlertsEnabled,
      largeExpenseThreshold: row.largeExpenseThreshold,
      unusualSpendingAlertsEnabled: row.unusualSpendingAlertsEnabled,
      unusualSpendingMultiplier: row.unusualSpendingMultiplier,
      recurringMerchantAlertsEnabled: row.recurringMerchantAlertsEnabled,
      weeklySummaryAlertsEnabled: row.weeklySummaryAlertsEnabled,
      monthlySummaryAlertsEnabled: row.monthlySummaryAlertsEnabled,
    );
  }
}
