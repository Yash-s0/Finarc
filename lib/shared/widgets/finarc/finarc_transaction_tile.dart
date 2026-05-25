import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class FinarcTransactionTile extends StatelessWidget {
  const FinarcTransactionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.prefix,
    this.badges = const [],
    this.amountColor,
    this.onTap,
    this.meta,
  });

  final String title;
  final String subtitle;
  final String amount;
  final Widget? prefix;
  final List<Widget> badges;
  final Color? amountColor;
  final VoidCallback? onTap;
  final String? meta;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          if (prefix != null) ...[
            prefix!,
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.labelMedium),
                if (meta != null) ...[
                  const SizedBox(height: 2),
                  Text(meta!, style: Theme.of(context).textTheme.labelMedium),
                ],
                if (badges.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xxs),
                    child: Wrap(spacing: 6, runSpacing: 6, children: badges),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            amount,
            textAlign: TextAlign.end,
            style: AppTextStyles.amountStyle(
              color: amountColor ?? Theme.of(context).colorScheme.onSurface,
              size: 15,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: content,
    );
  }
}
