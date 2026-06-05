import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../data/recoverables_service.dart';

class RecoverablesBreakdownScreen extends ConsumerWidget {
  const RecoverablesBreakdownScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recoverablesSnapshotProvider);

    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Recoverables'),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              FinarcBalanceCard(
                label: 'Outstanding Recoverable',
                value: inr(data.normalRecoverables),
                subtitle:
                    'Grouped by person. Split receivables stay separate until person mapping is verified.',
                trendLabel:
                    'Actionable ${inr(data.actionableRecoverables)} • Recovered ${inr(data.settledRecoverables)}',
                statusLabel: data.normalRecoverables > 0 ? 'Open' : 'Clear',
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: FinarcMetricCard(
                      title: 'Card Billed',
                      value: inr(data.cardBilledRecoverables),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: FinarcMetricCard(
                      title: 'Card Unbilled',
                      value: inr(data.cardUnbilledRecoverables),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: FinarcMetricCard(
                      title: 'Bank / UPI',
                      value: inr(data.bankUpiRecoverables),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: FinarcMetricCard(
                      title: 'Cash',
                      value: inr(data.cashRecoverables),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: FinarcMetricCard(
                      title: 'Recovered',
                      value: inr(data.settledRecoverables),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: FinarcMetricCard(
                      title: 'Split Receivables',
                      value: inr(data.splitReceivables),
                      onTap: () => context.push('/split'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const FinarcSectionHeader(title: 'By Person'),
              const SizedBox(height: AppSpacing.xs),
              if (data.groups.isEmpty)
                const FinarcEmptyState(
                  title: 'No recoverables',
                  subtitle: 'Recoverables will appear here once you add them.',
                  icon: Icons.call_received_rounded,
                )
              else
                ...data.groups.map(
                  (group) => _RecoverablePartyCard(group: group),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RecoverablePartyCard extends StatelessWidget {
  const _RecoverablePartyCard({required this.group});

  final RecoverablePartyGroup group;

  @override
  Widget build(BuildContext context) {
    final dueDate = group.nearestDueDate;
    final sourceSummary = group.sourceSummary.join(' / ');

    return FinarcCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: () => context.push(
        Uri(
          path: '/recoverables/person',
          queryParameters: {'name': group.partyName},
        ).toString(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.partyName),
                    const SizedBox(height: 2),
                    Text(
                      '${group.transactionCount} transactions${sourceSummary.isEmpty ? '' : ' • $sourceSummary'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 18),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              FinarcStatusBadge(
                label: 'Remaining ${inr(group.remainingTotal)}',
                tone: FinarcStatusTone.info,
                compact: true,
              ),
              FinarcStatusBadge(
                label: 'Recovered ${inr(group.recoveredTotal)}',
                tone: group.recoveredTotal > 0
                    ? FinarcStatusTone.success
                    : FinarcStatusTone.neutral,
                compact: true,
              ),
              FinarcStatusBadge(
                label: 'Base ${inr(group.originalTotal)}',
                tone: FinarcStatusTone.neutral,
                compact: true,
              ),
              if (dueDate != null)
                FinarcStatusBadge(
                  label:
                      'Due ${transactionDateLabel(dueDate, includeTimeForToday: false)}',
                  tone: FinarcStatusTone.warning,
                  compact: true,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
