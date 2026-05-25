import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../alerts/data/alerts_providers.dart';
import '../../cards/data/cards_providers.dart';
import '../data/expenses_providers.dart';
import '../data/transaction_engine.dart';
import '../models/transaction_types.dart';
import '../../../core/database/database_providers.dart';

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
  final _recoverable = TextEditingController(text: '0');
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
    _recoverable.dispose();
    _notes.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sourceState = ref.watch(paymentSourcesProvider);

    return FinarcScaffold(
      appBar: FinarcAppBar(
        title: widget.isIncome ? 'Add Income' : 'Add Expense',
      ),
      body: sourceState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (sources) => Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              FinarcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FinarcSectionHeader(title: 'Transaction Basics'),
                    const SizedBox(height: AppSpacing.sm),
                    FinarcTextField(
                      controller: _amount,
                      label: 'Amount',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        final amt = double.tryParse(v ?? '');
                        if (amt == null || amt <= 0) {
                          return 'Amount must be greater than 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FinarcTextField(
                      controller: _title,
                      label: 'Merchant / Title',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FinarcTextField(controller: _category, label: 'Category'),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FinarcSectionHeader(title: 'Payment Source'),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      initialValue: _paymentMode,
                      decoration: const InputDecoration(
                        labelText: 'Payment mode',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: PaymentSourceType.cash,
                          child: Text('Cash'),
                        ),
                        DropdownMenuItem(
                          value: PaymentSourceType.upi,
                          child: Text('UPI'),
                        ),
                        DropdownMenuItem(
                          value: PaymentSourceType.bank,
                          child: Text('Bank'),
                        ),
                        DropdownMenuItem(
                          value: PaymentSourceType.creditCard,
                          child: Text('Credit Card'),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _paymentMode = v ?? PaymentSourceType.cash;
                          _sourceId = null;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<int>(
                      initialValue: _sourceId,
                      decoration: const InputDecoration(
                        labelText: 'Source selector',
                      ),
                      items: _sourceItems(sources),
                      onChanged: (v) => setState(() => _sourceId = v),
                      validator: (v) {
                        if (v == null) return 'Payment source required';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FinarcTextField(
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
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FinarcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FinarcSectionHeader(title: 'Adjustments'),
                    const SizedBox(height: AppSpacing.sm),
                    FinarcTextField(
                      controller: _cashback,
                      label: 'Cashback amount (optional)',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final value = double.tryParse(v.trim());
                        if (value == null || value < 0) {
                          return 'Enter valid cashback';
                        }
                        final amount = double.tryParse(_amount.text.trim()) ?? 0;
                        if (value > amount && amount > 0) {
                          return 'Cashback cannot exceed amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _forOthers,
                      onChanged: (v) => setState(() => _forOthers = v),
                      title: const Text('For others?'),
                    ),
                    if (_forOthers) ...[
                      const SizedBox(height: AppSpacing.xs),
                      FinarcTextField(
                        controller: _recoverable,
                        label: 'Recoverable amount',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) {
                          if (!_forOthers) return null;
                          if (v == null || v.trim().isEmpty) {
                            return 'Recoverable amount required';
                          }
                          final value = double.tryParse(v.trim());
                          if (value == null || value < 0) {
                            return 'Enter valid recoverable amount';
                          }
                          final amount = double.tryParse(_amount.text.trim()) ?? 0;
                          if (value > amount && amount > 0) {
                            return 'Recoverable cannot exceed amount';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    FinarcTextField(
                      controller: _notes,
                      label: 'Notes',
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FinarcCard(
                padding: const EdgeInsets.all(AppSpacing.sm),
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
                        'Preview amount: ${inr(double.tryParse(_amount.text) ?? 0)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FinarcPrimaryButton(
                onPressed: _submit,
                label: 'Save Transaction',
                icon: Icons.check_circle_outline,
              ),
            ],
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amount.text.trim());
    final cashback = double.tryParse(_cashback.text.trim()) ?? 0;
    final recoverable = _forOthers
        ? double.tryParse(_recoverable.text.trim()) ?? 0
        : null;
    if (cashback > amount) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cashback cannot exceed amount')),
      );
      return;
    }
    if (_forOthers && recoverable != null && recoverable > amount) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recoverable cannot exceed amount')),
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
              recoverableAmount: recoverable,
            ),
          );

      final db = ref.read(appDatabaseProvider);
      final latest = await (db.select(
        db.transactions,
      )..orderBy([(t) => OrderingTerm.desc(t.id)])..limit(1)).getSingleOrNull();
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
