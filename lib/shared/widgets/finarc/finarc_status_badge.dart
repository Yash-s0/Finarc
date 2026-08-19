import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';

class FinarcStatusBadge extends StatelessWidget {
  const FinarcStatusBadge({
    super.key,
    required this.label,
    this.tone = FinarcStatusTone.neutral,
    this.compact = false,
  });

  final String label;
  final FinarcStatusTone tone;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (bg, border, fg) = switch (tone) {
      FinarcStatusTone.success => (
        (isDark ? AppColors.darkSuccess : AppColors.lightSuccess).withValues(
          alpha: 0.16,
        ),
        (isDark ? AppColors.darkSuccess : AppColors.lightSuccess).withValues(
          alpha: 0.36,
        ),
        isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
      ),
      FinarcStatusTone.warning => (
        (isDark ? AppColors.darkWarning : AppColors.lightWarning).withValues(
          alpha: 0.16,
        ),
        (isDark ? AppColors.darkWarning : AppColors.lightWarning).withValues(
          alpha: 0.38,
        ),
        isDark ? AppColors.darkWarning : AppColors.lightWarning,
      ),
      FinarcStatusTone.error => (
        (isDark ? AppColors.darkError : AppColors.lightError).withValues(
          alpha: 0.16,
        ),
        (isDark ? AppColors.darkError : AppColors.lightError).withValues(
          alpha: 0.38,
        ),
        isDark ? AppColors.darkError : AppColors.lightError,
      ),
      FinarcStatusTone.info => (
        isDark ? AppColors.darkPrimarySoft : AppColors.lightPrimarySoft,
        (isDark ? AppColors.darkAccent : AppColors.lightAccent).withValues(
          alpha: 0.38,
        ),
        isDark ? AppColors.darkAccent : AppColors.lightAccent,
      ),
      FinarcStatusTone.neutral => (
        isDark ? AppColors.darkSurfaceLow : AppColors.lightSurfaceHigh,
        isDark ? AppColors.darkBorder : AppColors.lightBorder,
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.78),
      ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style:
            (compact
                    ? Theme.of(context).textTheme.labelSmall
                    : Theme.of(context).textTheme.labelMedium)
                ?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
      ),
    );
  }
}

enum FinarcStatusTone { neutral, success, warning, error, info }
