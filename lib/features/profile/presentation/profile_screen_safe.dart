import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../dashboard/data/dashboard_providers.dart';
import '../data/profile_settings_providers.dart';
import '../data/profile_settings_service.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme_controller.dart';
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
              FinarcTextField(
                controller: company,
                label: 'Company Name',
                textInputAction: TextInputAction.done,
              ),
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
            companyName: profile?.companyName,
            onEdit: () => _showProfileEditSheet(context, ref, profile),
          ),
          const SizedBox(height: AppSpacing.sm),
          FinarcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FinarcSectionHeader(title: 'Access Setup'),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Notification listener is available in release. SMS features are intentionally unavailable.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                FinarcPrimaryButton(
                  onPressed: () => context.push('/notifications/setup'),
                  icon: Icons.notifications_active_outlined,
                  label: 'Notification Access',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          DataControlsEntryCard(
            onOpen: () => context.push(AppRoutes.profileDataControls),
          ),
          const SizedBox(height: AppSpacing.sm),
          ThemeSettingsSection(
            currentTheme: currentTheme,
            onThemeChanged: (theme) {
              ref.read(themeModeProvider.notifier).state = theme;
            },
          ),
        ],
      ),
    );
  }
}
