import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import 'finarc_card.dart';
import 'finarc_status_badge.dart';

class FinarcBalanceCard extends StatelessWidget {
  const FinarcBalanceCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.statusLabel,
  });

  final String label;
  final String value;
  final String? subtitle;
  final String? statusLabel;

  @override
  Widget build(BuildContext context) {
    return FinarcCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const Spacer(),
              if (statusLabel != null)
                FinarcStatusBadge(
                  label: statusLabel!,
                  tone: FinarcStatusTone.success,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTextStyles.amountStyle(
              color: Theme.of(context).colorScheme.onSurface,
              size: 30,
              weight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle!, style: Theme.of(context).textTheme.labelMedium),
          ],
        ],
      ),
    );
  }
}
