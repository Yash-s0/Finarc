import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../data/onboarding_providers.dart';

class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  ConsumerState<OnboardingFlowScreen> createState() =>
      _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _StepTemplate(
        title: 'Welcome to Finarc',
        subtitle:
            'Track expenses, cards, bills, cash, UPI, splits and loans. Works fully offline, and your data stays on device.',
        icon: Icons.wallet_rounded,
      ),
      _StepTemplate(
        title: 'Privacy-first by design',
        subtitle:
            'No cloud sync in v1. SMS/notification detection is optional. Detected transactions require confirmation. No CVV or card expiry is stored.',
        icon: Icons.privacy_tip_outlined,
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
        actions: [
          FinarcSecondaryButton(
            onPressed: () => context.push('/notifications/setup'),
            icon: Icons.notifications_outlined,
            label: 'Notification Setup',
          ),
          const SizedBox(height: AppSpacing.xs),
          FinarcSecondaryButton(
            onPressed: () => context.push('/sms/setup'),
            icon: Icons.sms_outlined,
            label: 'SMS Setup',
          ),
        ],
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
                        ? _finish
                        : () => _controller.nextPage(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                          ),
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

  Future<void> _finish() async {
    await ref.read(onboardingActionsProvider).complete();
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
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget>? actions;

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
