import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import 'onboarding_service.dart';

final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  return OnboardingService(ref.read(appDatabaseProvider));
});

final onboardingCompletedProvider = FutureProvider<bool>((ref) async {
  await ref.watch(seedProvider.future);
  return ref.read(onboardingServiceProvider).hasCompletedOnboarding();
});

final onboardingActionsProvider = Provider((ref) {
  Future<void> complete({
    String? userName,
    double? monthlySalary,
    int? salaryCreditDay,
    String? companyName,
  }) async {
    await ref
        .read(onboardingServiceProvider)
        .setCompleted(
          true,
          userName: userName,
          monthlySalary: monthlySalary,
          salaryCreditDay: salaryCreditDay,
          companyName: companyName,
        );
    ref.invalidate(onboardingCompletedProvider);
  }

  Future<void> reset() async {
    await ref.read(onboardingServiceProvider).setCompleted(false);
    ref.invalidate(onboardingCompletedProvider);
  }

  return (complete: complete, reset: reset);
});
