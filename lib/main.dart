import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/onboarding/data/onboarding_providers.dart';
import 'features/pending/notifications/notification_providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: FinarcApp()));
}

class FinarcApp extends ConsumerWidget {
  const FinarcApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(notificationListenerBootstrapProvider);
    final onboardingState = ref.watch(onboardingCompletedProvider);
    onboardingState.whenData((completed) {
      final path = appRouter.routeInformationProvider.value.uri.path;
      if (!completed && path != '/onboarding') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          appRouter.go('/onboarding');
        });
      }
      if (completed && path == '/onboarding') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          appRouter.go('/');
        });
      }
    });
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
