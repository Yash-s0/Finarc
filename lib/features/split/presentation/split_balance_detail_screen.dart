import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../data/split_providers.dart';

class SplitBalanceDetailScreen extends ConsumerWidget {
  const SplitBalanceDetailScreen({super.key, required this.groupId});

  final int groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(splitGroupDetailProvider(groupId));

    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Group Balances'),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const FinarcSectionHeader(title: 'Member-wise Balances'),
              const SizedBox(height: AppSpacing.xs),
              ...data.memberBalances.map((entry) {
                final net = entry.net;
                final color = net < 0
                    ? AppColors.darkError
                    : AppColors.darkSuccess;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: FinarcCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.member.isCurrentUser
                                ? '${entry.member.name} (You)'
                                : entry.member.name,
                          ),
                        ),
                        Text(
                          inr(net),
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall?.copyWith(color: color),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: AppSpacing.md),
              const FinarcSectionHeader(title: 'Simplified Settlements'),
              const SizedBox(height: AppSpacing.xs),
              if (data.simplifiedTransfers.isEmpty)
                const FinarcCard(child: Text('All balances are settled.'))
              else
                ...data.simplifiedTransfers.map((xfer) {
                  final fromName = _memberNameById(data, xfer.fromMemberId);
                  final toName = _memberNameById(data, xfer.toMemberId);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: FinarcCard(
                      child: Row(
                        children: [
                          Expanded(child: Text(fromName)),
                          const Icon(Icons.arrow_forward_rounded, size: 16),
                          Expanded(
                            child: Text(toName, textAlign: TextAlign.end),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            inr(xfer.amount),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  String _memberNameById(SplitGroupDetail data, int id) {
    for (final member in data.members) {
      if (member.id == id) return member.name;
    }
    return 'Member #$id';
  }
}
