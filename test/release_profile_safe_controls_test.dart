import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:finarc/core/config/app_info_provider.dart';
import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/core/database/database_providers.dart';
import 'package:finarc/core/router/app_router_release.dart';
import 'package:finarc/core/router/app_routes.dart';
import 'package:finarc/features/profile/presentation/profile_data_controls_screen.dart';
import 'package:finarc/features/profile/presentation/profile_screen_safe.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets(
    'release-safe profile links to data controls and hides SMS/debug tools',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            appVersionProvider.overrideWith((ref) async => '1.0.0'),
          ],
          child: const MaterialApp(home: ProfileScreenSafe()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Profile & Salary'), findsOneWidget);
      expect(find.text('BUILD STATUS'), findsNothing);
      expect(find.text('Build mode'), findsNothing);
      expect(find.text('Notification Access'), findsOneWidget);

      expect(find.text('Data Controls'), findsOneWidget);
      expect(find.text('Open Data Controls'), findsOneWidget);
      expect(find.text('Import Transactions'), findsNothing);
      expect(find.text('Export Transactions CSV'), findsNothing);
      expect(find.text('Export Full Backup'), findsNothing);
      expect(find.text('Delete All Data & Start Fresh'), findsNothing);
      expect(find.textContaining('BACKUPS ARE UNENCRYPTED'), findsNothing);

      expect(find.textContaining('SMS Access'), findsNothing);
      expect(find.text('Open Debug Logs'), findsNothing);
      expect(find.text('Open Release Checklist'), findsNothing);
      expect(find.text('Notification Testing'), findsNothing);
    },
  );

  testWidgets('data controls screen shows backup/export/import controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: const ProfileDataControlsScreen(),
          routes: {
            AppRoutes.transactionImport: (_) =>
                const Scaffold(body: Text('Transaction import route')),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Data Controls'), findsWidgets);
    expect(find.text('Export Full Backup'), findsOneWidget);
    expect(find.text('Import Full Backup'), findsOneWidget);
    expect(find.text('Import Transactions'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Delete All Data & Start Fresh'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Export Transactions CSV'), findsOneWidget);
    expect(find.text('Export Expenses CSV'), findsOneWidget);
    expect(find.text('Export Accounts CSV'), findsOneWidget);
    expect(find.text('Export Cards CSV'), findsOneWidget);
    expect(find.text('Delete All Data & Start Fresh'), findsOneWidget);
    expect(
      find.textContaining('BACKUPS ARE UNENCRYPTED JSON/CSV FILES'),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Anyone with file access can read your financial data.',
      ),
      findsOneWidget,
    );
  });

  test('release-safe profile warns before CSV export', () async {
    final source = await File(
      'lib/features/profile/presentation/profile_data_controls_screen.dart',
    ).readAsString();

    expect(source, contains("title: Text('Export \$label?')"));
    expect(
      source,
      contains('This file contains financial data. Keep it private.'),
    );
  });

  test(
    'restore replace-all warning copy exists in release-safe profile',
    () async {
      final source = await File(
        'lib/features/profile/presentation/profile_data_controls_screen.dart',
      ).readAsString();

      expect(
        source,
        contains(
          'This will permanently replace all local Finarc data on this device.',
        ),
      );
      expect(
        source,
        contains(
          'Only import a backup file you trust. Existing local data will be deleted before restore.',
        ),
      );
    },
  );

  test('android manifest disables platform backups', () async {
    final manifest = await File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsString();

    expect(manifest, contains('android:allowBackup="false"'));
  });

  test(
    'release router includes data controls and transaction import routes',
    () {
      bool containsRoute(List<RouteBase> routes, String targetPath) {
        for (final route in routes) {
          if (route is GoRoute && route.path == targetPath) {
            return true;
          }
          if (route is ShellRouteBase &&
              containsRoute(route.routes, targetPath)) {
            return true;
          }
        }
        return false;
      }

      expect(
        containsRoute(
          appRouterRelease.configuration.routes,
          AppRoutes.profileDataControls,
        ),
        isTrue,
      );
      expect(
        containsRoute(
          appRouterRelease.configuration.routes,
          AppRoutes.transactionImport,
        ),
        isTrue,
      );
      expect(
        containsRoute(
          appRouterRelease.configuration.routes,
          AppRoutes.transactionImportPaste,
        ),
        isTrue,
      );
      expect(
        containsRoute(
          appRouterRelease.configuration.routes,
          AppRoutes.transactionImportPreview,
        ),
        isTrue,
      );
      expect(
        containsRoute(
          appRouterRelease.configuration.routes,
          AppRoutes.transactionImportResult,
        ),
        isTrue,
      );
      expect(
        containsRoute(
          appRouterRelease.configuration.routes,
          AppRoutes.transactionImportSampleFormat,
        ),
        isTrue,
      );
    },
  );
}
