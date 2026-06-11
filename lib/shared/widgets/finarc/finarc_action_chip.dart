import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';

class FinarcActionChip extends StatelessWidget {
  const FinarcActionChip({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = selected
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.82);

    return ActionChip(
      onPressed: onTap,
      avatar: icon == null
          ? null
          : Container(
              height: 18,
              width: 18,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.2)
                    : (isDark ? AppColors.darkPrimarySoft : AppColors.lightPrimarySoft).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: 12,
                color: selected ? Colors.white : (isDark ? AppColors.darkAccent : AppColors.lightAccent),
              ),
            ),
      label: Text(label),
      labelStyle: Theme.of(
        context,
      ).textTheme.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w700),
      backgroundColor: selected
          ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
          : (isDark ? AppColors.darkSurfaceLow : AppColors.lightSurfaceHigh),
      side: BorderSide(
        color: selected
            ? (isDark ? AppColors.darkAccent : AppColors.lightAccent).withValues(alpha: 0.9)
            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      elevation: 0,
      pressElevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    );
  }
}
