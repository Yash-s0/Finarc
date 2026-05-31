import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_info_provider.dart';
import '../../../core/config/app_mode.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../dashboard/data/dashboard_providers.dart';
import '../../onboarding/data/onboarding_providers.dart';
import '../data/profile_settings_providers.dart';
import '../data/profile_settings_service.dart';
import '../../../core/router/app_routes.dart';
import 'widgets/profile_sections.dart';

Future<void> _showProfileEditSheet(
  BuildContext context,
  WidgetRef ref,
  UserProfileSettings? profile,
) async {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController(text: profile?.name ?? '');
  final salary = TextEditingController(
    text: profile?.monthlySalary?.toString() ?? '',
  );
  final salaryDay = TextEditingController(
    text: profile?.salaryCreditDay?.toString() ?? '',
  );
  final company = TextEditingController(text: profile?.companyName ?? '');

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.md,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FinarcTextField(controller: name, label: 'Name'),
              const SizedBox(height: AppSpacing.xs),
              FinarcTextField(
                controller: salary,
                label: 'Monthly Salary',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return null;
                  final parsed = double.tryParse(text);
                  if (parsed == null || parsed <= 0) {
                    return 'Salary must be a positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              FinarcTextField(
                controller: salaryDay,
                label: 'Salary Credit Day',
                keyboardType: TextInputType.number,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return null;
                  final parsed = int.tryParse(text);
                  if (parsed == null || parsed < 1 || parsed > 31) {
                    return 'Day must be between 1 and 31';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              FinarcTextField(controller: company, label: 'Company Name'),
              const SizedBox(height: AppSpacing.sm),
              FinarcPrimaryButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  await ref
                      .read(profileSettingsServiceProvider)
                      .save(
                        UserProfileSettings(
                          name: name.text.trim(),
                          monthlySalary: double.tryParse(salary.text.trim()),
                          salaryCreditDay: (() {
                            final parsed = int.tryParse(salaryDay.text.trim());
                            if (parsed == null) return null;
                            if (parsed < 1 || parsed > 31) return null;
                            return parsed;
                          })(),
                          companyName: company.text.trim(),
                        ),
                      );
                  ref.invalidate(userProfileSettingsProvider);
                  ref.invalidate(dashboardProvider);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
                label: 'Save Profile',
                icon: Icons.check_circle_outline,
              ),
            ],
          ),
        ),
      );
    },
  );
}

class ProfileScreenSafe extends ConsumerWidget {
  const ProfileScreenSafe({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingDone = ref.watch(onboardingCompletedProvider).valueOrNull;
    final appVersion = ref.watch(appVersionProvider).valueOrNull ?? 'unknown';
    final profile = ref.watch(userProfileSettingsProvider).valueOrNull;

    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Profile'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          ProfileHeaderCard(
            name: profile?.name,
            monthlySalary: profile?.monthlySalary,
            salaryCreditDay: profile?.salaryCreditDay,
            companyName: profile?.companyName,
            onEdit: () => _showProfileEditSheet(context, ref, profile),
          ),
          const SizedBox(height: AppSpacing.sm),
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
          const SizedBox(height: AppSpacing.sm),
          FinarcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FinarcSectionHeader(title: 'Data Controls'),
                const SizedBox(height: AppSpacing.sm),
                FinarcPrimaryButton(
                  onPressed: () => context.push(AppRoutes.transactionImport),
                  icon: Icons.playlist_add_check_circle_outlined,
                  label: 'Import Transactions',
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
