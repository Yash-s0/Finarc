import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/analytics_models.dart';

class FinarcLineChart extends StatelessWidget {
  const FinarcLineChart({
    super.key,
    required this.points,
    required this.color,
    this.height = 120,
  });

  final List<TrendPoint> points;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(height: height);
    }
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _LineChartPainter(points: points, color: color),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class FinarcBarChart extends StatelessWidget {
  const FinarcBarChart({
    super.key,
    required this.items,
    this.color = AppColors.darkAccent,
    this.maxItems = 6,
  });

  final List<NamedAmount> items;
  final Color color;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    final data = items.take(maxItems).toList(growable: false);
    if (data.isEmpty) {
      return const SizedBox.shrink();
    }
    final max = data.fold<double>(0, (m, x) => x.amount > m ? x.amount : m);

    return Column(
      children: [
        for (final item in data) ...[
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                flex: 6,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: max <= 0 ? 0 : item.amount / max,
                    minHeight: 8,
                    backgroundColor: AppColors.darkSurfaceHigh,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }
}

class FinarcDonutChart extends StatelessWidget {
  const FinarcDonutChart({super.key, required this.items, this.size = 140});

  final List<NamedAmount> items;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return SizedBox(width: size, height: size);
    }
    final total = items.fold<double>(0, (s, x) => s + x.amount);
    final palette = [
      AppColors.darkAccent,
      AppColors.darkSuccess,
      AppColors.darkWarning,
      AppColors.darkError,
      const Color(0xFF6A7DFF),
      const Color(0xFF6D8E7C),
    ];

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(items: items, total: total, palette: palette),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({required this.points, required this.color});

  final List<TrendPoint> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) {
      return;
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final max = points.fold<double>(0, (m, p) => p.value > m ? p.value : m);
    final safeMax = max <= 0 ? 1 : max;

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final y = size.height - ((points[i].value / safeMax) * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final grid = Paint()
      ..color = AppColors.darkBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 1; i <= 2; i++) {
      final y = (size.height / 3) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.items,
    required this.total,
    required this.palette,
  });

  final List<NamedAmount> items;
  final double total;
  final List<Color> palette;

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;

    final stroke = size.width * 0.18;
    final rect = Offset.zero & size;
    final bgPaint = Paint()
      ..color = AppColors.darkSurfaceHigh
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    canvas.drawArc(rect.deflate(stroke / 2), 0, math.pi * 2, false, bgPaint);

    var start = -math.pi / 2;
    for (var i = 0; i < items.length; i++) {
      final sweep = (items[i].amount / total) * math.pi * 2;
      final paint = Paint()
        ..color = palette[i % palette.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect.deflate(stroke / 2), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.items != items || oldDelegate.total != total;
  }
}
