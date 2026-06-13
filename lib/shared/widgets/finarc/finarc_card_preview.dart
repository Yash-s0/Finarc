import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import 'finarc_card.dart';
import 'finarc_status_badge.dart';

class FinarcCardPreview extends StatelessWidget {
  const FinarcCardPreview({
    super.key,
    required this.bank,
    required this.nickname,
    required this.maskedNumber,
    required this.outstanding,
    this.network,
    this.utilization,
    this.dueLabel,
    this.dueTone = FinarcStatusTone.neutral,
    this.onTap,
    this.footer,
  });

  final String bank;
  final String nickname;
  final String maskedNumber;
  final String outstanding;
  final String? network;
  final double? utilization;
  final String? dueLabel;
  final FinarcStatusTone dueTone;
  final VoidCallback? onTap;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final utilizationPct = (utilization ?? 0).clamp(0, 1).toDouble();

    // Theme-aware gradient and foreground colors
    final gradientColors = isDark
        ? [
            AppColors.darkPrimarySoft.withValues(alpha: 0.95),
            AppColors.darkSurfaceHigh,
          ]
        : [AppColors.lightHeroGradientStart, AppColors.lightHeroGradientEnd];
    final borderColor = isDark
        ? AppColors.darkAccent.withValues(alpha: 0.42)
        : AppColors.lightPrimary.withValues(alpha: 0.25);
    final primaryFg = isDark ? Colors.white : AppColors.lightText;
    final secondaryFg = isDark ? Colors.white70 : AppColors.lightTextMuted;
    final glowColor = isDark
        ? AppColors.darkAccent.withValues(alpha: 0.28)
        : AppColors.lightPrimary.withValues(alpha: 0.12);
    final progressBg = isDark
        ? AppColors.darkSurfaceLow
        : AppColors.lightBorder;
    final progressFg = isDark ? AppColors.darkAccent : AppColors.lightPrimary;

    return FinarcCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradientColors,
      ),
      borderColor: borderColor,
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -20,
            child: Container(
              height: 104,
              width: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [glowColor, Colors.transparent],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      bank,
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall?.copyWith(color: primaryFg),
                    ),
                  ),
                  if (dueLabel != null)
                    FinarcStatusBadge(
                      label: dueLabel!,
                      tone: dueTone,
                      compact: true,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                nickname,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: secondaryFg),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      maskedNumber,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: secondaryFg),
                    ),
                  ),
                  Text(
                    _networkLabel(network),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: primaryFg,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                outstanding,
                style: AppTextStyles.amountStyle(
                  color: primaryFg,
                  size: 20,
                  weight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: utilizationPct,
                        minHeight: 6,
                        backgroundColor: progressBg,
                        valueColor: AlwaysStoppedAnimation(progressFg),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Utilized ${(utilizationPct * 100).toStringAsFixed(0)}%',
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: secondaryFg),
                  ),
                ],
              ),
              if (footer != null) ...[
                const SizedBox(height: AppSpacing.sm),
                footer!,
              ],
            ],
          ),
        ],
      ),
    );
  }

  static String _networkLabel(String? network) {
    switch (network) {
      case 'mastercard':
        return 'MC';
      case 'rupay':
        return 'RuPay';
      case 'amex':
        return 'AMEX';
      case 'visa':
      default:
        return 'VISA';
    }
  }
}
