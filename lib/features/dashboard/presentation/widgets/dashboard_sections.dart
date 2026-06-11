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
    this.onSettingsTap,
  });

  final String? name;
  final int unreadAlertsCount;
  final DateTime? now;
  final VoidCallback? onAlertsTap;
  final VoidCallback? onSettingsTap;

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
        const SizedBox(width: AppSpacing.xs),
        _headerAction(context, icon: Icons.tune_rounded, onTap: onSettingsTap),
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceHigh,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.darkBorder),
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
                color: AppColors.darkError,
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
    return GestureDetector(
      onTap: () => context.push('/dashboard/net-worth-breakdown'),
      child: FinarcCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.darkPrimarySoft.withValues(alpha: 0.72),
            AppColors.darkSurfaceHigh,
          ],
        ),
        borderColor: AppColors.darkBorder.withValues(alpha: 0.9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Net Worth', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              inr(data.netWorth),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(
                  Icons.trending_up_rounded,
                  size: 16,
                  color: AppColors.darkSuccess,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _spendTrendLabel(data.monthlySpendTrend),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.darkSuccess,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 92,
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

class _MonthlySpendTrendChart extends StatelessWidget {
  const _MonthlySpendTrendChart({required this.points});

  final List<MonthlySpendPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      painter: _MonthlySpendTrendPainter(points),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: points
              .map(
                (point) => Expanded(
                  child: Text(
                    _monthShort(point.month),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.darkTextMuted.withValues(alpha: 0.72),
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }

  static String _monthShort(DateTime month) {
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

class _MonthlySpendTrendPainter extends CustomPainter {
  _MonthlySpendTrendPainter(this.points);

  final List<MonthlySpendPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2 || size.width <= 0 || size.height <= 0) return;
    final chartHeight = math.max(12.0, size.height - 18);
    final amounts = points.map((point) => point.amount).toList(growable: false);
    final maxValue = amounts.reduce(math.max);
    final minValue = amounts.reduce(math.min);
    final range = maxValue - minValue;
    final stepX = size.width / (points.length - 1);

    final path = Path();
    for (var i = 0; i < points.length; i += 1) {
      final normalized = range <= 0 ? 0.5 : (amounts[i] - minValue) / range;
      final x = i * stepX;
      final y = chartHeight - (normalized * (chartHeight - 8)) + 4;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final glowPaint = Paint()
      ..color = AppColors.darkAccent.withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final linePaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.darkBlue, AppColors.darkAccent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);

    final last = path.computeMetrics().last;
    final tangent = last.getTangentForOffset(last.length);
    if (tangent != null) {
      canvas.drawCircle(
        tangent.position,
        3.5,
        Paint()..color = AppColors.darkAccent,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MonthlySpendTrendPainter oldDelegate) {
    return oldDelegate.points != points;
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
    final cards = [
      FinarcMetricCard(
        title: 'Bank Balance',
        value: inr(data.bankBalance),
        icon: Icons.account_balance_rounded,
        iconColor: AppColors.darkMint,
        iconBackgroundColor: AppColors.darkMint.withValues(alpha: 0.14),
        onTap: () => context.push('/accounts'),
      ),
      FinarcMetricCard(
        title: 'Card Dues',
        value: inr(data.cardDues),
        icon: Icons.credit_card_rounded,
        iconColor: AppColors.darkError,
        iconBackgroundColor: AppColors.darkError.withValues(alpha: 0.14),
        onTap: () => context.push('/cards'),
      ),
      FinarcMetricCard(
        title: 'Cash In Hand',
        value: inr(data.cashInHand),
        icon: Icons.wallet_rounded,
        iconColor: AppColors.darkWarning,
        iconBackgroundColor: AppColors.darkWarning.withValues(alpha: 0.14),
        onTap: () => context.push('/accounts'),
      ),
      FinarcMetricCard(
        title: 'Loans',
        value: inr(data.loansOutstanding),
        icon: Icons.account_balance_wallet_outlined,
        iconColor: AppColors.darkOrange,
        iconBackgroundColor: AppColors.darkOrange.withValues(alpha: 0.14),
        onTap: () => context.push('/loans'),
      ),
      FinarcMetricCard(
        title: 'To Receive',
        value: inr(data.recoverableAmount),
        icon: Icons.call_received_rounded,
        iconColor: AppColors.darkAccent,
        iconBackgroundColor: AppColors.darkAccent.withValues(alpha: 0.14),
        onTap: () => context.push('/recoverables'),
      ),
      FinarcMetricCard(
        title: 'Upcoming Bills',
        value: inr(data.payableAmount),
        icon: Icons.receipt_long_rounded,
        iconColor: AppColors.darkOrange,
        iconBackgroundColor: AppColors.darkOrange.withValues(alpha: 0.14),
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
    return FinarcCard(
      onTap: () => context.push('/pending'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.darkPrimarySoft,
            child: Icon(Icons.notification_important_outlined, size: 18),
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
    return FinarcCard(
      onTap: () => context.push('/cards'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.darkPrimarySoft,
            child: Icon(Icons.event_busy_outlined, size: 18),
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
            emptyState: const FinarcEmptyState(
              title: 'No transactions yet',
              subtitle: 'Add your first expense from quick actions.',
            ),
            itemBuilder: (context, index) {
              final t = items[index];
              final isIncome = t.type == 'income' || t.type == 'refund';
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
                  backgroundColor: _avatarColor(t.category),
                  child: Icon(
                    _categoryIcon(t.category),
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                amount: '${isIncome ? '+' : '-'}${inr(t.amount)}',
                amountColor: isIncome
                    ? AppColors.darkSuccess
                    : AppColors.darkError,
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

  static Color _avatarColor(String category) {
    final key = category.trim().toLowerCase();
    if (key.contains('food')) return AppColors.darkOrange;
    if (key.contains('travel')) return AppColors.darkBlue;
    if (key.contains('bill')) return AppColors.darkAccent;
    if (key.contains('shop')) return AppColors.darkPink;
    return AppColors.darkMint;
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
    return FinarcCard(
      onTap: () => context.push('/analytics'),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.darkPrimarySoft,
            child: Icon(Icons.insights_outlined, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('View Reports'),
                const SizedBox(height: 2),
                Text(
                  'Monthly spend ${inr(monthlySpends)} • Open analytics dashboard',
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
        const FinarcCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.darkPrimarySoft,
                child: Icon(Icons.offline_bolt_rounded, size: 18),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Offline-first and local-only. No cloud sync. Data stays on this device.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
