import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/numeric_input_formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../alerts/data/alerts_providers.dart';
import '../../cards/data/cards_providers.dart';
import '../data/expenses_providers.dart';
import '../data/transaction_engine.dart';
import '../models/transaction_types.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key, this.isIncome = false});

  final bool isIncome;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _title = TextEditingController();
  final _category = TextEditingController(text: 'General');
  final _cashback = TextEditingController(text: '0');
  final _recoverableParty = TextEditingController();
  final _recovered = TextEditingController(text: '0');
  final _notes = TextEditingController();
  final _dateController = TextEditingController();

  String _paymentMode = PaymentSourceType.cash;
  int? _sourceId;
  bool _forOthers = false;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _dateController.text = _dateText(_date);
  }

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    _category.dispose();
    _cashback.dispose();
    _recoverableParty.dispose();
    _recovered.dispose();
    _notes.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sourceState = ref.watch(paymentSourcesProvider);
    final amount = double.tryParse(_amount.text.trim()) ?? 0;
    final cashback = _paymentMode == PaymentSourceType.cash
        ? 0.0
        : (double.tryParse(_cashback.text.trim()) ?? 0);
    final recoverable = _forOthers
        ? (amount - cashback).clamp(0, amount).toDouble()
        : 0.0;
    final recovered = _forOthers
        ? (double.tryParse(_recovered.text.trim()) ?? 0)
              .clamp(0, recoverable)
              .toDouble()
        : 0.0;
    final remaining = (recoverable - recovered)
        .clamp(0, recoverable)
        .toDouble();
    final recoverableSuggestions = ref.watch(
      recoverablePartySuggestionsProvider,
    );

    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Add Expense'),
      body: sourceState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (sources) => Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              FinarcCard(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment<String>(
                      value: 'expense',
                      label: Text('Expense'),
                    ),
                    ButtonSegment<String>(
                      value: 'income',
                      label: Text('Income'),
                    ),
                  ],
                  selected: const {'expense'},
                  onSelectionChanged: (selection) {
                    if (selection.first == 'income') {
                      context.go('/income/add');
                    }
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FinarcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inr(amount),
                      style: AppTextStyles.amountStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 33,
                        weight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextFormField(
                      controller: _amount,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [StripLeadingZeroFormatter()],
                      onChanged: (_) => setState(() {}),
                      style: AppTextStyles.amountStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 40,
                        weight: FontWeight.w800,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Enter amount',
                        prefixText: '₹ ',
                      ),
                      validator: (v) {
                        final amt = double.tryParse(v ?? '');
                        if (amt == null || amt <= 0) {
                          return 'Amount must be greater than 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    FinarcTextField(
                      controller: _title,
                      label: 'Merchant / Title',
                      prefixIcon: const Icon(
                        Icons.storefront_rounded,
                        size: 18,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
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
                    const FinarcSectionHeader(title: 'Payment Mode'),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _modeChip(
                          PaymentSourceType.cash,
                          Icons.wallet_rounded,
                          'Wallet/Cash',
                        ),
                        _modeChip(
                          PaymentSourceType.upi,
                          Icons.qr_code_scanner_rounded,
                          'UPI',
                        ),
                        _modeChip(
                          PaymentSourceType.creditCard,
                          Icons.credit_card_rounded,
                          'Card',
                        ),
                        _modeChip(
                          PaymentSourceType.bank,
                          Icons.account_balance_rounded,
                          'Bank',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (_paymentMode == PaymentSourceType.cash &&
                        sources.cashWallets.isEmpty)
                      const Text(
                        'No cash wallet found. Add one from Accounts.',
                        style: TextStyle(color: AppColors.darkWarning),
                      ),
                    if (_paymentMode == PaymentSourceType.cash &&
                        sources.cashWallets.length == 1)
                      Text(
                        'Using wallet: ${sources.cashWallets.first.walletName}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    if (_shouldShowSourceSelector(sources))
                      DropdownButtonFormField<int>(
                        initialValue: _sourceId,
                        decoration: InputDecoration(
                          labelText: _paymentMode == PaymentSourceType.cash
                              ? 'Wallet'
                              : 'Source selector',
                        ),
                        items: _sourceItems(sources),
                        onChanged: (v) => setState(() => _sourceId = v),
                        validator: (v) {
                          if (_paymentMode == PaymentSourceType.cash &&
                              sources.cashWallets.length <= 1) {
                            return null;
                          }
                          if (v == null) return 'Payment source required';
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
                    const FinarcSectionHeader(title: 'Category'),
                    const SizedBox(height: AppSpacing.xs),
                    FinarcTextField(controller: _category, label: 'Category'),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children:
                          ['Food', 'Groceries', 'Bills', 'Travel', 'Health']
                              .map(
                                (c) => FinarcActionChip(
                                  label: c,
                                  selected:
                                      _category.text.trim().toLowerCase() ==
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
                child: FinarcTextField(
                  controller: _dateController,
                  label: 'Transaction date',
                  readOnly: true,
                  suffixIcon: const Icon(Icons.calendar_month_outlined),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        _date = picked;
                        _dateController.text = _dateText(_date);
                      });
                    }
                  },
                ),
              ),
              if (_paymentMode != PaymentSourceType.cash) ...[
                const SizedBox(height: AppSpacing.sm),
                FinarcCard(
                  child: FinarcTextField(
                    controller: _cashback,
                    label: 'Cashback amount',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [StripLeadingZeroFormatter()],
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final value = double.tryParse(v.trim());
                      if (value == null || value < 0) {
                        return 'Enter valid cashback';
                      }
                      final enteredAmount =
                          double.tryParse(_amount.text.trim()) ?? 0;
                      if (value > enteredAmount && enteredAmount > 0) {
                        return 'Cashback cannot exceed amount';
                      }
                      return null;
                    },
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              FinarcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _forOthers,
                      onChanged: (v) => setState(() {
                        _forOthers = v;
                        if (!v) _recoverableParty.clear();
                      }),
                      title: const Text('For Others?'),
                    ),
                    if (_forOthers) ...[
                      const SizedBox(height: AppSpacing.xs),
                      FinarcTextField(
                        controller: _recoverableParty,
                        label: 'Paid for whom?',
                        validator: (v) {
                          if (!_forOthers) return null;
                          if (v == null || v.trim().isEmpty) {
                            return 'Person/contact required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      FinarcTextField(
                        controller: _recovered,
                        label: 'Recovered amount (optional)',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [StripLeadingZeroFormatter()],
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          if (!_forOthers) return null;
                          if (v == null || v.trim().isEmpty) return null;
                          final value = double.tryParse(v.trim());
                          if (value == null || value < 0) {
                            return 'Enter valid recovered amount';
                          }
                          if (value > recoverable) {
                            return 'Recovered cannot exceed recoverable base';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      if (recoverableSuggestions.hasValue &&
                          (recoverableSuggestions.valueOrNull ?? []).isNotEmpty)
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: recoverableSuggestions.valueOrNull!
                              .take(6)
                              .map(
                                (name) => FinarcActionChip(
                                  label: name,
                                  selected:
                                      _recoverableParty.text.trim() == name,
                                  onTap: () => setState(
                                    () => _recoverableParty.text = name,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FinarcCard(
                child: FinarcTextField(
                  controller: _notes,
                  label: 'Notes',
                  maxLines: 2,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FinarcCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.darkPrimarySoft,
                      child: Icon(Icons.receipt_long_outlined, size: 14),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _forOthers
                            ? 'Recoverable base ${inr(recoverable)} • Recovered ${inr(recovered)} • Remaining ${inr(remaining)}'
                            : 'Preview amount: ${inr(amount)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: FinarcPrimaryButton(
            onPressed: _submit,
            label: 'Save Expense',
            icon: Icons.check_circle_outline,
          ),
        ),
      ),
    );
  }

  String _dateText(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  List<DropdownMenuItem<int>> _sourceItems(PaymentSourcesData sources) {
    if (_paymentMode == PaymentSourceType.creditCard) {
      return sources.cards
          .map<DropdownMenuItem<int>>(
            (c) => DropdownMenuItem<int>(
              value: c.id,
              child: Text('${c.bankName} • ${c.last4}'),
            ),
          )
          .toList();
    }
    if (_paymentMode == PaymentSourceType.cash) {
      return sources.cashWallets
          .map<DropdownMenuItem<int>>(
            (w) =>
                DropdownMenuItem<int>(value: w.id, child: Text(w.walletName)),
          )
          .toList();
    }
    return sources.banks
        .map<DropdownMenuItem<int>>(
          (b) => DropdownMenuItem<int>(value: b.id, child: Text(b.accountName)),
        )
        .toList();
  }

  bool _shouldShowSourceSelector(PaymentSourcesData sources) {
    if (_paymentMode != PaymentSourceType.cash) return true;
    return sources.cashWallets.length > 1;
  }

  Widget _modeChip(String mode, IconData icon, String label) {
    final selected = _paymentMode == mode;
    return InkWell(
      onTap: () {
        setState(() {
          _paymentMode = mode;
          _sourceId = null;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.darkPrimarySoft
              : AppColors.darkSurfaceLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.darkAccent.withValues(alpha: 0.8)
                : AppColors.darkBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected
                  ? AppColors.darkAccent
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.75),
            ),
            const SizedBox(width: 6),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final sources = ref.read(paymentSourcesProvider).valueOrNull;
    if (_paymentMode == PaymentSourceType.cash) {
      final wallets = sources?.cashWallets ?? const [];
      final cashId = _sourceId ?? (wallets.isEmpty ? null : wallets.first.id);
      if (cashId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Add a cash wallet before recording cash payments.'),
          ),
        );
        return;
      }
      _sourceId = cashId;
    }

    final amount = double.parse(_amount.text.trim());
    final cashback = _paymentMode == PaymentSourceType.cash
        ? 0.0
        : (double.tryParse(_cashback.text.trim()) ?? 0);
    final recoverableBase = _forOthers
        ? (amount - cashback).clamp(0, amount).toDouble()
        : 0.0;
    final recovered = _forOthers
        ? (double.tryParse(_recovered.text.trim()) ?? 0)
              .clamp(0, recoverableBase)
              .toDouble()
        : 0.0;
    if (cashback > amount) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cashback cannot exceed amount')),
      );
      return;
    }

    final type = widget.isIncome
        ? TransactionType.income
        : _paymentMode == PaymentSourceType.creditCard
        ? TransactionType.creditCard
        : _paymentMode;

    try {
      await ref
          .read(transactionEngineProvider)
          .addTransaction(
            AddTransactionInput(
              type: type,
              amount: amount,
              title: _title.text.trim(),
              category: _category.text.trim(),
              notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
              transactionDate: _date,
              paymentSourceType: _paymentMode,
              paymentSourceId: _sourceId,
              cashbackAmount: cashback,
              isForOthers: _forOthers,
              recoverableAmount: _forOthers
                  ? (recoverableBase - recovered)
                        .clamp(0, recoverableBase)
                        .toDouble()
                  : null,
              recoveredAmount: recovered,
              recoverablePartyName: _forOthers
                  ? _recoverableParty.text.trim()
                  : null,
            ),
          );

      final db = ref.read(appDatabaseProvider);
      final latest =
          await (db.select(db.transactions)
                ..orderBy([(t) => OrderingTerm.desc(t.id)])
                ..limit(1))
              .getSingleOrNull();
      if (latest != null) {
        await ref
            .read(alertEvaluationActionsProvider)
            .evaluateAfterTransaction(latest);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to save transaction: $e')));
      return;
    }

    ref.invalidate(expenseListProvider);
    ref.invalidate(cardsOverviewProvider);
    if (mounted) context.pop();
  }
}
