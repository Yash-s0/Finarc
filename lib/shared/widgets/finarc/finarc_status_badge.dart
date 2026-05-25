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
    final (bg, border, fg) = switch (tone) {
      FinarcStatusTone.success => (
        AppColors.darkSuccess.withValues(alpha: 0.16),
        AppColors.darkSuccess.withValues(alpha: 0.36),
        AppColors.darkSuccess,
      ),
      FinarcStatusTone.warning => (
        AppColors.darkWarning.withValues(alpha: 0.16),
        AppColors.darkWarning.withValues(alpha: 0.38),
        AppColors.darkWarning,
      ),
      FinarcStatusTone.error => (
        AppColors.darkError.withValues(alpha: 0.16),
        AppColors.darkError.withValues(alpha: 0.38),
        AppColors.darkError,
      ),
      FinarcStatusTone.info => (
        AppColors.darkPrimarySoft,
        AppColors.darkAccent.withValues(alpha: 0.38),
        AppColors.darkAccent,
      ),
      FinarcStatusTone.neutral => (
        AppColors.darkSurfaceLow,
        AppColors.darkBorder,
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.78),
      ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

enum FinarcStatusTone { neutral, success, warning, error, info }
