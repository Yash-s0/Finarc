import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../data/accounts_providers.dart';

class AddEditAccountScreen extends ConsumerStatefulWidget {
  const AddEditAccountScreen({super.key, this.initialType});

  final String? initialType;

  @override
  ConsumerState<AddEditAccountScreen> createState() =>
      _AddEditAccountScreenState();
}

class _AddEditAccountScreenState extends ConsumerState<AddEditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bank = TextEditingController();
  final _name = TextEditingController();
  final _balance = TextEditingController(text: '0');
  final _last4 = TextEditingController();
  final _color = TextEditingController();
  bool _isCash = false;
  String _accountType = 'savings';

  @override
  void initState() {
    super.initState();
    if (widget.initialType == 'cash') {
      _isCash = true;
    }
  }

  @override
  void dispose() {
    _bank.dispose();
    _name.dispose();
    _balance.dispose();
    _last4.dispose();
    _color.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Add / Edit Account'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            FinarcCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FinarcSectionHeader(title: 'Account Kind'),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FinarcActionChip(
                        label: 'Bank Account',
                        selected: !_isCash,
                        onTap: () => setState(() => _isCash = false),
                      ),
                      FinarcActionChip(
                        label: 'Cash Wallet',
                        selected: _isCash,
                        onTap: () => setState(() => _isCash = true),
                      ),
                    ],
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
                  if (!_isCash) ...[
                    FinarcTextField(
                      controller: _bank,
                      label: 'Bank name',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FinarcTextField(
                      controller: _last4,
                      label: 'Account last 4 digits (optional)',
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final value = (v ?? '').trim();
                        if (value.isEmpty) return null;
                        if (!RegExp(r'^\d{4}$').hasMatch(value)) {
                          return 'Enter exactly 4 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  FinarcTextField(
                    controller: _name,
                    label: _isCash ? 'Wallet name' : 'Account nickname',
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      return null;
                    },
                  ),
                  if (!_isCash) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Account type',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['savings', 'salary', 'current']
                          .map(
                            (t) => FinarcActionChip(
                              label: t.toUpperCase(),
                              selected: _accountType == t,
                              onTap: () => setState(() => _accountType = t),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  FinarcTextField(
                    controller: _balance,
                    label: _isCash ? 'Current balance' : 'Starting balance',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      if (double.tryParse(v ?? '') == null) {
                        return 'Enter valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FinarcTextField(
                    controller: _color,
                    label: 'Color/Icon (optional)',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FinarcPrimaryButton(
              onPressed: _save,
              label: 'Save Account',
              icon: Icons.check_circle_outline,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final service = ref.read(accountServiceProvider);
    if (_isCash) {
      await service.createCashWallet(
        walletName: _name.text.trim(),
        currentBalance: double.tryParse(_balance.text) ?? 0,
      );
    } else {
      await service.createBankAccount(
        bankName: _bank.text.trim(),
        accountName: _name.text.trim(),
        accountType: _accountType,
        currentBalance: double.tryParse(_balance.text) ?? 0,
        last4: _last4.text.trim().isEmpty ? null : _last4.text.trim(),
        colorOrIcon: _color.text.trim().isEmpty ? null : _color.text.trim(),
      );
    }

    ref.invalidate(accountsOverviewProvider);
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}
