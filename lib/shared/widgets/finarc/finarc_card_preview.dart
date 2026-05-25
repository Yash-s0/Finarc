import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
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
  final double? utilization;
  final String? dueLabel;
  final FinarcStatusTone dueTone;
  final VoidCallback? onTap;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final utilizationPct = (utilization ?? 0).clamp(0, 1).toDouble();

    return FinarcCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -34,
            child: Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.darkAccent.withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
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
                      ).textTheme.titleSmall?.copyWith(color: Colors.white),
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
              Text(nickname, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.md),
              Text(
                maskedNumber,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                outstanding,
                style: AppTextStyles.amountStyle(
                  color: Colors.white,
                  size: 22,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: utilizationPct,
                        minHeight: 6,
                        backgroundColor: AppColors.darkSurfaceLow,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.darkAccent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${(utilizationPct * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.labelMedium,
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
}
