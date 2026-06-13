import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

/// Shimmer/pulse loading skeleton that respects theme and reduced motion.
class FinarcLoadingSkeleton extends StatefulWidget {
  const FinarcLoadingSkeleton({
    super.key,
    this.height = 72,
    this.width,
    this.radius = AppRadius.md,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  State<FinarcLoadingSkeleton> createState() => _FinarcLoadingSkeletonState();
}

class _FinarcLoadingSkeletonState extends State<FinarcLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? AppColors.darkSurfaceHigh
        : AppColors.lightSurfaceHigh;
    final shimmerColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightSurfaceLow;
    final reducedMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    if (reducedMotion) {
      return Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 + 2 * _ctrl.value, 0),
              end: Alignment(1 + 2 * _ctrl.value, 0),
              colors: [baseColor, shimmerColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Convenience widget that renders a standard column of loading skeletons.
///
/// Use this instead of manually building skeleton columns in each screen.
class FinarcLoadingSkeletonGroup extends StatelessWidget {
  const FinarcLoadingSkeletonGroup({
    super.key,
    this.items = 4,
    this.itemHeight = 72,
    this.headerHeight = 20,
    this.spacing = AppSpacing.sm,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.showHeader = true,
  });

  final int items;
  final double itemHeight;
  final double headerHeight;
  final double spacing;
  final EdgeInsetsGeometry padding;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            FinarcLoadingSkeleton(height: headerHeight, width: 160),
            SizedBox(height: spacing),
          ],
          for (var i = 0; i < items; i++) ...[
            FinarcLoadingSkeleton(height: itemHeight),
            if (i < items - 1) SizedBox(height: spacing),
          ],
        ],
      ),
    );
  }
}
