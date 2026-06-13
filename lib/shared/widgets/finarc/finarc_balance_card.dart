import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
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
    this.trendLabel,
    this.isHero = false,
    this.leading,
  });

  final String label;
  final String value;
  final String? subtitle;
  final String? statusLabel;
  final String? trendLabel;
  final bool isHero;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FinarcCard(
      padding: EdgeInsets.all(isHero ? AppSpacing.lg : AppSpacing.md),
      gradient: isHero
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.darkPrimarySoft.withValues(alpha: 0.95),
                AppColors.darkSurfaceHigh,
              ],
            )
          : null,
      borderColor: isHero
          ? AppColors.darkAccent.withValues(alpha: 0.35)
          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const Spacer(),
              if (statusLabel != null)
                FinarcStatusBadge(
                  label: statusLabel!,
                  tone: isHero
                      ? FinarcStatusTone.info
                      : FinarcStatusTone.success,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTextStyles.amountStyle(
              color: Theme.of(context).colorScheme.onSurface,
              size: isHero ? 28 : 24,
              weight: FontWeight.w800,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle!, style: Theme.of(context).textTheme.labelMedium),
          ],
          if (trendLabel != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  size: 14,
                  color: isDark
                      ? AppColors.darkSuccess
                      : AppColors.lightSuccess,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    trendLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.darkSuccess
                          : AppColors.lightSuccess,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
