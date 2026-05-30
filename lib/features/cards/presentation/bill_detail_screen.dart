import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../data/cards_providers.dart';

class BillDetailScreen extends ConsumerStatefulWidget {
  const BillDetailScreen({
    super.key,
    required this.billId,
    required this.cardId,
  });

  final int billId;
  final int cardId;

  @override
  ConsumerState<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends ConsumerState<BillDetailScreen> {
  int? _selectedBankAccountId;

  @override
  Widget build(BuildContext context) {
    if (widget.billId <= 0 || widget.cardId <= 0) {
      return FinarcScaffold(
        appBar: const FinarcAppBar(title: 'Bill Detail'),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const FinarcEmptyState(
              title: 'Invalid bill route',
              subtitle: 'This bill link is invalid.',
              icon: Icons.error_outline,
            ),
            const SizedBox(height: AppSpacing.sm),
            FinarcPrimaryButton(
              onPressed: () => context.go('/cards'),
              icon: Icons.arrow_back_rounded,
              label: 'Back to Cards',
            ),
          ],
        ),
      );
    }

    final state = ref.watch(billDetailProvider(widget.billId));
    return state.when(
      loading: () => const FinarcScaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => FinarcScaffold(
        appBar: const FinarcAppBar(title: 'Bill Detail'),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const FinarcEmptyState(
              title: 'Bill not found',
              subtitle: 'This bill may have been deleted or already cleared.',
              icon: Icons.receipt_long_outlined,
            ),
            const SizedBox(height: AppSpacing.sm),
            FinarcPrimaryButton(
              onPressed: () => context.go('/cards'),
              icon: Icons.arrow_back_rounded,
              label: 'Back to Cards',
            ),
          ],
        ),
      ),
      data: (data) {
        final bill = data.bill;
        final dueDays = bill.dueDate.difference(DateTime.now()).inDays;
        final pendingAmount = (bill.billedAmount - bill.paidAmount)
            .clamp(0, bill.billedAmount)
            .toDouble();
        final tone = _toneForStatus(bill.status);

        return FinarcScaffold(
          appBar: const FinarcAppBar(title: 'Bill Detail'),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              FinarcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Statement',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        FinarcStatusBadge(
                          label: bill.status.toUpperCase(),
                          tone: tone,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _metricLine(
                      context,
                      'Bill amount',
                      inr(bill.billedAmount),
                      emphasize: true,
                    ),
                    _metricLine(
                      context,
                      'Paid amount',
                      inr(bill.paidAmount),
                      valueColor: AppColors.darkSuccess,
                    ),
                    _metricLine(
                      context,
                      'Pending amount',
                      inr(pendingAmount),
                      valueColor: pendingAmount == 0
                          ? AppColors.darkSuccess
                          : AppColors.darkWarning,
                    ),
                    _metricLine(
                      context,
                      'Due date',
                      _dateText(bill.dueDate),
                      isAmount: false,
                    ),
                    _metricLine(
                      context,
                      'Countdown',
                      _countdownText(dueDays),
                      isAmount: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FinarcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FinarcSectionHeader(title: 'Payment Source'),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedBankAccountId,
                      decoration: const InputDecoration(
                        labelText: 'Bank account for payment',
                      ),
                      items: data.accounts
                          .map<DropdownMenuItem<int>>(
                            (a) => DropdownMenuItem<int>(
                              value: a.id,
                              child: Text(
                                '${a.accountName} (${inr(a.currentBalance)})',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: bill.status == 'paid'
                          ? null
                          : (v) => setState(() => _selectedBankAccountId = v),
                    ),
                    if (data.accounts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          'No bank account available for payment.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    else if (_selectedBankAccountId == null &&
                        bill.status != 'paid')
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          'Select bank account to pay this bill',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: AppColors.darkWarning),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    FinarcPrimaryButton(
                      onPressed:
                          bill.status == 'paid' ||
                              _selectedBankAccountId == null
                          ? null
                          : () => _openPaymentConfirmation(
                              context,
                              billAmount: pendingAmount,
                              onConfirm: () async {
                                await ref.read(markBillPaidProvider)(
                                  widget.billId,
                                  _selectedBankAccountId,
                                  pendingAmount,
                                );
                                if (!mounted) return;
                                Navigator.of(this.context).pop();
                                ref.invalidate(
                                  cardDetailProvider(widget.cardId),
                                );
                                ref.invalidate(
                                  billDetailProvider(widget.billId),
                                );
                              },
                            ),
                      label: bill.status == 'paid'
                          ? 'Already Paid'
                          : 'Mark as Paid',
                      icon: Icons.check_circle_outline,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const FinarcSectionHeader(title: 'Transactions Included'),
              const SizedBox(height: AppSpacing.xs),
              if (data.txns.isEmpty)
                const FinarcEmptyState(
                  title: 'No transactions in this bill',
                  subtitle:
                      'Statement transactions will appear here after bill generation.',
                  icon: Icons.receipt_long_outlined,
                )
              else
                ...data.txns.map(
                  (t) => FinarcTransactionTile(
                    title: t.title,
                    subtitle: t.category,
                    meta: FinarcTransactionPresentation.meta(
                      date: t.transactionDate,
                      source: 'Card • Statement #${widget.billId}',
                    ),
                    amount: '-${inr(t.amount)}',
                    amountColor: AppColors.darkError,
                    badges: [
                      FinarcTransactionPresentation.billedBadge(billed: true),
                    ],
                    prefix: const CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.darkPrimarySoft,
                      child: Icon(Icons.receipt_long_outlined, size: 15),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openPaymentConfirmation(
    BuildContext context, {
    required double billAmount,
    required Future<void> Function() onConfirm,
  }) {
    return FinarcBottomSheet.show<void>(
      context,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirm Card Payment',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Pay ${inr(billAmount)} from selected bank account?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: FinarcSecondaryButton(
                    onPressed: () => Navigator.of(context).pop(),
                    label: 'Cancel',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FinarcPrimaryButton(
                    onPressed: () async => onConfirm(),
                    label: 'Confirm',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  static Widget _metricLine(
    BuildContext context,
    String label,
    String value, {
    bool emphasize = false,
    Color? valueColor,
    bool isAmount = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          isAmount
              ? Text(
                  value,
                  style: AppTextStyles.amountStyle(
                    color:
                        valueColor ?? Theme.of(context).colorScheme.onSurface,
                    size: emphasize ? 17 : 15,
                    weight: emphasize ? FontWeight.w700 : FontWeight.w600,
                  ),
                )
              : Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: valueColor),
                ),
        ],
      ),
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
      default:
        return FinarcStatusTone.info;
    }
  }

  static String _countdownText(int dueDays) {
    if (dueDays < 0) return '${dueDays.abs()} days overdue';
    if (dueDays == 0) return 'Due today';
    if (dueDays == 1) return 'Due tomorrow';
    return '$dueDays days left';
  }

  static String _dateText(DateTime date) {
    final d = date.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
