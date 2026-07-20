import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finarc/core/database/backup/backup_service.dart';
import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/core/database/database_providers.dart';
import 'package:finarc/features/pending/notifications/missed_message_sample_service.dart';
import 'package:finarc/features/pending/notifications/notification_ingestion_service.dart';
import 'package:finarc/features/profile/presentation/developer_space_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late MissedMessageSampleService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = MissedMessageSampleService(db);
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'records learning samples, classifies them, and dedupes repeats',
    () async {
      final billDue = _entry(
        reason: 'card-bill-due-mismatchAlert',
        parseResult: 'card-bill-due-notification',
        body: 'Credit card bill of ₹4,126.95 for Yes Bank card 8731 is due.',
      );
      final manualPaste = _entry(
        sourceType: 'manualPaste',
        packageName: 'manual-paste',
        title: 'Manual paste',
        decision: 'parsed',
        reason: 'manual-paste-parser-no-candidate',
        parseResult: 'parser-failed',
        body: 'Could not parse this sample.',
      );

      await service.recordFromDebugEntry(billDue);
      await service.recordFromDebugEntry(billDue);
      await service.recordFromDebugEntry(manualPaste);

      final all = await service.listSamples();
      expect(all, hasLength(2));
      expect(
        all.firstWhere((row) => row.sampleType == 'bill_due').seenCount,
        2,
      );
      expect(
        await service.listSamples(filter: MissedMessageSampleFilter.billDue),
        hasLength(1),
      );
      expect(
        await service.listSamples(
          filter: MissedMessageSampleFilter.manualPaste,
        ),
        hasLength(1),
      );

      final counts = await service.countsByFilter();
      expect(counts[MissedMessageSampleFilter.all], 2);
      expect(counts[MissedMessageSampleFilter.billDue], 1);
      expect(counts[MissedMessageSampleFilter.manualPaste], 1);
    },
  );

  test('does not persist normal pending-created samples', () async {
    await service.recordFromDebugEntry(
      _entry(
        decision: 'pending-created',
        reason: 'success',
        parseResult: 'parsed-pending-created',
        body: 'Paid ₹500 to Swiggy',
      ),
      createdPendingCount: 1,
    );

    expect(await service.listSamples(), isEmpty);
  });

  test('normal backup excludes missed-message sample text', () async {
    await service.recordFromDebugEntry(
      _entry(
        reason: 'parser-no-candidate',
        parseResult: 'parser-failed',
        body: 'Private parser sample that should not enter normal backup.',
      ),
    );

    final backup = await BackupService(db).createBackupJson();

    expect(backup, isNot(contains('missedMessageSamples')));
    expect(backup, isNot(contains('Private parser sample')));
  });

  testWidgets('Developer Space filters persisted samples', (tester) async {
    await service.recordFromDebugEntry(
      _entry(
        reason: 'card-payment-pendingCreated',
        parseResult: 'card-payment-notification',
        body: 'Payment received towards your credit card.',
      ),
    );
    await service.recordFromDebugEntry(
      _entry(
        reason: 'parser-no-candidate',
        parseResult: 'parser-failed',
        body: 'Unparsed transfer wording.',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: DeveloperSpaceScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Card payment'), findsWidgets);
    expect(find.text('Payment received towards your credit card.'), findsOne);
    expect(find.text('Unparsed transfer wording.'), findsOne);

    await tester.tap(find.textContaining('Parser failed').first);
    await tester.pumpAndSettle();

    expect(
      find.text('Payment received towards your credit card.'),
      findsNothing,
    );
    expect(find.text('Unparsed transfer wording.'), findsOne);
  });
}

NotificationDebugEntry _entry({
  String sourceType = 'appNotification',
  String packageName = 'com.example.bank',
  String title = 'Bank',
  String decision = 'parsed',
  required String reason,
  required String parseResult,
  required String body,
}) {
  return NotificationDebugEntry(
    receivedAt: DateTime(2026, 7, 20, 12),
    packageName: packageName,
    title: title,
    bodyPreview: body,
    decision: decision,
    reason: reason,
    sourceType: sourceType,
    result: parseResult,
    parseResult: parseResult,
  );
}
