import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';

class PendingSuccessScreen extends StatelessWidget {
  const PendingSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Confirmed'),
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
              'Transaction Confirmed',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Center(
            child: Text(
              'Added to your expense timeline successfully.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FinarcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FinarcSectionHeader(title: 'Summary'),
                const SizedBox(height: AppSpacing.sm),
                _line(context, 'Amount', inr(0)),
                _line(context, 'Undo countdown', '5s placeholder'),
                _line(context, 'Status', 'Confirmed'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const FinarcCard(
            child: Row(
              children: [
                Icon(Icons.notifications_active_outlined, size: 18),
                SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text('You have more pending transactions to review.'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FinarcPrimaryButton(
            onPressed: () => context.go('/pending'),
            label: 'Review More Pending',
            icon: Icons.list_alt_outlined,
          ),
          const SizedBox(height: AppSpacing.xs),
          FinarcSecondaryButton(
            onPressed: () => context.go('/expenses'),
            label: 'Go to Expenses',
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
}
