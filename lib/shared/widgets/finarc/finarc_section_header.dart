import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class FinarcSectionHeader extends StatelessWidget {
  const FinarcSectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.35,
              color: isDark
                  ? AppColors.darkTextMuted.withValues(alpha: 0.88)
                  : AppColors.lightTextMuted.withValues(alpha: 0.90),
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}
