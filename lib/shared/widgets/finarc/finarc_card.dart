import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';

class FinarcCard extends StatefulWidget {
  const FinarcCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.gradient,
    this.useShadow = true,
    this.radius = AppRadius.card,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final Gradient? gradient;
  final bool useShadow;
  final double radius;

  @override
  State<FinarcCard> createState() => _FinarcCardState();
}

class _FinarcCardState extends State<FinarcCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.975,
    ).animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Theme.of(context).cardTheme.color,
        gradient: widget.gradient,
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(
          color:
              widget.borderColor ??
              (isDark
                  ? AppColors.darkBorder.withValues(alpha: 0.8)
                  : AppColors.lightBorder),
          width: 0.9,
        ),
        boxShadow: widget.useShadow
            ? (isDark ? AppShadows.card : AppShadows.cardLight)
            : null,
      ),
      child: Padding(padding: widget.padding, child: widget.child),
    );
    final content = Padding(
      padding: widget.margin ?? EdgeInsets.zero,
      child: card,
    );

    if (widget.onTap == null) return content;

    // Subtle scale press feedback for interactive cards
    return ScaleTransition(
      scale: _scale,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => _pressCtrl.forward(),
          onTapUp: (_) => _pressCtrl.reverse(),
          onTapCancel: () => _pressCtrl.reverse(),
          borderRadius: BorderRadius.circular(widget.radius),
          child: content,
        ),
      ),
    );
  }
}
