import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/numeric_input_formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../analytics/data/analytics_providers.dart';
import '../../dashboard/data/dashboard_providers.dart';
import '../data/expenses_providers.dart';
import '../data/transaction_engine.dart';
import '../models/transaction_types.dart';
import '../../recoverables/data/recoverables_service.dart';
import 'payment_source_selector_support.dart';

final transactionByIdProvider = FutureProvider.family((ref, int id) async {
  await ref.watch(seedProvider.future);
  final db = ref.read(appDatabaseProvider);
  return (db.select(
    db.transactions,
  )..where((t) => t.id.equals(id))).getSingleOrNull();
});

class TransactionDetailScreen extends ConsumerStatefulWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});

  final int transactionId;

  @override
  ConsumerState<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState
    extends ConsumerState<TransactionDetailScreen> {
  static const _allModes = [
    FinarcPaymentModeOption(
      value: PaymentSourceType.cash,
      label: 'Cash',
      icon: Icons.payments_rounded,
    ),
    FinarcPaymentModeOption(
      value: PaymentSourceType.upi,
      label: 'UPI',
      icon: Icons.qr_code_scanner_rounded,
    ),
    FinarcPaymentModeOption(
      value: PaymentSourceType.creditCard,
      label: 'Card',
      icon: Icons.credit_card_rounded,
    ),
    FinarcPaymentModeOption(
      value: PaymentSourceType.bank,
      label: 'Bank',
      icon: Icons.account_balance_rounded,
    ),
  ];
  static const _incomeModes = [
    FinarcPaymentModeOption(
      value: PaymentSourceType.cash,
      label: 'Cash',
      icon: Icons.payments_rounded,
    ),
    FinarcPaymentModeOption(
      value: PaymentSourceType.upi,
      label: 'UPI',
      icon: Icons.qr_code_scanner_rounded,
    ),
    FinarcPaymentModeOption(
      value: PaymentSourceType.bank,
      label: 'Bank',
      icon: Icons.account_balance_rounded,
    ),
  ];
  static const _cardOnlyModes = [
    FinarcPaymentModeOption(
      value: PaymentSourceType.creditCard,
      label: 'Card',
      icon: Icons.credit_card_rounded,
    ),
  ];

  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _title = TextEditingController();
  final _category = TextEditingController();
  final _notes = TextEditingController();
  final _dateController = TextEditingController();
  final _cashback = TextEditingController();
  final _recoverableParty = TextEditingController();

  bool _forOthers = false;
  DateTime _date = DateTime.now();
  String _sourceType = PaymentSourceType.cash;
  int? _sourceId;
  String _type = TransactionType.cash;
  bool _initialized = false;

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    _category.dispose();
    _notes.dispose();
    _dateController.dispose();
    _cashback.dispose();
    _recoverableParty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txnState = ref.watch(transactionByIdProvider(widget.transactionId));
    final sourcesState = ref.watch(paymentSourcesProvider);

    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Transaction Details'),
      body: txnState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (txn) => sourcesState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (sources) {
            if (txn == null) {
              return const Center(child: Text('Transaction not found'));
            }
            final editable = ref
                .read(transactionEngineProvider)
                .isEditable(txn);
            if (!_initialized) {
              _amount.text = txn.amount.toStringAsFixed(2);
              _title.text = txn.title;
              _category.text = txn.category;
              _notes.text = txn.notes ?? '';
              _date = txn.transactionDate;
              _dateController.text = '${_date.toLocal()}'.split('.').first;
              _sourceType = txn.paymentSourceType;
              _sourceId = txn.paymentSourceId;
              _cashback.text = txn.cashbackAmount.toStringAsFixed(2);
              _recoverableParty.text = txn.recoverablePartyName ?? '';
              _forOthers = _recoverableParty.text.trim().isNotEmpty;
              _type = txn.type;
              _initialized = true;
            }

            final formAmount = double.tryParse(_amount.text) ?? txn.amount;
            final formCashback = _sourceType == PaymentSourceType.cash
                ? 0.0
                : (double.tryParse(_cashback.text) ?? txn.cashbackAmount);
            final recoverableBase = _forOthers
                ? (formAmount - formCashback).clamp(0, formAmount).toDouble()
                : 0.0;
            final recoveredAmount = _forOthers
                ? txn.recoveredAmount.clamp(0, recoverableBase).toDouble()
                : 0.0;
            final remainingRecoverable = (recoverableBase - recoveredAmount)
                .clamp(0, recoverableBase)
                .toDouble();
            final modeOptions = _sourceModesForType(txn.type);
            final sourceConfig = sourceConfigForMode(
              sources,
              _sourceType,
              destination: txn.type == TransactionType.income,
            );
            _syncSourceSelection(sourceConfig.options);
            final emptyState = sourceConfig.options.isEmpty
                ? FinarcPaymentSourceEmptyState(
                    message: sourceConfig.emptyMessage!,
                    ctaLabel: sourceConfig.emptyCtaLabel!,
                    onTap: () => context.push(sourceConfig.emptyCtaRoute!),
                  )
                : null;

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  FinarcCard(
                    child: FinarcTransactionTile(
                      title: txn.title,
                      subtitle: txn.category,
                      meta: FinarcTransactionPresentation.meta(
                        date: txn.transactionDate,
                        source: FinarcTransactionPresentation.sourceLabel(
                          txn.paymentSourceType,
                        ),
                      ),
                      amount:
                          '${(txn.type == 'income' || txn.type == 'refund') ? '+' : '-'}${inr(txn.amount)}',
                      amountColor:
                          (txn.type == 'income' || txn.type == 'refund')
                          ? AppColors.darkSuccess
                          : AppColors.darkError,
                      amountMeta: txn.cardBillId != null
                          ? 'Statement #${txn.cardBillId}'
                          : null,
                      badges: [
                        if (txn.paymentSourceType == 'creditCard')
                          FinarcTransactionPresentation.billedBadge(
                            billed: txn.cardBillId != null,
                          ),
                        if (txn.cashbackAmount > 0)
                          FinarcTransactionPresentation.cashbackBadge,
                        if (txn.type == TransactionType.loanEmi)
                          FinarcTransactionPresentation.loanPaymentBadge,
                        if (txn.isForOthers)
                          FinarcTransactionPresentation.recoverableStatusBadge(
                            txn.recoverableStatus,
                          ),
                        if (txn.isForOthers &&
                            (txn.recoverablePartyName?.trim().isNotEmpty ??
                                false))
                          FinarcStatusBadge(
                            label: 'For ${txn.recoverablePartyName!.trim()}',
                            tone: FinarcStatusTone.info,
                            compact: true,
                          ),
                      ],
                    ),
                  ),
                  if (txn.isForOthers) ...[
                    const SizedBox(height: AppSpacing.xs),
                    FinarcCard(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recoverable Visibility',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          _detailRow(
                            context,
                            'Person',
                            (txn.recoverablePartyName?.trim().isNotEmpty ??
                                    false)
                                ? txn.recoverablePartyName!.trim()
                                : 'Not set',
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          _detailRow(
                            context,
                            'Recoverable base',
                            inr(recoverableBase),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          _detailRow(
                            context,
                            'Recovered',
                            inr(recoveredAmount),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          _detailRow(
                            context,
                            'Remaining',
                            inr(remainingRecoverable),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  if (!editable)
                    const FinarcCard(
                      child: Text(
                        'This transaction has linked/system effects, so only viewing is allowed.',
                      ),
                    ),
                  if (!editable) const SizedBox(height: AppSpacing.sm),
                  FinarcTextField(
                    controller: _amount,
                    label: 'Amount',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [StripLeadingZeroFormatter()],
                    validator: (v) {
                      final amount = double.tryParse(v ?? '');
                      if (amount == null || amount <= 0) {
                        return 'Amount must be greater than 0';
                      }
                      return null;
                    },
                    readOnly: !editable,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  FinarcTextField(
                    controller: _title,
                    label: 'Title',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                    readOnly: !editable,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  FinarcTextField(
                    controller: _category,
                    label: 'Category',
                    readOnly: !editable,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  FinarcPaymentSelector(
                    title: txn.type == TransactionType.income
                        ? 'Receive into'
                        : 'Payment Source',
                    selectedMode: _sourceType,
                    modes: modeOptions,
                    onModeChanged: (v) => setState(() {
                      _sourceType = v;
                      _sourceId = null;
                    }),
                    sources: sourceConfig.options,
                    selectedSourceId: _sourceId,
                    onSourceChanged: (v) => setState(() => _sourceId = v),
                    sourceLabel: sourceConfig.fieldLabel,
                    singleSourcePrefix: sourceConfig.singlePrefix,
                    emptyState: emptyState,
                    enabled: editable,
                    sourceValidator: (v) {
                      if (sourceConfig.options.length <= 1) return null;
                      return v == null ? 'Source required' : null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  FinarcTextField(
                    controller: _dateController,
                    label: 'Date',
                    readOnly: true,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (_sourceType != PaymentSourceType.cash)
                    FinarcTextField(
                      controller: _cashback,
                      label: 'Cashback',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [StripLeadingZeroFormatter()],
                      readOnly: !editable,
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'For others?',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        flex: 3,
                        child: FinarcTextField(
                          controller: _recoverableParty,
                          label: 'Person name',
                          readOnly: !editable,
                          onChanged: !editable
                              ? null
                              : (value) => setState(
                                  () => _forOthers = value.trim().isNotEmpty,
                                ),
                        ),
                      ),
                    ],
                  ),
                  if (_forOthers)
                    FinarcCard(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recoverable: ${inr(recoverableBase)} from ${_recoverableParty.text.trim()}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Recovered ${inr(recoveredAmount)} • Remaining ${inr(remainingRecoverable)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          _RecoverableStatusPill(
                            status: txn.recoverableStatus,
                            recoveredAt: txn.recoveredAt,
                          ),
                          if (editable &&
                              txn.isForOthers &&
                              txn.recoverableStatus != 'recovered') ...[
                            const SizedBox(height: AppSpacing.sm),
                            FinarcPrimaryButton(
                              onPressed: () => _markRecovered(txn.id),
                              label: 'Mark as Recovered',
                              icon: Icons.verified_outlined,
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  FinarcTextField(
                    controller: _notes,
                    label: 'Notes',
                    maxLines: 2,
                    readOnly: !editable,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (editable)
                    FinarcPrimaryButton(
                      onPressed: () => _save(txn),
                      label: 'Save Changes',
                      icon: Icons.check_circle_outline,
                    ),
                  if (editable) const SizedBox(height: AppSpacing.xs),
                  if (editable)
                    FinarcSecondaryButton(
                      onPressed: () => _delete(txn.id),
                      label: 'Delete Transaction',
                      icon: Icons.delete_outline,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<FinarcPaymentModeOption> _sourceModesForType(String txnType) {
    if (txnType == TransactionType.income) return _incomeModes;
    if (txnType == TransactionType.creditCard) return _cardOnlyModes;
    return _allModes;
  }

  void _syncSourceSelection(List<FinarcPaymentSourceOption> options) {
    final next = resolveAutoSelectedSourceId(_sourceId, options);
    if (next == _sourceId) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _sourceId = next);
    });
  }

  Future<void> _save(dynamic txn) async {
    if (!_formKey.currentState!.validate()) return;
    final sources = ref.read(paymentSourcesProvider).valueOrNull;
    final sourceConfig = sourceConfigForMode(
      sources ??
          const PaymentSourcesData(banks: [], cards: [], cashWallets: []),
      _sourceType,
      destination: txn.type == TransactionType.income,
    );
    final sourceId = resolveAutoSelectedSourceId(
      _sourceId,
      sourceConfig.options,
    );
    if (sourceId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(sourceConfig.emptyMessage ?? 'Source required')),
      );
      return;
    }

    try {
      final amount = double.parse(_amount.text);
      final cashback = _sourceType == PaymentSourceType.cash
          ? 0.0
          : (double.tryParse(_cashback.text) ?? 0.0);
      final recoverableParty = _recoverableParty.text.trim();
      final forOthers = recoverableParty.isNotEmpty;
      final recoverableBase = forOthers
          ? (amount - cashback).clamp(0, amount).toDouble()
          : 0.0;
      final recoveredAmount = forOthers
          ? txn.recoveredAmount.clamp(0, recoverableBase).toDouble()
          : 0.0;

      await ref
          .read(transactionEngineProvider)
          .updateTransaction(
            txn.id,
            AddTransactionInput(
              type: _type,
              amount: amount,
              title: _title.text.trim(),
              category: _category.text.trim(),
              transactionDate: _date,
              paymentSourceType: _sourceType,
              paymentSourceId: sourceId,
              cashbackAmount: cashback,
              isForOthers: forOthers,
              recoverableAmount: forOthers
                  ? (recoverableBase - recoveredAmount)
                        .clamp(0, recoverableBase)
                        .toDouble()
                  : null,
              recoveredAmount: recoveredAmount,
              recoverablePartyName: forOthers ? recoverableParty : null,
              recoveredAt: txn.recoveredAt,
              notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
            ),
          );
      _invalidateAll();
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to update: $e')));
    }
  }

  Future<void> _markRecovered(int transactionId) async {
    try {
      await ref.read(transactionEngineProvider).markRecovered(transactionId);
      _invalidateAll();
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to mark as recovered: $e')),
      );
    }
  }

  Future<void> _delete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('This will reverse its balance effect.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(transactionEngineProvider).deleteTransaction(id);
      _invalidateAll();
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to delete: $e')));
    }
  }

  void _invalidateAll() {
    ref.invalidate(expenseListProvider);
    ref.invalidate(dashboardProvider);
    ref.invalidate(analyticsSnapshotProvider);
    ref.invalidate(recoverablesSnapshotProvider);
    ref.invalidate(transactionByIdProvider(widget.transactionId));
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.labelMedium),
        ),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _RecoverableStatusPill extends StatelessWidget {
  const _RecoverableStatusPill({
    required this.status,
    required this.recoveredAt,
  });

  final String? status;
  final DateTime? recoveredAt;

  @override
  Widget build(BuildContext context) {
    final normalized = (status ?? 'unpaid').toLowerCase();
    final isRecovered = normalized == 'recovered';
    final isPartial = normalized == 'partial';
    final label = isRecovered
        ? 'Recovered${recoveredAt == null ? '' : ' • ${recoveredAt!.day}/${recoveredAt!.month}/${recoveredAt!.year}'}'
        : isPartial
        ? 'Partially Recovered'
        : 'Unpaid';
    return FinarcStatusBadge(
      label: label,
      tone: isRecovered
          ? FinarcStatusTone.success
          : isPartial
          ? FinarcStatusTone.info
          : FinarcStatusTone.warning,
    );
  }
}
