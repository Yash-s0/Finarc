import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../../core/utils/numeric_input_formatters.dart';
import '../../pending/notifications/notification_permission_service.dart';
import '../data/onboarding_providers.dart';

final onboardingNotificationPermissionServiceProvider =
    Provider<NotificationPermissionService>((ref) {
      return NotificationPermissionService();
    });

class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  ConsumerState<OnboardingFlowScreen> createState() =>
      _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  final _controller = PageController();
  final _name = TextEditingController();
  final _salary = TextEditingController();
  final _salaryDay = TextEditingController();
  final _company = TextEditingController();
  final _nameFocus = FocusNode();
  final _salaryFocus = FocusNode();
  final _salaryDayFocus = FocusNode();
  final _companyFocus = FocusNode();
  int _index = 0;
  static const int _profileStepIndex = 3;
  bool _notificationPromptHandled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybePromptForAppNotifications();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _name.dispose();
    _salary.dispose();
    _salaryDay.dispose();
    _company.dispose();
    _nameFocus.dispose();
    _salaryFocus.dispose();
    _salaryDayFocus.dispose();
    _companyFocus.dispose();
    super.dispose();
  }

  Future<void> _maybePromptForAppNotifications() async {
    if (_notificationPromptHandled || !mounted) return;
    _notificationPromptHandled = true;

    if (defaultTargetPlatform != TargetPlatform.android) return;

    final permissionService = ref.read(
      onboardingNotificationPermissionServiceProvider,
    );
    final granted = await permissionService.isPostNotificationsGranted();
    if (!mounted || granted) return;

    final allow = await showDialog<bool>(
      context: context,
      builder: (context) => const _NotificationPermissionPrompt(),
    );

    if (!mounted || allow != true) return;
    await permissionService.requestPostNotificationsPermission();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _StepTemplate(
        stepLabel: 'Step 1 of 5',
        title: 'Private by default',
        subtitle: 'Track money on this device. No account. No cloud sync.',
        icon: Icons.wallet_rounded,
        accent: _OnboardingAccent.info,
        chips: const ['Offline-first', 'On-device', 'You approve'],
        showPreview: false,
        supporting: [
          _PopupGuideCard(
            icon: Icons.privacy_tip_outlined,
            title: 'Quick privacy tour',
            description: 'Local data, pending review and manual backups.',
            onTap: () => _showPrivacyTour(context),
          ),
          const SizedBox(height: AppSpacing.xs),
          const _ExpandableFeatureTile(
            icon: Icons.pending_actions_outlined,
            title: 'Review first',
            description: 'Detected transactions wait for confirmation.',
            expandedDescription:
                'SMS and notification parsing are helpers. They create pending items, not final transactions.',
          ),
          const SizedBox(height: AppSpacing.xs),
          const _ExpandableFeatureTile(
            icon: Icons.cloud_off_outlined,
            title: 'Offline-first',
            description: 'Use the app without a network connection.',
            expandedDescription:
                'Accounts, expenses, cards, splits and loans are stored locally. Backup and restore are manual Profile actions.',
          ),
        ],
      ),
      _SetupChoicesStep(
        onAddBank: () => context.push('/accounts/add?type=bank'),
        onAddCash: () => context.push('/accounts/add?type=cash'),
        onAddCard: () => context.push('/cards/add'),
      ),
      _StepTemplate(
        stepLabel: 'Step 3 of 5',
        title: 'Connect detection',
        subtitle:
            'Turn on SMS or notification detection now, or do it later from Profile.',
        icon: Icons.notifications_active_outlined,
        accent: _OnboardingAccent.warning,
        chips: const ['Optional', 'Local', 'Pending first'],
        showPreview: false,
        supporting: [
          Row(
            children: [
              Expanded(
                child: FinarcSecondaryButton(
                  onPressed: () => context.push('/notifications/setup'),
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: FinarcSecondaryButton(
                  onPressed: () => context.push('/sms/setup'),
                  icon: Icons.sms_outlined,
                  label: 'SMS Setup',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const _BulletPanel(
            title: 'You stay in control',
            bullets: [
              'Enable only the sources you want',
              'Review every detected item before saving',
              'Change this later from Profile',
            ],
          ),
        ],
      ),
      _ProfileSetupStep(
        nameController: _name,
        salaryController: _salary,
        salaryDayController: _salaryDay,
        companyController: _company,
        nameFocusNode: _nameFocus,
        salaryFocusNode: _salaryFocus,
        salaryDayFocusNode: _salaryDayFocus,
        companyFocusNode: _companyFocus,
        onSkipName: _skipNameAndContinue,
      ),
      _StepTemplate(
        stepLabel: 'Step 5 of 5',
        title: 'Ready',
        subtitle: 'Start with manual entries, detected pending items, or both.',
        icon: Icons.check_circle_outline,
        accent: _OnboardingAccent.success,
        chips: const ['Private', 'Flexible', 'Review-first'],
        showPreview: false,
        supporting: const [
          _InlineInfoCard(
            icon: Icons.verified_user_outlined,
            title: 'Privacy-first, everywhere',
            description:
                'Finarc keeps the same local-first model across expenses, cards, splits, loans and backups.',
          ),
          SizedBox(height: AppSpacing.xs),
          _ExpandableFeatureTile(
            icon: Icons.account_balance_outlined,
            title: 'Add accounts anytime',
            description: 'Bank accounts, wallets and cards can be added later.',
            expandedDescription:
                'You can start with an empty ledger and add accounts from the Accounts or Cards sections when ready.',
          ),
          SizedBox(height: AppSpacing.xs),
          _ExpandableFeatureTile(
            icon: Icons.pending_actions_outlined,
            title: 'Confirm detected transactions',
            description: 'Detected items stay pending until you review them.',
            expandedDescription:
                'Notification detection is designed as a helper, not an automatic writer. You stay in control.',
          ),
          SizedBox(height: AppSpacing.xs),
          _ExpandableFeatureTile(
            icon: Icons.notifications_active_outlined,
            title: 'Notification detection',
            description: 'Optional detection can be enabled later.',
            expandedDescription:
                'When supported, notification detection creates pending items for review instead of saving them automatically.',
          ),
          SizedBox(height: AppSpacing.xs),
          _ExpandableFeatureTile(
            icon: Icons.backup_outlined,
            title: 'Backup & restore',
            description: 'Export when you want a copy.',
            expandedDescription:
                'Exports and imports are available from Profile so you can protect or move your local records intentionally.',
          ),
        ],
      ),
    ];

    return FinarcScaffold(
      appBar: FinarcAppBar(
        title: 'First Run Setup',
        actions: [TextButton(onPressed: _finish, child: const Text('Skip'))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Row(
              children: List.generate(
                pages.length,
                (i) => Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      right: i == pages.length - 1 ? 0 : 6,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: i <= _index
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: _StepCounter(current: _index + 1, total: pages.length),
          ),
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _index = i),
              children: pages,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _OnboardingNavBar(
              canGoBack: _index != 0,
              isLast: _index == pages.length - 1,
              onBack: () => _controller.previousPage(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
              ),
              onNext: _index == pages.length - 1 ? _finish : _onNext,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onNext() async {
    if (_index == _profileStepIndex && !_validateProfileInputs()) {
      return;
    }
    await _controller.nextPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  bool _validateProfileInputs() {
    final salaryText = _salary.text.trim();
    final salaryDayText = _salaryDay.text.trim();

    if (salaryText.isNotEmpty) {
      final salary = double.tryParse(salaryText);
      if (salary == null || salary <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Monthly salary must be positive.')),
        );
        return false;
      }
    }

    if (salaryDayText.isNotEmpty) {
      final salaryDay = int.tryParse(salaryDayText);
      if (salaryDay == null || salaryDay < 1 || salaryDay > 31) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Salary credit day must be 1 to 31.')),
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _skipNameAndContinue() async {
    _name.clear();
    FocusScope.of(context).unfocus();
    await _controller.nextPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Future<void> _finish() async {
    if (!_validateProfileInputs()) return;

    final name = _name.text.trim();
    final salary = double.tryParse(_salary.text.trim());
    final rawSalaryDay = int.tryParse(_salaryDay.text.trim());
    final salaryDay = rawSalaryDay == null
        ? null
        : (rawSalaryDay >= 1 && rawSalaryDay <= 31 ? rawSalaryDay : null);
    final company = _company.text.trim();
    await ref
        .read(onboardingActionsProvider)
        .complete(
          userName: name.isEmpty ? null : name,
          monthlySalary: salary,
          salaryCreditDay: salaryDay,
          companyName: company.isEmpty ? null : company,
        );
    if (!mounted) return;
    context.go('/');
  }

  void _showPrivacyTour(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.82,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How privacy works',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'A quick tour before you start.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                const _TourPoint(
                  icon: Icons.phone_android_outlined,
                  title: 'Stored on this device',
                  description: 'Your ledger is local and works offline.',
                ),
                const SizedBox(height: AppSpacing.xs),
                const _TourPoint(
                  icon: Icons.fact_check_outlined,
                  title: 'Pending before saved',
                  description: 'Detected items wait for your confirmation.',
                ),
                const SizedBox(height: AppSpacing.xs),
                const _TourPoint(
                  icon: Icons.ios_share_outlined,
                  title: 'Backups are manual',
                  description: 'Export or restore only when you choose.',
                ),
                const SizedBox(height: AppSpacing.md),
                FinarcPrimaryButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icons.check_circle_outline,
                  label: 'Got it',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StepTemplate extends StatelessWidget {
  const _StepTemplate({
    required this.stepLabel,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.accent = _OnboardingAccent.primary,
    this.chips = const [],
    this.showPreview = true,
    this.supporting,
  });

  final String stepLabel;
  final String title;
  final String subtitle;
  final IconData icon;
  final _OnboardingAccent accent;
  final List<String> chips;
  final bool showPreview;
  final List<Widget>? supporting;

  @override
  Widget build(BuildContext context) {
    return _OnboardingExpansionScope(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        children: [
          _HeroPanel(
            stepLabel: stepLabel,
            icon: icon,
            title: title,
            subtitle: subtitle,
            accent: accent.resolve(context),
            chips: chips,
            showPreview: showPreview,
          ),
          if (supporting != null && supporting!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            ...supporting!,
          ],
        ],
      ),
    );
  }
}

class _NotificationPermissionPrompt extends StatelessWidget {
  const _NotificationPermissionPrompt();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.primary;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      color: accent.withValues(alpha: 0.16),
                    ),
                    child: Icon(
                      Icons.notifications_active_outlined,
                      color: accent,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Not now',
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Allow Finarc notifications?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Get local reminders when a pending transaction needs review.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              _PermissionPromptPoint(
                color: accent,
                icon: Icons.pending_actions_outlined,
                title: 'Pending alerts',
                description: 'Know when SMS or app detection finds a match.',
              ),
              const SizedBox(height: AppSpacing.xs),
              _PermissionPromptPoint(
                color: accent,
                icon: Icons.event_available_outlined,
                title: 'Bill reminders',
                description: 'Keep card dues and settlements visible.',
              ),
              const SizedBox(height: AppSpacing.xs),
              _PermissionPromptPoint(
                color: accent,
                icon: Icons.lock_outline,
                title: 'Still private',
                description: 'Alerts are local and can be changed later.',
              ),
              const SizedBox(height: AppSpacing.lg),
              FinarcPrimaryButton(
                onPressed: () => Navigator.of(context).pop(true),
                icon: Icons.check_circle_outline,
                label: 'Allow notifications',
              ),
              const SizedBox(height: AppSpacing.xs),
              FinarcSecondaryButton(
                onPressed: () => Navigator.of(context).pop(false),
                icon: Icons.schedule_outlined,
                label: 'Not now',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionPromptPoint extends StatelessWidget {
  const _PermissionPromptPoint({
    required this.color,
    required this.icon,
    required this.title,
    required this.description,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(description, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _SetupChoicesStep extends StatelessWidget {
  const _SetupChoicesStep({
    required this.onAddBank,
    required this.onAddCash,
    required this.onAddCard,
  });

  final VoidCallback onAddBank;
  final VoidCallback onAddCash;
  final VoidCallback onAddCard;

  @override
  Widget build(BuildContext context) {
    return _OnboardingExpansionScope(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        children: [
          const _HeroPanel(
            stepLabel: 'Step 2 of 5',
            icon: Icons.add_card_outlined,
            title: 'Set up your first account',
            subtitle:
                'Pick what you use. Each balance stays in your local ledger.',
            accent: AppColors.lightAccent,
            chips: ['Optional', 'Local balances', 'Add later'],
          ),
          const SizedBox(height: AppSpacing.sm),
          _SetupOptionCard(
            icon: Icons.account_balance_outlined,
            title: 'Bank account',
            description: 'Track balances, transfers and salary deposits.',
            badge: 'Best start',
            buttonLabel: 'Add Bank Account',
            onPressed: onAddBank,
            isPrimary: true,
          ),
          const SizedBox(height: AppSpacing.xs),
          _SetupOptionCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Cash wallet',
            description: 'Track cash on hand and wallet-style balances.',
            badge: 'Quick',
            buttonLabel: 'Add Cash Wallet',
            onPressed: onAddCash,
          ),
          const SizedBox(height: AppSpacing.xs),
          _SetupOptionCard(
            icon: Icons.credit_card_outlined,
            title: 'Credit card',
            description: 'Track card spends, statements and bill dues.',
            badge: 'Bills',
            buttonLabel: 'Add Credit Card',
            onPressed: onAddCard,
          ),
        ],
      ),
    );
  }
}

class _SetupOptionCard extends StatelessWidget {
  const _SetupOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.badge,
    required this.buttonLabel,
    required this.onPressed,
    this.isPrimary = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final String badge;
  final String buttonLabel;
  final VoidCallback onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final button = isPrimary
        ? FinarcPrimaryButton(
            onPressed: onPressed,
            icon: icon,
            label: buttonLabel,
          )
        : FinarcSecondaryButton(
            onPressed: onPressed,
            icon: icon,
            label: buttonLabel,
          );

    return FinarcCard(
      backgroundColor: isDark
          ? AppColors.darkSurfaceLow
          : AppColors.lightSurfaceHigh,
      borderColor: isPrimary
          ? accent.withValues(alpha: 0.44)
          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
      useShadow: isPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isPrimary ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              _OptionBadge(label: badge, active: isPrimary),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          button,
        ],
      ),
    );
  }
}

class _OptionBadge extends StatelessWidget {
  const _OptionBadge({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = active
        ? (isDark ? AppColors.darkAccent : AppColors.lightAccent)
        : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: active ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: color.withValues(alpha: active ? 0.32 : 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ),
    );
  }
}

class _PopupGuideCard extends StatelessWidget {
  const _PopupGuideCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    return FinarcCard(
      backgroundColor: accent.withValues(alpha: isDark ? 0.12 : 0.08),
      borderColor: accent.withValues(alpha: isDark ? 0.34 : 0.24),
      useShadow: false,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Icon(
            Icons.open_in_new_rounded,
            size: 18,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ],
      ),
    );
  }
}

class _ProfileSetupStep extends StatelessWidget {
  const _ProfileSetupStep({
    required this.nameController,
    required this.salaryController,
    required this.salaryDayController,
    required this.companyController,
    required this.nameFocusNode,
    required this.salaryFocusNode,
    required this.salaryDayFocusNode,
    required this.companyFocusNode,
    required this.onSkipName,
  });

  final TextEditingController nameController;
  final TextEditingController salaryController;
  final TextEditingController salaryDayController;
  final TextEditingController companyController;
  final FocusNode nameFocusNode;
  final FocusNode salaryFocusNode;
  final FocusNode salaryDayFocusNode;
  final FocusNode companyFocusNode;
  final VoidCallback onSkipName;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        const _HeroPanel(
          stepLabel: 'Step 4 of 5',
          icon: Icons.person_outline,
          title: 'Tell us about you',
          subtitle:
              'Optional details for local insights. Skip anything you do not need.',
          accent: AppColors.lightSuccess,
          chips: ['Optional profile', 'Local insights', 'Can skip'],
          showPreview: false,
        ),
        const SizedBox(height: AppSpacing.sm),
        const _InlineInfoCard(
          icon: Icons.insights_outlined,
          title: 'Local insights only',
          description:
              'Salary details are optional and only used for on-device trends and reminders.',
        ),
        const SizedBox(height: AppSpacing.sm),
        FinarcTextField(
          controller: nameController,
          label: 'Your name',
          focusNode: nameFocusNode,
          nextFocusNode: salaryFocusNode,
        ),
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onSkipName,
            child: const Text('Skip name for now'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        FinarcTextField(
          controller: salaryController,
          label: 'Monthly salary',
          focusNode: salaryFocusNode,
          nextFocusNode: salaryDayFocusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [StripLeadingZeroFormatter()],
        ),
        const SizedBox(height: AppSpacing.sm),
        FinarcTextField(
          controller: salaryDayController,
          label: 'Salary credit day',
          focusNode: salaryDayFocusNode,
          nextFocusNode: companyFocusNode,
          keyboardType: TextInputType.number,
          inputFormatters: [StripLeadingZeroFormatter(allowDecimal: false)],
        ),
        const SizedBox(height: AppSpacing.sm),
        FinarcTextField(
          controller: companyController,
          label: 'Company name',
          focusNode: companyFocusNode,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.stepLabel,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    this.chips = const [],
    this.showPreview = true,
  });

  final String stepLabel;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final List<String> chips;
  final bool showPreview;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reducedMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final motionDuration = reducedMotion
        ? Duration.zero
        : const Duration(milliseconds: 260);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.98, end: 1),
      duration: motionDuration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(opacity: reducedMotion ? 1 : value, child: child),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.darkHeroGradientEnd,
                    AppColors.darkSurface.withValues(alpha: 0.94),
                  ]
                : [
                    AppColors.lightHeroGradientStart,
                    AppColors.lightHeroGradientEnd,
                  ],
          ),
          border: Border.all(
            color: accent.withValues(alpha: isDark ? 0.36 : 0.24),
            width: 1,
          ),
          boxShadow: [
            ...(isDark ? AppShadows.heroGlow : AppShadows.heroGlowLight),
            BoxShadow(
              color: accent.withValues(alpha: isDark ? 0.14 : 0.08),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _StepPill(label: stepLabel, color: accent),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _HeroIconBadge(icon: icon, accent: accent),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              if (showPreview) ...[
                const SizedBox(height: AppSpacing.sm),
                _HeroPreview(icon: icon, accent: accent),
              ],
              if (chips.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: chips
                      .map((chip) => _HeroChip(label: chip, color: accent))
                      .toList(growable: false),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StepCounter extends StatelessWidget {
  const _StepCounter({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Text(
          'Step $current of $total',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
        const Spacer(),
        Text(
          _stepHint(current),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
          ),
        ),
      ],
    );
  }

  String _stepHint(int step) {
    switch (step) {
      case 1:
        return 'Privacy';
      case 2:
        return 'Accounts';
      case 3:
        return 'Detection';
      case 4:
        return 'Profile';
      case 5:
        return 'Finish';
      default:
        return '';
    }
  }
}

class _OnboardingNavBar extends StatelessWidget {
  const _OnboardingNavBar({
    required this.canGoBack,
    required this.isLast,
    required this.onBack,
    required this.onNext,
  });

  final bool canGoBack;
  final bool isLast;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface.withValues(alpha: 0.96)
            : AppColors.lightSurface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: isDark ? AppShadows.card : AppShadows.cardLight,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 380;
            return Row(
              children: [
                Expanded(
                  child: FinarcSecondaryButton(
                    onPressed: canGoBack ? onBack : null,
                    icon: compact ? null : Icons.arrow_back_rounded,
                    label: 'Back',
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: FinarcPrimaryButton(
                    onPressed: onNext,
                    icon: compact
                        ? null
                        : (isLast
                              ? Icons.check_circle_outline
                              : Icons.arrow_forward_rounded),
                    label: isLast
                        ? (compact ? 'Finish' : 'Finish Setup')
                        : 'Next',
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: color.withValues(alpha: 0.32)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 6,
          ),
          child: Text(label, style: Theme.of(context).textTheme.labelMedium),
        ),
      ),
    );
  }
}

class _HeroIconBadge extends StatelessWidget {
  const _HeroIconBadge({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Icon(icon, color: isDark ? Colors.white : accent, size: 24),
    );
  }
}

class _HeroPreview extends StatelessWidget {
  const _HeroPreview({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final previewColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.58);
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: previewColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Stack(
        children: [
          Positioned(
            left: AppSpacing.sm,
            top: AppSpacing.sm,
            bottom: AppSpacing.sm,
            child: _PreviewRail(color: accent),
          ),
          Positioned(
            left: 54,
            right: AppSpacing.sm,
            top: AppSpacing.sm,
            child: _PreviewLine(widthFactor: 0.92, color: accent),
          ),
          Positioned(
            left: 54,
            right: AppSpacing.xl,
            top: 30,
            child: _PreviewLine(widthFactor: 0.68, color: accent),
          ),
          Positioned(
            right: AppSpacing.sm,
            bottom: AppSpacing.sm,
            child: _PreviewAction(icon: icon, color: accent),
          ),
        ],
      ),
    );
  }
}

class _PreviewRail extends StatelessWidget {
  const _PreviewRail({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PreviewDot(color: color, active: true),
        Container(width: 2, height: 8, color: color.withValues(alpha: 0.26)),
        _PreviewDot(color: color),
      ],
    );
  }
}

class _PreviewDot extends StatelessWidget {
  const _PreviewDot({required this.color, this.active = false});

  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? 12 : 8,
      height: active ? 12 : 8,
      decoration: BoxDecoration(
        color: color.withValues(alpha: active ? 0.95 : 0.36),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({required this.widthFactor, required this.color});

  final double widthFactor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: 10,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
    );
  }
}

class _PreviewAction extends StatelessWidget {
  const _PreviewAction({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 5,
        ),
        child: Text(label, style: Theme.of(context).textTheme.labelMedium),
      ),
    );
  }
}

class _BulletPanel extends StatelessWidget {
  const _BulletPanel({required this.title, required this.bullets});

  final String title;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FinarcCard(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      borderColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          ...bullets.map(
            (bullet) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkAccent
                          : AppColors.lightAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      bullet,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingExpansionScope extends StatefulWidget {
  const _OnboardingExpansionScope({required this.child});

  final Widget child;

  static ValueNotifier<String?> of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_OnboardingExpansionController>();
    assert(scope != null, 'Expandable onboarding tiles require a scope.');
    return scope!.notifier!;
  }

  @override
  State<_OnboardingExpansionScope> createState() =>
      _OnboardingExpansionScopeState();
}

class _OnboardingExpansionScopeState extends State<_OnboardingExpansionScope> {
  final _expandedTile = ValueNotifier<String?>(null);

  @override
  void dispose() {
    _expandedTile.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _OnboardingExpansionController(
      notifier: _expandedTile,
      child: widget.child,
    );
  }
}

class _OnboardingExpansionController
    extends InheritedNotifier<ValueNotifier<String?>> {
  const _OnboardingExpansionController({
    required super.notifier,
    required super.child,
  });
}

class _ExpandableFeatureTile extends StatelessWidget {
  const _ExpandableFeatureTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.expandedDescription,
  });

  final IconData icon;
  final String title;
  final String description;
  final String expandedDescription;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = _OnboardingExpansionScope.of(context);
    return ValueListenableBuilder<String?>(
      valueListenable: controller,
      builder: (context, expandedTitle, _) {
        final expanded = expandedTitle == title;
        return FinarcCard(
          backgroundColor: isDark
              ? AppColors.darkSurfaceLow
              : AppColors.lightSurfaceHigh,
          borderColor: expanded
              ? (isDark ? AppColors.darkAccent : AppColors.lightAccent)
                    .withValues(alpha: 0.72)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          useShadow: false,
          onTap: () => controller.value = expanded ? null : title,
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkPrimarySoft
                          : AppColors.lightPrimarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      icon,
                      color: isDark
                          ? AppColors.darkAccent
                          : AppColors.lightAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                child: expanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            expandedDescription,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InlineInfoCard extends StatelessWidget {
  const _InlineInfoCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reducedMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, reducedMotion ? 0 : 10 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceLow : AppColors.lightSurfaceHigh,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkPrimarySoft
                      : AppColors.lightPrimarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  icon,
                  color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TourPoint extends StatelessWidget {
  const _TourPoint({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceLow : AppColors.lightSurfaceHigh,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: accent, size: 18),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _OnboardingAccent { primary, info, warning, success }

extension on _OnboardingAccent {
  Color resolve(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (this) {
      case _OnboardingAccent.primary:
        return isDark ? AppColors.darkAccent : AppColors.lightAccent;
      case _OnboardingAccent.info:
        return isDark ? AppColors.darkBlue : AppColors.lightBlue;
      case _OnboardingAccent.warning:
        return isDark ? AppColors.darkOrange : AppColors.lightOrange;
      case _OnboardingAccent.success:
        return isDark ? AppColors.darkMint : AppColors.lightMint;
    }
  }
}
