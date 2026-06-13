import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import 'finarc_status_badge.dart';

class FinarcAccountTile extends StatelessWidget {
  const FinarcAccountTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.amount,
    this.onTap,
    this.icon = Icons.account_balance_wallet_outlined,
    this.badge,
    this.iconColor,
    this.meta,
  });

  final String title;
  final String? subtitle;
  final String amount;
  final VoidCallback? onTap;
  final IconData icon;
  final String? badge;
  final Color? iconColor;
  final String? meta;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final content = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceLow : AppColors.lightSurfaceHigh,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isDark
                ? AppColors.darkPrimarySoft
                : AppColors.lightPrimarySoft,
            child: Icon(
              icon,
              size: 18,
              color:
                  iconColor ??
                  (isDark ? AppColors.darkAccent : AppColors.lightAccent),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
                if (meta != null) ...[
                  const SizedBox(height: 2),
                  Text(meta!, style: Theme.of(context).textTheme.labelMedium),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: AppTextStyles.amountStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 15,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                FinarcStatusBadge(
                  label: badge!,
                  tone: FinarcStatusTone.neutral,
                  compact: true,
                ),
              ],
            ],
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
