import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/numeric_input_formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../analytics/data/analytics_providers.dart';
import '../../dashboard/data/dashboard_providers.dart';
import '../data/expenses_providers.dart';
import '../data/transaction_engine.dart';
import '../models/transaction_types.dart';

final transactionByIdProvider = FutureProvider.family((ref, int id) async {
  await ref.watch(seedProvider.future);
  final db = ref.read(appDatabaseProvider);
  return (db.select(db.transactions)..where((t) => t.id.equals(id))).getSingleOrNull();
});

class TransactionDetailScreen extends ConsumerStatefulWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});

  final int transactionId;

  @override
  ConsumerState<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends ConsumerState<TransactionDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _title = TextEditingController();
  final _category = TextEditingController();
  final _notes = TextEditingController();
  final _dateController = TextEditingController();
  final _cashback = TextEditingController();
  final _recoverable = TextEditingController();

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
    _recoverable.dispose();
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
            final editable = ref.read(transactionEngineProvider).isEditable(txn);
            if (!_initialized) {
              _amount.text = txn.amount.toStringAsFixed(2);
              _title.text = txn.title;
              _category.text = txn.category;
              _notes.text = txn.notes ?? '';
              _date = txn.transactionDate;
              _dateController.text = _date.toIso8601String().split('T').first;
              _sourceType = txn.paymentSourceType;
              _sourceId = txn.paymentSourceId;
              _forOthers = txn.isForOthers;
              _cashback.text = txn.cashbackAmount.toStringAsFixed(2);
              _recoverable.text = (txn.recoverableAmount ?? 0).toStringAsFixed(2);
              _type = txn.type;
              _initialized = true;
            }

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  if (!editable)
                    const FinarcCard(
                      child: Text('This transaction has linked/system effects, so only viewing is allowed.'),
                    ),
                  if (!editable) const SizedBox(height: AppSpacing.sm),
                  FinarcTextField(
                    controller: _amount,
                    label: 'Amount',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [StripLeadingZeroFormatter()],
                    validator: (v) {
                      final amount = double.tryParse(v ?? '');
                      if (amount == null || amount <= 0) return 'Amount must be greater than 0';
                      return null;
                    },
                    readOnly: !editable,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  FinarcTextField(
                    controller: _title,
                    label: 'Title',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    readOnly: !editable,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  FinarcTextField(controller: _category, label: 'Category', readOnly: !editable),
                  const SizedBox(height: AppSpacing.xs),
                  DropdownButtonFormField<String>(
                    initialValue: _sourceType,
                    decoration: const InputDecoration(labelText: 'Payment source'),
                    onChanged: !editable
                        ? null
                        : (v) {
                            setState(() {
                              _sourceType = v ?? PaymentSourceType.cash;
                              _sourceId = null;
                            });
                          },
                    items: _sourceItemsForType(txn.type),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (_sourceType != PaymentSourceType.cash)
                    DropdownButtonFormField<int>(
                      initialValue: _sourceId,
                      decoration: const InputDecoration(labelText: 'Source account/card'),
                      onChanged: !editable ? null : (v) => setState(() => _sourceId = v),
                      items: _sourceItems(sources),
                      validator: (v) => v == null ? 'Source required' : null,
                    )
                  else
                    const Text('Cash source auto-selected'),
                  const SizedBox(height: AppSpacing.xs),
                  FinarcTextField(controller: _dateController, label: 'Date', readOnly: true),
                  const SizedBox(height: AppSpacing.xs),
                  if (_sourceType != PaymentSourceType.cash)
                    FinarcTextField(
                      controller: _cashback,
                      label: 'Cashback',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [StripLeadingZeroFormatter()],
                      readOnly: !editable,
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  SwitchListTile.adaptive(
                    title: const Text('For others'),
                    contentPadding: EdgeInsets.zero,
                    value: _forOthers,
                    onChanged: !editable ? null : (v) => setState(() => _forOthers = v),
                  ),
                  if (_forOthers)
                    FinarcTextField(
                      controller: _recoverable,
                      label: 'Recoverable amount',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [StripLeadingZeroFormatter()],
                      readOnly: !editable,
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  FinarcTextField(controller: _notes, label: 'Notes', maxLines: 2, readOnly: !editable),
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

  List<DropdownMenuItem<String>> _sourceItemsForType(String txnType) {
    if (txnType == TransactionType.income) {
      return const [
        DropdownMenuItem(value: PaymentSourceType.bank, child: Text('Bank')),
        DropdownMenuItem(value: PaymentSourceType.cash, child: Text('Cash')),
      ];
    }
    if (txnType == TransactionType.creditCard) {
      return const [
        DropdownMenuItem(value: PaymentSourceType.creditCard, child: Text('Credit Card')),
      ];
    }
    return const [
      DropdownMenuItem(value: PaymentSourceType.bank, child: Text('Bank')),
      DropdownMenuItem(value: PaymentSourceType.upi, child: Text('UPI')),
      DropdownMenuItem(value: PaymentSourceType.cash, child: Text('Cash')),
      DropdownMenuItem(value: PaymentSourceType.creditCard, child: Text('Credit Card')),
    ];
  }

  List<DropdownMenuItem<int>> _sourceItems(PaymentSourcesData sources) {
    if (_sourceType == PaymentSourceType.creditCard) {
      return sources.cards
          .map((c) => DropdownMenuItem(value: c.id, child: Text('${c.bankName} • ${c.last4}')))
          .toList();
    }
    if (_sourceType == PaymentSourceType.cash) {
      return sources.cashWallets
          .map((w) => DropdownMenuItem(value: w.id, child: Text(w.walletName)))
          .toList();
    }
    return sources.banks
        .map((b) => DropdownMenuItem(value: b.id, child: Text(b.accountName)))
        .toList();
  }

  Future<void> _save(dynamic txn) async {
    if (!_formKey.currentState!.validate()) return;
    final sources = ref.read(paymentSourcesProvider).valueOrNull;
    var sourceId = _sourceId;
    if (_sourceType == PaymentSourceType.cash) {
      final wallets = sources?.cashWallets ?? const [];
      sourceId = wallets.isEmpty ? null : wallets.first.id;
    }

    try {
      await ref.read(transactionEngineProvider).updateTransaction(
            txn.id,
            AddTransactionInput(
              type: _type,
              amount: double.parse(_amount.text),
              title: _title.text.trim(),
              category: _category.text.trim(),
              transactionDate: _date,
              paymentSourceType: _sourceType,
              paymentSourceId: sourceId,
              cashbackAmount: _sourceType == PaymentSourceType.cash ? 0 : (double.tryParse(_cashback.text) ?? 0),
              isForOthers: _forOthers,
              recoverableAmount: _forOthers ? (double.tryParse(_recoverable.text) ?? 0) : null,
              notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
            ),
          );
      _invalidateAll();
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unable to update: $e')));
    }
  }

  Future<void> _delete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('This will reverse its balance effect.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unable to delete: $e')));
    }
  }

  void _invalidateAll() {
    ref.invalidate(expenseListProvider);
    ref.invalidate(dashboardProvider);
    ref.invalidate(analyticsSnapshotProvider);
    ref.invalidate(transactionByIdProvider(widget.transactionId));
  }
}
