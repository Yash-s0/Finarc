import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../expenses/data/expenses_providers.dart';
import '../../expenses/models/transaction_types.dart';
import '../../expenses/presentation/payment_source_selector_support.dart';
import '../data/loans_providers.dart';

class EmiPaymentScreen extends ConsumerStatefulWidget {
  const EmiPaymentScreen({super.key, required this.loanId});

  final int loanId;

  @override
  ConsumerState<EmiPaymentScreen> createState() => _EmiPaymentScreenState();
}

class _EmiPaymentScreenState extends ConsumerState<EmiPaymentScreen> {
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
      value: PaymentSourceType.bank,
      label: 'Bank',
      icon: Icons.account_balance_rounded,
    ),
  ];

  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  final _dateText = TextEditingController();
  DateTime _date = DateTime.now();
  String _sourceType = 'bank';
  int? _sourceId;

  @override
  void initState() {
    super.initState();
    _dateText.text = '${_date.day}/${_date.month}/${_date.year}';
  }

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    _dateText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loanId <= 0) {
      return FinarcScaffold(
        appBar: const FinarcAppBar(title: 'Pay EMI'),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const FinarcEmptyState(
              title: 'Invalid loan route',
              subtitle: 'This payment link is invalid.',
              icon: Icons.error_outline,
            ),
            const SizedBox(height: AppSpacing.sm),
            FinarcPrimaryButton(
              onPressed: () => context.go('/loans'),
              icon: Icons.arrow_back_rounded,
              label: 'Back to Loans',
            ),
          ],
        ),
      );
    }

    final detail = ref.watch(loanDetailProvider(widget.loanId));
    final sources = ref.watch(paymentSourcesProvider);

    return detail.when(
      loading: () => const FinarcScaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => FinarcScaffold(
        appBar: const FinarcAppBar(title: 'Pay EMI'),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const FinarcEmptyState(
              title: 'Loan not found',
              subtitle: 'This loan may have been deleted after reset.',
              icon: Icons.account_balance_wallet_outlined,
            ),
            const SizedBox(height: AppSpacing.sm),
            FinarcPrimaryButton(
              onPressed: () => context.go('/loans'),
              icon: Icons.arrow_back_rounded,
              label: 'Back to Loans',
            ),
          ],
        ),
      ),
      data: (loanData) {
        if (_amount.text.isEmpty) {
          _amount.text = (loanData.loan.emiAmount ?? 0).toStringAsFixed(0);
        }

        return FinarcScaffold(
          appBar: const FinarcAppBar(title: 'Pay EMI'),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                FinarcCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FinarcSectionHeader(title: 'Loan Summary'),
                      const SizedBox(height: AppSpacing.xs),
                      Text(loanData.loan.title),
                      const SizedBox(height: 2),
                      Text(
                        'Outstanding ${inr(loanData.loan.currentOutstanding)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                FinarcCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FinarcSectionHeader(title: 'Payment Details'),
                      const SizedBox(height: AppSpacing.sm),
                      FinarcTextField(
                        controller: _amount,
                        label: 'Payment amount',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) {
                          final value = double.tryParse(v ?? '');
                          if (value == null || value <= 0) {
                            return 'Enter valid amount';
                          }
                          if (value > loanData.loan.currentOutstanding) {
                            return 'Amount cannot exceed outstanding balance';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      sources.when(
                        loading: () => const FinarcLoadingSkeleton(height: 56),
                        error: (e, _) => Text(
                          'Unable to load payment sources.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        data: (sourceData) {
                          final sourceConfig = sourceConfigForMode(
                            sourceData,
                            _sourceType,
                          );
                          _syncSourceSelection(sourceConfig.options);
                          final emptyState = sourceConfig.options.isEmpty
                              ? FinarcPaymentSourceEmptyState(
                                  message: sourceConfig.emptyMessage!,
                                  ctaLabel: sourceConfig.emptyCtaLabel!,
                                  onTap: () =>
                                      context.push(sourceConfig.emptyCtaRoute!),
                                )
                              : null;
                          return FinarcPaymentSelector(
                            title: 'Payment Source',
                            selectedMode: _sourceType,
                            modes: _modeOptions,
                            onModeChanged: (v) => setState(() {
                              _sourceType = v;
                              _sourceId = null;
                            }),
                            sources: sourceConfig.options,
                            selectedSourceId: _sourceId,
                            onSourceChanged: (value) =>
                                setState(() => _sourceId = value),
                            sourceLabel: sourceConfig.fieldLabel,
                            singleSourcePrefix: sourceConfig.singlePrefix,
                            emptyState: emptyState,
                            sourceValidator: (value) {
                              if (sourceConfig.options.length <= 1) {
                                return null;
                              }
                              return value == null ? 'Select source' : null;
                            },
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      FinarcTextField(
                        label: 'Payment date',
                        controller: _dateText,
                        readOnly: true,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              _date = picked;
                              _dateText.text =
                                  '${_date.day}/${_date.month}/${_date.year}';
                            });
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      FinarcTextField(
                        controller: _notes,
                        label: 'Notes',
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FinarcPrimaryButton(
                  onPressed: _submit,
                  icon: Icons.check_circle_outline,
                  label: 'Confirm EMI Payment',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final sources = ref.read(paymentSourcesProvider).valueOrNull;
    final sourceConfig = sourceConfigForMode(
      sources ??
          const PaymentSourcesData(banks: [], cards: [], cashWallets: []),
      _sourceType,
    );
    final sourceId = resolveAutoSelectedSourceId(
      _sourceId,
      sourceConfig.options,
    );
    if (sourceId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(sourceConfig.emptyMessage ?? 'Select source')),
      );
      return;
    }

    final amount = double.parse(_amount.text);
    await ref
        .read(loanActionsProvider)
        .markEmiPaid(
          loanId: widget.loanId,
          amount: amount,
          paymentSourceType: _sourceType,
          paymentSourceId: sourceId,
          paymentDate: _date,
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('EMI payment recorded: ${inr(amount)}')),
    );
    context.pop();
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
