import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';

class FinarcLoadingSkeleton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
