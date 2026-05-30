import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/features/pending/notifications/detection_settings.dart';
import 'package:finarc/features/pending/notifications/notification_providers.dart';
import 'package:finarc/features/pending/notifications/sms_access_setup_screen.dart';
import 'package:finarc/features/pending/notifications/sms_permission_service.dart';

class _FakeDetectionSettingsController extends DetectionSettingsController {
  _FakeDetectionSettingsController(this._settings);

  final DetectionSettings _settings;

  @override
  Future<DetectionSettings> build() async => _settings;
}

void main() {
  const settings = DetectionSettings(
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
        'Finarc reads transaction notifications locally to suggest expenses. Data stays on your device. You confirm before anything is added.',
      ),
      findsOneWidget,
    );
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
}
