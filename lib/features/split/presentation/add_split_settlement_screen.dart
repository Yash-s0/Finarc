import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../expenses/data/expenses_providers.dart';
import '../../expenses/models/transaction_types.dart';
import '../../expenses/presentation/payment_source_selector_support.dart';
import '../data/split_providers.dart';

class AddSplitSettlementScreen extends ConsumerStatefulWidget {
  const AddSplitSettlementScreen({super.key, required this.groupId});

  final int groupId;

  @override
  ConsumerState<AddSplitSettlementScreen> createState() =>
      _AddSplitSettlementScreenState();
}

class _AddSplitSettlementScreenState
    extends ConsumerState<AddSplitSettlementScreen> {
  static const _payerModes = [
    FinarcPaymentModeOption(
      value: PaymentSourceType.cash,
      label: 'Cash',
      icon: Icons.payments_rounded,
    ),
    FinarcPaymentModeOption(
      value: PaymentSourceType.upi,
      label: 'UPI',
      icon: Icons.qr_code_scanner_rounded,
    ),
    FinarcPaymentModeOption(
      value: PaymentSourceType.creditCard,
      label: 'Card',
      icon: Icons.credit_card_rounded,
    ),
    FinarcPaymentModeOption(
      value: PaymentSourceType.bank,
      label: 'Bank',
      icon: Icons.account_balance_rounded,
    ),
  ];
  static const _receiverModes = [
    FinarcPaymentModeOption(
      value: PaymentSourceType.cash,
      label: 'Cash',
      icon: Icons.payments_rounded,
    ),
    FinarcPaymentModeOption(
      value: PaymentSourceType.upi,
      label: 'UPI',
      icon: Icons.qr_code_scanner_rounded,
    ),
    FinarcPaymentModeOption(
      value: PaymentSourceType.bank,
      label: 'Bank',
      icon: Icons.account_balance_rounded,
    ),
  ];

  final _formKey = GlobalKey<FormState>();
  int? _fromMemberId;
  int? _toMemberId;
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  DateTime _date = DateTime.now();

  String _paymentSourceType = PaymentSourceType.bank;
  int? _paymentSourceId;

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupState = ref.watch(splitGroupDetailProvider(widget.groupId));
    final sourceState = ref.watch(paymentSourcesProvider);

    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Record Settlement'),
      body: groupState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (group) {
          if (_fromMemberId == null && group.members.isNotEmpty) {
            _fromMemberId = group.members.first.id;
          }
          if (_toMemberId == null && group.members.length > 1) {
            _toMemberId = group.members[1].id;
          }

          final currentUser = group.members
              .where((m) => m.isCurrentUser)
              .firstOrNull;
          final userInvolved =
              currentUser != null &&
              (_fromMemberId == currentUser.id ||
                  _toMemberId == currentUser.id);

          return sourceState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (sources) {
              final amount = double.tryParse(_amount.text) ?? 0;
              final currentUserPays =
                  currentUser != null && _fromMemberId == currentUser.id;
              final modeOptions = currentUserPays
                  ? _payerModes
                  : _receiverModes;
              if (!modeOptions.any((m) => m.value == _paymentSourceType)) {
                _paymentSourceType = PaymentSourceType.bank;
                _paymentSourceId = null;
              }
              final sourceConfig = sourceConfigForMode(
                sources,
                _paymentSourceType,
                destination: !currentUserPays,
              );
              _syncSourceSelection(sourceConfig.options);
              final emptyState = sourceConfig.options.isEmpty
                  ? FinarcPaymentSourceEmptyState(
                      message: sourceConfig.emptyMessage!,
                      ctaLabel: sourceConfig.emptyCtaLabel!,
                      onTap: () => context.push(sourceConfig.emptyCtaRoute!),
                    )
                  : null;

              return Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    FinarcCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const FinarcSectionHeader(
                            title: 'Settlement Details',
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          DropdownButtonFormField<int>(
                            initialValue: _fromMemberId,
                            decoration: const InputDecoration(
                              labelText: 'From member',
                            ),
                            items: group.members
                                .map(
                                  (m) => DropdownMenuItem<int>(
                                    value: m.id,
                                    child: Text(
                                      m.isCurrentUser
                                          ? '${m.name} (You)'
                                          : m.name,
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (v) => setState(() => _fromMemberId = v),
                            validator: (v) =>
                                v == null ? 'Select from member' : null,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          DropdownButtonFormField<int>(
                            initialValue: _toMemberId,
                            decoration: const InputDecoration(
                              labelText: 'To member',
                            ),
                            items: group.members
                                .map(
                                  (m) => DropdownMenuItem<int>(
                                    value: m.id,
                                    child: Text(
                                      m.isCurrentUser
                                          ? '${m.name} (You)'
                                          : m.name,
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (v) => setState(() => _toMemberId = v),
                            validator: (v) {
                              if (v == null) return 'Select to member';
                              if (v == _fromMemberId) {
                                return 'From and To cannot be same';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          FinarcTextField(
                            controller: _amount,
                            label: 'Amount',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (v) {
                              final parsed = double.tryParse(v ?? '');
                              if (parsed == null || parsed <= 0) {
                                return 'Enter amount > 0';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Date: ${_date.toLocal()}'.split(' ').first,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                    initialDate: _date,
                                  );
                                  if (date == null) return;
                                  setState(() => _date = date);
                                },
                                icon: const Icon(Icons.calendar_month_outlined),
                                label: const Text('Change'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (userInvolved)
                      FinarcCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FinarcPaymentSelector(
                              title: currentUserPays
                                  ? 'Payment Source'
                                  : 'Receive into',
                              selectedMode: _paymentSourceType,
                              modes: modeOptions,
                              onModeChanged: (v) => setState(() {
                                _paymentSourceType = v;
                                _paymentSourceId = null;
                              }),
                              sources: sourceConfig.options,
                              selectedSourceId: _paymentSourceId,
                              onSourceChanged: (v) =>
                                  setState(() => _paymentSourceId = v),
                              sourceLabel: sourceConfig.fieldLabel,
                              singleSourcePrefix: sourceConfig.singlePrefix,
                              emptyState: emptyState,
                              sourceValidator: (v) {
                                if (sourceConfig.options.length <= 1) {
                                  return null;
                                }
                                return v == null ? 'Source required' : null;
                              },
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    FinarcCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const FinarcSectionHeader(title: 'Summary'),
                          const SizedBox(height: AppSpacing.sm),
                          Text('Settlement amount: ${inr(amount)}'),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            userInvolved
                                ? 'This settlement will update your account history.'
                                : 'No personal account movement for this settlement.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FinarcTextField(
                      controller: _notes,
                      label: 'Notes (optional)',
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FinarcPrimaryButton(
                      onPressed: () => _submit(currentUser?.id, userInvolved),
                      icon: Icons.check_circle_outline,
                      label: 'Record Settlement',
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _submit(int? currentUserId, bool userInvolved) async {
    if (!_formKey.currentState!.validate()) return;
    if (_fromMemberId == null || _toMemberId == null) return;
    if (_fromMemberId == _toMemberId) return;

    final amount = double.tryParse(_amount.text) ?? 0;
    if (amount <= 0) return;

    final sources = ref.read(paymentSourcesProvider).valueOrNull;
    final currentUserPays =
        currentUserId != null && _fromMemberId == currentUserId;
    final sourceConfig = sourceConfigForMode(
      sources ??
          const PaymentSourcesData(banks: [], cards: [], cashWallets: []),
      _paymentSourceType,
      destination: !currentUserPays,
    );
    final sourceId = resolveAutoSelectedSourceId(
      _paymentSourceId,
      sourceConfig.options,
    );
    if (userInvolved && sourceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sourceConfig.emptyMessage ??
                'Select payment source for personal settlement',
          ),
        ),
      );
      return;
    }
    _paymentSourceId = sourceId;

    await ref
        .read(splitActionsProvider)
        .addSettlement(
          groupId: widget.groupId,
          fromMemberId: _fromMemberId!,
          toMemberId: _toMemberId!,
          amount: amount,
          settlementDate: _date,
          paymentSourceType: userInvolved ? _paymentSourceType : null,
          paymentSourceId: userInvolved ? sourceId : null,
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );

    if (!mounted) return;
    context.go(
      '/split/settlement/success?amount=$amount&groupId=${widget.groupId}',
    );
  }

  void _syncSourceSelection(List<FinarcPaymentSourceOption> options) {
    final next = resolveAutoSelectedSourceId(_paymentSourceId, options);
    if (next == _paymentSourceId) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _paymentSourceId = next);
    });
  }
}
