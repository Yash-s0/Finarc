import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../data/accounts_providers.dart';

class AccountsOverviewScreen extends ConsumerWidget {
  const AccountsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountsOverviewProvider);

    return FinarcScaffold(
      appBar: FinarcAppBar(
        title: 'Accounts',
        actions: [
          IconButton(
            onPressed: () => context.push('/accounts/add'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: state.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: const [
            FinarcLoadingSkeleton(height: 190),
            SizedBox(height: AppSpacing.sm),
            FinarcLoadingSkeleton(height: 144),
          ],
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              'Liquid assets',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            FinarcCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'TOTAL LIQUID BALANCE',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const Spacer(),
                      FinarcStatusBadge(
                        label: data.liquid >= 0 ? 'Stable' : 'Attention',
                        tone: data.liquid >= 0
                            ? FinarcStatusTone.success
                            : FinarcStatusTone.warning,
                        compact: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    inr(data.liquid),
                    style: AppTextStyles.amountStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 32,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _breakdown(
                          context,
                          'Banks',
                          inr(data.bankTotal),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _breakdown(context, 'Cash', inr(data.cashTotal)),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FinarcPrimaryButton(
                    onPressed: () => context.push('/accounts/transfer'),
                    icon: Icons.swap_horiz,
                    label: 'Quick Transfer',
                  ),
                ],
              ),
            ),
            if (data.banks.isEmpty && data.wallets.isEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              FinarcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FinarcSectionHeader(title: 'Get Started'),
                    const SizedBox(height: AppSpacing.sm),
                    FinarcPrimaryButton(
                      onPressed: () => context.push('/accounts/add?type=bank'),
                      icon: Icons.account_balance_outlined,
                      label: 'Add Bank Account',
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    FinarcSecondaryButton(
                      onPressed: () => context.push('/accounts/add?type=cash'),
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Add Cash Wallet',
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            _section(
              context,
              title: 'Bank Accounts',
              child: data.banks.isEmpty
                  ? const FinarcEmptyState(
                      title: 'No bank accounts',
                      subtitle:
                          'Add a bank account to start tracking balances.',
                      icon: Icons.account_balance_outlined,
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < data.banks.length; i++) ...[
                          FinarcAccountTile(
                            onTap: () => context.push(
                              '/accounts/detail/bank/${data.banks[i].id}',
                            ),
                            title: data.banks[i].accountName,
                            subtitle:
                                '${data.banks[i].bankName} • ${_maskAccount(data.banks[i].id)}',
                            amount: inr(data.banks[i].currentBalance),
                            icon: Icons.account_balance,
                            badge: data.banks[i].accountType.toUpperCase(),
                            iconColor: AppColors.darkAccent,
                          ),
                          if (i != data.banks.length - 1)
                            const SizedBox(height: AppSpacing.xs),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _section(
              context,
              title: 'Cash Wallets',
              child: data.wallets.isEmpty
                  ? const FinarcEmptyState(
                      title: 'No cash wallets',
                      subtitle: 'Create a wallet to track cash movements.',
                      icon: Icons.payments_outlined,
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < data.wallets.length; i++) ...[
                          FinarcAccountTile(
                            onTap: () => context.push(
                              '/accounts/detail/cash/${data.wallets[i].id}',
                            ),
                            title: data.wallets[i].walletName,
                            subtitle: 'Cash wallet',
                            meta:
                                'Updated ${_shortDate(data.wallets[i].updatedAt)}',
                            amount: inr(data.wallets[i].currentBalance),
                            icon: Icons.account_balance_wallet_outlined,
                            badge: 'CASH',
                            iconColor: AppColors.darkWarning,
                          ),
                          if (i != data.wallets.length - 1)
                            const SizedBox(height: AppSpacing.xs),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _section(
              context,
              title: 'Recent Activity',
              child: data.recent.isEmpty
                  ? const FinarcEmptyState(
                      title: 'No recent activity',
                      subtitle:
                          'Transfers and reconciliation events will appear here.',
                      icon: Icons.history,
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < data.recent.length; i++) ...[
                          FinarcTransactionTile(
                            title: data.recent[i].title,
                            subtitle: data.recent[i].category,
                            meta:
                                '${_sourceLabel(data.recent[i].paymentSourceType)} • ${transactionDateLabel(data.recent[i].transactionDate)}',
                            amount:
                                '${_activitySign(data.recent[i].title)}${inr(data.recent[i].amount)}',
                            amountColor:
                                _activitySign(data.recent[i].title) == '-'
                                ? AppColors.darkError
                                : AppColors.darkSuccess,
                            prefix: const CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.darkPrimarySoft,
                              child: Icon(Icons.sync_alt_rounded, size: 16),
                            ),
                          ),
                          if (i != data.recent.length - 1)
                            const SizedBox(height: AppSpacing.xs),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _section(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FinarcSectionHeader(title: title),
        const SizedBox(height: AppSpacing.xs),
        FinarcCard(padding: const EdgeInsets.all(AppSpacing.sm), child: child),
      ],
    );
  }

  static Widget _breakdown(BuildContext context, String label, String amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          amount,
          style: AppTextStyles.amountStyle(
            color: Theme.of(context).colorScheme.onSurface,
            size: 15,
            weight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  static String _maskAccount(int id) {
    final s = id.toString().padLeft(4, '0');
    return '••$s';
  }

  static String _shortDate(DateTime dt) {
    final d = dt.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  }

  static String _activitySign(String title) {
    if (title.contains('Out')) return '-';
    if (title.contains('In') || title.contains('Adjustment')) return '+';
    return '';
  }

  static String _sourceLabel(String source) {
    if (source == 'creditCard') return 'Card';
    if (source == 'cash') return 'Cash';
    return source.toUpperCase();
  }
}
