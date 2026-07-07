import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../data/pending_providers.dart';
import '../data/pending_service.dart';
import '../models/pending_models.dart';
import '../notifications/card_payment_pending_codec.dart';
import '../parsing/parser_text_utils.dart';
import '../parsing/transaction_direction_classifier.dart';

String _sourceLabelForPending(String source) {
  switch (source) {
    case 'upiNotification':
      return 'UPI';
    case 'appNotification':
      return 'Notification';
    case 'manualImport':
      return 'Import';
    case 'cardPaymentNotification':
      return 'Card payment';
    default:
      return source.toUpperCase();
  }
}

String _cardPaymentCardLabel(CardPaymentPendingData data) {
  final issuer = data.issuer?.trim();
  final last4 = data.cardLast4?.trim();
  if (issuer != null &&
      issuer.isNotEmpty &&
      last4 != null &&
      last4.isNotEmpty) {
    return '$issuer Card XX$last4';
  }
  if (issuer != null && issuer.isNotEmpty) return '$issuer Card';
  if (last4 != null && last4.isNotEmpty) return 'Card XX$last4';
  return 'Credit card';
}

String _previewTextForPending(PendingTransaction item) {
  final cardPaymentData = CardPaymentPendingCodec.tryDecode(item.rawText);
  if (cardPaymentData == null) return item.rawText;
  final stripped = CardPaymentPendingCodec.strip(item.rawText);
  final parts = stripped
      .split(RegExp(r'\n---\n'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) return stripped;
  return parts.join('\n---\n');
}

String _pendingMetaWithExactTime(PendingTransaction item) {
  final local = item.transactionDate.toLocal();
  final exact = local.toString().split('.').first;
  return '$exact • ${_sourceLabelForPending(item.sourceType)}';
}

class _PendingMonthGroup {
  const _PendingMonthGroup({
    required this.key,
    required this.month,
    required this.items,
  });

  final String key;
  final DateTime month;
  final List<PendingTransaction> items;
}

class PendingTransactionsScreen extends ConsumerStatefulWidget {
  const PendingTransactionsScreen({super.key, this.openPendingId});

  final int? openPendingId;

  @override
  ConsumerState<PendingTransactionsScreen> createState() =>
      _PendingTransactionsScreenState();
}

class _PendingTransactionsScreenState
    extends ConsumerState<PendingTransactionsScreen> {
  int? _lastAutoOpenedPendingId;
  final Set<String> _collapsedMonthKeys = {};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(pendingTransactionsProvider);
    final historyState = ref.watch(pendingHistoryProvider);
    final filter = ref.watch(pendingFilterProvider);

    return FinarcScaffold(
      appBar: FinarcAppBar(
        title: 'Pending Transactions',
        actions: [
          IconButton(
            onPressed: () => context.push('/notifications/setup'),
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'Notification setup',
          ),
          IconButton(
            onPressed: () => context.push('/pending/paste'),
            icon: const Icon(Icons.text_snippet_outlined),
            tooltip: 'Paste missed message',
          ),
          if (kDebugMode)
            TextButton.icon(
              onPressed: () => ref.read(pendingActionProvider).seedDemo(),
              icon: const Icon(Icons.auto_awesome_outlined, size: 16),
              label: const Text('Seed Demo'),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _filters
                  .map(
                    (f) => FinarcActionChip(
                      label: _filterLabel(f),
                      selected: filter == f,
                      onTap: () =>
                          ref.read(pendingFilterProvider.notifier).state = f,
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: state.when(
              loading: () => ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: const [
                  FinarcLoadingSkeleton(height: 96),
                  SizedBox(height: AppSpacing.xs),
                  FinarcLoadingSkeleton(height: 96),
                  SizedBox(height: AppSpacing.xs),
                  FinarcLoadingSkeleton(height: 96),
                ],
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (items) {
                _autoOpenPendingIfNeeded(items, context);
                if (items.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(pendingTransactionsProvider);
                      ref.invalidate(pendingHistoryProvider);
                      await ref.read(pendingTransactionsProvider.future);
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      children: [
                        const SizedBox(height: 120),
                        FinarcEmptyState(
                          title: 'No pending transactions',
                          subtitle:
                              'Detected spends will appear here for confirmation.',
                          icon: Icons.notifications_paused_outlined,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        FinarcSecondaryButton(
                          onPressed: () => context.push('/notifications/setup'),
                          icon: Icons.notifications_active_outlined,
                          label: 'Enable Notification Detection',
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        FinarcSecondaryButton(
                          onPressed: () => context.push('/pending/paste'),
                          icon: Icons.text_snippet_outlined,
                          label: 'Paste Missed Message',
                        ),
                      ],
                    ),
                  );
                }

                final monthGroups = _groupByTransactionMonth(items);

                final listChildren = monthGroups.map<Widget>((group) {
                  final collapsed = _collapsedMonthKeys.contains(group.key);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FinarcSectionHeader(
                          title: _prettyMonth(group.month),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FinarcStatusBadge(
                                label: '${group.items.length}',
                                tone: FinarcStatusTone.info,
                                compact: true,
                              ),
                              const SizedBox(width: AppSpacing.xxs),
                              IconButton(
                                constraints: const BoxConstraints.tightFor(
                                  width: 36,
                                  height: 36,
                                ),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                                tooltip: collapsed
                                    ? 'Expand ${_prettyMonth(group.month)}'
                                    : 'Collapse ${_prettyMonth(group.month)}',
                                icon: Icon(
                                  collapsed
                                      ? Icons.keyboard_arrow_down_rounded
                                      : Icons.keyboard_arrow_up_rounded,
                                ),
                                onPressed: () {
                                  setState(() {
                                    if (collapsed) {
                                      _collapsedMonthKeys.remove(group.key);
                                    } else {
                                      _collapsedMonthKeys.add(group.key);
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        if (!collapsed) ...[
                          const SizedBox(height: AppSpacing.xs),
                          ...group.items.map((item) {
                            final confidenceLabel = _confidenceLabel(
                              item.confidenceScore,
                            );
                            final confidenceTone = _confidenceTone(
                              item.confidenceScore,
                            );
                            final direction = _pendingDirection(item);
                            final isIncome =
                                direction == PendingTransactionDirection.income;

                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.xs,
                              ),
                              child: FinarcTransactionTile(
                                onTap: () => FinarcBottomSheet.show<void>(
                                  context,
                                  isScrollControlled: true,
                                  child: _ConfirmTransactionSheet(item: item),
                                ),
                                title: item.merchant,
                                subtitle: item.categorySuggestion,
                                meta: _pendingMetaWithExactTime(item),
                                amount:
                                    '${isIncome ? '+' : '-'}${inr(item.amount)}',
                                amountColor: isIncome
                                    ? (isDark
                                          ? AppColors.darkSuccess
                                          : AppColors.lightSuccess)
                                    : (isDark
                                          ? AppColors.darkError
                                          : AppColors.lightError),
                                prefix: CircleAvatar(
                                  radius: 15,
                                  backgroundColor: isDark
                                      ? AppColors.darkPrimarySoft
                                      : AppColors.lightPrimarySoft,
                                  child: Icon(
                                    _pendingIcon(item.sourceType),
                                    size: 14,
                                    color: isDark
                                        ? AppColors.darkAccent
                                        : AppColors.lightAccent,
                                  ),
                                ),
                                badges: [
                                  FinarcTransactionPresentation.pendingStatusBadge(
                                    'pending',
                                  ),
                                  if (isIncome)
                                    const FinarcStatusBadge(
                                      label: 'Income',
                                      tone: FinarcStatusTone.success,
                                      compact: true,
                                    ),
                                  FinarcStatusBadge(
                                    label: confidenceLabel,
                                    tone: confidenceTone,
                                    compact: true,
                                  ),
                                  FinarcStatusBadge(
                                    label: _timeAgo(item.detectedAt),
                                    tone: FinarcStatusTone.neutral,
                                    compact: true,
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  );
                }).toList();

                listChildren.add(const SizedBox(height: AppSpacing.sm));
                listChildren.add(
                  const FinarcSectionHeader(
                    title: 'Pending Confirmation History',
                  ),
                );
                listChildren.add(const SizedBox(height: AppSpacing.xs));
                listChildren.add(
                  historyState.when(
                    loading: () => const FinarcLoadingSkeleton(height: 88),
                    error: (_, _) => FinarcEmptyState(
                      title: 'No decision history',
                      subtitle: 'Ignored and duplicate items will appear here.',
                      icon: Icons.history_toggle_off_outlined,
                    ),
                    data: (history) {
                      if (history.isEmpty) {
                        return FinarcEmptyState(
                          title: 'No decision history',
                          subtitle:
                              'Ignored and duplicate items will appear here.',
                          icon: Icons.history_toggle_off_outlined,
                        );
                      }
                      return Column(
                        children: history
                            .map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.xs,
                                ),
                                child: FinarcTransactionTile(
                                  title: item.merchant,
                                  subtitle: item.categorySuggestion,
                                  meta: _pendingMetaWithExactTime(item),
                                  amount:
                                      '${_pendingDirection(item) == PendingTransactionDirection.income ? '+' : '-'}${inr(item.amount)}',
                                  amountColor:
                                      _pendingDirection(item) ==
                                          PendingTransactionDirection.income
                                      ? (isDark
                                            ? AppColors.darkSuccess
                                            : AppColors.lightSuccess)
                                      : (isDark
                                            ? AppColors.darkError
                                            : AppColors.lightError),
                                  prefix: CircleAvatar(
                                    radius: 15,
                                    backgroundColor: isDark
                                        ? AppColors.darkSurfaceHigh
                                        : AppColors.lightSurfaceHigh,
                                    child: Icon(
                                      _pendingIcon(item.sourceType),
                                      size: 14,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                  ),
                                  badges: [
                                    FinarcTransactionPresentation.pendingStatusBadge(
                                      item.status,
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                );

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(pendingTransactionsProvider);
                    ref.invalidate(pendingHistoryProvider);
                    await ref.read(pendingTransactionsProvider.future);
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    children: listChildren,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static const _filters = ['All', 'sms', 'upiNotification', 'appNotification'];

  void _autoOpenPendingIfNeeded(
    List<PendingTransaction> items,
    BuildContext context,
  ) {
    final targetId = widget.openPendingId;
    if (targetId == null || _lastAutoOpenedPendingId == targetId) return;
    PendingTransaction? item;
    for (final value in items) {
      if (value.id == targetId) {
        item = value;
        break;
      }
    }
    if (item == null) return;
    final selected = item;
    _lastAutoOpenedPendingId = targetId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FinarcBottomSheet.show<void>(
        context,
        isScrollControlled: true,
        child: _ConfirmTransactionSheet(item: selected),
      );
    });
  }

  static String _filterLabel(String filter) {
    switch (filter) {
      case 'upiNotification':
        return 'UPI';
      case 'appNotification':
        return 'Notification';
      case 'sms':
        return 'SMS';
      default:
        return filter;
    }
  }

  static String _confidenceLabel(double score) {
    final pct = (score * 100).toStringAsFixed(0);
    if (score >= 0.9) return 'High $pct%';
    if (score >= 0.8) return 'Medium $pct%';
    return 'Low $pct%';
  }

  static FinarcStatusTone _confidenceTone(double score) {
    if (score >= 0.9) return FinarcStatusTone.success;
    if (score >= 0.8) return FinarcStatusTone.warning;
    return FinarcStatusTone.error;
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  static List<_PendingMonthGroup> _groupByTransactionMonth(
    List<PendingTransaction> items,
  ) {
    final sortedItems = [...items]
      ..sort((a, b) {
        final dateCompare = b.transactionDate.compareTo(a.transactionDate);
        if (dateCompare != 0) return dateCompare;
        return b.detectedAt.compareTo(a.detectedAt);
      });
    final grouped = <String, List<PendingTransaction>>{};
    final months = <String, DateTime>{};
    for (final item in sortedItems) {
      final local = item.transactionDate.toLocal();
      final month = DateTime(local.year, local.month);
      final key = _monthKey(month);
      months[key] = month;
      grouped.putIfAbsent(key, () => []).add(item);
    }
    final groups = grouped.entries
        .map(
          (entry) => _PendingMonthGroup(
            key: entry.key,
            month: months[entry.key]!,
            items: entry.value,
          ),
        )
        .toList(growable: false);
    return groups..sort((a, b) => b.month.compareTo(a.month));
  }

  static String _monthKey(DateTime month) {
    return '${month.year}-${month.month.toString().padLeft(2, '0')}';
  }

  static String _prettyMonth(DateTime month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${names[month.month - 1]} ${month.year}';
  }

  static IconData _pendingIcon(String sourceType) {
    switch (sourceType) {
      case 'upiNotification':
        return Icons.qr_code_2_rounded;
      case 'appNotification':
        return Icons.notifications_active_outlined;
      default:
        return Icons.sms_outlined;
    }
  }

  static PendingTransactionDirection _pendingDirection(
    PendingTransaction item,
  ) {
    return PendingDirectionClassifier.detect(
      text: item.rawText,
      categoryHint: item.categorySuggestion,
    );
  }
}

class _ConfirmTransactionSheet extends ConsumerWidget {
  const _ConfirmTransactionSheet({required this.item});

  final PendingTransaction item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = ref.read(pendingActionProvider);
    final direction = PendingDirectionClassifier.detect(
      text: item.rawText,
      categoryHint: item.categorySuggestion,
    );
    final cardPaymentData = CardPaymentPendingCodec.tryDecode(item.rawText);
    final isCardPayment = cardPaymentData != null;
    final isIncome = direction == PendingTransactionDirection.income;
    final sourceLabel = isCardPayment
        ? 'Paid from'
        : isIncome
        ? 'Received in'
        : 'Payment source';
    final sourceValue =
        cardPaymentData?.sourceHint ??
        ParserTextUtils.extractAccountHint(item.rawText) ??
        item.paymentSourceTypeSuggestion;
    final previewText = _previewTextForPending(item);

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isCardPayment
                  ? 'Confirm Card Payment'
                  : isIncome
                  ? 'Confirm Income'
                  : 'Confirm Transaction',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${isIncome ? '+' : '-'}${inr(item.amount)}',
              style: AppTextStyles.amountStyle(
                color: isIncome
                    ? (Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkSuccess
                          : AppColors.lightSuccess)
                    : Theme.of(context).colorScheme.onSurface,
                size: 30,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(item.merchant, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            FinarcCard(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row(context, 'Category', item.categorySuggestion),
                  _row(context, sourceLabel, sourceValue),
                  if (cardPaymentData != null)
                    _row(
                      context,
                      'Credit card',
                      _cardPaymentCardLabel(cardPaymentData),
                    ),
                  _row(
                    context,
                    'Date/Time',
                    '${item.transactionDate.toLocal()}'.split('.').first,
                  ),
                  _row(
                    context,
                    'Confidence',
                    '${(item.confidenceScore * 100).toStringAsFixed(0)}% • ${_sourceLabelForPending(item.sourceType)}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Raw Text Preview',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkSurfaceLow
                    : AppColors.lightSurfaceHigh,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder,
                ),
              ),
              child: Text(
                previewText,
                style: TextStyle(
                  fontFamily: AppTextStyles.amountFontFamily,
                  fontSize: 11,
                  height: 1.35,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: FinarcPrimaryButton(
                    onPressed: () async {
                      try {
                        final duplicate = await action.detectDuplicate(item);
                        if (duplicate != null && context.mounted) {
                          await FinarcBottomSheet.show<void>(
                            context,
                            child: _DuplicateWarningSheet(
                              pending: item,
                              existing: duplicate,
                            ),
                          );
                          return;
                        }
                        await action.confirm(
                          item.id,
                          PendingEditData(
                            amount: item.amount,
                            merchant: item.merchant,
                            category: item.categorySuggestion,
                            paymentSourceType: item.paymentSourceTypeSuggestion,
                            paymentSourceId: item.paymentSourceIdSuggestion,
                            transactionDate: item.transactionDate,
                            cashbackAmount: item.cashbackAmount,
                            isForOthers: item.isForOthers,
                            recoverableAmount: item.recoverableAmount,
                            recoveredAmount: item.recoveredAmount,
                            recoverablePartyName: item.recoverablePartyName,
                            notes: item.notes,
                          ),
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          context.push('/pending/success');
                        }
                      } on PendingConfirmationException catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error.userMessage)),
                        );
                        if (error.reason == 'missing-destination-account') {
                          Navigator.pop(context);
                          context.push('/pending/edit/${item.id}');
                        }
                      } catch (_) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Unable to confirm transaction. Please edit and try again.',
                            ),
                          ),
                        );
                      }
                    },
                    label: 'Confirm',
                    icon: Icons.check_circle_outline,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FinarcSecondaryButton(
                    onPressed: () => context.push('/pending/edit/${item.id}'),
                    label: 'Edit',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FinarcActionChip(
                  onTap: () => context.push('/pending/for-others/${item.id}'),
                  label: 'For Others',
                  icon: Icons.group_outlined,
                ),
                FinarcActionChip(
                  onTap: () => context.push('/pending/cashback/${item.id}'),
                  label: 'Add Cashback',
                  icon: Icons.local_offer_outlined,
                ),
                FinarcActionChip(
                  onTap: () async {
                    final duplicate = await action.detectDuplicate(item);
                    if (duplicate != null) {
                      await action.markDuplicate(item.id, duplicate.id);
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  label: 'Mark Duplicate',
                  icon: Icons.content_copy_outlined,
                ),
                FinarcActionChip(
                  onTap: () async {
                    await action.ignore(item.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                  label: 'Ignore',
                  icon: Icons.visibility_off_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _DuplicateWarningSheet extends ConsumerWidget {
  const _DuplicateWarningSheet({required this.pending, required this.existing});

  final PendingTransaction pending;
  final Transaction existing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final similarity = _similarity(pending.merchant, existing.title);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkWarning
                    : AppColors.lightWarning,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Duplicate Warning',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Similarity score ${(similarity * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: similarity,
              minHeight: 7,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkSurfaceLow
                  : AppColors.lightSurfaceHigh,
              valueColor: AlwaysStoppedAnimation(
                Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkWarning
                    : AppColors.lightWarning,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: FinarcCard(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Existing',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        existing.title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        inr(existing.amount),
                        style: AppTextStyles.amountStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 14,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: FinarcCard(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        pending.merchant,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        inr(pending.amount),
                        style: AppTextStyles.amountStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 14,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: FinarcPrimaryButton(
                  onPressed: () async {
                    await ref
                        .read(pendingActionProvider)
                        .mergeDuplicate(pending.id, existing.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                  label: 'Merge',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FinarcSecondaryButton(
                  onPressed: () async {
                    try {
                      await ref
                          .read(pendingActionProvider)
                          .confirm(
                            pending.id,
                            PendingEditData(
                              amount: pending.amount,
                              merchant: pending.merchant,
                              category: pending.categorySuggestion,
                              paymentSourceType:
                                  pending.paymentSourceTypeSuggestion,
                              paymentSourceId:
                                  pending.paymentSourceIdSuggestion,
                              transactionDate: pending.transactionDate,
                              cashbackAmount: pending.cashbackAmount,
                              isForOthers: pending.isForOthers,
                              recoverableAmount: pending.recoverableAmount,
                              recoveredAmount: pending.recoveredAmount,
                              recoverablePartyName:
                                  pending.recoverablePartyName,
                              notes: pending.notes,
                            ),
                          );
                      if (context.mounted) Navigator.pop(context);
                    } on PendingConfirmationException catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error.userMessage)),
                      );
                      if (error.reason == 'missing-destination-account') {
                        Navigator.pop(context);
                        context.push('/pending/edit/${pending.id}');
                      }
                    } catch (_) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Unable to confirm transaction. Please edit and try again.',
                          ),
                        ),
                      );
                    }
                  },
                  label: 'Keep Both',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('This is different'),
            ),
          ),
        ],
      ),
    );
  }

  static double _similarity(String a, String b) {
    final x = a.toLowerCase().trim().split(RegExp(r'\s+')).toSet();
    final y = b.toLowerCase().trim().split(RegExp(r'\s+')).toSet();
    final common = x.intersection(y).length;
    return x.union(y).isEmpty ? 0 : common / x.union(y).length;
  }
}
