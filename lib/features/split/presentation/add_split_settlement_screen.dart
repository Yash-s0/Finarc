import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../expenses/data/expenses_providers.dart';
import '../../expenses/models/transaction_types.dart';
import '../data/split_providers.dart';

class AddSplitSettlementScreen extends ConsumerStatefulWidget {
  const AddSplitSettlementScreen({super.key, required this.groupId});

  final int groupId;

  @override
  ConsumerState<AddSplitSettlementScreen> createState() =>
      _AddSplitSettlementScreenState();
}

class _AddSplitSettlementScreenState
    extends ConsumerState<AddSplitSettlementScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _fromMemberId;
  int? _toMemberId;
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  DateTime _date = DateTime.now();

  String _paymentSourceType = PaymentSourceType.bank;
  int? _paymentSourceId;

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupState = ref.watch(splitGroupDetailProvider(widget.groupId));
    final sourceState = ref.watch(paymentSourcesProvider);

    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Record Settlement'),
      body: groupState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (group) {
          if (_fromMemberId == null && group.members.isNotEmpty) {
            _fromMemberId = group.members.first.id;
          }
          if (_toMemberId == null && group.members.length > 1) {
            _toMemberId = group.members[1].id;
          }

          final currentUser = group.members
              .where((m) => m.isCurrentUser)
              .firstOrNull;
          final userInvolved =
              currentUser != null &&
              (_fromMemberId == currentUser.id ||
                  _toMemberId == currentUser.id);

          return sourceState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (sources) {
              final selectedSource = _selectedSourceLabel(sources);
              final amount = double.tryParse(_amount.text) ?? 0;

              return Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    FinarcCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const FinarcSectionHeader(
                            title: 'Settlement Details',
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          DropdownButtonFormField<int>(
                            initialValue: _fromMemberId,
                            decoration: const InputDecoration(
                              labelText: 'From member',
                            ),
                            items: group.members
                                .map(
                                  (m) => DropdownMenuItem<int>(
                                    value: m.id,
                                    child: Text(
                                      m.isCurrentUser
                                          ? '${m.name} (You)'
                                          : m.name,
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (v) => setState(() => _fromMemberId = v),
                            validator: (v) =>
                                v == null ? 'Select from member' : null,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          DropdownButtonFormField<int>(
                            initialValue: _toMemberId,
                            decoration: const InputDecoration(
                              labelText: 'To member',
                            ),
                            items: group.members
                                .map(
                                  (m) => DropdownMenuItem<int>(
                                    value: m.id,
                                    child: Text(
                                      m.isCurrentUser
                                          ? '${m.name} (You)'
                                          : m.name,
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (v) => setState(() => _toMemberId = v),
                            validator: (v) {
                              if (v == null) return 'Select to member';
                              if (v == _fromMemberId) {
                                return 'From and To cannot be same';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          FinarcTextField(
                            controller: _amount,
                            label: 'Amount',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (v) {
                              final parsed = double.tryParse(v ?? '');
                              if (parsed == null || parsed <= 0) {
                                return 'Enter amount > 0';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Date: ${_date.toLocal()}'.split(' ').first,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                    initialDate: _date,
                                  );
                                  if (date == null) return;
                                  setState(() => _date = date);
                                },
                                icon: const Icon(Icons.calendar_month_outlined),
                                label: const Text('Change'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (userInvolved)
                      FinarcCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FinarcSectionHeader(title: 'Payment Source'),
                            const SizedBox(height: AppSpacing.sm),
                            DropdownButtonFormField<String>(
                              initialValue: _paymentSourceType,
                              decoration: const InputDecoration(
                                labelText: 'Source type',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: PaymentSourceType.bank,
                                  child: Text('Bank'),
                                ),
                                DropdownMenuItem(
                                  value: PaymentSourceType.upi,
                                  child: Text('UPI'),
                                ),
                                DropdownMenuItem(
                                  value: PaymentSourceType.cash,
                                  child: Text('Cash'),
                                ),
                              ],
                              onChanged: (v) {
                                setState(() {
                                  _paymentSourceType =
                                      v ?? PaymentSourceType.bank;
                                  _paymentSourceId = null;
                                });
                              },
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            InkWell(
                              onTap: () async {
                                final selected =
                                    await FinarcBottomSheet.show<int>(
                                      context,
                                      child: _SettlementSourceSheet(
                                        data: sources,
                                        sourceType: _paymentSourceType,
                                        selectedId: _paymentSourceId,
                                      ),
                                    );
                                if (selected == null) return;
                                setState(() => _paymentSourceId = selected);
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Source account/wallet',
                                  suffixIcon: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                  ),
                                ),
                                child: Text(selectedSource),
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
                          const FinarcSectionHeader(title: 'Summary'),
                          const SizedBox(height: AppSpacing.sm),
                          Text('Settlement amount: ${inr(amount)}'),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            userInvolved
                                ? 'This settlement will update your account history.'
                                : 'No personal account movement for this settlement.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FinarcTextField(
                      controller: _notes,
                      label: 'Notes (optional)',
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FinarcPrimaryButton(
                      onPressed: () => _submit(currentUser?.id, userInvolved),
                      icon: Icons.check_circle_outline,
                      label: 'Record Settlement',
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _selectedSourceLabel(PaymentSourcesData data) {
    if (_paymentSourceId == null) return 'Select source';
    if (_paymentSourceType == PaymentSourceType.cash) {
      final wallet = data.cashWallets
          .where((w) => w.id == _paymentSourceId)
          .firstOrNull;
      return wallet == null
          ? 'Select source'
          : '${wallet.walletName} • ${inr(wallet.currentBalance)}';
    }
    final bank = data.banks.where((b) => b.id == _paymentSourceId).firstOrNull;
    return bank == null
        ? 'Select source'
        : '${bank.accountName} • ${inr(bank.currentBalance)}';
  }

  Future<void> _submit(int? currentUserId, bool userInvolved) async {
    if (!_formKey.currentState!.validate()) return;
    if (_fromMemberId == null || _toMemberId == null) return;
    if (_fromMemberId == _toMemberId) return;

    final amount = double.tryParse(_amount.text) ?? 0;
    if (amount <= 0) return;

    if (userInvolved && _paymentSourceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select payment source for personal settlement'),
        ),
      );
      return;
    }

    await ref
        .read(splitActionsProvider)
        .addSettlement(
          groupId: widget.groupId,
          fromMemberId: _fromMemberId!,
          toMemberId: _toMemberId!,
          amount: amount,
          settlementDate: _date,
          paymentSourceType: userInvolved ? _paymentSourceType : null,
          paymentSourceId: userInvolved ? _paymentSourceId : null,
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );

    if (!mounted) return;
    context.go(
      '/split/settlement/success?amount=$amount&groupId=${widget.groupId}',
    );
  }
}

class _SettlementSourceSheet extends StatelessWidget {
  const _SettlementSourceSheet({
    required this.data,
    required this.sourceType,
    required this.selectedId,
  });

  final PaymentSourcesData data;
  final String sourceType;
  final int? selectedId;

  @override
  Widget build(BuildContext context) {
    final rows = sourceType == PaymentSourceType.cash
        ? data.cashWallets
              .map(
                (w) => _SourceItem(
                  id: w.id,
                  title: w.walletName,
                  subtitle: 'Cash wallet',
                  amount: inr(w.currentBalance),
                  icon: Icons.account_balance_wallet_outlined,
                ),
              )
              .toList(growable: false)
        : data.banks
              .map(
                (b) => _SourceItem(
                  id: b.id,
                  title: b.accountName,
                  subtitle: b.bankName,
                  amount: inr(b.currentBalance),
                  icon: Icons.account_balance,
                ),
              )
              .toList(growable: false);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FinarcSectionHeader(title: 'Select Source'),
          const SizedBox(height: AppSpacing.sm),
          ...rows.map((row) {
            final selected = row.id == selectedId;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: FinarcCard(
                onTap: () => Navigator.pop(context, row.id),
                child: Row(
                  children: [
                    Icon(row.icon, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(row.title),
                          const SizedBox(height: 2),
                          Text(
                            row.subtitle,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      row.amount,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (selected) ...[
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(Icons.check_circle_rounded, size: 18),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SourceItem {
  const _SourceItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
  });

  final int id;
  final String title;
  final String subtitle;
  final String amount;
  final IconData icon;
}
