import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:finarc/shared/widgets/app_shell.dart';

void main() {
  testWidgets(
    'FAB is right floating with stable spacing on common phone widths',
    (tester) async {
      final router = GoRouter(
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) =>
                AppShell(navigationShell: navigationShell),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/',
                    builder: (context, state) =>
                        const Scaffold(body: Center(child: Text('home'))),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/expenses',
                    builder: (context, state) =>
                        const Scaffold(body: Center(child: Text('expenses'))),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/cards',
                    builder: (context, state) =>
                        const Scaffold(body: Center(child: Text('cards'))),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/split',
                    builder: (context, state) =>
                        const Scaffold(body: Center(child: Text('split'))),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/profile',
                    builder: (context, state) =>
                        const Scaffold(body: Center(child: Text('profile'))),
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      final widths = <double>[360, 393, 430];

      for (final width in widths) {
        await tester.binding.setSurfaceSize(Size(width, 800));
        await tester.pumpAndSettle();

        final fabFinder = find.byType(FloatingActionButton);
        final navFinder = find.byType(NavigationBar);

        expect(fabFinder, findsOneWidget);
        expect(navFinder, findsOneWidget);

        final fabRect = tester.getRect(fabFinder);
        final navRect = tester.getRect(navFinder);

        expect(fabRect.width, closeTo(50, 0.1));
        expect(fabRect.height, closeTo(50, 0.1));
        expect(width - fabRect.right, inInclusiveRange(16, 20));
        expect(navRect.top - fabRect.bottom, inInclusiveRange(28, 36));
      }

      await tester.binding.setSurfaceSize(null);
    },
  );
}
