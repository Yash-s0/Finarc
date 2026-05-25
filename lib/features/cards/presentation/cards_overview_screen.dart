import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../data/cards_providers.dart';

class CardsOverviewScreen extends ConsumerWidget {
  const CardsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cardsOverviewProvider);
    return state.when(
      loading: () => ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: const [
          FinarcLoadingSkeleton(height: 36, width: 120),
          SizedBox(height: AppSpacing.md),
          FinarcLoadingSkeleton(height: 166),
          SizedBox(height: AppSpacing.sm),
          FinarcLoadingSkeleton(height: 98),
          SizedBox(height: AppSpacing.sm),
          FinarcLoadingSkeleton(height: 220),
        ],
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (data) {
        if (data.cards.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const FinarcEmptyState(
                title: 'No cards added yet',
                subtitle:
                    'Track billing day, due day and card utilization once you add a card.',
                icon: Icons.credit_card_off_outlined,
              ),
              const SizedBox(height: AppSpacing.sm),
              FinarcPrimaryButton(
                onPressed: () => context.push('/cards/add'),
                icon: Icons.add_card_rounded,
                label: 'Add Card',
              ),
            ],
          );
        }

        final now = DateTime.now();
        final dueSorted = [...data.cards]
          ..sort(
            (a, b) => _daysUntilDue(
              now,
              a.dueDay,
            ).compareTo(_daysUntilDue(now, b.dueDay)),
          );
        final dueSoon = dueSorted
            .where((c) => _daysUntilDue(now, c.dueDay) <= 7)
            .toList();

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text('Cards', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Track dues, limits and statements in one place.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            FinarcBalanceCard(
              label: 'Total Card Dues',
              value: inr(data.totalDues),
              subtitle: 'Across ${data.cards.length} cards',
              statusLabel: data.utilization >= 0.8
                  ? 'High utilization'
                  : data.utilization >= 0.5
                  ? 'Moderate utilization'
                  : 'Utilization in control',
            ),
            const SizedBox(height: AppSpacing.sm),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.72,
              crossAxisSpacing: AppSpacing.xs,
              mainAxisSpacing: AppSpacing.xs,
              children: [
                FinarcMetricCard(
                  title: 'Unbilled Spends',
                  value: inr(data.unbilled),
                ),
                FinarcMetricCard(
                  title: 'Total Utilization',
                  value: '${(data.utilization * 100).toStringAsFixed(1)}%',
                  trailing: Icon(
                    Icons.stacked_line_chart_rounded,
                    size: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const FinarcSectionHeader(title: 'Upcoming Dues'),
            const SizedBox(height: AppSpacing.xs),
            if (dueSoon.isEmpty)
              const FinarcCard(child: Text('No dues in the next 7 days.'))
            else
              ...dueSoon.map((card) {
                final days = _daysUntilDue(now, card.dueDay);
                return FinarcCard(
                  margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  onTap: () => context.push('/cards/${card.id}'),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 17,
                        backgroundColor: AppColors.darkPrimarySoft,
                        child: Icon(Icons.event_available_outlined, size: 16),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${card.bankName} • ${card.nickname}',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              '${_dueDayLabel(days)} • ${card.maskedNumber}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        inr(card.currentOutstanding),
                        style: AppTextStyles.amountStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 14,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: AppSpacing.md),
            const FinarcSectionHeader(title: 'Card Portfolio'),
            const SizedBox(height: AppSpacing.xs),
            ...dueSorted.map((card) {
              final utilization = card.creditLimit == 0
                  ? 0.0
                  : (card.currentOutstanding / card.creditLimit)
                        .clamp(0, 1)
                        .toDouble();
              final dueDays = _daysUntilDue(now, card.dueDay);

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: FinarcCardPreview(
                  bank: card.bankName,
                  nickname: card.nickname,
                  maskedNumber: card.maskedNumber,
                  outstanding: inr(card.currentOutstanding),
                  utilization: utilization,
                  dueLabel: _dueDayLabel(dueDays),
                  dueTone: _toneForDueDays(dueDays),
                  onTap: () => context.push('/cards/${card.id}'),
                  footer: Row(
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.labelMedium,
                            children: [
                              const TextSpan(text: 'Limit '),
                              TextSpan(
                                text: inr(card.creditLimit),
                                style: AppTextStyles.amountStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  size: 11,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        'Last 4: ${card.last4}',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  static int _daysUntilDue(DateTime now, int dueDay) {
    final day = dueDay.clamp(1, 28);
    var dueDate = DateTime(now.year, now.month, day);
    if (!dueDate.isAfter(DateTime(now.year, now.month, now.day))) {
      dueDate = DateTime(now.year, now.month + 1, day);
    }
    return dueDate.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  static String _dueDayLabel(int days) {
    if (days <= 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    return 'Due in $days days';
  }

  static FinarcStatusTone _toneForDueDays(int days) {
    if (days <= 1) return FinarcStatusTone.error;
    if (days <= 4) return FinarcStatusTone.warning;
    return FinarcStatusTone.info;
  }
}
