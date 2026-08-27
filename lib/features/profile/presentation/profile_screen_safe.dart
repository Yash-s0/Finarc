import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../dashboard/data/dashboard_providers.dart';
import '../../onboarding/data/onboarding_providers.dart';
import '../data/profile_settings_providers.dart';
import '../data/profile_settings_service.dart';
import '../data/salary_credit_schedule.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme_controller.dart';
import 'widgets/profile_sections.dart';
import 'widgets/salary_credit_day_picker_field.dart';

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
  var salaryCreditSchedule = profile?.salaryCreditSchedule;
  final company = TextEditingController(text: profile?.companyName ?? '');

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
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
                  SalaryCreditDayPickerField(
                    label: 'Salary Credit Day',
                    value: salaryCreditSchedule,
                    onChanged: (schedule) =>
                        setSheetState(() => salaryCreditSchedule = schedule),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  FinarcTextField(
                    controller: company,
                    label: 'Company Name',
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FinarcPrimaryButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final salaryDay =
                          salaryCreditSchedule?.rule ==
                              SalaryCreditRule.fixedDay
                          ? salaryCreditSchedule?.fixedDay
                          : null;
                      await ref
                          .read(profileSettingsServiceProvider)
                          .save(
                            UserProfileSettings(
                              name: name.text.trim(),
                              monthlySalary: double.tryParse(
                                salary.text.trim(),
                              ),
                              salaryCreditDay: salaryDay,
                              salaryCreditRule:
                                  salaryCreditSchedule?.rule.storageValue,
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
    },
  );
}

class ProfileScreenSafe extends ConsumerWidget {
  const ProfileScreenSafe({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileSettingsProvider).valueOrNull;
    final currentTheme = ref.watch(themeModeProvider);

    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Profile'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          ProfileHeaderCard(
            name: profile?.name,
            monthlySalary: profile?.monthlySalary,
            salaryCreditDay: profile?.salaryCreditDay,
            salaryCreditRule: profile?.salaryCreditRule,
            companyName: profile?.companyName,
            onEdit: () => _showProfileEditSheet(context, ref, profile),
            onRedoOnboarding: () async {
              await ref.read(onboardingActionsProvider).reset();
              if (context.mounted) context.go(AppRoutes.onboarding);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          ThemeSettingsSection(
            currentTheme: currentTheme,
            onThemeChanged: (theme) {
              ref.read(themeModeProvider.notifier).state = theme;
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          FinarcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FinarcSectionHeader(title: 'Access Setup'),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Manage Android notification access so Finarc can detect transactions and surface pending items for review.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                FinarcPrimaryButton(
                  onPressed: () => context.push('/notifications/setup'),
                  icon: Icons.notifications_active_outlined,
                  label: 'Notification Access',
                ),
                const SizedBox(height: AppSpacing.xs),
                FinarcSecondaryButton(
                  onPressed: () => context.push(AppRoutes.smsRecovery),
                  icon: Icons.history_toggle_off_outlined,
                  label: 'Import Past SMS',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          DataControlsEntryCard(
            onOpen: () => context.push(AppRoutes.profileDataControls),
          ),
          const SizedBox(height: AppSpacing.sm),
          DeveloperSpaceEntryCard(
            onOpen: () => context.push(AppRoutes.developerSpace),
          ),
          const SizedBox(height: AppSpacing.sm),
          const DeveloperSignatureFooter(),
        ],
      ),
    );
  }
}
