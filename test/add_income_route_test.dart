import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:finarc/core/router/app_router.dart';

void main() {
  test('add income route exists in app router', () {
    bool containsRoute(List<RouteBase> routes) {
      for (final route in routes) {
        if (route is GoRoute && route.path == '/income/add') {
          return true;
        }
        if (route is ShellRouteBase && containsRoute(route.routes)) {
          return true;
        }
      }
      return false;
    }

    expect(containsRoute(appRouter.configuration.routes), isTrue);
  });
}
