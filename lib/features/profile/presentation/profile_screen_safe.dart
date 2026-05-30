import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_info_provider.dart';
import '../../../core/config/app_mode.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../onboarding/data/onboarding_providers.dart';

class ProfileScreenSafe extends ConsumerWidget {
  const ProfileScreenSafe({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingDone = ref.watch(onboardingCompletedProvider).valueOrNull;
    final appVersion = ref.watch(appVersionProvider).valueOrNull ?? 'unknown';

    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Profile'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          FinarcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FinarcSectionHeader(title: 'Build Status'),
                const SizedBox(height: AppSpacing.sm),
                _line('App version', appVersion),
                _line('Build mode', AppModeConfig.label),
                _line(
                  'Onboarding',
                  onboardingDone == true ? 'Completed' : 'Pending',
                ),
                const SizedBox(height: AppSpacing.sm),
                const FinarcStatusBadge(
                  label: 'Notification listener enabled, SMS disabled',
                  tone: FinarcStatusTone.info,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FinarcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FinarcSectionHeader(title: 'Access Setup'),
                const SizedBox(height: AppSpacing.sm),
                FinarcPrimaryButton(
                  onPressed: () => context.push('/notifications/setup'),
                  icon: Icons.notifications_active_outlined,
                  label: 'Notification Access',
                ),
                const SizedBox(height: AppSpacing.xs),
                FinarcSecondaryButton(
                  onPressed: () => context.push('/sms/setup'),
                  icon: Icons.sms_outlined,
                  label: 'SMS Access (Unavailable)',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value),
        ],
      ),
    );
  }
}
