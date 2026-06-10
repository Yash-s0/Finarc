import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_mode.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../../core/utils/numeric_input_formatters.dart';
import '../data/onboarding_providers.dart';

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
  bool _nameSkippedExplicitly = false;
  static const int _profileStepIndex = 4;

  @override
  void dispose() {
    _controller.dispose();
    _name.dispose();
    _salary.dispose();
    _salaryDay.dispose();
    _company.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final smsSetupAvailable = AppModeConfig.isPersonalDebug;
    final pages = <Widget>[
      _StepTemplate(
        title: 'Welcome to Finarc',
        subtitle:
            'Track expenses, cards, bills, cash, UPI, splits and loans. Works fully offline, and your data stays on device.',
        icon: Icons.wallet_rounded,
        supporting: const [
          _InfoTile(
            icon: Icons.receipt_long_outlined,
            title: 'Expenses',
            description: 'Track daily spends, categories and quick cashflow.',
          ),
          _InfoTile(
            icon: Icons.credit_card_outlined,
            title: 'Cards & bills',
            description:
                'Follow statements, dues and utilization in one place.',
          ),
          _InfoTile(
            icon: Icons.cloud_off_outlined,
            title: 'Offline-first',
            description:
                'Your records stay on-device with no required account.',
          ),
        ],
      ),
      _StepTemplate(
        title: 'Privacy-first by design',
        subtitle:
            'No cloud sync in v1. SMS/notification detection is optional. Detected transactions require confirmation. No CVV or card expiry is stored.',
        icon: Icons.privacy_tip_outlined,
        supporting: const [
          _BulletPanel(
            title: 'Trust guardrails',
            bullets: [
              'Local-only data storage',
              'No cloud account required',
              'Detected transactions stay pending until you confirm',
              'No CVV or card expiry is stored',
            ],
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
        subtitle:
            'You can enable notification and SMS detection later from Profile. It is optional and local-only.',
        icon: Icons.notifications_active_outlined,
        supporting: [
          const _BulletPanel(
            title: 'How it works',
            bullets: [
              'Notification detection is optional',
              'Detected transactions go to Pending first',
              'You can enable or disable this later from Profile',
            ],
          ),
          if (!smsSetupAvailable)
            const _InlineInfoCard(
              icon: Icons.sms_failed_outlined,
              title: 'SMS setup unavailable in this build',
              description:
                  'Play-safe and release builds do not include SMS ingestion.',
            ),
        ],
        actions: [
          FinarcSecondaryButton(
            onPressed: () => context.push('/notifications/setup'),
            icon: Icons.notifications_outlined,
            label: 'Notification Setup',
          ),
          if (smsSetupAvailable) ...[
            const SizedBox(height: AppSpacing.xs),
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
        onSkipName: () => setState(() => _nameSkippedExplicitly = true),
      ),
      _StepTemplate(
        title: 'Setup complete',
        subtitle:
            'You can continue setup anytime from Accounts, Cards or Profile. Finarc is ready.',
        icon: Icons.check_circle_outline,
      ),
    ];

    return FinarcScaffold(
      appBar: FinarcAppBar(
        title: 'First Run Setup',
        actions: [
          TextButton(
            onPressed: () => _finish(allowNameSkip: true),
            child: const Text('Skip'),
          ),
        ],
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
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _index = i),
              children: pages,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: FinarcSecondaryButton(
                    onPressed: _index == 0
                        ? null
                        : () => _controller.previousPage(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                          ),
                    icon: Icons.arrow_back_rounded,
                    label: 'Back',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FinarcPrimaryButton(
                    onPressed: _index == pages.length - 1
                        ? () => _finish()
                        : _onNext,
                    icon: _index == pages.length - 1
                        ? Icons.check_circle_outline
                        : Icons.arrow_forward_rounded,
                    label: _index == pages.length - 1 ? 'Finish Setup' : 'Next',
                  ),
                ),
              ],
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
    final name = _name.text.trim();
    final salaryText = _salary.text.trim();
    final salaryDayText = _salaryDay.text.trim();

    if (name.isEmpty && !_nameSkippedExplicitly) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add your name or choose "Skip name for now".'),
        ),
      );
      return false;
    }

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

  Future<void> _finish({bool allowNameSkip = false}) async {
    if (allowNameSkip) {
      _nameSkippedExplicitly = true;
    }
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
    this.actions,
    this.supporting,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget>? actions;
  final List<Widget>? supporting;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        FinarcCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 28),
              const SizedBox(height: AppSpacing.sm),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
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
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const FinarcCard(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.add_card_outlined, size: 28),
              SizedBox(height: AppSpacing.sm),
              Text('Set up your first account'),
              SizedBox(height: AppSpacing.xs),
              Text(
                'Add a bank account, cash wallet or credit card now. You can also skip and add later.',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const _InlineInfoCard(
          icon: Icons.account_balance_outlined,
          title: 'Bank account',
          description: 'Track balances, transfers and salary deposits.',
        ),
        const SizedBox(height: AppSpacing.xs),
        const _InlineInfoCard(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Cash wallet',
          description: 'Track cash on hand and wallet-style balances.',
        ),
        const SizedBox(height: AppSpacing.xs),
        const _InlineInfoCard(
          icon: Icons.credit_card_outlined,
          title: 'Credit card',
          description: 'Track card spends, statements and bill dues.',
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
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const FinarcCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FinarcSectionHeader(title: 'Tell us about you'),
              SizedBox(height: AppSpacing.xs),
              Text(
                'Name is strongly recommended. Salary details are optional and used for local insights.',
              ),
            ],
          ),
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

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: _InlineInfoCard(
        icon: icon,
        title: title,
        description: description,
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
    return FinarcCard(
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
                    decoration: const BoxDecoration(
                      color: AppColors.darkAccent,
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.darkBorder),
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
                color: AppColors.darkPrimarySoft,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: AppColors.darkAccent, size: 18),
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
