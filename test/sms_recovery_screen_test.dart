import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/core/database/database_providers.dart';
import 'package:finarc/core/theme/app_theme.dart';
import 'package:finarc/features/expenses/data/expenses_providers.dart';
import 'package:finarc/features/expenses/models/transaction_types.dart';
import 'package:finarc/features/pending/notifications/notification_payload.dart';
import 'package:finarc/features/pending/notifications/notification_providers.dart';
import 'package:finarc/features/pending/notifications/sms_permission_service.dart';
import 'package:finarc/features/pending/notifications/sms_recovery_screen.dart';
import 'package:finarc/features/pending/notifications/sms_recovery_service.dart';

class _FakeSmsPermissionService extends SmsPermissionService {
  bool granted = true;

  @override
  Future<bool> isPermissionGranted() async => granted;

  @override
  Future<bool> isReadPermissionGranted() async => granted;

  @override
  Future<bool> requestPermission() async {
    granted = true;
    return true;
  }

  @override
  Future<bool> requestReadPermission() async {
    granted = true;
    return true;
  }

  @override
  Future<void> openAppPermissionSettings() async {}
}

class _FakeSmsRecoveryService implements SmsRecoveryService {
  _FakeSmsRecoveryService({required this.onPreviewRange});

  Future<List<SmsBackfillPreview>> Function({
    required DateTime from,
    required DateTime to,
  })
  onPreviewRange;

  @override
  Future<SmsBackfillPreview> classifyPayload(
    NotificationPayload payload, {
    String? id,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<SmsBackfillImportResult> importPreviews(
    Iterable<SmsBackfillPreview> previews,
  ) async {
    final list = previews.toList(growable: false);
    return SmsBackfillImportResult(
      importedCount: list.where((preview) => preview.canImport).length,
      duplicateOrSkippedCount: 0,
      previews: list
          .map(
            (preview) => preview.copyWith(
              status: SmsBackfillPreviewStatus.imported,
              reason: 'Added as transaction',
              createdTransactionCount: 1,
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<List<SmsBackfillPreview>> previewLastDays(int days) {
    final now = DateTime.now();
    return onPreviewRange(
      from: now.subtract(Duration(days: days)),
      to: now,
    );
  }

  @override
  Future<List<SmsBackfillPreview>> previewRange({
    required DateTime from,
    required DateTime to,
  }) {
    return onPreviewRange(from: from, to: to);
  }
}

void main() {
  Future<void> pumpSmsRecovery(
    WidgetTester tester, {
    required _FakeSmsRecoveryService recoveryService,
    _FakeSmsPermissionService? permissionService,
    Size? surfaceSize,
  }) async {
    if (surfaceSize != null) {
      await tester.binding.setSurfaceSize(surfaceSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));
    }

    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          smsIngestionAvailableProvider.overrideWith((ref) async => true),
          smsPermissionStatusProvider.overrideWith((ref) async => true),
          smsReadPermissionStatusProvider.overrideWith((ref) async => true),
          smsPermissionServiceProvider.overrideWithValue(
            permissionService ?? _FakeSmsPermissionService(),
          ),
          smsRecoveryServiceProvider.overrideWithValue(recoveryService),
          paymentSourcesProvider.overrideWith(
            (ref) async =>
                const PaymentSourcesData(banks: [], cards: [], cashWallets: []),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const SmsRecoveryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('initial state is compact and hides import actions', (
    tester,
  ) async {
    await pumpSmsRecovery(
      tester,
      recoveryService: _FakeSmsRecoveryService(
        onPreviewRange: ({required from, required to}) async => const [],
      ),
    );

    expect(find.text('Recover past SMS'), findsOneWidget);
    expect(find.text('Recover past SMS'), findsOneWidget);
    expect(find.text('Preview first. Adds confirmed records.'), findsNothing);
    expect(find.text('No preview yet'), findsOneWidget);
    expect(find.text('Preview last 60 days'), findsOneWidget);
    expect(find.textContaining('Import selected'), findsNothing);
  });

  testWidgets('range selection updates preview button label', (tester) async {
    await pumpSmsRecovery(
      tester,
      recoveryService: _FakeSmsRecoveryService(
        onPreviewRange: ({required from, required to}) async => const [],
      ),
    );

    await tester.tap(find.text('Last 60 days'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Last 7 days').last);
    await tester.pumpAndSettle();

    expect(find.text('Preview last 7 days'), findsOneWidget);
  });

  testWidgets('scan shows loading then zero-result state', (tester) async {
    final completer = Completer<List<SmsBackfillPreview>>();
    await pumpSmsRecovery(
      tester,
      recoveryService: _FakeSmsRecoveryService(
        onPreviewRange: ({required from, required to}) => completer.future,
      ),
    );

    await tester.tap(find.text('Preview last 60 days'));
    await tester.pump();

    expect(find.text('Scanning SMS...'), findsOneWidget);
    expect(find.text('This may take a few seconds.'), findsOneWidget);
    expect(find.textContaining('Add selected'), findsNothing);

    completer.complete(const []);
    await tester.pumpAndSettle();

    expect(find.text('No transaction-like SMS found'), findsOneWidget);
    expect(
      find.text('Try a wider date range or check your SMS permissions.'),
      findsOneWidget,
    );
  });

  testWidgets('results show summary, compact rows, and gated actions', (
    tester,
  ) async {
    await pumpSmsRecovery(
      tester,
      surfaceSize: const Size(390, 844),
      recoveryService: _FakeSmsRecoveryService(
        onPreviewRange: ({required from, required to}) async => [
          _preview(
            id: 'ready',
            status: SmsBackfillPreviewStatus.importable,
            reason: 'Ready to import',
            merchant: 'Amazon',
            body: 'RAW BODY SHOULD STAY OUT OF THE ROW',
          ),
          _preview(
            id: 'duplicate',
            status: SmsBackfillPreviewStatus.duplicateLikely,
            reason: 'Likely already exists',
            merchant: 'OpenAI',
            body: 'Duplicate raw SMS body',
          ),
        ],
      ),
    );

    await tester.tap(find.text('Preview last 60 days'));
    await tester.pumpAndSettle();

    expect(find.text('2 SMS scanned'), findsOneWidget);
    expect(find.textContaining('2 transaction-like matches'), findsOneWidget);
    expect(find.text('Import selected (1)'), findsOneWidget);
    expect(find.text('Import all (1)'), findsOneWidget);
    expect(find.text('RAW BODY SHOULD STAY OUT OF THE ROW'), findsNothing);
    expect(find.text('Amazon'), findsOneWidget);
    expect(find.text('OpenAI'), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0, -160));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Clear (1)'));
    await tester.pumpAndSettle();

    final addSelected = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Import selected (0)'),
    );
    expect(addSelected.onPressed, isNull);

    await tester.tap(find.text('Duplicate 1'));
    await tester.pumpAndSettle();

    expect(find.text('OpenAI'), findsOneWidget);
    final duplicateCheckbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(duplicateCheckbox.onChanged, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('results remain overflow-free on a small viewport', (
    tester,
  ) async {
    await pumpSmsRecovery(
      tester,
      surfaceSize: const Size(360, 640),
      recoveryService: _FakeSmsRecoveryService(
        onPreviewRange: ({required from, required to}) async => [
          _preview(
            id: 'ready',
            status: SmsBackfillPreviewStatus.importable,
            reason: 'Ready to import',
            merchant: 'Amazon',
            body: 'Compact row body',
          ),
        ],
      ),
    );

    await tester.tap(find.text('Preview last 60 days'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -260));
    await tester.pumpAndSettle();

    expect(find.text('Import selected (1)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

SmsBackfillPreview _preview({
  required String id,
  required SmsBackfillPreviewStatus status,
  required String reason,
  required String merchant,
  required String body,
}) {
  final receivedAt = DateTime(2026, 8, 27, 10, 15);
  return SmsBackfillPreview(
    id: id,
    sender: 'VM-HDFCBK',
    body: body,
    receivedAt: receivedAt,
    status: status,
    reason: reason,
    payload: NotificationPayload(
      packageName: 'android.sms',
      sourceType: 'sms',
      receivedAt: receivedAt,
      sender: 'VM-HDFCBK',
      body: body,
    ),
    amount: 1299,
    merchant: merchant,
    category: 'Shopping',
    transactionDate: receivedAt,
    parserName: 'Card',
    paymentSourceType: PaymentSourceType.creditCard,
    paymentSourceId: 1,
  );
}
