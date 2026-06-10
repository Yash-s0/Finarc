import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../data/wallet_types.dart';
import '../data/accounts_providers.dart';

class AddEditAccountScreen extends ConsumerStatefulWidget {
  const AddEditAccountScreen({
    super.key,
    this.initialType,
    this.editType,
    this.editId,
  });

  final String? initialType;
  final String? editType;
  final int? editId;

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
  bool _didLoadEditValues = false;
  String _accountType = 'savings';
  String _walletType = WalletType.cash;

  bool get _isEditing =>
      widget.editType != null && widget.editId != null && widget.editId! > 0;

  @override
  void initState() {
    super.initState();
    final startingType = widget.editType ?? widget.initialType;
    if (startingType == 'cash') {
      _isCash = true;
    }
    if (startingType == WalletType.amazonPay) {
      _isCash = true;
      _walletType = WalletType.amazonPay;
      _name.text = 'Amazon Pay';
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
    final editState = _isEditing
        ? ref.watch(accountEditorProvider((widget.editType!, widget.editId!)))
        : null;

    if (_isEditing) {
      return editState!.when(
        loading: () => const FinarcScaffold(
          appBar: FinarcAppBar(title: 'Edit Account'),
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => FinarcScaffold(
          appBar: const FinarcAppBar(title: 'Edit Account'),
          body: Center(child: Text('Error: $error')),
        ),
        data: (data) {
          _hydrateFromEditorData(data);
          return _buildScaffold(context);
        },
      );
    }

    return _buildScaffold(context);
  }

  Widget _buildScaffold(BuildContext context) {
    return FinarcScaffold(
      appBar: FinarcAppBar(title: _isEditing ? 'Edit Account' : 'Add Account'),
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
                  if (_isEditing)
                    Text(
                      _isCash
                          ? (_walletType == WalletType.amazonPay
                                ? 'Amazon Pay wallet'
                                : 'Cash wallet')
                          : 'Bank account',
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  else
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
                          selected: _isCash && _walletType == WalletType.cash,
                          onTap: () => setState(() {
                            _isCash = true;
                            _walletType = WalletType.cash;
                          }),
                        ),
                        FinarcActionChip(
                          label: 'Amazon Pay',
                          selected:
                              _isCash && _walletType == WalletType.amazonPay,
                          onTap: () => setState(() {
                            _isCash = true;
                            _walletType = WalletType.amazonPay;
                            if (_name.text.trim().isEmpty ||
                                _name.text.trim() == 'Cash') {
                              _name.text = 'Amazon Pay';
                            }
                          }),
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
                      maxLength: 4,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                    label: _isCash
                        ? (_walletType == WalletType.amazonPay
                              ? 'Wallet name'
                              : 'Wallet name')
                        : 'Account nickname',
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
                    textInputAction: TextInputAction.done,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FinarcPrimaryButton(
              onPressed: _save,
              label: _isEditing ? 'Save Changes' : 'Save Account',
              icon: Icons.check_circle_outline,
            ),
          ],
        ),
      ),
    );
  }

  void _hydrateFromEditorData(
    ({
      String type,
      String? bankName,
      String name,
      String? accountType,
      double balance,
      String? last4,
      String? colorOrIcon,
      String? walletType,
    })
    data,
  ) {
    if (_didLoadEditValues) return;
    _didLoadEditValues = true;
    _isCash = data.type == 'cash';
    _bank.text = data.bankName ?? '';
    _name.text = data.name;
    _accountType = data.accountType ?? _accountType;
    _balance.text = data.balance.toString();
    _last4.text = data.last4 ?? '';
    _color.text = data.colorOrIcon ?? '';
    _walletType = data.walletType ?? _walletType;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final service = ref.read(accountServiceProvider);
    final balance = double.tryParse(_balance.text) ?? 0;
    final trimmedLast4 = _last4.text.trim();
    if (_isCash) {
      if (_isEditing) {
        await service.updateCashWallet(
          widget.editId!,
          walletName: _name.text.trim(),
          walletType: _walletType,
          currentBalance: balance,
        );
      } else {
        await service.createCashWallet(
          walletName: _name.text.trim(),
          walletType: _walletType,
          currentBalance: balance,
        );
      }
    } else {
      final colorOrIcon = _color.text.trim().isEmpty
          ? null
          : _color.text.trim();
      if (_isEditing) {
        await service.updateBankAccount(
          widget.editId!,
          bankName: _bank.text.trim(),
          accountName: _name.text.trim(),
          accountType: _accountType,
          last4: trimmedLast4.isEmpty ? null : trimmedLast4,
          clearLast4: trimmedLast4.isEmpty,
          currentBalance: balance,
          colorOrIcon: colorOrIcon,
        );
      } else {
        await service.createBankAccount(
          bankName: _bank.text.trim(),
          accountName: _name.text.trim(),
          accountType: _accountType,
          currentBalance: balance,
          last4: trimmedLast4.isEmpty ? null : trimmedLast4,
          colorOrIcon: colorOrIcon,
        );
      }
    }

    ref.invalidate(accountsOverviewProvider);
    if (_isEditing) {
      ref.invalidate(accountDetailProvider((widget.editType!, widget.editId!)));
      ref.invalidate(accountEditorProvider((widget.editType!, widget.editId!)));
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}
