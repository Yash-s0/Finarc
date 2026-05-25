import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../expenses/data/expenses_providers.dart';
import '../data/accounts_providers.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  String _fromType = 'bank';
  int? _fromId;
  String _toType = 'cash';
  int? _toId;
  final _amount = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sourcesState = ref.watch(paymentSourcesProvider);
    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Transfer Money'),
      body: sourcesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (sources) {
          final fromLabel = _selectedLabel(
            sources,
            kind: _fromType,
            id: _fromId,
          );
          final toLabel = _selectedLabel(sources, kind: _toType, id: _toId);
          final amountValue = double.tryParse(_amount.text) ?? 0;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                FinarcCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FinarcSectionHeader(title: 'Transfer Direction'),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _fromType,
                              decoration: const InputDecoration(
                                labelText: 'From type',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'bank',
                                  child: Text('Bank'),
                                ),
                                DropdownMenuItem(
                                  value: 'cash',
                                  child: Text('Cash'),
                                ),
                              ],
                              onChanged: (v) {
                                setState(() {
                                  _fromType = v ?? 'bank';
                                  _fromId = null;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _toType,
                              decoration: const InputDecoration(
                                labelText: 'To type',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'bank',
                                  child: Text('Bank'),
                                ),
                                DropdownMenuItem(
                                  value: 'cash',
                                  child: Text('Cash'),
                                ),
                                DropdownMenuItem(
                                  value: 'creditCard',
                                  child: Text('Credit Card Payment'),
                                ),
                              ],
                              onChanged: (v) {
                                setState(() {
                                  _toType = v ?? 'bank';
                                  _toId = null;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _selectorField(
                        context,
                        label: 'From account',
                        value: fromLabel,
                        onTap: () => _pickAccount(
                          context,
                          sources,
                          type: _fromType,
                          isFrom: true,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _selectorField(
                        context,
                        label: _toType == 'creditCard'
                            ? 'To card'
                            : 'To account',
                        value: toLabel,
                        onTap: () => _pickAccount(
                          context,
                          sources,
                          type: _toType,
                          isFrom: false,
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
                      const FinarcSectionHeader(title: 'Amount & Notes'),
                      const SizedBox(height: AppSpacing.sm),
                      FinarcTextField(
                        controller: _amount,
                        label: 'Amount',
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
                const SizedBox(height: AppSpacing.sm),
                FinarcCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FinarcSectionHeader(title: 'Transfer Summary'),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              fromLabel,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                          Expanded(
                            child: Text(
                              toLabel,
                              textAlign: TextAlign.end,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        inr(amountValue),
                        style: AppTextStyles.amountStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 24,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FinarcPrimaryButton(
                  onPressed: () => _submit(context),
                  label: 'Confirm Transfer',
                  icon: Icons.check_circle_outline,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _selectorField(
    BuildContext context, {
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
        ),
        child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
      ),
    );
  }

  Future<void> _pickAccount(
    BuildContext context,
    PaymentSourcesData sources, {
    required String type,
    required bool isFrom,
  }) async {
    final selected = await FinarcBottomSheet.show<int>(
      context,
      child: _AccountSelectorSheet(
        type: type,
        sources: sources,
        selectedId: isFrom ? _fromId : _toId,
      ),
    );

    if (selected == null) return;
    setState(() {
      if (isFrom) {
        _fromId = selected;
      } else {
        _toId = selected;
      }
    });
  }

  String _selectedLabel(
    PaymentSourcesData sources, {
    required String kind,
    required int? id,
  }) {
    if (id == null) return 'Select';

    if (kind == 'cash') {
      final matches = sources.cashWallets.where((w) => w.id == id);
      final match = matches.isEmpty ? null : matches.first;
      return match == null
          ? 'Select'
          : '${match.walletName} • ${inr(match.currentBalance)}';
    }
    if (kind == 'creditCard') {
      final matches = sources.cards.where((c) => c.id == id);
      final match = matches.isEmpty ? null : matches.first;
      return match == null ? 'Select' : '${match.bankName} • ${match.last4}';
    }

    final matches = sources.banks.where((b) => b.id == id);
    final match = matches.isEmpty ? null : matches.first;
    return match == null
        ? 'Select'
        : '${match.accountName} • ${inr(match.currentBalance)}';
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    if (_fromId == null || _toId == null) return;

    final amount = double.tryParse(_amount.text) ?? 0;
    await ref
        .read(accountServiceProvider)
        .transferBetweenAccounts(
          sourceType: _fromType,
          sourceId: _fromId!,
          destinationType: _toType,
          destinationId: _toId!,
          amount: amount,
          transactionDate: DateTime.now(),
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );

    ref.invalidate(accountsOverviewProvider);
    ref.invalidate(expenseListProvider);
    if (!mounted) return;
    this.context.push(
      '/accounts/transfer/success?amount=$amount&from=$_fromType&to=$_toType',
    );
  }
}

class _AccountSelectorSheet extends StatelessWidget {
  const _AccountSelectorSheet({
    required this.type,
    required this.sources,
    required this.selectedId,
  });

  final String type;
  final PaymentSourcesData sources;
  final int? selectedId;

  @override
  Widget build(BuildContext context) {
    final List<_SheetItem> items;
    if (type == 'cash') {
      items = sources.cashWallets
          .map(
            (w) => _SheetItem(
              id: w.id,
              title: w.walletName,
              subtitle: 'Cash wallet',
              amount: inr(w.currentBalance),
              badge: 'CASH',
              icon: Icons.account_balance_wallet_outlined,
            ),
          )
          .toList();
    } else if (type == 'creditCard') {
      items = sources.cards
          .map(
            (c) => _SheetItem(
              id: c.id,
              title: '${c.bankName} • ${c.last4}',
              subtitle: c.maskedNumber,
              amount: inr(c.currentOutstanding),
              badge: 'CARD',
              icon: Icons.credit_card,
            ),
          )
          .toList();
    } else {
      items = sources.banks
          .map(
            (b) => _SheetItem(
              id: b.id,
              title: b.accountName,
              subtitle: b.bankName,
              amount: inr(b.currentBalance),
              badge: b.accountType.toUpperCase(),
              icon: Icons.account_balance,
            ),
          )
          .toList();
    }

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
          Text(
            'Select ${type == 'creditCard' ? 'Card' : 'Account'}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (items.isEmpty)
            const FinarcEmptyState(
              title: 'No options available',
              subtitle: 'Create an account or wallet first.',
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: selectedId == item.id
                          ? AppColors.darkAccent.withValues(alpha: 0.5)
                          : Colors.transparent,
                    ),
                  ),
                  child: FinarcAccountTile(
                    title: item.title,
                    subtitle: item.subtitle,
                    amount: item.amount,
                    icon: item.icon,
                    badge: item.badge,
                    onTap: () => Navigator.of(context).pop(item.id),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SheetItem {
  const _SheetItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.badge,
    required this.icon,
  });

  final int id;
  final String title;
  final String subtitle;
  final String amount;
  final String badge;
  final IconData icon;
}
