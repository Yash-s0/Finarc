import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../data/accounts_providers.dart';

class AccountDetailScreen extends ConsumerWidget {
  const AccountDetailScreen({super.key, required this.type, required this.id});

  final String type;
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (id <= 0) {
      return FinarcScaffold(
        appBar: const FinarcAppBar(title: 'Account Detail'),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const FinarcEmptyState(
              title: 'Invalid account route',
              subtitle: 'This account link is invalid.',
              icon: Icons.error_outline,
            ),
            const SizedBox(height: AppSpacing.sm),
            FinarcPrimaryButton(
              onPressed: () => context.go('/accounts'),
              icon: Icons.arrow_back_rounded,
              label: 'Back to Accounts',
            ),
          ],
        ),
      );
    }

    final state = ref.watch(accountDetailProvider((type, id)));

    return FinarcScaffold(
      appBar: FinarcAppBar(
        title: type == 'cash' ? 'Cash Wallet' : 'Bank Account',
        actions: [
          IconButton(
            onPressed: () =>
                context.push('/accounts/add?editType=$type&editId=$id'),
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: state.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: const [
            FinarcLoadingSkeleton(height: 176),
            SizedBox(height: AppSpacing.sm),
            FinarcLoadingSkeleton(height: 126),
          ],
        ),
        error: (e, _) => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const FinarcEmptyState(
              title: 'Account not found',
              subtitle: 'This account may have been deleted after reset.',
              icon: Icons.account_balance_wallet_outlined,
            ),
            const SizedBox(height: AppSpacing.sm),
            FinarcPrimaryButton(
              onPressed: () => context.go('/accounts'),
              icon: Icons.arrow_back_rounded,
              label: 'Back to Accounts',
            ),
          ],
        ),
        data: (data) {
          final incoming = data.txns
              .where((t) => !t.title.contains('Out'))
              .fold<double>(0, (s, t) => s + t.amount);
          final outgoing = data.txns
              .where((t) => t.title.contains('Out'))
              .fold<double>(0, (s, t) => s + t.amount);

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              FinarcCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type == 'cash'
                          ? 'CASH WALLET BALANCE'
                          : 'ACCOUNT BALANCE',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      inr(data.balance),
                      style: AppTextStyles.amountStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 32,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      data.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _summary(
                            context,
                            'Incoming',
                            '+${inr(incoming)}',
                            AppColors.darkSuccess,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _summary(
                            context,
                            'Outgoing',
                            '-${inr(outgoing)}',
                            AppColors.darkError,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: FinarcPrimaryButton(
                      onPressed: () => context.push('/accounts/transfer'),
                      icon: Icons.swap_horiz,
                      label: 'Transfer',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FinarcSecondaryButton(
                      onPressed: () =>
                          context.push('/accounts/reconcile/$type/$id'),
                      label: 'Reconcile',
                    ),
                  ),
                ],
              ),
              if (type == 'cash') ...[
                const SizedBox(height: AppSpacing.xs),
                FinarcSecondaryButton(
                  onPressed: () => context.push('/income/add'),
                  icon: Icons.add_circle_outline,
                  label: 'Quick Add Cash',
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              FinarcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FinarcSectionHeader(title: 'Account Insights'),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Placeholder for future account insight rules.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const FinarcSectionHeader(title: 'Recent Transactions'),
              const SizedBox(height: AppSpacing.xs),
              if (data.txns.isEmpty)
                const FinarcEmptyState(
                  title: 'No transactions found',
                  subtitle: 'Transfers and reconciliations will appear here.',
                  icon: Icons.receipt_long_outlined,
                )
              else
                ...data.txns.map<Widget>((t) {
                  final sign = t.title.contains('Out') ? '-' : '+';
                  final color = sign == '-'
                      ? AppColors.darkError
                      : AppColors.darkSuccess;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: FinarcTransactionTile(
                      title: t.title,
                      subtitle: t.category,
                      meta: FinarcTransactionPresentation.meta(
                        date: t.transactionDate,
                        source: FinarcTransactionPresentation.sourceLabel(
                          t.paymentSourceType,
                        ),
                      ),
                      amount: '$sign${inr(t.amount)}',
                      amountColor: color,
                      prefix: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.darkPrimarySoft,
                        child: Icon(
                          sign == '-'
                              ? Icons.north_east_rounded
                              : Icons.south_west_rounded,
                          size: 15,
                          color: AppColors.darkAccent,
                        ),
                      ),
                      badges: [
                        if (t.cashbackAmount > 0)
                          FinarcTransactionPresentation.cashbackBadge,
                        if (t.isForOthers)
                          FinarcTransactionPresentation.recoverableStatusBadge(
                            t.recoverableStatus,
                          ),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  static Widget _summary(
    BuildContext context,
    String label,
    String amount,
    Color color,
  ) {
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
            color: color,
            size: 14,
            weight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
