import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';

class CashbackScreen extends StatefulWidget {
  const CashbackScreen({super.key});

  @override
  State<CashbackScreen> createState() => _CashbackScreenState();
}

class _CashbackScreenState extends State<CashbackScreen> {
  final _amount = TextEditingController(text: '0');
  String _type = 'instant';
  final _base = 1000.0;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cashback = double.tryParse(_amount.text) ?? 0;
    final effective = (_base - cashback).clamp(0, _base);

    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Add Cashback'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          FinarcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FinarcSectionHeader(title: 'Cashback Details'),
                const SizedBox(height: AppSpacing.sm),
                FinarcTextField(
                  controller: _amount,
                  label: 'Cashback amount',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onTap: () => setState(() {}),
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Cashback type',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _typeChip('instant', 'Instant'),
                    _typeChip('pending', 'Pending'),
                    _typeChip('rewardPoints', 'Reward Points'),
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
                const FinarcSectionHeader(title: 'Effective Cost Preview'),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Base expense',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                    Text(
                      inr(_base),
                      style: AppTextStyles.amountStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 15,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Cashback',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                    Text(
                      '-${inr(cashback)}',
                      style: AppTextStyles.amountStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 15,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Effective cost',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    Text(
                      inr(effective),
                      style: AppTextStyles.amountStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 17,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FinarcPrimaryButton(
            onPressed: () => Navigator.pop(context),
            label: 'Save',
            icon: Icons.check_circle_outline,
          ),
        ],
      ),
    );
  }

  Widget _typeChip(String value, String label) {
    return FinarcActionChip(
      label: label,
      selected: _type == value,
      onTap: () => setState(() => _type = value),
    );
  }
}
