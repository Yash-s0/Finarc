import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../../core/utils/numeric_input_formatters.dart';
import '../../pending/notifications/notification_providers.dart';
import '../../pending/notifications/notification_permission_service.dart';
import '../../profile/data/salary_credit_schedule.dart';
import '../../profile/presentation/widgets/salary_credit_day_picker_field.dart';
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

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen>
    with WidgetsBindingObserver {
  final _controller = PageController();
  final _name = TextEditingController();
  final _salary = TextEditingController();
  final _nameFocus = FocusNode();
  final _salaryFocus = FocusNode();
  SalaryCreditSchedule? _salaryCreditSchedule;
  int _index = 0;
  static const int _profileStepIndex = 3;
  bool _notificationPromptHandled = false;
  bool _bankSetupOpened = false;
  bool _cashSetupOpened = false;
  bool _cardSetupOpened = false;
  bool _notificationSetupOpened = false;
  bool _smsSetupOpened = false;
  bool _detectionSkipPromptShown = false;
  bool _profileSkipPromptShown = false;
  bool _isFinishing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybePromptForAppNotifications();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _name.dispose();
    _salary.dispose();
    _nameFocus.dispose();
    _salaryFocus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    ref.invalidate(notificationAccessStatusProvider);
    ref.invalidate(notificationIngestionAvailableProvider);
    ref.invalidate(postNotificationsPermissionProvider);
    ref.invalidate(smsPermissionStatusProvider);
    ref.invalidate(smsIngestionAvailableProvider);
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
        title: 'Your data, your device',
        subtitle:
            'Finarc keeps your financial data on this device. No account or cloud sync is required.',
        icon: Icons.privacy_tip_outlined,
        showPreview: false,
        supporting: [
          _SimplePoint(
            icon: Icons.privacy_tip_outlined,
            title: 'Stored locally',
            description: 'Your data never leaves this device.',
            onTap: () => _showPrivacyTour(context),
          ),
          const SizedBox(height: AppSpacing.xs),
          const _SimplePoint(
            icon: Icons.pending_actions_outlined,
            title: 'You review first',
            description: 'Detected items are reviewed before saving.',
          ),
          const SizedBox(height: AppSpacing.xs),
          const _SimplePoint(
            icon: Icons.cloud_off_outlined,
            title: 'Works offline',
            description: 'Track your finances without an internet connection.',
          ),
        ],
      ),
      _SetupChoicesStep(
        bankOpened: _bankSetupOpened,
        cashOpened: _cashSetupOpened,
        cardOpened: _cardSetupOpened,
        onAddBank: () => _openSetup(
          '/accounts/add?type=bank',
          () => _bankSetupOpened = true,
        ),
        onAddCash: () => _openSetup(
          '/accounts/add?type=cash',
          () => _cashSetupOpened = true,
        ),
        onAddCard: () =>
            _openSetup('/cards/add', () => _cardSetupOpened = true),
        onSetUpLater: _goNext,
      ),
      _DetectionSetupStep(
        notificationSetupOpened: _notificationSetupOpened,
        smsSetupOpened: _smsSetupOpened,
        onOpenNotifications: () => _openSetup(
          '/notifications/setup',
          () => _notificationSetupOpened = true,
        ),
        onOpenSms: () => _openSetup('/sms/setup', () => _smsSetupOpened = true),
        onSetUpLater: () async {
          _detectionSkipPromptShown = true;
          await _goNext();
        },
      ),
      _ProfileSetupStep(
        nameController: _name,
        salaryController: _salary,
        salaryCreditSchedule: _salaryCreditSchedule,
        nameFocusNode: _nameFocus,
        salaryFocusNode: _salaryFocus,
        onSalaryCreditScheduleChanged: (schedule) =>
            setState(() => _salaryCreditSchedule = schedule),
        onSetUpLater: _setUpProfileLater,
      ),
      _ReadyStep(
        isLoading: _isFinishing,
        onStart: () => _finish(),
        onAddExpense: () => _finish(routeAfterComplete: '/expenses/add'),
      ),
    ];

    return FinarcScaffold(
      body: Column(
        children: [
          _OnboardingHeader(
            current: _index + 1,
            total: pages.length,
            showSkip: _index != pages.length - 1,
            isFinishing: _isFinishing,
            onSkip: _confirmSkipSetup,
          ),
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _index = i),
              children: pages,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: _CompactNavRow(
              canGoBack: _index != 0,
              isLoading: _isFinishing,
              onBack: _goBack,
              onNext: _index == pages.length - 1 ? null : _onNext,
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
    if (!await _confirmOptionalSkipIfNeeded()) return;
    await _goNext();
  }

  Future<void> _goNext() async {
    await _controller.nextPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Future<void> _goBack() async {
    await _controller.previousPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Future<void> _openSetup(String route, VoidCallback markOpened) async {
    setState(markOpened);
    await context.push(route);
    if (!mounted) return;
    ref.invalidate(notificationAccessStatusProvider);
    ref.invalidate(notificationIngestionAvailableProvider);
    ref.invalidate(postNotificationsPermissionProvider);
    ref.invalidate(smsPermissionStatusProvider);
    ref.invalidate(smsIngestionAvailableProvider);
  }

  Future<bool> _confirmOptionalSkipIfNeeded() async {
    if (_index == 2 &&
        !_detectionSkipPromptShown &&
        !_notificationSetupOpened &&
        !_smsSetupOpened) {
      _detectionSkipPromptShown = true;
      return _showSkipSheet(
        title: 'Skip detection setup?',
        description:
            'You can enable SMS or notification detection later from Profile. Manual entries still work.',
        continueLabel: 'Skip for now',
      );
    }
    if (_index == _profileStepIndex &&
        !_profileSkipPromptShown &&
        _name.text.trim().isEmpty &&
        _salary.text.trim().isEmpty &&
        _salaryCreditSchedule == null) {
      _profileSkipPromptShown = true;
      return _showSkipSheet(
        title: 'Skip profile details?',
        description:
            'Salary details only improve local insights. You can add them later from Profile.',
        continueLabel: 'Continue empty',
      );
    }
    return true;
  }

  bool _validateProfileInputs() {
    final salaryText = _salary.text.trim();

    if (salaryText.isNotEmpty) {
      final salary = double.tryParse(salaryText);
      if (salary == null || salary <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Monthly salary must be positive.')),
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _setUpProfileLater() async {
    _name.clear();
    _salary.clear();
    setState(() => _salaryCreditSchedule = null);
    FocusScope.of(context).unfocus();
    _profileSkipPromptShown = true;
    await _goNext();
  }

  Future<void> _finish({
    String? routeAfterComplete,
    bool discardProfile = false,
  }) async {
    if (_isFinishing) return;
    if (!discardProfile && !_validateProfileInputs()) return;

    final name = discardProfile ? '' : _name.text.trim();
    final salary = discardProfile ? null : double.tryParse(_salary.text.trim());
    final salarySchedule = discardProfile ? null : _salaryCreditSchedule;
    final salaryDay = salarySchedule?.rule == SalaryCreditRule.fixedDay
        ? salarySchedule?.fixedDay
        : null;
    final salaryRule = salarySchedule?.rule.storageValue;
    setState(() => _isFinishing = true);
    try {
      await ref
          .read(onboardingActionsProvider)
          .complete(
            userName: name.isEmpty ? null : name,
            monthlySalary: salary,
            salaryCreditDay: salaryDay,
            salaryCreditRule: salaryRule,
          );
      if (!mounted) return;
      context.go(routeAfterComplete ?? AppRoutes.home);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isFinishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Setup could not be saved. Try again.')),
      );
    }
  }

  Future<void> _confirmSkipSetup() async {
    final skip = await _showSkipSheet(
      title: 'Skip setup?',
      description:
          'You can add accounts, detection, and profile details later from Profile. Finarc will start with empty, local data.',
      continueLabel: 'Skip setup',
    );
    if (!skip) return;
    await _finish(discardProfile: true);
  }

  Future<bool> _showSkipSheet({
    required String title,
    required String description,
    required String continueLabel,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.72,
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
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(description, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.md),
              FinarcPrimaryButton(
                onPressed: () => Navigator.of(context).pop(true),
                icon: Icons.arrow_forward_rounded,
                label: continueLabel,
              ),
              const SizedBox(height: AppSpacing.xs),
              FinarcSecondaryButton(
                onPressed: () => Navigator.of(context).pop(false),
                icon: Icons.keyboard_return_rounded,
                label: 'Go back',
              ),
            ],
          ),
        ),
      ),
    );
    return result == true;
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

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({
    required this.current,
    required this.total,
    required this.showSkip,
    required this.isFinishing,
    required this.onSkip,
  });

  final int current;
  final int total;
  final bool showSkip;
  final bool isFinishing;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'First Run Setup',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (showSkip)
                TextButton(
                  onPressed: isFinishing ? null : onSkip,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 34),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                  ),
                  child: const Text('Skip setup'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            children: List.generate(
              total,
              (i) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i == total - 1 ? 0 : 5),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      color: i <= current - 1
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
          const SizedBox(height: AppSpacing.xs),
          _StepCounter(current: current, total: total),
        ],
      ),
    );
  }
}

class _StepTemplate extends StatelessWidget {
  const _StepTemplate({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.accent = _OnboardingAccent.primary,
    this.showPreview = true,
    this.supporting,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final _OnboardingAccent accent;
  final bool showPreview;
  final List<Widget>? supporting;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      children: [
        _HeroPanel(
          icon: icon,
          title: title,
          subtitle: subtitle,
          accent: accent.resolve(context),
          showPreview: showPreview,
        ),
        if (supporting != null && supporting!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          ...supporting!,
        ],
      ],
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
    required this.bankOpened,
    required this.cashOpened,
    required this.cardOpened,
    required this.onAddBank,
    required this.onAddCash,
    required this.onAddCard,
    required this.onSetUpLater,
  });

  final bool bankOpened;
  final bool cashOpened;
  final bool cardOpened;
  final VoidCallback onAddBank;
  final VoidCallback onAddCash;
  final VoidCallback onAddCard;
  final VoidCallback onSetUpLater;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      children: [
        const _HeroPanel(
          icon: Icons.add_card_outlined,
          title: 'Add your first account',
          subtitle: 'Add what you use today. You can always add more later.',
          accent: AppColors.lightAccent,
          showPreview: false,
        ),
        const SizedBox(height: AppSpacing.sm),
        _SetupOptionCard(
          icon: Icons.account_balance_outlined,
          title: 'Bank account',
          description: 'Track balances, transfers and salary deposits.',
          badge: bankOpened ? 'Opened' : 'Recommended',
          buttonLabel: 'Add Bank Account',
          onPressed: onAddBank,
          isPrimary: true,
          completed: bankOpened,
        ),
        const SizedBox(height: AppSpacing.xs),
        _SetupOptionCard(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Cash wallet',
          description: 'Track cash and wallet balances.',
          badge: cashOpened ? 'Opened' : null,
          buttonLabel: 'Add Wallet',
          onPressed: onAddCash,
          completed: cashOpened,
        ),
        const SizedBox(height: AppSpacing.xs),
        _SetupOptionCard(
          icon: Icons.credit_card_outlined,
          title: 'Credit card',
          description: 'Track card purchases, statements and due dates.',
          badge: cardOpened ? 'Opened' : null,
          buttonLabel: 'Add Card',
          onPressed: onAddCard,
          completed: cardOpened,
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: _TertiaryAction(
            onPressed: onSetUpLater,
            icon: Icons.schedule_outlined,
            label: 'Set up later',
          ),
        ),
      ],
    );
  }
}

class _SetupOptionCard extends StatelessWidget {
  const _SetupOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
    this.badge,
    this.isPrimary = false,
    this.completed = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? badge;
  final String buttonLabel;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final button = isPrimary
        ? _CompactGradientButton(
            onPressed: onPressed,
            icon: Icons.arrow_forward_rounded,
            label: buttonLabel,
          )
        : _CompactOutlineButton(
            onPressed: onPressed,
            icon: Icons.arrow_forward_rounded,
            label: buttonLabel,
          );

    Widget content({required bool inlineAction}) {
      final copy = Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xxs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                if (badge != null)
                  _OptionBadge(
                    label: badge!,
                    active: isPrimary || completed,
                    icon: completed ? Icons.check_rounded : null,
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(description, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isPrimary ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              copy,
              if (inlineAction) ...[
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 122,
                  child: _CompactOutlineButton(
                    onPressed: onPressed,
                    icon: Icons.arrow_forward_rounded,
                    label: buttonLabel,
                  ),
                ),
              ],
            ],
          ),
          if (!inlineAction) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: isPrimary ? Alignment.center : Alignment.centerRight,
              child: isPrimary
                  ? SizedBox(width: double.infinity, child: button)
                  : ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 150),
                      child: button,
                    ),
            ),
          ],
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final inlineAction = !isPrimary && constraints.maxWidth >= 310;
        return FinarcCard(
          backgroundColor: isDark
              ? AppColors.darkSurfaceLow
              : AppColors.lightSurfaceHigh,
          borderColor: isPrimary
              ? accent.withValues(alpha: 0.44)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          padding: const EdgeInsets.all(AppSpacing.sm),
          useShadow: false,
          radius: AppRadius.lg,
          child: content(inlineAction: inlineAction),
        );
      },
    );
  }
}

class _OptionBadge extends StatelessWidget {
  const _OptionBadge({required this.label, required this.active, this.icon});

  final String label;
  final bool active;
  final IconData? icon;

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
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
            ],
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 78),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: color),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetectionSetupStep extends ConsumerWidget {
  const _DetectionSetupStep({
    required this.notificationSetupOpened,
    required this.smsSetupOpened,
    required this.onOpenNotifications,
    required this.onOpenSms,
    required this.onSetUpLater,
  });

  final bool notificationSetupOpened;
  final bool smsSetupOpened;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenSms;
  final VoidCallback onSetUpLater;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationAccess = ref.watch(notificationAccessStatusProvider);
    final smsAccess = ref.watch(smsPermissionStatusProvider);
    final notificationAvailable = ref.watch(
      notificationIngestionAvailableProvider,
    );
    final smsAvailable = ref.watch(smsIngestionAvailableProvider);

    return _StepTemplate(
      title: 'Detect transactions automatically',
      subtitle:
          'Finarc can detect payment notifications and SMS. You review everything before it reaches your ledger.',
      icon: Icons.notifications_active_outlined,
      accent: _OnboardingAccent.primary,
      showPreview: false,
      supporting: [
        _SetupStatusCard(
          icon: Icons.notifications_outlined,
          title: 'App notifications',
          description: 'Detect payment notifications in the background.',
          status: _accessLabel(
            notificationAccess,
            notificationAvailable,
            notificationSetupOpened,
          ),
          statusTone: _accessTone(
            notificationAccess,
            notificationAvailable,
            notificationSetupOpened,
          ),
          buttonLabel: _setupButtonLabel(
            notificationAccess,
            notificationAvailable,
          ),
          onPressed: _isAvailable(notificationAvailable)
              ? onOpenNotifications
              : null,
        ),
        const SizedBox(height: AppSpacing.xs),
        _SetupStatusCard(
          icon: Icons.sms_outlined,
          title: 'SMS detection',
          description: _isAvailable(smsAvailable)
              ? 'Scan transaction SMS for alerts.'
              : 'SMS detection is not available in this build.',
          status: _accessLabel(smsAccess, smsAvailable, smsSetupOpened),
          statusTone: _accessTone(smsAccess, smsAvailable, smsSetupOpened),
          buttonLabel: _setupButtonLabel(smsAccess, smsAvailable),
          onPressed: _isAvailable(smsAvailable) ? onOpenSms : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        const _SimplePoint(
          icon: Icons.notifications_active_outlined,
          title: "You'll get alerts",
          description:
              "We'll notify you when detected items are waiting for review.",
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: _TertiaryAction(
            onPressed: onSetUpLater,
            icon: Icons.schedule_outlined,
            label: 'Set up later',
          ),
        ),
      ],
    );
  }

  bool _isAvailable(AsyncValue<bool> availability) {
    return availability.valueOrNull == true;
  }

  String _accessLabel(
    AsyncValue<bool> state,
    AsyncValue<bool> availability,
    bool opened,
  ) {
    if (availability.isLoading) return 'Checking';
    if (availability.valueOrNull != true) return 'Unavailable';
    return state.maybeWhen(
      data: (enabled) {
        if (enabled) return 'Enabled';
        return opened ? 'Still off' : 'Not set up';
      },
      orElse: () => opened ? 'Checking' : 'Not set up',
    );
  }

  FinarcStatusTone _accessTone(
    AsyncValue<bool> state,
    AsyncValue<bool> availability,
    bool opened,
  ) {
    if (availability.isLoading) return FinarcStatusTone.info;
    if (availability.valueOrNull != true) return FinarcStatusTone.neutral;
    return state.maybeWhen(
      data: (enabled) {
        if (enabled) return FinarcStatusTone.success;
        return opened ? FinarcStatusTone.warning : FinarcStatusTone.neutral;
      },
      orElse: () => opened ? FinarcStatusTone.info : FinarcStatusTone.neutral,
    );
  }

  String _setupButtonLabel(
    AsyncValue<bool> state,
    AsyncValue<bool> availability,
  ) {
    if (availability.valueOrNull != true) return 'Unavailable';
    return state.maybeWhen(
      data: (enabled) => enabled ? 'Manage settings' : 'Set up',
      orElse: () => 'Set up',
    );
  }
}

class _SetupStatusCard extends StatelessWidget {
  const _SetupStatusCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
    required this.statusTone,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final String status;
  final FinarcStatusTone statusTone;
  final String buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceLow : AppColors.lightSurfaceHigh,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final action = _CompactOutlineButton(
            onPressed: onPressed,
            icon: Icons.arrow_forward_rounded,
            label: buttonLabel,
          );

          return Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SmallIconTile(icon: icon),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xxs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          FinarcStatusBadge(
                            label: status,
                            tone: statusTone,
                            compact: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Align(alignment: Alignment.centerRight, child: action),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SimplePoint extends StatelessWidget {
  const _SimplePoint({
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SmallIconTile(icon: icon, size: 34, iconSize: 17),
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
              const SizedBox(height: 2),
              Text(description, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: content,
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceLow : AppColors.lightSurfaceHigh,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.all(AppSpacing.sm),
        child: _SimplePoint(
          icon: Icons.lightbulb_outline,
          title: 'Used for local insights',
          description:
              'Salary and credit day help estimate monthly income trends.',
        ),
      ),
    );
  }
}

class _CompletionPanel extends StatelessWidget {
  const _CompletionPanel({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceLow : AppColors.lightSurfaceHigh,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: AppColors.darkSuccess.withValues(alpha: 0.16),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.darkSuccess.withValues(alpha: 0.45),
                ),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.darkSuccess,
                size: 34,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ReadyCheckItem extends StatelessWidget {
  const _ReadyCheckItem({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.darkPrimary, AppColors.darkAccent],
              ),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadyStep extends StatelessWidget {
  const _ReadyStep({
    required this.isLoading,
    required this.onStart,
    required this.onAddExpense,
  });

  final bool isLoading;
  final VoidCallback onStart;
  final VoidCallback onAddExpense;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      children: [
        _CompletionPanel(
          title: "You're ready to go!",
          subtitle:
              'Finarc is set up and ready for you. Start tracking expenses and take control of your finances.',
          children: const [
            _ReadyCheckItem(
              title: 'Local-first & private',
              description: 'Your data stays on this device.',
            ),
            _ReadyCheckItem(
              title: 'Accounts can be added anytime',
              description: 'Add bank, cash or cards later.',
            ),
            _ReadyCheckItem(
              title: 'Detection preferences saved',
              description: 'Detected items stay pending until review.',
            ),
            _ReadyCheckItem(
              title: 'Profile can be updated later',
              description: 'Name, salary and credit day remain optional.',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _CompactGradientButton(
          onPressed: isLoading ? null : onStart,
          isLoading: isLoading,
          icon: Icons.arrow_forward_rounded,
          label: 'Start using Finarc',
        ),
        const SizedBox(height: AppSpacing.xs),
        _CompactOutlineButton(
          onPressed: isLoading ? null : onAddExpense,
          icon: Icons.add_rounded,
          label: 'Add first expense',
        ),
      ],
    );
  }
}

class _SmallIconTile extends StatelessWidget {
  const _SmallIconTile({
    required this.icon,
    this.size = 40,
    this.iconSize = 20,
  });

  final IconData icon;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(icon, color: accent, size: iconSize),
    );
  }
}

class _ProfileSetupStep extends StatelessWidget {
  const _ProfileSetupStep({
    required this.nameController,
    required this.salaryController,
    required this.salaryCreditSchedule,
    required this.nameFocusNode,
    required this.salaryFocusNode,
    required this.onSalaryCreditScheduleChanged,
    required this.onSetUpLater,
  });

  final TextEditingController nameController;
  final TextEditingController salaryController;
  final SalaryCreditSchedule? salaryCreditSchedule;
  final FocusNode nameFocusNode;
  final FocusNode salaryFocusNode;
  final ValueChanged<SalaryCreditSchedule?> onSalaryCreditScheduleChanged;
  final VoidCallback onSetUpLater;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      children: [
        const _HeroPanel(
          icon: Icons.person_outline,
          title: 'Personalize your insights',
          subtitle:
              'Optional details help Finarc understand your monthly cash flow and show better insights.',
          accent: AppColors.lightAccent,
          showPreview: false,
        ),
        const SizedBox(height: AppSpacing.sm),
        _OnboardingFieldLabel(
          label: 'Name',
          child: FinarcTextField(
            controller: nameController,
            hint: 'e.g. Yash Sharma',
            focusNode: nameFocusNode,
            nextFocusNode: salaryFocusNode,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _OnboardingFieldLabel(
          label: 'Monthly salary',
          child: FinarcTextField(
            controller: salaryController,
            hint: '₹ 0',
            focusNode: salaryFocusNode,
            textInputAction: TextInputAction.done,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [StripLeadingZeroFormatter()],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _OnboardingFieldLabel(
          label: 'Salary credit day',
          child: SalaryCreditDayPickerField(
            value: salaryCreditSchedule,
            onChanged: onSalaryCreditScheduleChanged,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const _InsightCard(),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.center,
          child: _TertiaryAction(
            onPressed: onSetUpLater,
            icon: Icons.schedule_outlined,
            label: 'Set up later',
          ),
        ),
      ],
    );
  }
}

class _OnboardingFieldLabel extends StatelessWidget {
  const _OnboardingFieldLabel({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label (optional)',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        child,
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
    this.showPreview = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
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
          borderRadius: BorderRadius.circular(AppRadius.lg),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.darkHeroGradientEnd,
                    AppColors.darkSurface.withValues(alpha: 0.97),
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
          boxShadow: null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroIconBadge(icon: icon, accent: accent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(height: 1.35),
                    ),
                    if (showPreview) ...[
                      const SizedBox(height: AppSpacing.xs),
                      _HeroPreview(icon: icon, accent: accent),
                    ],
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

class _StepCounter extends StatelessWidget {
  const _StepCounter({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Flexible(
          fit: FlexFit.tight,
          child: Text(
            'Step $current of $total',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              _stepHint(current),
              maxLines: 1,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
              ),
            ),
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
        return 'Ready';
      default:
        return '';
    }
  }
}

class _CompactNavRow extends StatelessWidget {
  const _CompactNavRow({
    required this.canGoBack,
    required this.isLoading,
    required this.onBack,
    this.onNext,
  });

  final bool canGoBack;
  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final backButton = Expanded(
          child: _CompactOutlineButton(
            onPressed: canGoBack && !isLoading ? onBack : null,
            icon: compact ? null : Icons.arrow_back_rounded,
            leadingIcon: true,
            label: 'Back',
          ),
        );

        if (onNext == null) {
          return Row(
            children: [
              backButton,
              const SizedBox(width: AppSpacing.sm),
              const Spacer(),
            ],
          );
        }

        return Row(
          children: [
            backButton,
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _CompactGradientButton(
                onPressed: isLoading ? null : onNext,
                isLoading: isLoading,
                icon: compact ? null : Icons.arrow_forward_rounded,
                label: 'Next',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CompactGradientButton extends StatelessWidget {
  const _CompactGradientButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;
    final colors = Theme.of(context).brightness == Brightness.dark
        ? const [AppColors.darkPrimary, AppColors.darkAccent]
        : const [AppColors.lightPrimary, AppColors.lightAccent];
    return FilledButton(
      onPressed: disabled ? null : onPressed,
      style: FilledButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        disabledBackgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        minimumSize: const Size(0, 44),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: AnimatedOpacity(
          opacity: disabled ? 0.55 : 1,
          duration: const Duration(milliseconds: 160),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: isLoading
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : _ButtonLabel(label: label, icon: icon),
          ),
        ),
      ),
    );
  }
}

class _CompactOutlineButton extends StatelessWidget {
  const _CompactOutlineButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.leadingIcon = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool leadingIcon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      child: _ButtonLabel(label: label, icon: icon, leadingIcon: leadingIcon),
    );
  }
}

class _TertiaryAction extends StatelessWidget {
  const _TertiaryAction({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      ),
      child: _ButtonLabel(label: label, icon: icon, leadingIcon: true),
    );
  }
}

class _ButtonLabel extends StatelessWidget {
  const _ButtonLabel({
    required this.label,
    this.icon,
    this.leadingIcon = false,
  });

  final String label;
  final IconData? icon;
  final bool leadingIcon;

  @override
  Widget build(BuildContext context) {
    final labelWidget = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final iconWidget = icon == null ? null : Icon(icon, size: 17);
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconWidget != null && leadingIcon) ...[
            iconWidget,
            const SizedBox(width: AppSpacing.xs),
          ],
          labelWidget,
          if (iconWidget != null && !leadingIcon) ...[
            const SizedBox(width: AppSpacing.xs),
            iconWidget,
          ],
        ],
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
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Icon(icon, color: isDark ? Colors.white : accent, size: 22),
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
