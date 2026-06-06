import 'package:flutter/material.dart';

class FinarcContainedList extends StatelessWidget {
  const FinarcContainedList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.itemExtentEstimate,
    this.maxHeight = 320,
    this.emptyHeight = 164,
    this.separatorHeight = 8,
    this.emptyState,
    this.physics = const BouncingScrollPhysics(),
    this.showScrollbar = true,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double itemExtentEstimate;
  final double maxHeight;
  final double emptyHeight;
  final double separatorHeight;
  final Widget? emptyState;
  final ScrollPhysics physics;
  final bool showScrollbar;

  @override
  Widget build(BuildContext context) {
    final estimatedHeight = itemCount == 0
        ? emptyHeight
        : (itemExtentEstimate * itemCount) +
              (separatorHeight * (itemCount - 1)).clamp(0, maxHeight);
    final contentHeight = itemCount == 0
        ? emptyHeight
        : estimatedHeight.clamp(0, maxHeight).toDouble();

    Widget child;
    if (itemCount == 0) {
      child = emptyState ?? const SizedBox.shrink();
    } else {
      child = ListView.separated(
        primary: false,
        padding: EdgeInsets.zero,
        physics: physics,
        itemCount: itemCount,
        separatorBuilder: (_, _) => SizedBox(height: separatorHeight),
        itemBuilder: itemBuilder,
      );
      if (showScrollbar) {
        child = Scrollbar(child: child);
      }
    }

    return SizedBox(height: contentHeight, child: child);
  }
}
