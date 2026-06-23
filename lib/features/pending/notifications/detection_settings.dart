import 'package:flutter/material.dart';

class DetectionSettings {
  const DetectionSettings({
    required this.notificationDetectionEnabled,
    required this.paymentAppNotificationsEnabled,
    required this.showDetectionNotifications,
    required this.reminderEnabled,
    required this.dailyReminderEnabled,
    required this.weeklyReminderEnabled,
    required this.reminderHour,
    required this.reminderMinute,
    required this.weeklyReminderWeekday,
    required this.cardDueReminderEnabled,
    required this.pendingTransactionReminderEnabled,
    required this.settlementReminderEnabled,
    required this.lastReminderShownAt,
    required this.smsDetectionEnabled,
    required this.smsPermissionAskedAt,
    required this.smsBackfillEnabled,
    required this.smsBackfillDays,
    required this.smsLastScannedAt,
    required this.quietHoursStartHour,
    required this.quietHoursStartMinute,
    required this.quietHoursEndHour,
    required this.quietHoursEndMinute,
    required this.smartAlertsEnabled,
    required this.lowBalanceAlertsEnabled,
    required this.lowBalanceThreshold,
    required this.largeExpenseAlertsEnabled,
    required this.largeExpenseThreshold,
    required this.unusualSpendingAlertsEnabled,
    required this.unusualSpendingMultiplier,
    required this.recurringMerchantAlertsEnabled,
    required this.weeklySummaryAlertsEnabled,
    required this.monthlySummaryAlertsEnabled,
  });

  final bool notificationDetectionEnabled;
  final bool paymentAppNotificationsEnabled;
  final bool showDetectionNotifications;
  final bool reminderEnabled;
  final bool dailyReminderEnabled;
  final bool weeklyReminderEnabled;
  final int reminderHour;
  final int reminderMinute;
  final int weeklyReminderWeekday;
  final bool cardDueReminderEnabled;
  final bool pendingTransactionReminderEnabled;
  final bool settlementReminderEnabled;
  final DateTime? lastReminderShownAt;
  final bool smsDetectionEnabled;
  final DateTime? smsPermissionAskedAt;
  final bool smsBackfillEnabled;
  final int smsBackfillDays;
  final DateTime? smsLastScannedAt;
  final int quietHoursStartHour;
  final int quietHoursStartMinute;
  final int quietHoursEndHour;
  final int quietHoursEndMinute;
  final bool smartAlertsEnabled;
  final bool lowBalanceAlertsEnabled;
  final double lowBalanceThreshold;
  final bool largeExpenseAlertsEnabled;
  final double largeExpenseThreshold;
  final bool unusualSpendingAlertsEnabled;
  final double unusualSpendingMultiplier;
  final bool recurringMerchantAlertsEnabled;
  final bool weeklySummaryAlertsEnabled;
  final bool monthlySummaryAlertsEnabled;

  TimeOfDay get reminderTime =>
      TimeOfDay(hour: reminderHour, minute: reminderMinute);

  DetectionSettings copyWith({
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
  }) {
    return DetectionSettings(
      notificationDetectionEnabled:
          notificationDetectionEnabled ?? this.notificationDetectionEnabled,
      paymentAppNotificationsEnabled:
          paymentAppNotificationsEnabled ?? this.paymentAppNotificationsEnabled,
      showDetectionNotifications:
          showDetectionNotifications ?? this.showDetectionNotifications,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      weeklyReminderEnabled:
          weeklyReminderEnabled ?? this.weeklyReminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      weeklyReminderWeekday:
          weeklyReminderWeekday ?? this.weeklyReminderWeekday,
      cardDueReminderEnabled:
          cardDueReminderEnabled ?? this.cardDueReminderEnabled,
      pendingTransactionReminderEnabled:
          pendingTransactionReminderEnabled ??
          this.pendingTransactionReminderEnabled,
      settlementReminderEnabled:
          settlementReminderEnabled ?? this.settlementReminderEnabled,
      lastReminderShownAt: clearLastReminderShownAt
          ? null
          : (lastReminderShownAt ?? this.lastReminderShownAt),
      smsDetectionEnabled: smsDetectionEnabled ?? this.smsDetectionEnabled,
      smsPermissionAskedAt: clearSmsPermissionAskedAt
          ? null
          : (smsPermissionAskedAt ?? this.smsPermissionAskedAt),
      smsBackfillEnabled: smsBackfillEnabled ?? this.smsBackfillEnabled,
      smsBackfillDays: smsBackfillDays ?? this.smsBackfillDays,
      smsLastScannedAt: clearSmsLastScannedAt
          ? null
          : (smsLastScannedAt ?? this.smsLastScannedAt),
      quietHoursStartHour: quietHoursStartHour ?? this.quietHoursStartHour,
      quietHoursStartMinute:
          quietHoursStartMinute ?? this.quietHoursStartMinute,
      quietHoursEndHour: quietHoursEndHour ?? this.quietHoursEndHour,
      quietHoursEndMinute: quietHoursEndMinute ?? this.quietHoursEndMinute,
      smartAlertsEnabled: smartAlertsEnabled ?? this.smartAlertsEnabled,
      lowBalanceAlertsEnabled:
          lowBalanceAlertsEnabled ?? this.lowBalanceAlertsEnabled,
      lowBalanceThreshold: lowBalanceThreshold ?? this.lowBalanceThreshold,
      largeExpenseAlertsEnabled:
          largeExpenseAlertsEnabled ?? this.largeExpenseAlertsEnabled,
      largeExpenseThreshold:
          largeExpenseThreshold ?? this.largeExpenseThreshold,
      unusualSpendingAlertsEnabled:
          unusualSpendingAlertsEnabled ?? this.unusualSpendingAlertsEnabled,
      unusualSpendingMultiplier:
          unusualSpendingMultiplier ?? this.unusualSpendingMultiplier,
      recurringMerchantAlertsEnabled:
          recurringMerchantAlertsEnabled ?? this.recurringMerchantAlertsEnabled,
      weeklySummaryAlertsEnabled:
          weeklySummaryAlertsEnabled ?? this.weeklySummaryAlertsEnabled,
      monthlySummaryAlertsEnabled:
          monthlySummaryAlertsEnabled ?? this.monthlySummaryAlertsEnabled,
    );
  }

  static DetectionSettings defaults() {
    return const DetectionSettings(
      notificationDetectionEnabled: true,
      paymentAppNotificationsEnabled: true,
      showDetectionNotifications: true,
      reminderEnabled: false,
      dailyReminderEnabled: false,
      weeklyReminderEnabled: false,
      reminderHour: 20,
      reminderMinute: 0,
      weeklyReminderWeekday: DateTime.monday,
      cardDueReminderEnabled: true,
      pendingTransactionReminderEnabled: true,
      settlementReminderEnabled: false,
      lastReminderShownAt: null,
      smsDetectionEnabled: false,
      smsPermissionAskedAt: null,
      smsBackfillEnabled: false,
      smsBackfillDays: 7,
      smsLastScannedAt: null,
      quietHoursStartHour: 22,
      quietHoursStartMinute: 0,
      quietHoursEndHour: 7,
      quietHoursEndMinute: 0,
      smartAlertsEnabled: true,
      lowBalanceAlertsEnabled: true,
      lowBalanceThreshold: 2000,
      largeExpenseAlertsEnabled: true,
      largeExpenseThreshold: 10000,
      unusualSpendingAlertsEnabled: true,
      unusualSpendingMultiplier: 1.8,
      recurringMerchantAlertsEnabled: true,
      weeklySummaryAlertsEnabled: true,
      monthlySummaryAlertsEnabled: true,
    );
  }
}
