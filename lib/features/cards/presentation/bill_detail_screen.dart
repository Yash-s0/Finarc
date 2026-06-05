import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/numeric_input_formatters.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../accounts/data/wallet_types.dart';
import '../../expenses/models/transaction_types.dart';
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
  final _paymentFormKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  int? _selectedPaymentSourceId;
  String _paymentSourceType = PaymentSourceType.bank;
  DateTime _paymentDate = DateTime.now();
  bool _isFullPayment = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

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
        final paymentSources = _paymentSourcesFor(
          accounts: data.accounts,
          wallets: data.wallets,
          sourceType: _paymentSourceType,
        );
        final hasAnyPaymentSource =
            data.accounts.isNotEmpty || data.wallets.isNotEmpty;
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
                      'Remaining due',
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
                    const FinarcSectionHeader(title: 'Payment'),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      pendingAmount <= 0
                          ? 'This statement is fully paid.'
                          : bill.paidAmount > 0
                          ? 'Paid ${inr(bill.paidAmount)} so far. Record another payment for the remaining due.'
                          : 'Record a full or partial bill payment with source, date, and optional reference.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (!hasAnyPaymentSource)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          'Add a bank account or cash wallet before recording a card payment.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    FinarcPrimaryButton(
                      onPressed: pendingAmount <= 0 || !hasAnyPaymentSource
                          ? null
                          : () => _openPaymentSheet(
                              context,
                              data: data,
                              bill: bill,
                              remainingDue: pendingAmount,
                            ),
                      label: pendingAmount <= 0 ? 'Paid' : 'Record Payment',
                      icon: pendingAmount <= 0
                          ? Icons.check_circle_outline
                          : Icons.payments_outlined,
                    ),
                    if (paymentSources.isEmpty && hasAnyPaymentSource)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          'No ${_paymentSourceType == PaymentSourceType.cash ? 'cash wallet' : 'bank account'} available for the selected payment mode.',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: AppColors.darkWarning),
                        ),
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
                    amount: '${t.type == 'refund' ? '+' : '-'}${inr(t.amount)}',
                    amountColor: t.type == 'refund'
                        ? AppColors.darkSuccess
                        : AppColors.darkError,
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

  Future<void> _openPaymentSheet(
    BuildContext context, {
    required ({
      CardBill bill,
      List<Transaction> txns,
      List<BankAccount> accounts,
      List<CashWallet> wallets,
    })
    data,
    required CardBill bill,
    required double remainingDue,
  }) async {
    _preparePaymentForm(data: data, remainingDue: remainingDue);
    await FinarcBottomSheet.show<void>(
      context,
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          final sources = _paymentSourcesFor(
            accounts: data.accounts,
            wallets: data.wallets,
            sourceType: _paymentSourceType,
          );
          final selectedSourceId = _resolveSelectedSourceId(sources);
          final modeOptions = [
            if (data.accounts.isNotEmpty)
              const FinarcPaymentModeOption(
                value: PaymentSourceType.bank,
                label: 'Bank',
                icon: Icons.account_balance_rounded,
              ),
            if (data.wallets.isNotEmpty)
              const FinarcPaymentModeOption(
                value: PaymentSourceType.cash,
                label: 'Cash Wallet',
                icon: Icons.wallet_rounded,
              ),
          ];

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.85,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              child: Form(
                key: _paymentFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text(
                    'Record Payment',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Remaining due ${inr(remainingDue)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: [
                      ChoiceChip(
                        label: const Text('Full Payment'),
                        selected: _isFullPayment,
                        onSelected: (selected) {
                          if (!selected) return;
                          setSheetState(() {
                            _isFullPayment = true;
                            _amountController.text = moneyInput(remainingDue);
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Partial Payment'),
                        selected: !_isFullPayment,
                        onSelected: (selected) {
                          if (!selected) return;
                          setSheetState(() => _isFullPayment = false);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FinarcTextField(
                    controller: _amountController,
                    label: 'Payment amount',
                    readOnly: _isFullPayment,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}$'),
                      ),
                      StripLeadingZeroFormatter(),
                    ],
                    validator: (value) {
                      final parsed = double.tryParse(value ?? '');
                      if (parsed == null || parsed <= 0) {
                        return 'Payment amount must be greater than 0';
                      }
                      if (parsed > remainingDue + 0.009) {
                        return 'Payment amount cannot exceed remaining due';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FinarcPaymentSelector(
                    title: 'Payment Source',
                    selectedMode: _paymentSourceType,
                    modes: modeOptions,
                    onModeChanged: (value) {
                      setSheetState(() {
                        _paymentSourceType = value;
                        _selectedPaymentSourceId = null;
                      });
                    },
                    sources: sources,
                    selectedSourceId: selectedSourceId,
                    onSourceChanged: (value) =>
                        setSheetState(() => _selectedPaymentSourceId = value),
                    sourceLabel: _paymentSourceType == PaymentSourceType.cash
                        ? 'Cash wallet'
                        : 'Bank account',
                    singleSourcePrefix: _paymentSourceType == PaymentSourceType.cash
                        ? 'Using wallet'
                        : 'Using account',
                    sourceValidator: (value) {
                      if (sources.isEmpty) {
                        return 'Add a payment source first';
                      }
                      if (sources.length > 1 && value == null) {
                        return 'Select payment source';
                      }
                      return null;
                    },
                    compactModeTiles: true,
                    modeTestPrefix: 'card-payment-mode',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _paymentDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked == null) return;
                      setSheetState(() => _paymentDate = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Payment date',
                      ),
                      child: Text(_dateText(_paymentDate)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FinarcTextField(
                    controller: _noteController,
                    label: 'Note / Reference (optional)',
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: FinarcSecondaryButton(
                          onPressed: _isSaving
                              ? null
                              : () => Navigator.of(context).pop(),
                          label: 'Cancel',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: FinarcPrimaryButton(
                          onPressed: _isSaving
                              ? null
                              : () => _submitPayment(
                                  context,
                                  selectedSourceId: selectedSourceId,
                                  remainingDue: remainingDue,
                                ),
                          label: _isSaving ? 'Saving...' : 'Confirm',
                        ),
                      ),
                    ],
                  ),
                ],
                ),
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  void _preparePaymentForm({
    required ({
      CardBill bill,
      List<Transaction> txns,
      List<BankAccount> accounts,
      List<CashWallet> wallets,
    })
    data,
    required double remainingDue,
  }) {
    if (data.accounts.isEmpty && data.wallets.isNotEmpty) {
      _paymentSourceType = PaymentSourceType.cash;
    } else {
      _paymentSourceType = PaymentSourceType.bank;
    }
    _selectedPaymentSourceId = null;
    _paymentDate = DateTime.now();
    _isFullPayment = true;
    _isSaving = false;
    _amountController.text = moneyInput(remainingDue);
    _noteController.clear();
  }

  int? _resolveSelectedSourceId(List<FinarcPaymentSourceOption> sources) {
    if (sources.isEmpty) return null;
    if (sources.length == 1) {
      return sources.first.id;
    }
    if (sources.any((source) => source.id == _selectedPaymentSourceId)) {
      return _selectedPaymentSourceId;
    }
    return null;
  }

  List<FinarcPaymentSourceOption> _paymentSourcesFor({
    required List<BankAccount> accounts,
    required List<CashWallet> wallets,
    required String sourceType,
  }) {
    if (sourceType == PaymentSourceType.cash) {
      return wallets
          .map(
            (wallet) => FinarcPaymentSourceOption(
              id: wallet.id,
              label:
                  '${WalletType.displayName(wallet)} • ${inr(wallet.currentBalance)}',
            ),
          )
          .toList(growable: false);
    }
    return accounts
        .map(
          (account) => FinarcPaymentSourceOption(
            id: account.id,
            label: '${account.accountName} • ${inr(account.currentBalance)}',
          ),
        )
        .toList(growable: false);
  }

  Future<void> _submitPayment(
    BuildContext context, {
    required int? selectedSourceId,
    required double remainingDue,
  }) async {
    if (!_paymentFormKey.currentState!.validate()) return;
    if (selectedSourceId == null) return;

    setState(() => _isSaving = true);
    final amount = double.parse(_amountController.text);
    final result = await ref.read(markBillPaidProvider)(
      billId: widget.billId,
      paymentSourceId: selectedSourceId,
      paymentSourceType: _paymentSourceType,
      amount: amount,
      paymentDate: _paymentDate,
      notes: _noteController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.of(context).pop();
    ref.invalidate(cardDetailProvider(widget.cardId));
    ref.invalidate(billDetailProvider(widget.billId));
    final message =
        result.message ??
        'Recorded ${inr(result.appliedAmount)}. Remaining due ${inr(result.remainingDueAfter)}.';
    ScaffoldMessenger.of(this.context).showSnackBar(
      SnackBar(content: Text(message)),
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
