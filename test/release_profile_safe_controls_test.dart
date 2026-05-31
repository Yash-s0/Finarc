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
    'release-safe profile shows backup/export/import controls and hides SMS/debug tools',
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
      expect(find.text('BUILD STATUS'), findsOneWidget);
      expect(find.text('Build mode'), findsOneWidget);
      expect(find.text('Notification Access'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Import Transactions'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Import Transactions'), findsOneWidget);
      expect(find.text('Export Transactions CSV'), findsOneWidget);
      expect(find.text('Export Expenses CSV'), findsOneWidget);
      expect(find.text('Export Accounts CSV'), findsOneWidget);
      expect(find.text('Export Cards CSV'), findsOneWidget);
      expect(find.text('Export Full Backup'), findsOneWidget);
      expect(find.text('Import Full Backup'), findsOneWidget);
      expect(find.text('Delete All Data & Start Fresh'), findsOneWidget);

      expect(find.textContaining('SMS Access'), findsNothing);
      expect(find.text('Open Debug Logs'), findsNothing);
      expect(find.text('Open Release Checklist'), findsNothing);
      expect(find.text('Notification Testing'), findsNothing);
    },
  );

  test('release router includes transaction import routes', () {
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
  });
}
