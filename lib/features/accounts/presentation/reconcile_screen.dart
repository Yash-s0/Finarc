import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../data/accounts_providers.dart';

class ReconcileScreen extends ConsumerStatefulWidget {
  const ReconcileScreen({super.key, required this.type, required this.id});

  final String type;
  final int id;

  @override
  ConsumerState<ReconcileScreen> createState() => _ReconcileScreenState();
}

class _ReconcileScreenState extends ConsumerState<ReconcileScreen> {
  final _balance = TextEditingController();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _balance.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(
      accountDetailProvider((widget.type, widget.id)),
    );

    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Reconcile Balance'),
      body: detailState.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: const [
            FinarcLoadingSkeleton(height: 160),
            SizedBox(height: AppSpacing.sm),
            FinarcLoadingSkeleton(height: 180),
          ],
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (detail) {
          final current = detail.balance;
          final next = double.tryParse(_balance.text) ?? current;
          final diff = next - current;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              FinarcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FinarcSectionHeader(title: 'Current Snapshot'),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      detail.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      inr(current),
                      style: AppTextStyles.amountStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 28,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FinarcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FinarcSectionHeader(title: 'Adjustment Input'),
                    const SizedBox(height: AppSpacing.sm),
                    FinarcTextField(
                      controller: _balance,
                      label: 'New balance',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onTap: () => setState(() {}),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FinarcTextField(
                      controller: _reason,
                      label: 'Adjustment reason',
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FinarcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FinarcSectionHeader(title: 'Preview'),
                    const SizedBox(height: AppSpacing.sm),
                    _line(context, 'Current balance', inr(current)),
                    _line(context, 'New balance', inr(next)),
                    _line(
                      context,
                      'Difference',
                      '${diff >= 0 ? '+' : '-'}${inr(diff.abs())}',
                      color: diff >= 0
                          ? AppColors.darkSuccess
                          : AppColors.darkError,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Reconciliation creates an adjustment entry in transaction history.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FinarcPrimaryButton(
                onPressed: () async {
                  await ref
                      .read(accountServiceProvider)
                      .reconcileBalance(
                        accountType: widget.type,
                        accountId: widget.id,
                        newBalance: double.tryParse(_balance.text) ?? current,
                        reason: _reason.text.trim(),
                      );
                  ref.invalidate(accountsOverviewProvider);
                  if (!mounted) return;
                  this.context.pop();
                },
                label: 'Apply Reconciliation',
                icon: Icons.rule_folder_outlined,
              ),
            ],
          );
        },
      ),
    );
  }

  static Widget _line(
    BuildContext context,
    String label,
    String value, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          Text(
            value,
            style: AppTextStyles.amountStyle(
              color: color ?? Theme.of(context).colorScheme.onSurface,
              size: 15,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
