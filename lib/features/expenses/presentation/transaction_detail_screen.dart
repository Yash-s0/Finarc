import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/database_providers.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _title = TextEditingController();
  final _category = TextEditingController();
  final _notes = TextEditingController();
  final _dateController = TextEditingController();
  final _cashback = TextEditingController();
  final _recoverableParty = TextEditingController();
  final _recoveredAmount = TextEditingController(text: '0');

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
    _recoveredAmount.dispose();
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
              _dateController.text = _date.toIso8601String().split('T').first;
              _sourceType = txn.paymentSourceType;
              _sourceId = txn.paymentSourceId;
              _forOthers = txn.isForOthers;
              _cashback.text = txn.cashbackAmount.toStringAsFixed(2);
              _recoverableParty.text = txn.recoverablePartyName ?? '';
              _recoveredAmount.text = txn.recoveredAmount.toStringAsFixed(2);
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
                ? (double.tryParse(_recoveredAmount.text) ??
                          txn.recoveredAmount)
                      .clamp(0, recoverableBase)
                      .toDouble()
                : 0.0;
            final remainingRecoverable = (recoverableBase - recoveredAmount)
                .clamp(0, recoverableBase)
                .toDouble();

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
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
                  DropdownButtonFormField<String>(
                    initialValue: _sourceType,
                    decoration: const InputDecoration(
                      labelText: 'Payment source',
                    ),
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
                      decoration: const InputDecoration(
                        labelText: 'Source account/card',
                      ),
                      onChanged: !editable
                          ? null
                          : (v) => setState(() => _sourceId = v),
                      items: _sourceItems(sources),
                      validator: (v) => v == null ? 'Source required' : null,
                    )
                  else
                    const Text('Cash source auto-selected'),
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
                  SwitchListTile.adaptive(
                    title: const Text('For others'),
                    contentPadding: EdgeInsets.zero,
                    value: _forOthers,
                    onChanged: !editable
                        ? null
                        : (v) => setState(() => _forOthers = v),
                  ),
                  if (_forOthers)
                    FinarcCard(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const FinarcSectionHeader(
                            title: 'Recoverable Details',
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Recoverable amount is auto-calculated from amount - cashback.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.sm),
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
                          const SizedBox(height: AppSpacing.xs),
                          FinarcTextField(
                            controller: _recoveredAmount,
                            label: 'Recovered amount',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [StripLeadingZeroFormatter()],
                            readOnly: !editable,
                            onChanged: (_) => setState(() {}),
                            validator: (v) {
                              if (!_forOthers) return null;
                              if (v == null || v.trim().isEmpty) return null;
                              final recovered = double.tryParse(v.trim());
                              if (recovered == null || recovered < 0) {
                                return 'Enter valid recovered amount';
                              }
                              if (recovered > recoverableBase) {
                                return 'Recovered cannot exceed recoverable base';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          FinarcTextField(
                            controller: _recoverableParty,
                            label: 'Paid for whom?',
                            readOnly: !editable,
                            validator: (v) {
                              if (!_forOthers) return null;
                              if (v == null || v.trim().isEmpty) {
                                return 'Person/contact required';
                              }
                              return null;
                            },
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

  List<DropdownMenuItem<String>> _sourceItemsForType(String txnType) {
    if (txnType == TransactionType.income) {
      return const [
        DropdownMenuItem(value: PaymentSourceType.bank, child: Text('Bank')),
        DropdownMenuItem(value: PaymentSourceType.cash, child: Text('Cash')),
      ];
    }
    if (txnType == TransactionType.creditCard) {
      return const [
        DropdownMenuItem(
          value: PaymentSourceType.creditCard,
          child: Text('Credit Card'),
        ),
      ];
    }
    return const [
      DropdownMenuItem(value: PaymentSourceType.bank, child: Text('Bank')),
      DropdownMenuItem(value: PaymentSourceType.upi, child: Text('UPI')),
      DropdownMenuItem(value: PaymentSourceType.cash, child: Text('Cash')),
      DropdownMenuItem(
        value: PaymentSourceType.creditCard,
        child: Text('Credit Card'),
      ),
    ];
  }

  List<DropdownMenuItem<int>> _sourceItems(PaymentSourcesData sources) {
    if (_sourceType == PaymentSourceType.creditCard) {
      return sources.cards
          .map(
            (c) => DropdownMenuItem(
              value: c.id,
              child: Text('${c.bankName} • ${c.last4}'),
            ),
          )
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
      final amount = double.parse(_amount.text);
      final cashback = _sourceType == PaymentSourceType.cash
          ? 0.0
          : (double.tryParse(_cashback.text) ?? 0.0);
      final recoverableBase = _forOthers
          ? (amount - cashback).clamp(0, amount).toDouble()
          : 0.0;
      final recoveredAmount = _forOthers
          ? (double.tryParse(_recoveredAmount.text) ?? 0)
                .clamp(0, recoverableBase)
                .toDouble()
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
              isForOthers: _forOthers,
              recoverableAmount: _forOthers
                  ? (recoverableBase - recoveredAmount)
                        .clamp(0, recoverableBase)
                        .toDouble()
                  : null,
              recoveredAmount: recoveredAmount,
              recoverablePartyName: _forOthers
                  ? _recoverableParty.text.trim()
                  : null,
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
