import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';

class SplitSettlementSuccessScreen extends StatelessWidget {
  const SplitSettlementSuccessScreen({
    super.key,
    required this.amount,
    required this.groupId,
  });

  final double amount;
  final int groupId;

  @override
  Widget build(BuildContext context) {
    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Settlement Recorded'),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            const Spacer(),
            const Icon(Icons.check_circle_rounded, size: 72),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Settlement saved',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              '${inr(amount)} has been added to settlement history.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            FinarcPrimaryButton(
              onPressed: () => context.go('/split/groups/$groupId'),
              icon: Icons.arrow_back_rounded,
              label: 'Back to Group',
            ),
            const SizedBox(height: AppSpacing.sm),
            FinarcSecondaryButton(
              onPressed: () => context.go('/split'),
              icon: Icons.call_split_outlined,
              label: 'Go to Split Dashboard',
            ),
          ],
        ),
      ),
    );
  }
}
