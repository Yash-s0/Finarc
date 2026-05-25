import 'package:flutter/material.dart';

class DetectionSettings {
  const DetectionSettings({
    required this.notificationDetectionEnabled,
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
  });

  final bool notificationDetectionEnabled;
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

  TimeOfDay get reminderTime =>
      TimeOfDay(hour: reminderHour, minute: reminderMinute);

  DetectionSettings copyWith({
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
  }) {
    return DetectionSettings(
      notificationDetectionEnabled:
          notificationDetectionEnabled ?? this.notificationDetectionEnabled,
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
    );
  }

  static DetectionSettings defaults() {
    return const DetectionSettings(
      notificationDetectionEnabled: true,
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
    );
  }
}
