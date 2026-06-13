import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import 'finarc_card.dart';

class FinarcMetricCard extends StatelessWidget {
  const FinarcMetricCard({
    super.key,
    required this.title,
    required this.value,
    this.trailing,
    this.onTap,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.minHeight,
    this.titleMaxLines = 1,
  });

  final String title;
  final String value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final double? minHeight;
  final int titleMaxLines;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FinarcCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 8,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight ?? 74),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Container(
                    height: 26,
                    width: 26,
                    decoration: BoxDecoration(
                      color:
                          iconBackgroundColor ??
                          (isDark
                                  ? AppColors.darkPrimarySoft
                                  : AppColors.lightPrimarySoft)
                              .withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      icon,
                      size: 14,
                      color:
                          iconColor ??
                          (isDark
                              ? AppColors.darkAccent
                              : AppColors.lightAccent),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Expanded(
                  child: Text(
                    title,
                    maxLines: titleMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(letterSpacing: 0.2),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.amountStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 16,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
