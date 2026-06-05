import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../expenses/data/expenses_providers.dart';
import '../../expenses/models/transaction_types.dart';
import '../../expenses/presentation/payment_source_selector_support.dart';
import '../data/accounts_providers.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  static const _fromModes = [
    FinarcPaymentModeOption(
      value: PaymentSourceType.cash,
      label: 'Wallet/Cash',
      icon: Icons.wallet_rounded,
    ),
    FinarcPaymentModeOption(
      value: PaymentSourceType.bank,
      label: 'Bank',
      icon: Icons.account_balance_rounded,
    ),
  ];

  static const _toModes = [
    FinarcPaymentModeOption(
      value: PaymentSourceType.cash,
      label: 'Wallet/Cash',
      icon: Icons.wallet_rounded,
    ),
    FinarcPaymentModeOption(
      value: PaymentSourceType.bank,
      label: 'Bank',
      icon: Icons.account_balance_rounded,
    ),
    FinarcPaymentModeOption(
      value: PaymentSourceType.creditCard,
      label: 'Card',
      icon: Icons.credit_card_rounded,
    ),
  ];

  final _formKey = GlobalKey<FormState>();
  String _fromType = PaymentSourceType.bank;
  int? _fromId;
  String _toType = PaymentSourceType.cash;
  int? _toId;
  final _amount = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sourcesState = ref.watch(paymentSourcesProvider);
    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Transfer Money'),
      body: sourcesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (sources) {
          final fromConfig = sourceConfigForMode(sources, _fromType);
          final toConfig = sourceConfigForMode(
            sources,
            _toType,
            destination: true,
          );
          _syncSelection(isFrom: true, options: fromConfig.options);
          _syncSelection(isFrom: false, options: toConfig.options);

          final fromLabel = _selectedSourceLabel(_fromId, fromConfig.options);
          final toLabel = _selectedSourceLabel(_toId, toConfig.options);
          final amountValue = double.tryParse(_amount.text) ?? 0;

          final fromEmpty = fromConfig.options.isEmpty
              ? FinarcPaymentSourceEmptyState(
                  message: fromConfig.emptyMessage!,
                  ctaLabel: fromConfig.emptyCtaLabel!,
                  onTap: () => context.push(fromConfig.emptyCtaRoute!),
                )
              : null;
          final toEmpty = toConfig.options.isEmpty
              ? FinarcPaymentSourceEmptyState(
                  message: toConfig.emptyMessage!,
                  ctaLabel: toConfig.emptyCtaLabel!,
                  onTap: () => context.push(toConfig.emptyCtaRoute!),
                )
              : null;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                FinarcCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FinarcSectionHeader(title: 'Transfer Direction'),
                      const SizedBox(height: AppSpacing.sm),
                      FinarcPaymentSelector(
                        title: 'Transfer from',
                        selectedMode: _fromType,
                        modes: _fromModes,
                        onModeChanged: (v) => setState(() {
                          _fromType = v;
                          _fromId = null;
                        }),
                        sources: fromConfig.options,
                        selectedSourceId: _fromId,
                        onSourceChanged: (v) => setState(() => _fromId = v),
                        sourceLabel: fromConfig.fieldLabel,
                        singleSourcePrefix: fromConfig.singlePrefix,
                        emptyState: fromEmpty,
                        sourceValidator: (v) {
                          if (fromConfig.options.length <= 1) return null;
                          if (v == null) return 'Source required';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      FinarcPaymentSelector(
                        title: 'Transfer to',
                        selectedMode: _toType,
                        modes: _toModes,
                        onModeChanged: (v) => setState(() {
                          _toType = v;
                          _toId = null;
                        }),
                        sources: toConfig.options,
                        selectedSourceId: _toId,
                        onSourceChanged: (v) => setState(() => _toId = v),
                        sourceLabel: toConfig.fieldLabel,
                        singleSourcePrefix: toConfig.singlePrefix,
                        emptyState: toEmpty,
                        sourceValidator: (v) {
                          if (toConfig.options.length <= 1) return null;
                          if (v == null) return 'Destination required';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                FinarcCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FinarcSectionHeader(title: 'Amount & Notes'),
                      const SizedBox(height: AppSpacing.sm),
                      FinarcTextField(
                        controller: _amount,
                        label: 'Amount',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) {
                          final parsed = double.tryParse(v ?? '');
                          if (parsed == null || parsed <= 0) {
                            return 'Enter amount > 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      FinarcTextField(
                        controller: _notes,
                        label: 'Notes (optional)',
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                FinarcCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FinarcSectionHeader(title: 'Transfer Summary'),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              fromLabel,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                          Expanded(
                            child: Text(
                              toLabel,
                              textAlign: TextAlign.end,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        inr(amountValue),
                        style: AppTextStyles.amountStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 24,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FinarcPrimaryButton(
                  onPressed: () => _submit(context),
                  label: 'Confirm Transfer',
                  icon: Icons.check_circle_outline,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _selectedSourceLabel(
    int? id,
    List<FinarcPaymentSourceOption> options,
  ) {
    if (id == null) return 'Select';
    for (final option in options) {
      if (option.id == id) return option.label;
    }
    return 'Select';
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final sources = ref.read(paymentSourcesProvider).valueOrNull;
    final fromConfig = sourceConfigForMode(
      sources ??
          const PaymentSourcesData(banks: [], cards: [], cashWallets: []),
      _fromType,
    );
    final toConfig = sourceConfigForMode(
      sources ??
          const PaymentSourcesData(banks: [], cards: [], cashWallets: []),
      _toType,
      destination: true,
    );
    final fromId = resolveAutoSelectedSourceId(_fromId, fromConfig.options);
    final toId = resolveAutoSelectedSourceId(_toId, toConfig.options);

    if (fromId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(fromConfig.emptyMessage ?? 'Select source')),
      );
      return;
    }
    if (toId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(toConfig.emptyMessage ?? 'Select destination')),
      );
      return;
    }
    if (_fromType == _toType && fromId == toId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('From and To cannot be the same account')),
      );
      return;
    }

    final amount = double.tryParse(_amount.text) ?? 0;
    final result = await ref
        .read(accountServiceProvider)
        .transferBetweenAccounts(
          sourceType: _fromType,
          sourceId: fromId,
          destinationType: _toType,
          destinationId: toId,
          amount: amount,
          transactionDate: DateTime.now(),
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );

    ref.invalidate(accountsOverviewProvider);
    ref.invalidate(expenseListProvider);
    if (!mounted) return;
    if (result.transferredAmount <= 0.009) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
          content: Text(
            result.message ?? 'No transfer was applied for the selected card.',
          ),
        ),
      );
      return;
    }
    if (result.message != null && result.message!.trim().isNotEmpty) {
      ScaffoldMessenger.of(
        this.context,
      ).showSnackBar(SnackBar(content: Text(result.message!)));
    }
    this.context.push(
      '/accounts/transfer/success?amount=${result.transferredAmount}&from=$_fromType&to=$_toType',
    );
  }

  void _syncSelection({
    required bool isFrom,
    required List<FinarcPaymentSourceOption> options,
  }) {
    final current = isFrom ? _fromId : _toId;
    final next = resolveAutoSelectedSourceId(current, options);
    if (next == current) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        if (isFrom) {
          _fromId = next;
        } else {
          _toId = next;
        }
      });
    });
  }
}
