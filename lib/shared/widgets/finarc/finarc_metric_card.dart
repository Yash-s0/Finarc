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
  });

  final String title;
  final String value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    return FinarcCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight ?? 84),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Container(
                    height: 26,
                    width: 26,
                    decoration: BoxDecoration(
                      color:
                          iconBackgroundColor ??
                          AppColors.darkPrimarySoft.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      icon,
                      size: 14,
                      color: iconColor ?? AppColors.darkAccent,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
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
                size: 15.5,
                weight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
