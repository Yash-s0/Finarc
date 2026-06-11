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

class CardsOverviewScreen extends ConsumerStatefulWidget {
  const CardsOverviewScreen({super.key});

  @override
  ConsumerState<CardsOverviewScreen> createState() =>
      _CardsOverviewScreenState();
}

class _CardsOverviewScreenState extends ConsumerState<CardsOverviewScreen> {
  static const double _embeddedTransactionHeight = 320;
  static const double _embeddedTransactionEstimate = 72;

  final PageController _pageController = PageController(viewportFraction: 0.93);
  int _selectedCardIndex = 0;
  int _activeTab = 0;

  EdgeInsets _pagePadding(BuildContext context) {
    return EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.md,
      AppSpacing.md,
      AppSpacing.md,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cardsOverviewProvider);
    return state.when(
      loading: () => ListView(
        padding: _pagePadding(context),
        children: const [
          FinarcLoadingSkeleton(height: 34, width: 130),
          SizedBox(height: AppSpacing.sm),
          FinarcLoadingSkeleton(height: 170),
          SizedBox(height: AppSpacing.sm),
          FinarcLoadingSkeleton(height: 34),
          SizedBox(height: AppSpacing.sm),
          FinarcLoadingSkeleton(height: 240),
        ],
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (data) {
        if (data.cards.isEmpty) {
          return ListView(
            padding: _pagePadding(context),
            children: [
              const FinarcEmptyState(
                title: 'No cards added yet',
                subtitle:
                    'Add your first credit card to track dues and utilization.',
                icon: Icons.credit_card_off_outlined,
              ),
              const SizedBox(height: AppSpacing.sm),
              FinarcPrimaryButton(
                onPressed: () => context.push('/cards/add'),
                icon: Icons.add_card_rounded,
                label: 'Add Card',
              ),
            ],
          );
        }

        final now = _dateOnly(DateTime.now());
        final summaries = [...data.cardSummaries]
          ..sort(
            (a, b) => _sortDueDate(
              a.nextUnpaidDueDate,
              now,
            ).compareTo(_sortDueDate(b.nextUnpaidDueDate, now)),
          );

        if (_selectedCardIndex >= summaries.length) {
          _selectedCardIndex = 0;
        }
        final selected = summaries[_selectedCardIndex];
        final selectedDetailState = ref.watch(
          cardDetailProvider(selected.card.id),
        );

        return ListView(
          padding: _pagePadding(context),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Credit Cards',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Portfolio, dues, and billing in one place.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                SizedBox(
                  width: 92,
                  child: FinarcSecondaryButton(
                    onPressed: () => context.push('/cards/add'),
                    icon: Icons.add_card_rounded,
                    label: 'Add',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 204,
              child: PageView.builder(
                controller: _pageController,
                itemCount: summaries.length,
                onPageChanged: (index) {
                  setState(() {
                    _selectedCardIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final summary = summaries[index];
                  final dueDays = _daysUntilDue(now, summary.nextUnpaidDueDate);
                  final dueLabel = _dueDayLabel(dueDays);
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == summaries.length - 1 ? 0 : AppSpacing.xs,
                    ),
                    child: FinarcCardPreview(
                      bank: summary.card.bankName,
                      nickname: summary.card.nickname,
                      maskedNumber: summary.card.maskedNumber,
                      outstanding: inr(summary.totalOutstanding),
                      network: summary.card.network,
                      utilization: summary.utilization,
                      dueLabel: dueLabel,
                      dueTone: dueLabel == null
                          ? FinarcStatusTone.neutral
                          : _toneForDueDays(dueDays!),
                      onTap: () => context.push('/cards/${summary.card.id}'),
                    ),
                  );
                },
              ),
            ),
            if (summaries.length > 1) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  summaries.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: index == _selectedCardIndex ? 14 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: index == _selectedCardIndex
                          ? AppColors.darkAccent
                          : AppColors.darkBorder,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            _buildTabs(context),
            const SizedBox(height: AppSpacing.sm),
            if (_activeTab == 0)
              ..._overviewWidgets(
                context,
                selectedDetailState,
                selected.card.id,
              )
            else
              ..._detailTabWidgets(context, selectedDetailState),
          ],
        );
      },
    );
  }

  Widget _buildTabs(BuildContext context) {
    final tabs = ['Overview', 'Unbilled', 'Billed', 'History'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceLow,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = _activeTab == index;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _activeTab = index),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.darkPrimarySoft
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  tabs[index],
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: selected
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.64),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  List<Widget> _overviewWidgets(
    BuildContext context,
    AsyncValue<CardDetailViewModel> selectedDetailState,
    int selectedCardId,
  ) {
    return [
      selectedDetailState.when(
        loading: () => Column(
          children: const [
            FinarcLoadingSkeleton(height: 188),
            SizedBox(height: AppSpacing.sm),
            FinarcLoadingSkeleton(height: 132),
          ],
        ),
        error: (e, _) =>
            FinarcCard(child: Text('Unable to load selected card: $e')),
        data: (vm) {
          final hasActiveBill = vm.currentBill != null;
          final hasDues = hasActiveBill && vm.currentDueAmount > 0.009;
          return Column(
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.9,
                crossAxisSpacing: AppSpacing.xs,
                mainAxisSpacing: AppSpacing.xs,
                children: [
                  FinarcMetricCard(
                    title: 'Total Card Dues',
                    value: inr(vm.currentDueAmount),
                    icon: Icons.warning_amber_rounded,
                    iconColor: AppColors.darkWarning,
                    iconBackgroundColor: AppColors.darkWarning.withValues(
                      alpha: 0.14,
                    ),
                  ),
                  FinarcMetricCard(
                    title: 'Unbilled',
                    value: inr(vm.unbilledAmount),
                    icon: Icons.receipt_long_rounded,
                    iconColor: AppColors.darkBlue,
                    iconBackgroundColor: AppColors.darkBlue.withValues(
                      alpha: 0.14,
                    ),
                  ),
                  FinarcMetricCard(
                    title: 'Outstanding',
                    value: inr(vm.totalOutstanding),
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: AppColors.darkAccent,
                    iconBackgroundColor: AppColors.darkAccent.withValues(
                      alpha: 0.14,
                    ),
                  ),
                  FinarcMetricCard(
                    title: 'Utilization',
                    value: '${(vm.utilization * 100).toStringAsFixed(1)}%',
                    icon: Icons.pie_chart_outline_rounded,
                    iconColor: AppColors.darkMint,
                    iconBackgroundColor: AppColors.darkMint.withValues(
                      alpha: 0.14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              FinarcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FinarcSectionHeader(
                      title: 'Current Bill',
                      trailing: FinarcStatusBadge(
                        label: vm.billStatus.toUpperCase(),
                        tone: _toneForStatus(vm.billStatus),
                        compact: true,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                inr(vm.currentDueAmount),
                                style: AppTextStyles.amountStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  size: 24,
                                  weight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                vm.currentBill == null
                                    ? 'No active billed statement'
                                    : vm.currentBill!.paidAmount > 0
                                    ? 'Paid ${inr(vm.currentBill!.paidAmount)} • Remaining ${inr(vm.currentDueAmount)}'
                                    : 'Due ${_dateText(vm.currentBill!.dueDate)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: hasDues
                              ? FinarcPrimaryButton(
                                  onPressed: () => context.push(
                                    '/cards/$selectedCardId/bills/${vm.currentBill!.id}',
                                  ),
                                  label: 'Pay Now',
                                  expand: false,
                                )
                              : FinarcSecondaryButton(
                                  onPressed: hasActiveBill
                                      ? () => context.push(
                                          '/cards/$selectedCardId/bills/${vm.currentBill!.id}',
                                        )
                                      : null,
                                  label: hasActiveBill ? 'Paid' : 'No Bill',
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ];
  }

  List<Widget> _detailTabWidgets(
    BuildContext context,
    AsyncValue<CardDetailViewModel> selectedDetailState,
  ) {
    return [
      selectedDetailState.when(
        loading: () => const FinarcLoadingSkeleton(height: 240),
        error: (e, _) =>
            FinarcCard(child: Text('Unable to load transactions: $e')),
        data: (vm) {
          final txns = switch (_activeTab) {
            1 => vm.unbilledTransactions,
            2 => vm.billedTransactions,
            _ => vm.recentTransactions,
          };
          final emptyText = switch (_activeTab) {
            1 => 'No unbilled spends',
            2 => 'No billed spends',
            _ => 'No recent spends',
          };

          if (txns.isEmpty) {
            return FinarcEmptyState(
              title: emptyText,
              subtitle: 'Card transactions will appear once recorded.',
              icon: Icons.receipt_long_outlined,
            );
          }

          return FinarcContainedList(
            itemCount: txns.length,
            itemExtentEstimate: _embeddedTransactionEstimate,
            maxHeight: _embeddedTransactionHeight,
            itemBuilder: (context, index) =>
                _transactionRow(context, txns[index]),
          );
        },
      ),
    ];
  }

  Widget _transactionRow(BuildContext context, Transaction txn) {
    final billed = txn.cardBillId != null;
    final isRefund = txn.type == 'refund';
    return FinarcTransactionTile(
      title: txn.title,
      subtitle: txn.category,
      meta: FinarcTransactionPresentation.meta(
        date: txn.transactionDate,
        source: billed && txn.cardBillId != null
            ? 'Card • Statement #${txn.cardBillId}'
            : 'Card',
      ),
      amount: '${isRefund ? '+' : '-'}${inr(txn.amount)}',
      amountColor: isRefund ? AppColors.darkSuccess : AppColors.darkError,
      amountMeta: billed && txn.cardBillId != null
          ? 'Stmt #${txn.cardBillId}'
          : null,
      badges: [FinarcTransactionPresentation.billedBadge(billed: billed)],
      compact: true,
      prefix: CircleAvatar(
        radius: 15,
        backgroundColor: billed
            ? AppColors.darkPrimarySoft
            : AppColors.darkWarning.withValues(alpha: 0.22),
        child: Icon(
          billed ? Icons.receipt_long_rounded : Icons.pending_actions_rounded,
          size: 13,
          color: billed ? AppColors.darkAccent : AppColors.darkWarning,
        ),
      ),
      onTap: () {},
    );
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static int? _daysUntilDue(DateTime now, DateTime? dueDate) {
    if (dueDate == null) return null;
    return _dateOnly(dueDate).difference(now).inDays;
  }

  static int _sortDueDate(DateTime? dueDate, DateTime now) {
    if (dueDate == null) {
      return 1 << 20;
    }
    return _dateOnly(dueDate).difference(now).inDays;
  }

  static String? _dueDayLabel(int? days) {
    if (days == null) return null;
    if (days < 0) return 'Overdue ${days.abs()}d';
    if (days <= 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    return 'Due in $days days';
  }

  static FinarcStatusTone _toneForDueDays(int days) {
    if (days < 0) return FinarcStatusTone.error;
    if (days <= 1) return FinarcStatusTone.error;
    if (days <= 4) return FinarcStatusTone.warning;
    return FinarcStatusTone.info;
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
      default:
        return FinarcStatusTone.info;
    }
  }

  static String _dateText(DateTime date) {
    final d = date.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
