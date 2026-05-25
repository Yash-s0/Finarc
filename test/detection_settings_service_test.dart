import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/features/pending/notifications/detection_settings_service.dart';

void main() {
  late AppDatabase db;
  late DetectionSettingsService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = DetectionSettingsService(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('loads defaults and persists updates', () async {
    final initial = await service.load();
    expect(initial.notificationDetectionEnabled, isTrue);
    expect(initial.showDetectionNotifications, isTrue);
    expect(initial.reminderEnabled, isFalse);
    expect(initial.smsDetectionEnabled, isFalse);
    expect(initial.smsBackfillDays, 7);

    await service.patch(
      notificationDetectionEnabled: false,
      showDetectionNotifications: false,
      reminderEnabled: true,
      dailyReminderEnabled: true,
      weeklyReminderEnabled: true,
      reminderHour: 8,
      reminderMinute: 45,
      weeklyReminderWeekday: DateTime.friday,
      cardDueReminderEnabled: false,
      pendingTransactionReminderEnabled: false,
      settlementReminderEnabled: true,
      lastReminderShownAt: DateTime(2026, 5, 25, 9, 0),
      smsDetectionEnabled: true,
      smsPermissionAskedAt: DateTime(2026, 5, 25, 8, 0),
      smsBackfillEnabled: true,
      smsBackfillDays: 14,
      smsLastScannedAt: DateTime(2026, 5, 25, 8, 30),
    );

    final updated = await service.load();
    expect(updated.notificationDetectionEnabled, isFalse);
    expect(updated.showDetectionNotifications, isFalse);
    expect(updated.reminderEnabled, isTrue);
    expect(updated.dailyReminderEnabled, isTrue);
    expect(updated.weeklyReminderEnabled, isTrue);
    expect(updated.reminderHour, 8);
    expect(updated.reminderMinute, 45);
    expect(updated.weeklyReminderWeekday, DateTime.friday);
    expect(updated.cardDueReminderEnabled, isFalse);
    expect(updated.pendingTransactionReminderEnabled, isFalse);
    expect(updated.settlementReminderEnabled, isTrue);
    expect(updated.lastReminderShownAt, DateTime(2026, 5, 25, 9, 0));
    expect(updated.smsDetectionEnabled, isTrue);
    expect(updated.smsPermissionAskedAt, DateTime(2026, 5, 25, 8, 0));
    expect(updated.smsBackfillEnabled, isTrue);
    expect(updated.smsBackfillDays, 14);
    expect(updated.smsLastScannedAt, DateTime(2026, 5, 25, 8, 30));
  });
}
