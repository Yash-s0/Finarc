import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/numeric_input_formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../dashboard/data/dashboard_providers.dart';
import '../data/recoverables_service.dart';

class RecoverablePersonDetailScreen extends ConsumerStatefulWidget {
  const RecoverablePersonDetailScreen({super.key, required this.partyName});

  final String partyName;

  @override
  ConsumerState<RecoverablePersonDetailScreen> createState() =>
      _RecoverablePersonDetailScreenState();
}

class _RecoverablePersonDetailScreenState
    extends ConsumerState<RecoverablePersonDetailScreen> {
  String _filter = RecoverableSourceFilter.all;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recoverablesSnapshotProvider);

    return FinarcScaffold(
      appBar: FinarcAppBar(title: widget.partyName),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          final group = data.groups
              .where((group) => group.partyName == widget.partyName)
              .cast<RecoverablePartyGroup?>()
              .firstWhere((group) => group != null, orElse: () => null);
          if (group == null) {
            return const Center(
              child: FinarcEmptyState(
                title: 'Nothing open here',
                subtitle: 'This person has no open recoverables right now.',
                icon: Icons.check_circle_outline_rounded,
              ),
            );
          }

          final filteredItems = group.itemsForFilter(_filter);
          final dueDate = group.nearestDueDate;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              FinarcBalanceCard(
                label: 'Remaining',
                value: inr(group.remainingTotal),
                subtitle:
                    '${group.transactionCount} transactions • Base ${inr(group.originalTotal)} • Recovered ${inr(group.recoveredTotal)}',
                trendLabel: dueDate == null
                    ? null
                    : 'Nearest due ${transactionDateLabel(dueDate, includeTimeForToday: false)}',
                statusLabel: group.remainingTotal > 0 ? 'Open' : 'Clear',
              ),
              const SizedBox(height: AppSpacing.sm),
              FinarcPrimaryButton(
                label: 'Record Recovery',
                onPressed: () => _openRecordRecoveryDialog(group),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _filter == RecoverableSourceFilter.all,
                    onTap: () => setState(() {
                      _filter = RecoverableSourceFilter.all;
                    }),
                  ),
                  _FilterChip(
                    label: 'Card',
                    selected: _filter == RecoverableSourceFilter.card,
                    onTap: () => setState(() {
                      _filter = RecoverableSourceFilter.card;
                    }),
                  ),
                  _FilterChip(
                    label: 'Bank / UPI',
                    selected: _filter == RecoverableSourceFilter.bankUpi,
                    onTap: () => setState(() {
                      _filter = RecoverableSourceFilter.bankUpi;
                    }),
                  ),
                  _FilterChip(
                    label: 'Cash wallet',
                    selected: _filter == RecoverableSourceFilter.cash,
                    onTap: () => setState(() {
                      _filter = RecoverableSourceFilter.cash;
                    }),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const FinarcSectionHeader(title: 'Transactions'),
              const SizedBox(height: AppSpacing.xs),
              if (filteredItems.isEmpty)
                const FinarcEmptyState(
                  title: 'No items for this filter',
                  subtitle: 'Try another source tab.',
                  icon: Icons.filter_alt_off_rounded,
                )
              else
                ...filteredItems.map(
                  (item) => _RecoverableItemCard(item: item),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openRecordRecoveryDialog(RecoverablePartyGroup group) async {
    final result = await showDialog<RecordRecoveryResult>(
      context: context,
      builder: (context) => _RecordRecoveryDialog(group: group),
    );
    if (result == null || !mounted) return;

    ref.invalidate(recoverablesSnapshotProvider);
    ref.invalidate(dashboardProvider);

    final message = result.clamped
        ? 'Recorded ${inr(result.appliedAmount)} for ${result.partyName}. Entered amount was clamped to remaining ${inr(result.openBefore)}.'
        : 'Recorded ${inr(result.appliedAmount)} for ${result.partyName}. Remaining ${inr(result.remainingAfter)}.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FinarcActionChip(label: label, selected: selected, onTap: onTap);
  }
}

class _RecoverableItemCard extends StatelessWidget {
  const _RecoverableItemCard({required this.item});

  final RecoverableTransactionItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: FinarcTransactionTile(
        onTap: () => context.push('/expenses/transaction/${item.id}'),
        title: item.title,
        subtitle: item.category,
        meta:
            '${transactionDateLabel(item.transactionDate, includeTimeForToday: false)} • ${_sourceLabel(item)}',
        amount: inr(item.remainingRecoverableAmount),
        amountMeta:
            'Base ${inr(item.recoverableBaseAmount)} • Recovered ${inr(item.recoveredAmount)}',
        badges: [
          FinarcTransactionPresentation.recoverableStatusBadge(item.status),
          ..._billingBadges(item),
        ],
      ),
    );
  }

  String _sourceLabel(RecoverableTransactionItem item) {
    switch (item.sourceFilter) {
      case RecoverableSourceFilter.card:
        return 'Card';
      case RecoverableSourceFilter.cash:
        return 'Cash wallet';
      case RecoverableSourceFilter.bankUpi:
      default:
        return item.paymentSourceType == 'upi' ? 'UPI' : 'Bank';
    }
  }

  List<Widget> _billingBadges(RecoverableTransactionItem item) {
    if (item.sourceFilter != RecoverableSourceFilter.card) {
      return const [];
    }

    switch (item.billingState) {
      case RecoverableBillingState.unbilled:
        return [
          FinarcStatusBadge(
            label: 'Unbilled',
            tone: FinarcStatusTone.warning,
            compact: true,
          ),
        ];
      case RecoverableBillingState.billed:
        return [
          FinarcStatusBadge(
            label: item.dueDate == null
                ? 'Billed'
                : 'Due ${transactionDateLabel(item.dueDate!, includeTimeForToday: false)}',
            tone: FinarcStatusTone.info,
            compact: true,
          ),
        ];
      case RecoverableBillingState.paid:
        return const [
          FinarcStatusBadge(
            label: 'Bill Paid',
            tone: FinarcStatusTone.success,
            compact: true,
          ),
        ];
      case RecoverableBillingState.needsReview:
        return [
          FinarcStatusBadge(
            label: item.dueDate == null
                ? 'Needs review'
                : 'Needs review • ${transactionDateLabel(item.dueDate!, includeTimeForToday: false)}',
            tone: FinarcStatusTone.warning,
            compact: true,
          ),
        ];
      default:
        return const [];
    }
  }
}

class _RecordRecoveryDialog extends ConsumerStatefulWidget {
  const _RecordRecoveryDialog({required this.group});

  final RecoverablePartyGroup group;

  @override
  ConsumerState<_RecordRecoveryDialog> createState() =>
      _RecordRecoveryDialogState();
}

class _RecordRecoveryDialogState extends ConsumerState<_RecordRecoveryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.group.remainingTotal.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record Recovery'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.group.partyName} • Remaining ${inr(widget.group.remainingTotal)}',
            ),
            const SizedBox(height: AppSpacing.sm),
            FinarcTextField(
              controller: _amountController,
              label: 'Amount received',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$')),
                StripLeadingZeroFormatter(),
              ],
              validator: (value) {
                final parsed = double.tryParse(value ?? '');
                if (parsed == null || parsed <= 0) {
                  return 'Enter an amount greater than 0';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Recovery is applied billed-due first, then bank/UPI/cash by oldest date, then unbilled cards.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _saving ? null : _submit,
          child: Text(_saving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountController.text);

    setState(() => _saving = true);
    try {
      final result = await ref
          .read(recoverablesServiceProvider)
          .recordRecovery(partyName: widget.group.partyName, amount: amount);
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to record recovery: $e')));
    }
  }
}
