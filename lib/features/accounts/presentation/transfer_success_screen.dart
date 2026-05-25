import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';

class TransferSuccessScreen extends StatelessWidget {
  const TransferSuccessScreen({
    super.key,
    required this.amount,
    required this.fromType,
    required this.toType,
  });

  final double amount;
  final String fromType;
  final String toType;

  @override
  Widget build(BuildContext context) {
    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Transfer Success'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const SizedBox(height: AppSpacing.xl),
          const Center(
            child: CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.darkSuccess,
              child: Icon(Icons.check_rounded, size: 34, color: Colors.white),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(
              'Transfer Completed',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FinarcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FinarcSectionHeader(title: 'Summary'),
                const SizedBox(height: AppSpacing.sm),
                _line(context, 'Amount', inr(amount)),
                _line(context, 'From', _label(fromType)),
                _line(context, 'To', _label(toType)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const FinarcCard(
            child: Row(
              children: [
                Icon(Icons.receipt_long_outlined, size: 18),
                SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Transfer history has been recorded in recent activity.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FinarcPrimaryButton(
            onPressed: () => context.go('/accounts'),
            label: 'Back to Accounts',
            icon: Icons.account_balance_wallet_outlined,
          ),
        ],
      ),
    );
  }

  static Widget _line(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  static String _label(String type) {
    switch (type) {
      case 'bank':
        return 'Bank Account';
      case 'cash':
        return 'Cash Wallet';
      case 'creditCard':
        return 'Credit Card Payment';
      default:
        return type;
    }
  }
}
