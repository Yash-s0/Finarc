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
    final fg = selected
        ? Theme.of(context).colorScheme.onSurface
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.78);

    return ActionChip(
      onPressed: onTap,
      avatar: icon == null ? null : Icon(icon, size: 15, color: fg),
      label: Text(label),
      labelStyle: Theme.of(
        context,
      ).textTheme.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w700),
      backgroundColor: selected
          ? AppColors.darkPrimarySoft
          : AppColors.darkSurfaceLow,
      side: BorderSide(
        color: selected
            ? AppColors.darkAccent.withValues(alpha: 0.45)
            : AppColors.darkBorder,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    );
  }
}
