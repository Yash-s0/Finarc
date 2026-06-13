import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../expenses/data/expenses_providers.dart';
import '../../expenses/models/transaction_types.dart';
import '../data/split_providers.dart';
import '../data/split_service.dart';

class AddSplitExpenseScreen extends ConsumerStatefulWidget {
  const AddSplitExpenseScreen({super.key, required this.groupId});

  final int groupId;

  @override
  ConsumerState<AddSplitExpenseScreen> createState() =>
      _AddSplitExpenseScreenState();
}

class _AddSplitExpenseScreenState extends ConsumerState<AddSplitExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _category = TextEditingController(text: 'General');
  final _notes = TextEditingController();

  String _splitType = 'equal';
  int? _paidByMemberId;
  DateTime _expenseDate = DateTime.now();
  final Set<int> _includedMembers = <int>{};
  final Map<int, TextEditingController> _shareControllers =
      <int, TextEditingController>{};

  String _paymentSourceType = PaymentSourceType.bank;
  int? _paymentSourceId;

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _category.dispose();
    _notes.dispose();
    for (final controller in _shareControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupState = ref.watch(splitGroupDetailProvider(widget.groupId));
    final sourceState = ref.watch(paymentSourcesProvider);

    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Add Split Expense'),
      body: groupState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (group) {
          if (_paidByMemberId == null && group.members.isNotEmpty) {
            _paidByMemberId = group.members.first.id;
          }
          if (_includedMembers.isEmpty) {
            _includedMembers.addAll(group.members.map((m) => m.id));
          }
          for (final member in group.members) {
            _shareControllers.putIfAbsent(
              member.id,
              () => TextEditingController(),
            );
          }

          final currentUser = group.members
              .where((m) => m.isCurrentUser)
              .firstOrNull;
          final isCurrentUserPayer =
              currentUser != null && _paidByMemberId == currentUser.id;

          return sourceState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (sources) {
              final selectedSourceLabel = _selectedSourceLabel(sources);
              final totalAmount = double.tryParse(_amount.text) ?? 0;
              final splitPreview = _previewSplit(group.members, totalAmount);

              return Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    FinarcCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const FinarcSectionHeader(title: 'Expense Details'),
                          const SizedBox(height: AppSpacing.sm),
                          FinarcTextField(
                            controller: _title,
                            label: 'Title / Merchant',
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Title is required'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          FinarcTextField(
                            controller: _amount,
                            label: 'Total Amount',
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
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          FinarcTextField(
                            controller: _category,
                            label: 'Category',
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _dateRow(context),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FinarcCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const FinarcSectionHeader(
                            title: 'Paid By & Split Type',
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          DropdownButtonFormField<int>(
                            initialValue: _paidByMemberId,
                            decoration: const InputDecoration(
                              labelText: 'Paid by',
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
                            onChanged: (v) =>
                                setState(() => _paidByMemberId = v),
                            validator: (v) => v == null ? 'Select payer' : null,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _splitTypeChip('equal', 'Equal'),
                              _splitTypeChip('percentage', 'Percentage'),
                              _splitTypeChip('exact', 'Exact'),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _splitEditor(group.members),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (isCurrentUserPayer)
                      FinarcCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FinarcSectionHeader(title: 'Payment Source'),
                            const SizedBox(height: AppSpacing.sm),
                            DropdownButtonFormField<String>(
                              initialValue: _paymentSourceType,
                              decoration: const InputDecoration(
                                labelText: 'Payment mode',
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
                                DropdownMenuItem(
                                  value: PaymentSourceType.creditCard,
                                  child: Text('Credit Card'),
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
                                      child: _PaymentSourceSheet(
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
                                  labelText: 'Source',
                                  suffixIcon: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                  ),
                                ),
                                child: Text(selectedSourceLabel),
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
                          const FinarcSectionHeader(title: 'Split Preview'),
                          const SizedBox(height: AppSpacing.sm),
                          ...splitPreview.map(
                            (row) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.xs,
                              ),
                              child: Row(
                                children: [
                                  Expanded(child: Text(row.memberName)),
                                  Text(
                                    inr(row.amount),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Total ${inr(totalAmount)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FinarcTextField(
                      controller: _notes,
                      label: 'Notes (optional)',
                      maxLines: 2,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FinarcPrimaryButton(
                      onPressed: () => _submit(group.members, currentUser?.id),
                      icon: Icons.check_circle_outline,
                      label: 'Save Split Expense',
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

  Widget _dateRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text('Date: ${_expenseDate.toLocal()}'.split(' ').first),
        ),
        TextButton.icon(
          onPressed: () async {
            final date = await showDatePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
              initialDate: _expenseDate,
            );
            if (date == null) return;
            setState(() {
              _expenseDate = DateTime(
                date.year,
                date.month,
                date.day,
                _expenseDate.hour,
                _expenseDate.minute,
              );
            });
          },
          icon: const Icon(Icons.calendar_month_outlined),
          label: const Text('Change'),
        ),
      ],
    );
  }

  Widget _splitTypeChip(String value, String label) {
    return FinarcActionChip(
      label: label,
      selected: _splitType == value,
      onTap: () => setState(() => _splitType = value),
    );
  }

  Widget _splitEditor(List<dynamic> members) {
    if (_splitType == 'equal') {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: members
            .map((m) {
              final selected = _includedMembers.contains(m.id);
              return FinarcActionChip(
                label: m.isCurrentUser ? '${m.name} (You)' : m.name,
                selected: selected,
                onTap: () {
                  setState(() {
                    if (selected && _includedMembers.length > 1) {
                      _includedMembers.remove(m.id);
                    } else {
                      _includedMembers.add(m.id);
                    }
                  });
                },
              );
            })
            .toList(growable: false),
      );
    }

    final suffix = _splitType == 'percentage' ? '%' : '₹';
    final label = _splitType == 'percentage' ? 'Percentage' : 'Exact amount';
    return Column(
      children: members
          .map((m) {
            final controller = _shareControllers[m.id]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(m.isCurrentUser ? '${m.name} (You)' : m.name),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  SizedBox(
                    width: 150,
                    child: TextFormField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: label,
                        suffixText: suffix,
                      ),
                    ),
                  ),
                ],
              ),
            );
          })
          .toList(growable: false),
    );
  }

  List<_PreviewRow> _previewSplit(List<dynamic> members, double totalAmount) {
    if (totalAmount <= 0) {
      return members
          .map((m) => _PreviewRow(memberName: m.name as String, amount: 0))
          .toList(growable: false);
    }

    final service = ref.read(splitServiceProvider);
    List<SplitShareInput> shares;

    if (_splitType == 'equal') {
      final ids = _includedMembers.isEmpty
          ? members.map((m) => m.id as int).toList(growable: false)
          : _includedMembers.toList(growable: false);
      shares = service.calculateEqualSplit(
        memberIds: ids,
        totalAmount: totalAmount,
      );
    } else if (_splitType == 'percentage') {
      final map = <int, double>{};
      for (final m in members) {
        map[m.id as int] = double.tryParse(_shareControllers[m.id]!.text) ?? 0;
      }
      shares = service.calculatePercentageSplit(
        percentagesByMember: map,
        totalAmount: totalAmount,
      );
    } else {
      final map = <int, double>{};
      for (final m in members) {
        map[m.id as int] = double.tryParse(_shareControllers[m.id]!.text) ?? 0;
      }
      shares = service.calculateExactSplit(map);
    }

    return members
        .map((m) {
          var amount = 0.0;
          for (final share in shares) {
            if (share.memberId == m.id) {
              amount = share.exactAmount;
              break;
            }
          }
          return _PreviewRow(memberName: m.name as String, amount: amount);
        })
        .toList(growable: false);
  }

  String _selectedSourceLabel(PaymentSourcesData data) {
    if (_paymentSourceId == null) return 'Select source';
    if (_paymentSourceType == PaymentSourceType.cash) {
      final match = data.cashWallets
          .where((e) => e.id == _paymentSourceId)
          .firstOrNull;
      return match == null
          ? 'Select source'
          : '${match.walletName} • ${inr(match.currentBalance)}';
    }
    if (_paymentSourceType == PaymentSourceType.creditCard) {
      final match = data.cards
          .where((e) => e.id == _paymentSourceId)
          .firstOrNull;
      return match == null
          ? 'Select source'
          : '${match.bankName} • ${match.last4}';
    }
    final match = data.banks.where((e) => e.id == _paymentSourceId).firstOrNull;
    return match == null
        ? 'Select source'
        : '${match.accountName} • ${inr(match.currentBalance)}';
  }

  Future<void> _submit(List<dynamic> members, int? currentUserId) async {
    if (!_formKey.currentState!.validate()) return;
    if (_paidByMemberId == null) return;

    final totalAmount = double.tryParse(_amount.text) ?? 0;
    if (totalAmount <= 0) return;

    final isCurrentUserPayer =
        currentUserId != null && _paidByMemberId == currentUserId;
    if (isCurrentUserPayer && _paymentSourceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select payment source for current user payment'),
        ),
      );
      return;
    }

    final service = ref.read(splitServiceProvider);
    List<SplitShareInput> shares;
    try {
      if (_splitType == 'equal') {
        shares = service.calculateEqualSplit(
          memberIds: _includedMembers.toList(growable: false),
          totalAmount: totalAmount,
        );
      } else if (_splitType == 'percentage') {
        final map = <int, double>{};
        for (final m in members) {
          map[m.id as int] =
              double.tryParse(_shareControllers[m.id]!.text) ?? 0;
        }
        shares = service.calculatePercentageSplit(
          percentagesByMember: map,
          totalAmount: totalAmount,
        );
      } else {
        final map = <int, double>{};
        for (final m in members) {
          map[m.id as int] =
              double.tryParse(_shareControllers[m.id]!.text) ?? 0;
        }
        shares = service.calculateExactSplit(map);
      }

      await ref
          .read(splitActionsProvider)
          .addExpense(
            AddSplitExpenseInput(
              groupId: widget.groupId,
              title: _title.text.trim(),
              totalAmount: totalAmount,
              paidByMemberId: _paidByMemberId!,
              splitType: _splitType,
              expenseDate: _expenseDate,
              category: _category.text.trim().isEmpty
                  ? 'General'
                  : _category.text.trim(),
              notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
              shares: shares,
              paymentSourceType: isCurrentUserPayer ? _paymentSourceType : null,
              paymentSourceId: isCurrentUserPayer ? _paymentSourceId : null,
            ),
          );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save split expense: $e')),
      );
    }
  }
}

class _PreviewRow {
  const _PreviewRow({required this.memberName, required this.amount});

  final String memberName;
  final double amount;
}

class _PaymentSourceSheet extends StatelessWidget {
  const _PaymentSourceSheet({
    required this.data,
    required this.sourceType,
    required this.selectedId,
  });

  final PaymentSourcesData data;
  final String sourceType;
  final int? selectedId;

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows();
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
          if (rows.isEmpty)
            FinarcEmptyState(
              title: 'No sources',
              subtitle: 'Create an account first.',
            )
          else
            ...rows.map((row) {
              final isSelected = selectedId == row.id;
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
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        row.amount,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (isSelected) ...[
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

  List<_SourceRow> _buildRows() {
    if (sourceType == PaymentSourceType.cash) {
      return data.cashWallets
          .map(
            (w) => _SourceRow(
              id: w.id,
              title: w.walletName,
              subtitle: 'Cash wallet',
              amount: inr(w.currentBalance),
              icon: Icons.account_balance_wallet_outlined,
            ),
          )
          .toList(growable: false);
    }

    if (sourceType == PaymentSourceType.creditCard) {
      return data.cards
          .map(
            (c) => _SourceRow(
              id: c.id,
              title: c.bankName,
              subtitle: '**** ${c.last4}',
              amount: inr(c.currentOutstanding),
              icon: Icons.credit_card,
            ),
          )
          .toList(growable: false);
    }

    return data.banks
        .map(
          (b) => _SourceRow(
            id: b.id,
            title: b.accountName,
            subtitle: b.bankName,
            amount: inr(b.currentBalance),
            icon: Icons.account_balance,
          ),
        )
        .toList(growable: false);
  }
}

class _SourceRow {
  const _SourceRow({
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
