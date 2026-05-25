import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/database/reset_data_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../accounts/data/accounts_providers.dart';
import '../../cards/data/cards_providers.dart';
import '../../dashboard/data/dashboard_providers.dart';
import '../../expenses/data/expenses_providers.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../onboarding/data/onboarding_providers.dart';
import '../../pending/data/pending_providers.dart';
import '../../pending/notifications/notification_providers.dart';
import '../../split/data/split_providers.dart';

class _LocalRowsSummary {
  const _LocalRowsSummary({
    required this.accounts,
    required this.cards,
    required this.transactions,
    required this.pending,
    required this.splits,
  });

  final int accounts;
  final int cards;
  final int transactions;
  final int pending;
  final int splits;
}

final _localRowsSummaryProvider = FutureProvider<_LocalRowsSummary>((
  ref,
) async {
  final db = ref.read(appDatabaseProvider);
  final banks = await db.select(db.bankAccounts).get();
  final wallets = await db.select(db.cashWallets).get();
  final cards = await db.select(db.creditCards).get();
  final txns = await db.select(db.transactions).get();
  final pending = await db.select(db.pendingTransactions).get();
  final splitGroups = await db.select(db.splitGroups).get();
  final splitMembers = await db.select(db.splitMembers).get();
  final splitExpenses = await db.select(db.splitExpenses).get();
  final splitShares = await db.select(db.splitExpenseShares).get();
  final splitSettlements = await db.select(db.splitSettlements).get();

  return _LocalRowsSummary(
    accounts: banks.length + wallets.length,
    cards: cards.length,
    transactions: txns.length,
    pending: pending.length,
    splits:
        splitGroups.length +
        splitMembers.length +
        splitExpenses.length +
        splitShares.length +
        splitSettlements.length,
  );
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessState = ref.watch(notificationAccessStatusProvider);
    final smsAccessState = ref.watch(smsPermissionStatusProvider);
    final settings = ref.watch(detectionSettingsProvider).valueOrNull;
    final onboardingDone = ref.watch(onboardingCompletedProvider).valueOrNull;
    final detectionEnabled = settings?.notificationDetectionEnabled ?? true;
    final smsDetectionEnabled = settings?.smsDetectionEnabled ?? false;
    final localRowsSummary = kDebugMode
        ? ref.watch(_localRowsSummaryProvider).valueOrNull
        : null;

    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Profile'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          FinarcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Setup Status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'First-run onboarding and local setup progress.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                FinarcStatusBadge(
                  label: onboardingDone == true
                      ? 'ONBOARDING COMPLETED'
                      : 'ONBOARDING PENDING',
                  tone: onboardingDone == true
                      ? FinarcStatusTone.success
                      : FinarcStatusTone.warning,
                  compact: true,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: FinarcSecondaryButton(
                        onPressed: () => context.push('/onboarding'),
                        label: 'Open Onboarding',
                        icon: Icons.flag_outlined,
                      ),
                    ),
                  ],
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(
                        child: FinarcSecondaryButton(
                          onPressed: () async {
                            await ref.read(onboardingActionsProvider).reset();
                            if (context.mounted) context.go('/onboarding');
                          },
                          label: 'Reset Onboarding (Debug)',
                          icon: Icons.restart_alt_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FinarcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Loans & EMIs',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Track loan outstanding, upcoming EMIs and payment history.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: FinarcSecondaryButton(
                        onPressed: () => context.push('/loans'),
                        label: 'Open Loans Dashboard',
                        icon: Icons.account_balance_outlined,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FinarcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notification Detection',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Reads transaction-like notifications locally and creates pending transactions for review.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                accessState.when(
                  loading: () => const FinarcStatusBadge(
                    label: 'Checking access...',
                    tone: FinarcStatusTone.neutral,
                    compact: true,
                  ),
                  error: (error, stackTrace) => const FinarcStatusBadge(
                    label: 'Access check failed',
                    tone: FinarcStatusTone.warning,
                    compact: true,
                  ),
                  data: (enabled) => FinarcStatusBadge(
                    label: enabled
                        ? 'NOTIFICATION ACCESS ENABLED'
                        : 'NOTIFICATION ACCESS DISABLED',
                    tone: enabled
                        ? FinarcStatusTone.success
                        : FinarcStatusTone.warning,
                    compact: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: FinarcSecondaryButton(
                        onPressed: () => context.push('/notifications/setup'),
                        label: 'Open Setup',
                        icon: Icons.settings_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Text(
                      'Detection enabled',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    Switch.adaptive(
                      value: detectionEnabled,
                      onChanged: (value) {
                        ref
                            .read(detectionSettingsProvider.notifier)
                            .applyChanges(notificationDetectionEnabled: value);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FinarcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SMS Detection',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Reads transaction-like SMS locally and creates pending entries for review.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                smsAccessState.when(
                  loading: () => const FinarcStatusBadge(
                    label: 'Checking SMS access...',
                    tone: FinarcStatusTone.neutral,
                    compact: true,
                  ),
                  error: (error, stackTrace) => const FinarcStatusBadge(
                    label: 'SMS access check failed',
                    tone: FinarcStatusTone.warning,
                    compact: true,
                  ),
                  data: (enabled) => FinarcStatusBadge(
                    label: enabled
                        ? 'SMS ACCESS ENABLED'
                        : 'SMS ACCESS DISABLED',
                    tone: enabled
                        ? FinarcStatusTone.success
                        : FinarcStatusTone.warning,
                    compact: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: FinarcSecondaryButton(
                        onPressed: () => context.push('/sms/setup'),
                        label: 'Open SMS Setup',
                        icon: Icons.sms_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Text(
                      'SMS detection enabled',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    Switch.adaptive(
                      value: smsDetectionEnabled,
                      onChanged: (value) {
                        ref
                            .read(detectionSettingsProvider.notifier)
                            .applyChanges(smsDetectionEnabled: value);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FinarcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data Controls',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Delete all local finance data and restart setup.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                FinarcSecondaryButton(
                  onPressed: () => _confirmResetAllData(context, ref),
                  label: 'Delete All Data & Start Fresh',
                  icon: Icons.delete_forever_outlined,
                ),
                if (kDebugMode && localRowsSummary != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Local rows: accounts ${localRowsSummary.accounts}, cards ${localRowsSummary.cards}, txns ${localRowsSummary.transactions}, pending ${localRowsSummary.pending}, splits ${localRowsSummary.splits}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const FinarcCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.dark_mode_outlined),
              title: Text('Theme toggle (placeholder)'),
              subtitle: Text(
                'Dark mode default is active. Full theme persistence controls are planned next.',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const FinarcCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.offline_bolt_rounded),
              title: Text('Offline-first mode'),
              subtitle: Text('All data is stored locally on device only.'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const FinarcCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.privacy_tip_outlined),
              title: Text('Privacy rules'),
              subtitle: Text(
                'No CVV, no expiry date storage, masked card numbers only, no cloud sync.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmResetAllData(BuildContext context, WidgetRef ref) async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete all data?'),
          content: const Text(
            'This permanently deletes all local Finarc data on this device. This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldReset != true) return;

    final verification = await ResetDataService(
      ref.read(appDatabaseProvider),
    ).wipeAllUserDataAndRestartOnboarding();

    ref.invalidate(dashboardProvider);
    ref.invalidate(accountsOverviewProvider);
    ref.invalidate(cardsOverviewProvider);
    ref.invalidate(expenseListProvider);
    ref.invalidate(pendingTransactionsProvider);
    ref.invalidate(pendingCountProvider);
    ref.invalidate(splitDashboardProvider);
    ref.invalidate(onboardingCompletedProvider);
    ref.invalidate(detectionSettingsProvider);
    ref.invalidate(_localRowsSummaryProvider);

    if (context.mounted) {
      if (!verification.isClean) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reset verification failed. Please try again.'),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All local data deleted. Starting fresh.'),
        ),
      );
      context.go('/onboarding');
    }
  }
}
