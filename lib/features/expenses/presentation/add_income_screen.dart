import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/numeric_input_formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../alerts/data/alerts_providers.dart';
import '../../analytics/data/analytics_providers.dart';
import '../../dashboard/data/dashboard_providers.dart';
import '../data/expenses_providers.dart';
import '../data/transaction_engine.dart';
import '../models/transaction_types.dart';
import 'entry_date_time_utils.dart';
import 'payment_source_selector_support.dart';

class AddIncomeScreen extends ConsumerStatefulWidget {
  const AddIncomeScreen({super.key, this.initialDateTime});

  final DateTime? initialDateTime;

  @override
  ConsumerState<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends ConsumerState<AddIncomeScreen> {
  static const _destinationModes = [
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

  static const _incomeCategories = [
    'General',
    'Income',
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

  String _category = 'General';
  String _destinationType = PaymentSourceType.bank;
  int? _destinationId;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDateTime ?? DateTime.now();
    _dateController.text = _dateText(_date);
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
        data: (sources) {
          final destinationConfig = sourceConfigForMode(
            sources,
            _resolvedDestinationType,
            destination: true,
          );
          _syncDestinationSelection(destinationConfig.options);
          final emptyState = destinationConfig.options.isEmpty
              ? FinarcPaymentSourceEmptyState(
                  message: destinationConfig.emptyMessage!,
                  ctaLabel: destinationConfig.emptyCtaLabel!,
                  onTap: () => context.push(destinationConfig.emptyCtaRoute!),
                )
              : null;
          return Column(
            children: [
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
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
                          selected: const {'income'},
                          onSelectionChanged: (selection) {
                            if (selection.first == 'expense') {
                              context.go('/expenses/add');
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
                              inr(double.tryParse(_amount.text) ?? 0),
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            TextFormField(
                              controller: _amount,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              textInputAction: TextInputAction.next,
                              inputFormatters: [StripLeadingZeroFormatter()],
                              onChanged: (_) => setState(() {}),
                              onFieldSubmitted: (_) =>
                                  FocusScope.of(context).nextFocus(),
                              decoration: const InputDecoration(
                                labelText: 'Enter amount',
                                prefixText: '₹ ',
                              ),
                              validator: (v) {
                                final amount = double.tryParse(
                                  (v ?? '').trim(),
                                );
                                if (amount == null || amount <= 0) {
                                  return 'Amount must be greater than 0';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            FinarcTextField(
                              controller: _title,
                              label: 'Income source/title (optional)',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      FinarcCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FinarcSectionHeader(title: 'Receive Into'),
                            const SizedBox(height: AppSpacing.xs),
                            FinarcPaymentSelector(
                              title: 'Receive into',
                              selectedMode: _destinationType,
                              modes: _destinationModes,
                              onModeChanged: (mode) => setState(() {
                                _destinationType = mode;
                                _destinationId = null;
                              }),
                              sources: destinationConfig.options,
                              selectedSourceId: _destinationId,
                              onSourceChanged: (value) =>
                                  setState(() => _destinationId = value),
                              sourceLabel: destinationConfig.fieldLabel,
                              singleSourcePrefix:
                                  destinationConfig.singlePrefix,
                              emptyState: emptyState,
                              compactModeTiles: true,
                              useSourceCardPicker: true,
                              modeTestPrefix: 'income-mode',
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
                            DropdownButtonFormField<String>(
                              initialValue: _category,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                              ),
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
                                  _category = value ?? 'General';
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
                            FinarcTextField(
                              controller: _dateController,
                              label: 'Transaction date',
                              readOnly: true,
                              suffixIcon: const Icon(
                                Icons.calendar_month_outlined,
                              ),
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _date,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                );
                                if (picked == null) return;
                                setState(() {
                                  _date = mergeDateWithExistingTime(
                                    pickedDate: picked,
                                    existing: _date,
                                  );
                                  _dateController.text = _dateText(_date);
                                });
                              },
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            FinarcTextField(
                              controller: _notes,
                              label: 'Notes (optional)',
                              maxLines: 2,
                              textInputAction: TextInputAction.done,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs,
                  AppSpacing.md,
                  MediaQuery.of(context).viewInsets.bottom + AppSpacing.xs,
                ),
                child: FinarcPrimaryButton(
                  onPressed: _submit,
                  label: 'Save Income',
                  icon: Icons.check_circle_outline,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _syncDestinationSelection(List<FinarcPaymentSourceOption> options) {
    final next = resolveAutoSelectedSourceId(_destinationId, options);
    if (next == _destinationId) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _destinationId = next);
    });
  }

  String _dateText(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final sources = ref.read(paymentSourcesProvider).valueOrNull;
    final destinationConfig = sourceConfigForMode(
      sources ??
          const PaymentSourcesData(banks: [], cards: [], cashWallets: []),
      _resolvedDestinationType,
      destination: true,
    );
    final destinationId = resolveAutoSelectedSourceId(
      _destinationId,
      destinationConfig.options,
    );
    if (destinationId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            destinationConfig.emptyMessage ?? 'Destination account required',
          ),
        ),
      );
      return;
    }
    _destinationId = destinationId;

    final amount = double.parse(_amount.text.trim());
    final rawCategory = _category.trim();
    final category = rawCategory.isEmpty ? 'General' : rawCategory;
    final title = _title.text.trim().isEmpty
        ? ((category.toLowerCase() == 'general' ||
                  category.toLowerCase() == 'income')
              ? 'Income'
              : '$category Income')
        : _title.text.trim();

    try {
      await ref
          .read(transactionEngineProvider)
          .addTransaction(
            AddTransactionInput(
              type: TransactionType.income,
              amount: amount,
              title: title,
              category: category,
              notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
              transactionDate: _date,
              paymentSourceType: _resolvedDestinationType,
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
    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  String get _resolvedDestinationType => _destinationType;
}
