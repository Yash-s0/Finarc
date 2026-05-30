import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import 'finarc_status_badge.dart';

class FinarcTransactionTile extends StatelessWidget {
  const FinarcTransactionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.prefix,
    this.badges = const [],
    this.amountColor,
    this.onTap,
    this.meta,
    this.amountMeta,
    this.statusLabel,
    this.statusTone = FinarcStatusTone.neutral,
    this.compact = false,
    this.date,
    this.source,
  });

  final String title;
  final String subtitle;
  final String amount;
  final Widget? prefix;
  final List<Widget> badges;
  final Color? amountColor;
  final VoidCallback? onTap;
  final String? meta;
  final String? amountMeta;
  final String? statusLabel;
  final FinarcStatusTone statusTone;
  final bool compact;
  final DateTime? date;
  final String? source;

  @override
  Widget build(BuildContext context) {
    final iconGap = compact ? AppSpacing.xs : AppSpacing.sm;
    final titleStyle = compact
        ? Theme.of(context).textTheme.labelLarge
        : Theme.of(context).textTheme.titleSmall;
    final resolvedMeta =
        meta ??
        (date == null
            ? null
            : transactionMetaLabel(date!, sourceLabel: source));
    final content = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (prefix != null) ...[prefix!, SizedBox(width: iconGap)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: titleStyle),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.labelMedium),
                if (resolvedMeta != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    resolvedMeta,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (badges.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xxs),
                    child: Wrap(spacing: 6, runSpacing: 6, children: badges),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                textAlign: TextAlign.end,
                style: AppTextStyles.amountStyle(
                  color: amountColor ?? Theme.of(context).colorScheme.onSurface,
                  size: compact ? 13.5 : 14.5,
                  weight: FontWeight.w700,
                ),
              ),
              if (amountMeta != null) ...[
                const SizedBox(height: 2),
                Text(amountMeta!, style: Theme.of(context).textTheme.bodySmall),
              ],
              if (statusLabel != null) ...[
                const SizedBox(height: 4),
                FinarcStatusBadge(
                  label: statusLabel!,
                  tone: statusTone,
                  compact: true,
                ),
              ],
            ],
          ),
          if (onTap != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: content,
    );
  }
}
