import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../data/cards_providers.dart';

class CardDetailScreen extends ConsumerWidget {
  const CardDetailScreen({super.key, required this.cardId});

  final int cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cardDetailProvider(cardId));

    return state.when(
      loading: () => const FinarcScaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => FinarcScaffold(body: Center(child: Text('Error: $e'))),
      data: (vm) {
        final card = vm.card;
        final billedAmount = vm.currentBill?.billedAmount ?? 0.0;
        final unbilledAmount = vm.unbilledTransactions.fold<double>(
          0,
          (s, t) => s + t.amount,
        );
        final dueLabel = _dueLabel(vm.dueCountdownDays);
        final tone = _toneForStatus(vm.billStatus);

        return DefaultTabController(
          length: 4,
          child: FinarcScaffold(
            appBar: FinarcAppBar(
              title: '${card.bankName} • ${card.nickname}',
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.xs,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.darkSurfaceLow,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: TabBar(
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: AppColors.darkPrimarySoft,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: AppColors.darkAccent.withValues(alpha: 0.42),
                        ),
                      ),
                      indicatorPadding: const EdgeInsets.all(4),
                      labelStyle: Theme.of(context).textTheme.labelMedium
                          ?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                      unselectedLabelStyle: Theme.of(
                        context,
                      ).textTheme.labelMedium,
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Unbilled'),
                        Tab(text: 'Billed'),
                        Tab(text: 'History'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            body: TabBarView(
              children: [
                ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    FinarcCardPreview(
                      bank: card.bankName,
                      nickname: card.nickname,
                      maskedNumber: card.maskedNumber,
                      outstanding: inr(card.currentOutstanding),
                      utilization: vm.utilization,
                      dueLabel: dueLabel,
                      dueTone: tone,
                      footer: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Last 4: ${card.last4}',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                          FinarcStatusBadge(
                            label: vm.billStatus.toUpperCase(),
                            tone: tone,
                            compact: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.72,
                      crossAxisSpacing: AppSpacing.xs,
                      mainAxisSpacing: AppSpacing.xs,
                      children: [
                        FinarcMetricCard(
                          title: 'Available Limit',
                          value: inr(vm.availableLimit),
                        ),
                        FinarcMetricCard(
                          title: 'Credit Limit',
                          value: inr(card.creditLimit),
                        ),
                        FinarcMetricCard(
                          title: 'Utilization',
                          value:
                              '${(vm.utilization * 100).toStringAsFixed(1)}%',
                        ),
                        FinarcMetricCard(
                          title: 'Due Countdown',
                          value: vm.dueCountdownDays >= 0
                              ? '${vm.dueCountdownDays} days'
                              : '${vm.dueCountdownDays.abs()} days ago',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const FinarcSectionHeader(title: 'Current Statement'),
                    const SizedBox(height: AppSpacing.xs),
                    FinarcCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Bill Date: ${vm.currentBill == null ? 'Not generated' : _dateText(vm.currentBill!.billingDate)}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelMedium,
                                ),
                              ),
                              FinarcStatusBadge(
                                label: vm.billStatus.toUpperCase(),
                                tone: tone,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: _amountBlock(
                                  context,
                                  'Billed Amount',
                                  inr(billedAmount),
                                  AppColors.darkWarning,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: _amountBlock(
                                  context,
                                  'Unbilled Spends',
                                  inr(unbilledAmount),
                                  AppColors.darkAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  vm.currentBill == null
                                      ? 'Next statement will be generated automatically.'
                                      : 'Due on ${_dateText(vm.currentBill!.dueDate)}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              if (vm.currentBill != null)
                                FinarcSecondaryButton(
                                  onPressed: () => context.push(
                                    '/cards/$cardId/bills/${vm.currentBill!.id}',
                                  ),
                                  label: 'Bill Detail',
                                  icon: Icons.receipt_long_outlined,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const FinarcSectionHeader(title: 'Recent Transactions'),
                    const SizedBox(height: AppSpacing.xs),
                    if (vm.recentTransactions.isEmpty)
                      const FinarcEmptyState(
                        title: 'No transactions yet',
                        subtitle: 'Card spends will appear here once recorded.',
                        icon: Icons.receipt_long_outlined,
                      )
                    else
                      ...vm.recentTransactions.map(
                        (t) => FinarcTransactionTile(
                          title: t.title,
                          subtitle: t.category,
                          amount: '-${inr(t.amount)}',
                          amountColor: AppColors.darkError,
                          prefix: const CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.darkPrimarySoft,
                            child: Icon(Icons.credit_card, size: 15),
                          ),
                        ),
                      ),
                  ],
                ),
                _transactionTab(
                  context,
                  vm.unbilledTransactions,
                  emptyTitle: 'No unbilled spends',
                  emptySubtitle:
                      'New card expenses after statement date appear here.',
                ),
                _transactionTab(
                  context,
                  vm.billedTransactions,
                  emptyTitle: 'No billed transactions',
                  emptySubtitle:
                      'Generated statement transactions appear here.',
                ),
                _transactionTab(
                  context,
                  vm.recentTransactions,
                  emptyTitle: 'No transaction history',
                  emptySubtitle:
                      'Card history will appear here once you start using this card.',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _amountBlock(
    BuildContext context,
    String label,
    String amount,
    Color accent,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              amount,
              style: AppTextStyles.amountStyle(
                color: accent,
                size: 16,
                weight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _transactionTab(
    BuildContext context,
    List<Transaction> transactions, {
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (transactions.isEmpty)
          FinarcEmptyState(
            title: emptyTitle,
            subtitle: emptySubtitle,
            icon: Icons.list_alt_outlined,
          )
        else
          ...transactions.map(
            (t) => FinarcTransactionTile(
              title: t.title,
              subtitle: t.category,
              amount: '-${inr(t.amount)}',
              amountColor: AppColors.darkError,
              prefix: const CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.darkPrimarySoft,
                child: Icon(Icons.receipt_long_outlined, size: 15),
              ),
            ),
          ),
      ],
    );
  }

  static FinarcStatusTone _toneForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return FinarcStatusTone.success;
      case 'overdue':
        return FinarcStatusTone.error;
      case 'duesoon':
      case 'due soon':
        return FinarcStatusTone.warning;
      case 'billed':
      case 'upcoming':
      default:
        return FinarcStatusTone.info;
    }
  }

  static String _dueLabel(int days) {
    if (days < 0) return 'Overdue ${days.abs()}d';
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    return 'Due in ${days}d';
  }

  static String _dateText(DateTime date) {
    final d = date.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
