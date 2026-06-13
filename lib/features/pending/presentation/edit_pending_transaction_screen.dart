import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../expenses/data/expenses_providers.dart';
import '../../expenses/models/transaction_types.dart';
import '../../expenses/presentation/payment_source_selector_support.dart';
import '../data/pending_providers.dart';
import '../models/pending_models.dart';

final pendingByIdProvider = FutureProvider.family((ref, int id) async {
  await ref.watch(seedProvider.future);
  final db = ref.read(appDatabaseProvider);
  return (db.select(
    db.pendingTransactions,
  )..where((p) => p.id.equals(id))).getSingleOrNull();
});

class EditPendingTransactionScreen extends ConsumerStatefulWidget {
  const EditPendingTransactionScreen({super.key, required this.pendingId});

  final int pendingId;

  @override
  ConsumerState<EditPendingTransactionScreen> createState() =>
      _EditPendingTransactionScreenState();
}

class _EditPendingTransactionScreenState
    extends ConsumerState<EditPendingTransactionScreen> {
  static const _modeOptions = [
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

  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _merchant = TextEditingController();
  final _category = TextEditingController();
  final _notes = TextEditingController();
  final _recoverableParty = TextEditingController();
  DateTime _date = DateTime.now();
  String _sourceType = 'cash';
  int? _sourceId;
  bool _forOthers = false;
  bool _cashbackOn = false;
  final _cashback = TextEditingController(text: '0');
  final _dateController = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _amount.dispose();
    _merchant.dispose();
    _category.dispose();
    _notes.dispose();
    _recoverableParty.dispose();
    _cashback.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingState = ref.watch(pendingByIdProvider(widget.pendingId));
    final sourcesState = ref.watch(paymentSourcesProvider);

    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Edit Transaction'),
      body: pendingState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (pending) => sourcesState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (sources) {
            if (pending == null) {
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  FinarcEmptyState(
                    title: 'Pending transaction not found',
                    subtitle:
                        'It may have been confirmed, ignored, or deleted.',
                    icon: Icons.search_off_outlined,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FinarcPrimaryButton(
                    onPressed: () => context.go('/pending'),
                    icon: Icons.arrow_back_rounded,
                    label: 'Back to Pending List',
                  ),
                ],
              );
            }
            if (!_initialized) {
              _amount.text = moneyInput(pending.amount);
              _merchant.text = pending.merchant;
              _category.text = pending.categorySuggestion;
              _sourceType = pending.paymentSourceTypeSuggestion;
              _sourceId = pending.paymentSourceIdSuggestion;
              _date = pending.transactionDate;
              _cashbackOn = (pending.cashbackAmount ?? 0) > 0;
              if (_sourceType == PaymentSourceType.cash) {
                _cashbackOn = false;
              }
              _cashback.text = moneyInput(pending.cashbackAmount ?? 0);
              _recoverableParty.text = pending.recoverablePartyName ?? '';
              _forOthers = _recoverableParty.text.trim().isNotEmpty;
              _notes.text = pending.notes ?? '';
              _dateController.text = '${_date.toLocal()}'.split('.').first;
              _initialized = true;
            }
            final previewAmount =
                double.tryParse(_amount.text) ?? pending.amount;
            final previewCashback =
                (_sourceType != PaymentSourceType.cash && _cashbackOn)
                ? (double.tryParse(_cashback.text) ?? 0)
                : 0.0;
            final previewRecoverable = (previewAmount - previewCashback)
                .clamp(0, previewAmount)
                .toDouble();

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  FinarcCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FinarcSectionHeader(title: 'Core Details'),
                        const SizedBox(height: AppSpacing.sm),
                        FinarcTextField(
                          controller: _amount,
                          label: 'Amount',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            final amount = double.tryParse(v ?? '');
                            if (amount == null || amount <= 0) {
                              return 'Amount must be greater than 0';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        FinarcTextField(
                          controller: _merchant,
                          label: 'Merchant / Title',
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Merchant/title is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        FinarcTextField(
                          controller: _category,
                          label: 'Category',
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              ['Food', 'Shopping', 'Bills', 'Travel', 'General']
                                  .map(
                                    (c) => FinarcActionChip(
                                      label: c,
                                      selected:
                                          _category.text.toLowerCase() ==
                                          c.toLowerCase(),
                                      onTap: () =>
                                          setState(() => _category.text = c),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FinarcCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FinarcSectionHeader(title: 'Source & Date'),
                        const SizedBox(height: AppSpacing.sm),
                        Builder(
                          builder: (context) {
                            final sourceConfig = sourceConfigForMode(
                              sources,
                              _sourceType,
                            );
                            _syncSourceSelection(sourceConfig.options);
                            final emptyState = sourceConfig.options.isEmpty
                                ? FinarcPaymentSourceEmptyState(
                                    message: sourceConfig.emptyMessage!,
                                    ctaLabel: sourceConfig.emptyCtaLabel!,
                                    onTap: () => context.push(
                                      sourceConfig.emptyCtaRoute!,
                                    ),
                                  )
                                : null;
                            return FinarcPaymentSelector(
                              title: 'Payment Source',
                              selectedMode: _sourceType,
                              modes: _modeOptions,
                              onModeChanged: (v) => setState(() {
                                _sourceType = v;
                                _sourceId = null;
                                if (v == PaymentSourceType.cash) {
                                  _cashbackOn = false;
                                }
                              }),
                              sources: sourceConfig.options,
                              selectedSourceId: _sourceId,
                              onSourceChanged: (v) =>
                                  setState(() => _sourceId = v),
                              sourceLabel: sourceConfig.fieldLabel,
                              singleSourcePrefix: sourceConfig.singlePrefix,
                              emptyState: emptyState,
                              sourceValidator: (v) {
                                if (sourceConfig.options.length <= 1) {
                                  return null;
                                }
                                return v == null
                                    ? 'Payment source required'
                                    : null;
                              },
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        FinarcTextField(
                          controller: _dateController,
                          label: 'Date/Time',
                          readOnly: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FinarcCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FinarcSectionHeader(title: 'Adjustments'),
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
                                onChanged: (value) => setState(
                                  () => _forOthers = value.trim().isNotEmpty,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_forOthers) ...[
                          const SizedBox(height: AppSpacing.xs),
                          FinarcCard(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  radius: 14,
                                  backgroundColor: AppColors.darkPrimarySoft,
                                  child: Icon(Icons.replay_outlined, size: 14),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    'Recoverable: ${inr(previewRecoverable)} from ${_recoverableParty.text.trim()}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xs),
                        if (_sourceType != PaymentSourceType.cash)
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            value: _cashbackOn,
                            onChanged: (v) => setState(() => _cashbackOn = v),
                            title: const Text('Add Cashback'),
                          ),
                        if (_sourceType != PaymentSourceType.cash &&
                            _cashbackOn)
                          FinarcTextField(
                            controller: _cashback,
                            label: 'Cashback amount',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (v) {
                              if (!_cashbackOn) return null;
                              final cashback = double.tryParse(v ?? '');
                              final amount = double.tryParse(_amount.text) ?? 0;
                              if (cashback == null || cashback < 0) {
                                return 'Enter valid cashback amount';
                              }
                              if (cashback > amount) {
                                return 'Cashback cannot exceed amount';
                              }
                              return null;
                            },
                          ),
                        const SizedBox(height: AppSpacing.sm),
                        FinarcTextField(
                          controller: _notes,
                          label: 'Notes',
                          maxLines: 2,
                          textInputAction: TextInputAction.done,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FinarcCard(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Row(
                      children: [
                        const Icon(Icons.calculate_outlined, size: 16),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Preview remaining: ${inr(_forOthers ? previewRecoverable : 0)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FinarcPrimaryButton(
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      final recoverableParty = _recoverableParty.text.trim();
                      final forOthers = recoverableParty.isNotEmpty;
                      final amount =
                          double.tryParse(_amount.text) ?? pending.amount;
                      final cashback =
                          (_sourceType != PaymentSourceType.cash && _cashbackOn)
                          ? double.tryParse(_cashback.text) ?? 0
                          : 0.0;
                      final recoverableBase = (amount - cashback)
                          .clamp(0, amount)
                          .toDouble();

                      final edited = PendingEditData(
                        amount: amount,
                        merchant: _merchant.text.trim(),
                        category: _category.text.trim(),
                        paymentSourceType: _sourceType,
                        paymentSourceId: _sourceId,
                        transactionDate: _date,
                        cashbackAmount:
                            (_sourceType != PaymentSourceType.cash &&
                                _cashbackOn)
                            ? double.tryParse(_cashback.text) ?? 0
                            : 0,
                        isForOthers: forOthers,
                        recoverableAmount: forOthers
                            ? recoverableBase
                                  .clamp(0, double.infinity)
                                  .toDouble()
                            : null,
                        recoveredAmount: forOthers ? 0 : null,
                        recoverablePartyName: forOthers
                            ? recoverableParty
                            : null,
                        notes: _notes.text.trim().isEmpty
                            ? null
                            : _notes.text.trim(),
                      );
                      await ref
                          .read(pendingActionProvider)
                          .update(widget.pendingId, edited);
                      if (context.mounted) context.pop();
                    },
                    label: 'Save',
                    icon: Icons.check_circle_outline,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _syncSourceSelection(List<FinarcPaymentSourceOption> options) {
    final next = resolveAutoSelectedSourceId(_sourceId, options);
    if (next == _sourceId) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _sourceId = next);
    });
  }
}
