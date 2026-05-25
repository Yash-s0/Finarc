import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import 'finarc_card.dart';

class FinarcMetricCard extends StatelessWidget {
  const FinarcMetricCard({
    super.key,
    required this.title,
    required this.value,
    this.trailing,
  });

  final String title;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return FinarcCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.amountStyle(
              color: Theme.of(context).colorScheme.onSurface,
              size: 16,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
