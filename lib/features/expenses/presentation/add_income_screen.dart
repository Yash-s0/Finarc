import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../alerts/data/alerts_providers.dart';
import '../../analytics/data/analytics_providers.dart';
import '../../dashboard/data/dashboard_providers.dart';
import '../data/expenses_providers.dart';
import '../data/transaction_engine.dart';
import '../models/transaction_types.dart';

class AddIncomeScreen extends ConsumerStatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  ConsumerState<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends ConsumerState<AddIncomeScreen> {
  static const _incomeCategories = [
    'Salary',
    'Freelance',
    'Business',
    'Interest',
    'Cashback',
    'Refund',
    'Gift',
    'Other',
  ];

  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _title = TextEditingController();
  final _notes = TextEditingController();
  final _dateController = TextEditingController();

  String _category = _incomeCategories.first;
  String? _destinationType;
  int? _destinationId;
  DateTime? _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _dateController.text = _dateText(_date!);
  }

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    _notes.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sourcesState = ref.watch(paymentSourcesProvider);

    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Add Income'),
      body: sourcesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (sources) => Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              FinarcCard(
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.darkSuccess,
                      child: Icon(
                        Icons.south_west_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Money In: ${inr(double.tryParse(_amount.text) ?? 0)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FinarcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FinarcSectionHeader(title: 'Income Basics'),
                    const SizedBox(height: AppSpacing.sm),
                    FinarcTextField(
                      controller: _amount,
                      label: 'Amount',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        final amount = double.tryParse((v ?? '').trim());
                        if (amount == null || amount <= 0) {
                          return 'Amount must be greater than 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FinarcTextField(
                      controller: _title,
                      label: 'Income source/title',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Title is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: _incomeCategories
                          .map(
                            (category) => DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _category = value ?? _incomeCategories.first;
                        });
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
                    const FinarcSectionHeader(title: 'Destination'),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      initialValue: _destinationType,
                      decoration: const InputDecoration(
                        labelText: 'Destination type',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: PaymentSourceType.bank,
                          child: Text('Bank account'),
                        ),
                        DropdownMenuItem(
                          value: PaymentSourceType.cash,
                          child: Text('Cash wallet'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _destinationType = value;
                          _destinationId = null;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Destination type required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<int>(
                      initialValue: _destinationId,
                      decoration: const InputDecoration(
                        labelText: 'Destination account/wallet',
                      ),
                      items: _destinationItems(sources),
                      onChanged: (value) {
                        setState(() {
                          _destinationId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Destination account/wallet required';
                        }
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
                    const FinarcSectionHeader(title: 'Details'),
                    const SizedBox(height: AppSpacing.sm),
                    FinarcTextField(
                      controller: _dateController,
                      label: 'Date',
                      readOnly: true,
                      suffixIcon: const Icon(Icons.calendar_month_outlined),
                      onTap: () async {
                        final initial = _date ?? DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: initial,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked == null) return;
                        setState(() {
                          _date = picked;
                          _dateController.text = _dateText(picked);
                        });
                      },
                      validator: (value) {
                        if (_date == null) return 'Date required';
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
              const SizedBox(height: AppSpacing.md),
              FinarcPrimaryButton(
                onPressed: _submit,
                label: 'Save Income',
                icon: Icons.check_circle_outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<DropdownMenuItem<int>> _destinationItems(PaymentSourcesData sources) {
    if (_destinationType == PaymentSourceType.cash) {
      return sources.cashWallets
          .map(
            (wallet) => DropdownMenuItem<int>(
              value: wallet.id,
              child: Text(wallet.walletName),
            ),
          )
          .toList(growable: false);
    }

    return sources.banks
        .map(
          (bank) => DropdownMenuItem<int>(
            value: bank.id,
            child: Text(bank.accountName),
          ),
        )
        .toList(growable: false);
  }

  String _dateText(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Date required')));
      return;
    }

    final amount = double.parse(_amount.text.trim());

    try {
      await ref
          .read(transactionEngineProvider)
          .addTransaction(
            AddTransactionInput(
              type: TransactionType.income,
              amount: amount,
              title: _title.text.trim(),
              category: _category,
              notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
              transactionDate: _date!,
              paymentSourceType: _destinationType!,
              paymentSourceId: _destinationId,
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
      ).showSnackBar(SnackBar(content: Text('Unable to save income: $e')));
      return;
    }

    ref.invalidate(expenseListProvider);
    ref.invalidate(dashboardProvider);
    ref.invalidate(analyticsSnapshotProvider);
    if (mounted) context.pop();
  }
}
