import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_mode.dart';
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
      builder: (context) {
        return AlertDialog(
          title: const Text('Allow Finarc notifications?'),
          content: const Text(
            'Finarc can send local reminders and alerts for detected pending transactions. You can continue without this and change it later from Profile.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Allow'),
            ),
          ],
        );
      },
    );

    if (!mounted || allow != true) return;
    await permissionService.requestPostNotificationsPermission();
  }

  @override
  Widget build(BuildContext context) {
    final smsSetupAvailable = AppModeConfig.isPersonalDebug;
    final pages = <Widget>[
      _StepTemplate(
        title: 'Welcome to Finarc',
        subtitle:
            'Track expenses, cards, bills, cash, UPI, splits and loans. Your first finance OS stays fast, local and private.',
        icon: Icons.wallet_rounded,
        accent: _OnboardingAccent.info,
        chips: const ['No account', 'Local ledger', 'Manual control'],
        supporting: const [
          _ExpandableFeatureTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy-first',
            description: 'Your records stay on this device.',
            expandedDescription:
                'Your data stays on your device, no account is required, and there is no cloud sync in v1.',
          ),
          SizedBox(height: AppSpacing.xs),
          _ExpandableFeatureTile(
            icon: Icons.cloud_off_outlined,
            title: 'Offline-first',
            description: 'Open, add and review records without cloud sync.',
            expandedDescription:
                'The app is built around local storage. Notification detection is optional, and detected transactions require confirmation before entering your ledger.',
          ),
          SizedBox(height: AppSpacing.xs),
          _ExpandableFeatureTile(
            icon: Icons.credit_card_outlined,
            title: 'Cards & bills',
            description: 'Follow statements, dues and utilization.',
            expandedDescription:
                'Track card spending and bill due dates without storing CVV or card expiry details.',
          ),
          SizedBox(height: AppSpacing.xs),
          _ExpandableFeatureTile(
            icon: Icons.groups_2_outlined,
            title: 'Split expenses',
            description: 'Keep shared spends, dues and settlements clear.',
            expandedDescription:
                'Use groups to split costs and record settlements while keeping your personal ledger separate.',
          ),
          SizedBox(height: AppSpacing.xs),
          _ExpandableFeatureTile(
            icon: Icons.replay_circle_filled_outlined,
            title: 'Recoverables',
            description: 'Track money paid for others until it comes back.',
            expandedDescription:
                'Mark recoveries when friends, family or work reimburse you, while keeping original spends traceable.',
          ),
          SizedBox(height: AppSpacing.xs),
          _ExpandableFeatureTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Loans',
            description: 'Follow outstanding balances and EMI payments.',
            expandedDescription:
                'Loans stay separate from daily expenses, with optional EMI details for local planning.',
          ),
        ],
      ),
      _SetupChoicesStep(
        onAddBank: () => context.push('/accounts/add?type=bank'),
        onAddCash: () => context.push('/accounts/add?type=cash'),
        onAddCard: () => context.push('/cards/add'),
      ),
      _StepTemplate(
        title: 'Optional detection setup',
        subtitle: smsSetupAvailable
            ? 'Enable notification or SMS detection now, or turn it on later from Profile. Detection is optional and local-only.'
            : 'Enable notification detection now, or turn it on later from Profile. SMS ingestion is unavailable in this Play-safe build.',
        icon: Icons.notifications_active_outlined,
        accent: _OnboardingAccent.warning,
        chips: const ['Optional', 'Pending first', 'Profile controls'],
        supporting: [
          const _BulletPanel(
            title: 'How it works',
            bullets: [
              'Notification detection is optional',
              'Detected transactions go to Pending first',
              'You can enable or disable this later from Profile',
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          FinarcSecondaryButton(
            onPressed: () => context.push('/notifications/setup'),
            icon: Icons.notifications_outlined,
            label: 'Notification Setup',
          ),
          if (!smsSetupAvailable)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.xs),
              child: _InlineInfoCard(
                icon: Icons.sms_failed_outlined,
                title: 'SMS setup unavailable in this build',
                description:
                    'Play-safe and release builds do not include SMS ingestion.',
              ),
            ),
        ],
        actions: [
          if (smsSetupAvailable) ...[
            FinarcSecondaryButton(
              onPressed: () => context.push('/sms/setup'),
              icon: Icons.sms_outlined,
              label: 'SMS Setup',
            ),
          ],
        ],
      ),
      _ProfileSetupStep(
        nameController: _name,
        salaryController: _salary,
        salaryDayController: _salaryDay,
        companyController: _company,
        onSkipName: _skipNameAndContinue,
      ),
      _StepTemplate(
        title: 'You’re ready to track smarter',
        subtitle:
            'Your local finance workspace is ready. Add accounts anytime, confirm detected transactions before they enter your ledger, and keep your data on device.',
        icon: Icons.check_circle_outline,
        accent: _OnboardingAccent.success,
        chips: const ['Ready', 'Local', 'Review before save'],
        supporting: const [
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
            description: 'Use Profile tools when you want a local backup.',
            expandedDescription:
                'Exports and imports are available from Profile so you can protect or move your local records intentionally.',
          ),
          SizedBox(height: AppSpacing.xs),
          _ExpandableFeatureTile(
            icon: Icons.verified_user_outlined,
            title: 'Your data stays local',
            description: 'Finarc v1 keeps your finance data on this device.',
            expandedDescription:
                'Use Profile for backup and restore when you want to move or protect your records.',
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
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _index = i),
              children: pages,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 380;
                final isLast = _index == pages.length - 1;
                return Row(
                  children: [
                    Expanded(
                      child: FinarcSecondaryButton(
                        onPressed: _index == 0
                            ? null
                            : () => _controller.previousPage(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOut,
                              ),
                        icon: compact ? null : Icons.arrow_back_rounded,
                        label: 'Back',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FinarcPrimaryButton(
                        onPressed: isLast ? _finish : _onNext,
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
}

class _StepTemplate extends StatelessWidget {
  const _StepTemplate({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.accent = _OnboardingAccent.primary,
    this.chips = const [],
    this.actions,
    this.supporting,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final _OnboardingAccent accent;
  final List<String> chips;
  final List<Widget>? actions;
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
            icon: icon,
            title: title,
            subtitle: subtitle,
            accent: accent.resolve(context),
            chips: chips,
          ),
          if (supporting != null && supporting!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            ...supporting!,
          ],
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            ...actions!,
          ],
        ],
      ),
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
            icon: Icons.add_card_outlined,
            title: 'Set up your first account',
            subtitle:
                'Add a bank account, cash wallet or credit card now. You can also skip and add later.',
            accent: AppColors.lightAccent,
            chips: ['Optional', 'Add later', 'Local balances'],
          ),
          const SizedBox(height: AppSpacing.sm),
          const _ExpandableFeatureTile(
            icon: Icons.account_balance_outlined,
            title: 'Bank account',
            description: 'Track balances, transfers and salary deposits.',
            expandedDescription:
                'Use this for savings, salary and current accounts. Transfers and reconciliations stay in your local ledger.',
          ),
          const SizedBox(height: AppSpacing.xs),
          const _ExpandableFeatureTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Cash wallet',
            description: 'Track cash on hand and wallet-style balances.',
            expandedDescription:
                'Cash and wallet balances help you track offline spends without connecting an external service.',
          ),
          const SizedBox(height: AppSpacing.xs),
          const _ExpandableFeatureTile(
            icon: Icons.credit_card_outlined,
            title: 'Credit card',
            description: 'Track card spends, statements and bill dues.',
            expandedDescription:
                'Only masked card details are stored. CVV and expiry are never captured.',
          ),
          const SizedBox(height: AppSpacing.sm),
          FinarcPrimaryButton(
            onPressed: onAddBank,
            icon: Icons.account_balance_outlined,
            label: 'Add Bank Account',
          ),
          const SizedBox(height: AppSpacing.xs),
          FinarcSecondaryButton(
            onPressed: onAddCash,
            icon: Icons.account_balance_wallet_outlined,
            label: 'Add Cash Wallet',
          ),
          const SizedBox(height: AppSpacing.xs),
          FinarcSecondaryButton(
            onPressed: onAddCard,
            icon: Icons.credit_card_outlined,
            label: 'Add Credit Card',
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
    required this.onSkipName,
  });

  final TextEditingController nameController;
  final TextEditingController salaryController;
  final TextEditingController salaryDayController;
  final TextEditingController companyController;
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
          icon: Icons.person_outline,
          title: 'Tell us about you',
          subtitle:
              'Name and salary details are optional. Add them only if you want personalized local insights.',
          accent: AppColors.lightSuccess,
          chips: ['Optional profile', 'Local insights', 'Can skip'],
        ),
        const SizedBox(height: AppSpacing.sm),
        const _InlineInfoCard(
          icon: Icons.insights_outlined,
          title: 'Local insights only',
          description:
              'Salary details are optional and only used for on-device trends and reminders.',
        ),
        const SizedBox(height: AppSpacing.sm),
        FinarcTextField(controller: nameController, label: 'Your name'),
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
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [StripLeadingZeroFormatter()],
        ),
        const SizedBox(height: AppSpacing.sm),
        FinarcTextField(
          controller: salaryDayController,
          label: 'Salary credit day',
          keyboardType: TextInputType.number,
          inputFormatters: [StripLeadingZeroFormatter(allowDecimal: false)],
        ),
        const SizedBox(height: AppSpacing.sm),
        FinarcTextField(
          controller: companyController,
          label: 'Company name',
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    this.chips = const [],
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final List<String> chips;

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
              AnimatedContainer(
                duration: motionDuration,
                curve: Curves.easeOut,
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.16 : 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  icon,
                  color: isDark ? Colors.white : accent,
                  size: 24,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
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
