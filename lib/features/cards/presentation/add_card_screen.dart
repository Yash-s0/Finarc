import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../data/card_network_detector.dart';
import '../data/cards_providers.dart';

class AddCardScreen extends ConsumerStatefulWidget {
  const AddCardScreen({super.key});

  @override
  ConsumerState<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends ConsumerState<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bank = TextEditingController();
  final _nick = TextEditingController();
  final _bin = TextEditingController();
  final _last4 = TextEditingController();
  final _billing = TextEditingController();
  final _due = TextEditingController();
  final _limit = TextEditingController();
  final _outstanding = TextEditingController(text: '0');
  String _network = CardNetwork.visa;
  bool _networkAutoDetected = false;
  final _bankFocus = FocusNode();
  final _nickFocus = FocusNode();
  final _binFocus = FocusNode();
  final _last4Focus = FocusNode();
  final _billingFocus = FocusNode();
  final _dueFocus = FocusNode();
  final _limitFocus = FocusNode();
  final _outstandingFocus = FocusNode();

  @override
  void dispose() {
    _bank.dispose();
    _nick.dispose();
    _bin.dispose();
    _last4.dispose();
    _billing.dispose();
    _due.dispose();
    _limit.dispose();
    _outstanding.dispose();
    _bankFocus.dispose();
    _nickFocus.dispose();
    _binFocus.dispose();
    _last4Focus.dispose();
    _billingFocus.dispose();
    _dueFocus.dispose();
    _limitFocus.dispose();
    _outstandingFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final creditLimit = double.parse(_limit.text.trim());
    final outstanding = double.parse(_outstanding.text.trim());
    if (outstanding > creditLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Current outstanding cannot exceed credit limit'),
        ),
      );
      return;
    }

    await ref.read(addCardProvider)(
      AddCardPayload(
        bankName: _bank.text.trim(),
        nickname: _nick.text.trim(),
        last4: _last4.text.trim(),
        network: _network,
        billingDay: int.parse(_billing.text.trim()),
        dueDay: int.parse(_due.text.trim()),
        creditLimit: creditLimit,
        currentOutstanding: outstanding,
      ),
    );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Add Card'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              'Manual card tracking only',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Store only masked card data. Expiry and CVV are never captured.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            FinarcCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FinarcSectionHeader(title: 'Card Basics'),
                  const SizedBox(height: AppSpacing.sm),
                  _field(
                    _bank,
                    'Bank name',
                    focusNode: _bankFocus,
                    nextFocusNode: _nickFocus,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _field(
                    _nick,
                    'Card nickname',
                    focusNode: _nickFocus,
                    nextFocusNode: _binFocus,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _field(
                    _bin,
                    'First 6 digits (optional)',
                    focusNode: _binFocus,
                    nextFocusNode: _last4Focus,
                    maxLength: 8,
                    keyboardType: TextInputType.number,
                    onChanged: _onBinChanged,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final v = value.trim();
                      if (v.length < 6 || v.length > 8) {
                        return 'Enter 6 to 8 digits';
                      }
                      if (int.tryParse(v) == null) {
                        return 'Enter numbers only';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _field(
                    _last4,
                    'Last 4 digits',
                    focusNode: _last4Focus,
                    nextFocusNode: _billingFocus,
                    maxLength: 4,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      if (value.trim().length != 4) {
                        return 'Enter exactly 4 digits';
                      }
                      if (int.tryParse(value.trim()) == null) {
                        return 'Enter numbers only';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: _network,
                    decoration: InputDecoration(
                      labelText: 'Card type',
                      prefixIcon: const Icon(Icons.credit_card_rounded),
                      helperText: _networkAutoDetected
                          ? 'Auto-detected from BIN'
                          : null,
                    ),
                    items: CardNetwork.values
                        .map(
                          (network) => DropdownMenuItem(
                            value: network,
                            child: Text(CardNetwork.label(network)),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _network = value;
                        _networkAutoDetected = false;
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
                  const FinarcSectionHeader(title: 'Billing Setup'),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          _billing,
                          'Billing day',
                          focusNode: _billingFocus,
                          nextFocusNode: _dueFocus,
                          keyboardType: TextInputType.number,
                          validator: _dayValidator,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _field(
                          _due,
                          'Due day',
                          focusNode: _dueFocus,
                          nextFocusNode: _limitFocus,
                          keyboardType: TextInputType.number,
                          validator: _dayValidator,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _field(
                    _limit,
                    'Credit limit',
                    focusNode: _limitFocus,
                    nextFocusNode: _outstandingFocus,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _positiveAmountValidator,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _field(
                    _outstanding,
                    'Current outstanding (optional)',
                    focusNode: _outstandingFocus,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final parsed = double.tryParse(value.trim());
                      if (parsed == null || parsed < 0) {
                        return 'Enter valid amount';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FinarcCard(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.darkPrimarySoft,
                    child: Icon(Icons.privacy_tip_outlined, size: 14),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Finarc tracks only masked number + last 4 digits for '
                      'privacy-safe offline record keeping. First 6 digits '
                      'are used only to suggest card type and are not saved.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FinarcPrimaryButton(
              onPressed: _save,
              label: 'Save Card',
              icon: Icons.check_circle_outline,
            ),
          ],
        ),
      ),
    );
  }

  void _onBinChanged(String value) {
    final cleaned = value.trim();
    if (cleaned.length >= 6) {
      final detected = detectCardNetwork(cleaned);
      if (detected != null) {
        setState(() {
          _network = detected;
          _networkAutoDetected = true;
        });
        return;
      }
    }
    if (_networkAutoDetected) {
      setState(() => _networkAutoDetected = false);
    }
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    int? maxLength,
    String? Function(String?)? validator,
    TextInputAction? textInputAction,
    FocusNode? focusNode,
    FocusNode? nextFocusNode,
    ValueChanged<String>? onChanged,
  }) {
    return FinarcTextField(
      controller: controller,
      label: label,
      focusNode: focusNode,
      nextFocusNode: nextFocusNode,
      keyboardType: keyboardType,
      maxLength: maxLength,
      textInputAction: textInputAction,
      onChanged: onChanged,
      validator:
          validator ??
          (value) {
            if (value == null || value.trim().isEmpty) return 'Required';
            return null;
          },
    );
  }

  String? _dayValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final day = int.tryParse(value.trim());
    if (day == null || day < 1 || day > 31) return 'Use 1 to 31';
    return null;
  }

  String? _positiveAmountValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final amount = double.tryParse(value.trim());
    if (amount == null || amount <= 0) return 'Enter amount > 0';
    return null;
  }
}
