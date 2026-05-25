import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../expenses/data/expenses_providers.dart';
import '../data/pending_providers.dart';
import '../models/pending_models.dart';

final pendingByIdProvider = FutureProvider.family((ref, int id) async {
  await ref.watch(seedProvider.future);
  final db = ref.read(appDatabaseProvider);
  return (db.select(
    db.pendingTransactions,
  )..where((p) => p.id.equals(id))).getSingle();
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
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _merchant = TextEditingController();
  final _category = TextEditingController();
  final _notes = TextEditingController();
  DateTime _date = DateTime.now();
  String _sourceType = 'cash';
  int? _sourceId;
  bool _forOthers = false;
  bool _cashbackOn = false;
  final _cashback = TextEditingController(text: '0');
  final _recoverable = TextEditingController(text: '0');
  bool _initialized = false;

  @override
  void dispose() {
    _amount.dispose();
    _merchant.dispose();
    _category.dispose();
    _notes.dispose();
    _cashback.dispose();
    _recoverable.dispose();
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
            if (!_initialized) {
              _amount.text = pending.amount.toStringAsFixed(0);
              _merchant.text = pending.merchant;
              _category.text = pending.categorySuggestion;
              _sourceType = pending.paymentSourceTypeSuggestion;
              _sourceId = pending.paymentSourceIdSuggestion;
              _date = pending.transactionDate;
              _forOthers = pending.isForOthers;
              _cashbackOn = (pending.cashbackAmount ?? 0) > 0;
              _cashback.text = (pending.cashbackAmount ?? 0).toStringAsFixed(0);
              _recoverable.text = (pending.recoverableAmount ?? 0)
                  .toStringAsFixed(0);
              _notes.text = pending.notes ?? '';
              _initialized = true;
            }

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
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        FinarcTextField(
                          controller: _merchant,
                          label: 'Merchant / Title',
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
                        DropdownButtonFormField<String>(
                          initialValue: _sourceType,
                          items: const [
                            DropdownMenuItem(
                              value: 'cash',
                              child: Text('Cash'),
                            ),
                            DropdownMenuItem(value: 'upi', child: Text('UPI')),
                            DropdownMenuItem(
                              value: 'bank',
                              child: Text('Bank'),
                            ),
                            DropdownMenuItem(
                              value: 'creditCard',
                              child: Text('Credit Card'),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _sourceType = v ?? 'cash'),
                          decoration: const InputDecoration(
                            labelText: 'Payment source',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        DropdownButtonFormField<int>(
                          initialValue: _sourceId,
                          items:
                              (_sourceType == 'creditCard'
                                      ? sources.cards.map(
                                          (c) => DropdownMenuItem(
                                            value: c.id,
                                            child: Text(
                                              '${c.bankName} • ${c.last4}',
                                            ),
                                          ),
                                        )
                                      : _sourceType == 'cash'
                                      ? sources.cashWallets.map(
                                          (c) => DropdownMenuItem(
                                            value: c.id,
                                            child: Text(c.walletName),
                                          ),
                                        )
                                      : sources.banks.map(
                                          (b) => DropdownMenuItem(
                                            value: b.id,
                                            child: Text(b.accountName),
                                          ),
                                        ))
                                  .toList(),
                          onChanged: (v) => setState(() => _sourceId = v),
                          decoration: const InputDecoration(
                            labelText: 'Source account/card',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        FinarcTextField(
                          controller: TextEditingController(
                            text: '${_date.toLocal()}'.split('.').first,
                          ),
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
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: _forOthers,
                          onChanged: (v) => setState(() => _forOthers = v),
                          title: const Text('For Others'),
                        ),
                        if (_forOthers)
                          FinarcTextField(
                            controller: _recoverable,
                            label: 'Recoverable amount',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        const SizedBox(height: AppSpacing.xs),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: _cashbackOn,
                          onChanged: (v) => setState(() => _cashbackOn = v),
                          title: const Text('Add Cashback'),
                        ),
                        if (_cashbackOn)
                          FinarcTextField(
                            controller: _cashback,
                            label: 'Cashback amount',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
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
                  const SizedBox(height: AppSpacing.sm),
                  FinarcCard(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Row(
                      children: [
                        const Icon(Icons.calculate_outlined, size: 16),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Preview: ${inr(double.tryParse(_amount.text) ?? pending.amount)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FinarcPrimaryButton(
                    onPressed: () async {
                      final edited = PendingEditData(
                        amount: double.tryParse(_amount.text) ?? pending.amount,
                        merchant: _merchant.text.trim(),
                        category: _category.text.trim(),
                        paymentSourceType: _sourceType,
                        paymentSourceId: _sourceId,
                        transactionDate: _date,
                        cashbackAmount: _cashbackOn
                            ? double.tryParse(_cashback.text) ?? 0
                            : 0,
                        isForOthers: _forOthers,
                        recoverableAmount: _forOthers
                            ? double.tryParse(_recoverable.text)
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
}
