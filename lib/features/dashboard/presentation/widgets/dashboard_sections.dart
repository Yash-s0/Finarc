import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../data/dashboard_providers.dart';

class DashboardGreetingHeader extends StatelessWidget {
  const DashboardGreetingHeader({
    super.key,
    required this.name,
    required this.unreadAlertsCount,
    this.now,
    this.onAlertsTap,
  });

  final String? name;
  final int unreadAlertsCount;
  final DateTime? now;
  final VoidCallback? onAlertsTap;

  @override
  Widget build(BuildContext context) {
    final displayName = _displayName(name);
    final hasName = displayName.isNotEmpty;
    final greeting = _dynamicGreeting(now ?? DateTime.now());
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting,',
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                hasName ? '$displayName 👋' : 'Welcome 👋',
                style: Theme.of(context).textTheme.headlineSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _headerAction(
          context,
          icon: Icons.notifications_none_rounded,
          onTap: onAlertsTap,
          badge: unreadAlertsCount > 0 ? unreadAlertsCount.toString() : null,
        ),
      ],
    );
  }

  String _dynamicGreeting(DateTime now) {
    final hour = now.hour;
    if (hour >= 5 && hour <= 11) return 'Good morning';
    if (hour >= 12 && hour <= 16) return 'Good afternoon';
    if (hour >= 17 && hour <= 20) return 'Good evening';
    return 'Good night';
  }

  String _displayName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return '';
    return trimmed
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) {
          if (part.length == 1) return part.toUpperCase();
          return '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}';
        })
        .join(' ');
  }

  Widget _headerAction(
    BuildContext context, {
    required IconData icon,
    VoidCallback? onTap,
    String? badge,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceHigh
                  : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Icon(
              icon,
              size: 17,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        if (badge != null)
          Positioned(
            right: -3,
            top: -3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkError : AppColors.lightError,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badge,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class NetWorthHeroCard extends StatelessWidget {
  const NetWorthHeroCard({super.key, required this.data});

  final DashboardSnapshot data;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryFg = isDark ? Colors.white : AppColors.lightText;
    final secondaryFg = isDark ? Colors.white70 : AppColors.lightTextMuted;
    final successColor = isDark
        ? AppColors.darkSuccess
        : AppColors.lightSuccess;
    return GestureDetector(
      onTap: () => context.push('/dashboard/net-worth-breakdown'),
      child: FinarcCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.darkHeroGradientStart.withValues(alpha: 0.72),
                  AppColors.darkHeroGradientEnd,
                ]
              : [
                  AppColors.lightHeroGradientStart,
                  AppColors.lightHeroGradientEnd,
                ],
        ),
        borderColor: isDark
            ? AppColors.darkBorder.withValues(alpha: 0.9)
            : AppColors.lightPrimary.withValues(alpha: 0.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Net Worth',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: secondaryFg),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              inr(data.netWorth),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: primaryFg,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(Icons.trending_up_rounded, size: 16, color: successColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _spendTrendLabel(data.monthlySpendTrend),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: successColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 116,
              width: double.infinity,
              child: _MonthlySpendTrendChart(points: data.monthlySpendTrend),
            ),
          ],
        ),
      ),
    );
  }

  String _spendTrendLabel(List<MonthlySpendPoint> points) {
    if (points.isEmpty) return 'Monthly spends ${inr(data.monthlySpends)}';
    final current = points.last.amount;
    if (points.length < 2 || points[points.length - 2].amount <= 0) {
      return 'Spends this cycle ${inr(current)}';
    }
    final previous = points[points.length - 2].amount;
    final delta = current - previous;
    final percent = (delta / previous) * 100;
    final sign = delta >= 0 ? '+' : '-';
    return '$sign${percent.abs().toStringAsFixed(1)}% (${inr(delta.abs())}) this cycle';
  }
}

class _MonthlySpendTrendChart extends StatefulWidget {
  const _MonthlySpendTrendChart({required this.points});

  final List<MonthlySpendPoint> points;

  @override
  State<_MonthlySpendTrendChart> createState() =>
      _MonthlySpendTrendChartState();

  static String monthShort(DateTime month) {
    const labels = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return labels[month.month - 1];
  }
}

class _MonthlySpendTrendChartState extends State<_MonthlySpendTrendChart> {
  int? _selectedIndex;
  Timer? _tapHideTimer;

  @override
  void dispose() {
    _tapHideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final points = widget.points;
    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark
        ? AppColors.darkTextMuted.withValues(alpha: 0.72)
        : AppColors.lightTextMuted.withValues(alpha: 0.72);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return MouseRegion(
          onHover: (event) {
            _tapHideTimer?.cancel();
            _selectAt(event.localPosition.dx, width);
          },
          onExit: (_) => _clearSelection(),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapDown: (details) {
              _selectAt(details.localPosition.dx, width);
              _scheduleTapHide();
            },
            onTap: () {},
            onTapCancel: _clearSelection,
            onHorizontalDragUpdate: (details) {
              _tapHideTimer?.cancel();
              _selectAt(details.localPosition.dx, width);
            },
            onHorizontalDragEnd: (_) => _clearSelection(),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    top: _selectedIndex == null ? 8 : 56,
                  ),
                  child: CustomPaint(
                    painter: _MonthlySpendTrendPainter(
                      points,
                      isDark: isDark,
                      selectedIndex: _selectedIndex,
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: points
                            .map(
                              (point) => Expanded(
                                child: Text(
                                  _MonthlySpendTrendChart.monthShort(
                                    point.month,
                                  ),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(color: mutedColor),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                  ),
                ),
                if (_selectedIndex != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: _MonthlySpendTooltip(
                      point: points[_selectedIndex!],
                      index: _selectedIndex!,
                      count: points.length,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _selectAt(double dx, double width) {
    if (width <= 0 || widget.points.isEmpty) return;
    final count = widget.points.length;
    final segment = count <= 1 ? width : width / (count - 1);
    final index = count <= 1
        ? 0
        : (dx / segment).round().clamp(0, count - 1).toInt();
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  void _scheduleTapHide() {
    _tapHideTimer?.cancel();
    _tapHideTimer = Timer(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      _hideSelection();
    });
  }

  void _clearSelection() {
    _tapHideTimer?.cancel();
    _hideSelection();
  }

  void _hideSelection() {
    if (_selectedIndex == null) return;
    setState(() => _selectedIndex = null);
  }
}

class _MonthlySpendTooltip extends StatelessWidget {
  const _MonthlySpendTooltip({
    required this.point,
    required this.index,
    required this.count,
  });

  final MonthlySpendPoint point;
  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final bg = isDark
        ? AppColors.darkSurfaceHigh.withValues(alpha: 0.94)
        : AppColors.lightSurface.withValues(alpha: 0.96);
    final border = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.75)
        : AppColors.lightBorder.withValues(alpha: 0.8);
    final left = count <= 1 ? 0.0 : index / (count - 1);
    final alignmentX = (left * 2 - 1).clamp(-0.72, 0.72).toDouble();
    return Align(
      alignment: Alignment(alignmentX, -1),
      child: IgnorePointer(
        child: Container(
          width: 190,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.1),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _MonthlySpendTrendChart.monthShort(point.month),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              _TooltipAmountRow(
                label: 'Income',
                value: inr(point.income),
                color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
                muted: muted,
              ),
              const SizedBox(height: 3),
              _TooltipAmountRow(
                label: 'Expense',
                value: inr(point.amount),
                color: isDark ? AppColors.darkError : AppColors.lightError,
                muted: muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TooltipAmountRow extends StatelessWidget {
  const _TooltipAmountRow({
    required this.label,
    required this.value,
    required this.color,
    required this.muted,
  });

  final String label;
  final String value;
  final Color color;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Flexible(
          flex: 0,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: muted, letterSpacing: 0),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _MonthlySpendTrendPainter extends CustomPainter {
  _MonthlySpendTrendPainter(
    this.points, {
    this.isDark = true,
    this.selectedIndex,
  });

  final List<MonthlySpendPoint> points;
  final bool isDark;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2 || size.width <= 0 || size.height <= 0) return;
    final chartHeight = math.max(16.0, size.height - 20);
    final amounts = points.map((point) => point.amount).toList(growable: false);
    final maxValue = math.max(amounts.reduce(math.max), 1) * 1.08;
    final stepX = size.width / (points.length - 1);

    final path = Path();
    final areaPath = Path();
    final offsets = <Offset>[];
    for (var i = 0; i < points.length; i += 1) {
      final normalized = (amounts[i] / maxValue).clamp(0.0, 1.0);
      final x = i * stepX;
      final y = chartHeight - (normalized * (chartHeight - 8)) + 4;
      offsets.add(Offset(x, y));
      if (i == 0) {
        path.moveTo(x, y);
        areaPath.moveTo(x, chartHeight);
        areaPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        areaPath.lineTo(x, y);
      }
    }
    areaPath
      ..lineTo(size.width, chartHeight)
      ..close();

    final accentColor = isDark ? AppColors.darkAccent : AppColors.lightPrimary;
    final lineStartColor = isDark ? AppColors.darkBlue : AppColors.lightPrimary;
    final baselinePaint = Paint()
      ..color = (isDark ? AppColors.darkBorder : AppColors.lightBorder)
          .withValues(alpha: 0.55)
      ..strokeWidth = 1;
    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accentColor.withValues(alpha: 0.15),
          accentColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight));
    final glowPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [lineStartColor, accentColor],
      ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.25
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawLine(
      Offset(0, chartHeight),
      Offset(size.width, chartHeight),
      baselinePaint,
    );
    canvas.drawPath(areaPath, areaPaint);
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);

    final selected = selectedIndex;
    if (selected != null && selected >= 0 && selected < offsets.length) {
      final point = offsets[selected];
      final markerPaint = Paint()..color = accentColor;
      final centerPaint = Paint()
        ..color = isDark ? AppColors.darkSurfaceLow : AppColors.lightSurface;
      final ringPaint = Paint()
        ..color = accentColor.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5;
      final guidePaint = Paint()
        ..color = accentColor.withValues(alpha: 0.2)
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(point.dx, 2),
        Offset(point.dx, chartHeight),
        guidePaint,
      );
      canvas.drawCircle(point, 7, ringPaint);
      canvas.drawCircle(point, 4.5, markerPaint);
      canvas.drawCircle(point, 2, centerPaint);
    }

    final lastPoint = offsets.last;
    canvas.drawCircle(lastPoint, 3.5, Paint()..color = accentColor);
  }

  @override
  bool shouldRepaint(covariant _MonthlySpendTrendPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.isDark != isDark ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}

class SetupProgressCard extends StatelessWidget {
  const SetupProgressCard({super.key, required this.data});

  final DashboardSnapshot data;

  @override
  Widget build(BuildContext context) {
    return FinarcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FinarcSectionHeader(title: 'Setup Progress'),
          const SizedBox(height: AppSpacing.sm),
          _progressRow(
            context,
            'Bank account added',
            done: data.bankAccountCount > 0,
          ),
          const SizedBox(height: AppSpacing.xs),
          _progressRow(
            context,
            'Cash wallet added',
            done: data.cashWalletCount > 0,
          ),
          const SizedBox(height: AppSpacing.xs),
          _progressRow(context, 'Credit card added', done: data.cardCount > 0),
          const SizedBox(height: AppSpacing.xs),
          _progressRow(
            context,
            'Notification detection enabled',
            done: data.notificationDetectionEnabled,
          ),
        ],
      ),
    );
  }

  static Widget _progressRow(
    BuildContext context,
    String label, {
    required bool done,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        FinarcStatusBadge(
          label: done ? 'YES' : 'NO',
          tone: done ? FinarcStatusTone.success : FinarcStatusTone.neutral,
          compact: true,
        ),
      ],
    );
  }
}

class DashboardMetricGrid extends StatelessWidget {
  const DashboardMetricGrid({super.key, required this.data});

  final DashboardSnapshot data;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cards = [
      FinarcMetricCard(
        title: 'Bank Balance',
        value: inr(data.bankBalance),
        icon: Icons.account_balance_rounded,
        iconColor: isDark ? AppColors.darkMint : AppColors.lightSuccess,
        iconBackgroundColor:
            (isDark ? AppColors.darkMint : AppColors.lightSuccess).withValues(
              alpha: 0.14,
            ),
        onTap: () => context.push('/accounts'),
      ),
      FinarcMetricCard(
        title: 'Card Dues',
        value: inr(data.cardDues),
        icon: Icons.credit_card_rounded,
        iconColor: isDark ? AppColors.darkError : AppColors.lightError,
        iconBackgroundColor:
            (isDark ? AppColors.darkError : AppColors.lightError).withValues(
              alpha: 0.14,
            ),
        onTap: () => context.push('/cards'),
      ),
      FinarcMetricCard(
        title: 'Cash In Hand',
        value: inr(data.cashInHand),
        icon: Icons.wallet_rounded,
        iconColor: isDark ? AppColors.darkWarning : AppColors.lightWarning,
        iconBackgroundColor:
            (isDark ? AppColors.darkWarning : AppColors.lightWarning)
                .withValues(alpha: 0.14),
        onTap: () => context.push('/accounts'),
      ),
      FinarcMetricCard(
        title: 'Loans',
        value: inr(data.loansOutstanding),
        icon: Icons.account_balance_wallet_outlined,
        iconColor: isDark ? AppColors.darkOrange : AppColors.lightWarning,
        iconBackgroundColor:
            (isDark ? AppColors.darkOrange : AppColors.lightWarning).withValues(
              alpha: 0.14,
            ),
        onTap: () => context.push('/loans'),
      ),
      FinarcMetricCard(
        title: 'To Receive',
        value: inr(data.recoverableAmount),
        icon: Icons.call_received_rounded,
        iconColor: isDark ? AppColors.darkAccent : AppColors.lightAccent,
        iconBackgroundColor:
            (isDark ? AppColors.darkAccent : AppColors.lightAccent).withValues(
              alpha: 0.14,
            ),
        onTap: () => context.push('/recoverables'),
      ),
      FinarcMetricCard(
        title: 'Upcoming Bills',
        value: inr(data.payableAmount),
        icon: Icons.receipt_long_rounded,
        iconColor: isDark ? AppColors.darkOrange : AppColors.lightWarning,
        iconBackgroundColor:
            (isDark ? AppColors.darkOrange : AppColors.lightWarning).withValues(
              alpha: 0.14,
            ),
        onTap: () => context.push('/analytics'),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useSingleColumn = constraints.maxWidth < 290;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FinarcSectionHeader(
              title: 'Overview',
              trailing: TextButton(
                onPressed: () => context.push('/analytics'),
                child: const Text('See all'),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            GridView.builder(
              shrinkWrap: true,
              primary: false,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: useSingleColumn ? 1 : 2,
                crossAxisSpacing: AppSpacing.xs,
                mainAxisSpacing: AppSpacing.xs,
                mainAxisExtent: useSingleColumn ? 86 : 88,
              ),
              itemCount: cards.length,
              itemBuilder: (context, index) => cards[index],
            ),
          ],
        );
      },
    );
  }
}

class PendingConfirmationsCard extends StatelessWidget {
  const PendingConfirmationsCard({super.key, required this.pendingCount});

  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    if (pendingCount <= 0) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FinarcCard(
      onTap: () => context.push('/pending'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isDark
                ? AppColors.darkPrimarySoft
                : AppColors.lightPrimarySoft,
            child: const Icon(Icons.notification_important_outlined, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pending Confirmations',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Detected spends waiting for your confirmation',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          FinarcStatusBadge(
            label: '$pendingCount',
            tone: FinarcStatusTone.warning,
          ),
        ],
      ),
    );
  }
}

class DueSoonCard extends StatelessWidget {
  const DueSoonCard({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FinarcCard(
      onTap: () => context.push('/cards'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isDark
                ? AppColors.darkPrimarySoft
                : AppColors.lightPrimarySoft,
            child: const Icon(Icons.event_busy_outlined, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              dashboardDueSoonLabel(count),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const FinarcStatusBadge(label: 'DUE', tone: FinarcStatusTone.warning),
        ],
      ),
    );
  }
}

class DashboardAlertsSection extends StatelessWidget {
  const DashboardAlertsSection({
    super.key,
    required this.pendingCount,
    required this.dueSoonBillsCount,
  });

  final int pendingCount;
  final int dueSoonBillsCount;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      if (pendingCount > 0)
        PendingConfirmationsCard(pendingCount: pendingCount),
      if (dueSoonBillsCount > 0) DueSoonCard(count: dueSoonBillsCount),
    ];
    if (cards.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackVertically = constraints.maxWidth < 380 || cards.length == 1;
        if (stackVertically) {
          return Column(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                cards[i],
                if (i != cards.length - 1)
                  const SizedBox(height: AppSpacing.xs),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i != cards.length - 1) const SizedBox(width: AppSpacing.xs),
            ],
          ],
        );
      },
    );
  }
}

String dashboardDueSoonLabel(int count) {
  final noun = count == 1 ? 'bill' : 'bills';
  return '$count card $noun due soon';
}

class RecentTransactionsSection extends StatelessWidget {
  const RecentTransactionsSection({super.key, required this.data});

  static const double _compactTileEstimate = 72;

  final DashboardSnapshot data;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = data.recentTransactions;
    return FinarcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FinarcSectionHeader(
            title: 'Recent Transactions',
            trailing: TextButton(
              onPressed: () => context.push('/expenses'),
              child: const Text('See all'),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          FinarcContainedList(
            itemCount: items.length,
            itemExtentEstimate: _compactTileEstimate,
            emptyState: FinarcEmptyState(
              title: 'No transactions yet',
              subtitle: 'Add your first expense from quick actions.',
            ),
            itemBuilder: (context, index) {
              final t = items[index];
              final isIncome = FinarcTransactionPresentation.isPositive(
                type: t.type,
                paymentSourceType: t.paymentSourceType,
                title: t.title,
              );
              final isCard = t.paymentSourceType == 'creditCard';
              final isBilled = t.cardBillId != null;
              final tone = isIncome
                  ? FinarcStatusTone.success
                  : (isCard ? FinarcStatusTone.warning : FinarcStatusTone.info);
              return FinarcTransactionTile(
                title: t.title,
                subtitle: t.category,
                meta: FinarcTransactionPresentation.meta(
                  date: t.transactionDate,
                  source: FinarcTransactionPresentation.sourceLabel(
                    t.paymentSourceType,
                  ),
                ),
                prefix: CircleAvatar(
                  radius: 15,
                  backgroundColor: _avatarColor(t.category, isDark),
                  child: Icon(
                    _categoryIcon(t.category),
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                amount: '${isIncome ? '+' : '-'}${inr(t.amount)}',
                amountColor: isIncome
                    ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
                    : (isDark ? AppColors.darkError : AppColors.lightError),
                statusLabel: isIncome
                    ? 'Income'
                    : (isCard ? (isBilled ? 'Billed' : 'Unbilled') : 'Spent'),
                statusTone: tone,
                badges: [
                  if (isCard)
                    FinarcTransactionPresentation.billedBadge(billed: isBilled),
                  if (t.cashbackAmount > 0)
                    FinarcTransactionPresentation.cashbackBadge,
                  if (t.isForOthers)
                    FinarcTransactionPresentation.recoverableStatusBadge(
                      t.recoverableStatus,
                    ),
                ],
                compact: true,
              );
            },
          ),
        ],
      ),
    );
  }

  static Color _avatarColor(String category, bool isDark) {
    final key = category.trim().toLowerCase();
    if (key.contains('food')) {
      return isDark ? AppColors.darkOrange : AppColors.lightWarning;
    }
    if (key.contains('travel')) {
      return isDark ? AppColors.darkBlue : AppColors.lightAccent;
    }
    if (key.contains('bill')) {
      return isDark ? AppColors.darkAccent : AppColors.lightAccent;
    }
    if (key.contains('shop')) {
      return isDark ? AppColors.darkPink : AppColors.lightError;
    }
    return isDark ? AppColors.darkMint : AppColors.lightSuccess;
  }

  static IconData _categoryIcon(String category) {
    final key = category.trim().toLowerCase();
    if (key.contains('food')) return Icons.restaurant_rounded;
    if (key.contains('travel')) return Icons.flight_takeoff_rounded;
    if (key.contains('bill')) return Icons.receipt_long_rounded;
    if (key.contains('shop')) return Icons.shopping_bag_rounded;
    return Icons.paid_rounded;
  }
}

class AnalyticsCtaCard extends StatelessWidget {
  const AnalyticsCtaCard({super.key, required this.monthlySpends});

  final double monthlySpends;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FinarcCard(
      onTap: () => context.push('/analytics'),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isDark
                ? AppColors.darkPrimarySoft
                : AppColors.lightPrimarySoft,
            child: const Icon(Icons.insights_outlined, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'View Reports',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  'Monthly spend ${inr(monthlySpends)} • Open analytics dashboard',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          FinarcStatusBadge(
            label: monthlySpends > 0 ? 'TREND' : 'NEW',
            tone: monthlySpends > 0
                ? FinarcStatusTone.info
                : FinarcStatusTone.neutral,
            compact: true,
          ),
        ],
      ),
    );
  }
}

class DashboardFreshStartGate extends StatelessWidget {
  const DashboardFreshStartGate({super.key, required this.data});

  final DashboardSnapshot data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome to Finarc',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Start by adding your first bank account or credit card.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        SetupProgressCard(data: data),
        const SizedBox(height: AppSpacing.sm),
        FinarcCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FinarcSectionHeader(title: 'Next Best Actions'),
              const SizedBox(height: AppSpacing.sm),
              FinarcPrimaryButton(
                onPressed: () => context.push('/accounts/add?type=bank'),
                icon: Icons.account_balance_outlined,
                label: 'Add Bank Account',
              ),
              const SizedBox(height: AppSpacing.xs),
              FinarcSecondaryButton(
                onPressed: () => context.push('/accounts/add?type=cash'),
                icon: Icons.account_balance_wallet_outlined,
                label: 'Add Cash Wallet',
              ),
              const SizedBox(height: AppSpacing.xs),
              FinarcSecondaryButton(
                onPressed: () => context.push('/cards/add'),
                icon: Icons.credit_card_outlined,
                label: 'Add Card',
              ),
              const SizedBox(height: AppSpacing.xs),
              FinarcSecondaryButton(
                onPressed: () => context.push('/expenses/add'),
                icon: Icons.add_circle_outline,
                label: 'Add Expense',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        FinarcCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkPrimarySoft
                    : AppColors.lightPrimarySoft,
                child: const Icon(Icons.offline_bolt_rounded, size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Offline-first and local-only. No cloud sync. Data stays on this device.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
