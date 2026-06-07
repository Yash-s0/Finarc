import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/features/pending/notifications/detection_settings.dart';
import 'package:finarc/features/pending/notifications/notification_access_setup_screen_safe.dart';
import 'package:finarc/features/pending/notifications/notification_providers.dart';
import 'package:finarc/features/pending/notifications/sms_access_setup_screen.dart';
import 'package:finarc/features/pending/notifications/sms_permission_service.dart';

class _FakeDetectionSettingsController extends DetectionSettingsController {
  _FakeDetectionSettingsController(this._settings);

  final DetectionSettings _settings;

  @override
  Future<DetectionSettings> build() async => _settings;
}

class _MutableDetectionSettingsController extends DetectionSettingsController {
  _MutableDetectionSettingsController(this._settings);

  DetectionSettings _settings;

  @override
  Future<DetectionSettings> build() async => _settings;

  @override
  Future<void> applyChanges({
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
    _settings = _settings.copyWith(
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
    );
    state = AsyncValue.data(_settings);
  }
}

void main() {
  const settings = DetectionSettings(
    notificationDetectionEnabled: true,
    paymentAppNotificationsEnabled: false,
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

  List<Override> releaseOverrides() {
    return [
      notificationIngestionAvailableProvider.overrideWith((ref) async => true),
      smsIngestionAvailableProvider.overrideWith((ref) async => false),
      notificationAccessStatusProvider.overrideWith((ref) async => true),
      notificationListenerAvailableProvider.overrideWith((ref) async => true),
      smsPermissionStatusProvider.overrideWith((ref) async => false),
      smsReceiverAvailableProvider.overrideWith((ref) async => false),
      smsReceiverEnabledProvider.overrideWith((ref) async => false),
      smsPermissionRationaleProvider.overrideWith((ref) async => false),
      smsRuntimeDiagnosticsProvider.overrideWith(
        (ref) async => SmsRuntimeDiagnostics.empty,
      ),
      detectionSettingsProvider.overrideWith(
        () => _FakeDetectionSettingsController(settings),
      ),
    ];
  }

  testWidgets('release notification setup shows notification available', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: releaseOverrides(),
        child: const MaterialApp(home: NotificationAccessSetupScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Finarc only checks selected financial notifications and creates pending transactions for your confirmation. Chat and social apps are ignored.',
      ),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('UPI/payment app notifications'),
      300,
    );
    expect(find.text('UPI/payment app notifications'), findsOneWidget);
    final openSettingsButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Open Android Notification Access'),
    );
    expect(openSettingsButton.onPressed, isNotNull);
  });

  testWidgets('release SMS setup shows SMS unavailable', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: releaseOverrides(),
        child: const MaterialApp(home: SmsAccessSetupScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SMS NOT AVAILABLE IN THIS BUILD'), findsOneWidget);
    expect(
      find.text('SMS reading is not included in this Play-safe release build.'),
      findsOneWidget,
    );
    final enableSmsButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Enable SMS Access'),
    );
    expect(enableSmsButton.onPressed, isNull);
  });

  testWidgets('release-safe notification setup shows UPI toggle', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          detectionSettingsProvider.overrideWith(
            () => _FakeDetectionSettingsController(settings),
          ),
        ],
        child: const MaterialApp(home: NotificationAccessSetupScreenSafe()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('UPI/payment app notifications'), findsOneWidget);
    expect(
      find.text(
        'UPI/payment app notifications can improve detection but may create duplicates. You can turn them off anytime.',
      ),
      findsOneWidget,
    );
    final toggle = tester.widget<Switch>(find.byType(Switch).first);
    expect(toggle.value, isFalse);
  });

  testWidgets('release-safe notification setup toggle updates setting', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          detectionSettingsProvider.overrideWith(
            () => _MutableDetectionSettingsController(settings),
          ),
        ],
        child: const MaterialApp(home: NotificationAccessSetupScreenSafe()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    final toggle = tester.widget<Switch>(find.byType(Switch).first);
    expect(toggle.value, isTrue);
  });
}
