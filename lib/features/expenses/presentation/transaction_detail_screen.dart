import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart' show CreditCard;
import '../../../core/database/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/numeric_input_formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../accounts/data/wallet_types.dart';
import '../../analytics/data/analytics_providers.dart';
import '../../cards/data/billing_service.dart';
import '../../dashboard/data/dashboard_providers.dart';
import '../data/expenses_providers.dart';
import '../data/transaction_engine.dart';
import '../models/cashback_destination_types.dart';
import '../models/transaction_types.dart';
import '../../recoverables/data/recoverables_service.dart';
import 'payment_source_selector_support.dart';

final transactionByIdProvider = FutureProvider.family((ref, int id) async {
  await ref.watch(seedProvider.future);
  final db = ref.read(appDatabaseProvider);
  return (db.select(
    db.transactions,
  )..where((t) => t.id.equals(id))).getSingleOrNull();
});

class TransactionDetailScreen extends ConsumerStatefulWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});

  final int transactionId;

  @override
  ConsumerState<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState
    extends ConsumerState<TransactionDetailScreen> {
  static const _sameSourceCashbackDestination = '_sameSource';
  static const _allModes = [
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
  static const _incomeModes = [
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
  static const _cardOnlyModes = [
    FinarcPaymentModeOption(
      value: PaymentSourceType.creditCard,
      label: 'Card',
      icon: Icons.credit_card_rounded,
    ),
  ];

  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _title = TextEditingController();
  final _category = TextEditingController();
  final _notes = TextEditingController();
  final _dateController = TextEditingController();
  final _cashback = TextEditingController();
  final _recoverableParty = TextEditingController();

  bool _forOthers = false;
  DateTime _date = DateTime.now();
  String _sourceType = PaymentSourceType.cash;
  int? _sourceId;
  String _type = TransactionType.cash;
  String _cashbackDestinationType = CashbackDestinationType.unknown;
  int? _cashbackDestinationId;
  bool _initialized = false;

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    _category.dispose();
    _notes.dispose();
    _dateController.dispose();
    _cashback.dispose();
    _recoverableParty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txnState = ref.watch(transactionByIdProvider(widget.transactionId));
    final sourcesState = ref.watch(paymentSourcesProvider);

    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Transaction Details'),
      body: txnState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (txn) => sourcesState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (sources) {
            if (txn == null) {
              return const Center(child: Text('Transaction not found'));
            }
            final editable = ref
                .read(transactionEngineProvider)
                .isEditable(txn);
            if (!_initialized) {
              _amount.text = txn.amount.toStringAsFixed(2);
              _title.text = txn.title;
              _category.text = txn.category;
              _notes.text = txn.notes ?? '';
              _date = txn.transactionDate;
              _dateController.text = '${_date.toLocal()}'.split('.').first;
              _sourceType = txn.paymentSourceType;
              _sourceId = txn.paymentSourceId;
              _cashback.text = txn.cashbackAmount.toStringAsFixed(2);
              _recoverableParty.text = txn.recoverablePartyName ?? '';
              _forOthers = _recoverableParty.text.trim().isNotEmpty;
              _type = txn.type;
              _cashbackDestinationType =
                  txn.cashbackDestinationType ??
                  CashbackDestinationType.unknown;
              _cashbackDestinationId = txn.cashbackDestinationId;
              _initialized = true;
            }

            final formAmount = double.tryParse(_amount.text) ?? txn.amount;
            final cashbackSupported = _supportsCashback(sources);
            final formCashback = cashbackSupported
                ? (double.tryParse(_cashback.text) ?? txn.cashbackAmount)
                : 0.0;
            final recoverableBase = _forOthers
                ? (formAmount - formCashback).clamp(0, formAmount).toDouble()
                : 0.0;
            final recoveredAmount = _forOthers
                ? txn.recoveredAmount.clamp(0, recoverableBase).toDouble()
                : 0.0;
            final remainingRecoverable = (recoverableBase - recoveredAmount)
                .clamp(0, recoverableBase)
                .toDouble();
            final modeOptions = _sourceModesForType(txn.type);
            final sourceConfig = sourceConfigForMode(
              sources,
              _sourceType,
              destination: txn.type == TransactionType.income,
            );
            _syncSourceSelection(sourceConfig.options);
            _syncCashbackDestinationSelection(sources);
            final emptyState = sourceConfig.options.isEmpty
                ? FinarcPaymentSourceEmptyState(
                    message: sourceConfig.emptyMessage!,
                    ctaLabel: sourceConfig.emptyCtaLabel!,
                    onTap: () => context.push(sourceConfig.emptyCtaRoute!),
                  )
                : null;

            final isPositive = FinarcTransactionPresentation.isPositive(
              type: txn.type,
              paymentSourceType: txn.paymentSourceType,
              title: txn.title,
            );

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  FinarcCard(
                    child: FinarcTransactionTile(
                      title: txn.title,
                      subtitle: txn.category,
                      meta: FinarcTransactionPresentation.meta(
                        date: txn.transactionDate,
                        source: FinarcTransactionPresentation.sourceLabel(
                          txn.paymentSourceType,
                        ),
                      ),
                      amount: '${isPositive ? '+' : '-'}${inr(txn.amount)}',
                      amountColor: isPositive
                          ? AppColors.darkSuccess
                          : AppColors.darkError,
                      amountMeta: txn.cardBillId != null
                          ? 'Statement #${txn.cardBillId}'
                          : null,
                      badges: [
                        if (txn.paymentSourceType == 'creditCard')
                          FinarcTransactionPresentation.billedBadge(
                            billed: txn.cardBillId != null,
                          ),
                        if (txn.cashbackAmount > 0)
                          FinarcTransactionPresentation.cashbackBadge,
                        if (txn.type == TransactionType.loanEmi)
                          FinarcTransactionPresentation.loanPaymentBadge,
                        if (txn.isForOthers)
                          FinarcTransactionPresentation.recoverableStatusBadge(
                            txn.recoverableStatus,
                          ),
                        if (txn.isForOthers &&
                            (txn.recoverablePartyName?.trim().isNotEmpty ??
                                false))
                          FinarcStatusBadge(
                            label: 'For ${txn.recoverablePartyName!.trim()}',
                            tone: FinarcStatusTone.info,
                            compact: true,
                          ),
                      ],
                    ),
                  ),
                  if (txn.isForOthers) ...[
                    const SizedBox(height: AppSpacing.xs),
                    FinarcCard(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recoverable Visibility',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          _detailRow(
                            context,
                            'Person',
                            (txn.recoverablePartyName?.trim().isNotEmpty ??
                                    false)
                                ? txn.recoverablePartyName!.trim()
                                : 'Not set',
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          _detailRow(
                            context,
                            'Recoverable base',
                            inr(recoverableBase),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          _detailRow(
                            context,
                            'Recovered',
                            inr(recoveredAmount),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          _detailRow(
                            context,
                            'Remaining',
                            inr(remainingRecoverable),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  if (!editable)
                    const FinarcCard(
                      child: Text(
                        'This transaction has linked/system effects, so only viewing is allowed.',
                      ),
                    ),
                  if (!editable) const SizedBox(height: AppSpacing.sm),
                  FinarcTextField(
                    controller: _amount,
                    label: 'Amount',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [StripLeadingZeroFormatter()],
                    validator: (v) {
                      final amount = double.tryParse(v ?? '');
                      if (amount == null || amount <= 0) {
                        return 'Amount must be greater than 0';
                      }
                      return null;
                    },
                    readOnly: !editable,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  FinarcTextField(
                    controller: _title,
                    label: 'Title',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                    readOnly: !editable,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  FinarcTextField(
                    controller: _category,
                    label: 'Category',
                    readOnly: !editable,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  FinarcPaymentSelector(
                    title: txn.type == TransactionType.income
                        ? 'Receive into'
                        : 'Payment Source',
                    selectedMode: _sourceType,
                    modes: modeOptions,
                    onModeChanged: (v) => setState(() {
                      _sourceType = v;
                      _sourceId = null;
                    }),
                    sources: sourceConfig.options,
                    selectedSourceId: _sourceId,
                    onSourceChanged: (v) => setState(() => _sourceId = v),
                    sourceLabel: sourceConfig.fieldLabel,
                    singleSourcePrefix: sourceConfig.singlePrefix,
                    emptyState: emptyState,
                    enabled: editable,
                    sourceValidator: (v) {
                      if (sourceConfig.options.length <= 1) return null;
                      return v == null ? 'Source required' : null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  FinarcTextField(
                    controller: _dateController,
                    label: 'Date',
                    readOnly: true,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (cashbackSupported) ...[
                    FinarcTextField(
                      controller: _cashback,
                      label: 'Cashback',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [StripLeadingZeroFormatter()],
                      readOnly: !editable,
                      onChanged: !editable ? null : (_) => setState(() {}),
                    ),
                    if (formCashback > 0) ...[
                      const SizedBox(height: AppSpacing.xs),
                      DropdownButtonFormField<String>(
                        initialValue: _cashbackDestinationType,
                        decoration: const InputDecoration(
                          labelText: 'Cashback destination',
                        ),
                        items: _cashbackDestinationMenuItems(),
                        onChanged: !editable
                            ? null
                            : (value) => setState(() {
                                _cashbackDestinationType =
                                    value ?? CashbackDestinationType.unknown;
                                _cashbackDestinationId = null;
                              }),
                      ),
                      if (_shouldShowCashbackDestinationSourcePicker) ...[
                        const SizedBox(height: AppSpacing.xs),
                        DropdownButtonFormField<int>(
                          initialValue: _cashbackDestinationId,
                          decoration: InputDecoration(
                            labelText: _cashbackDestinationSourceLabel,
                          ),
                          items: _cashbackDestinationSourceItems(sources),
                          onChanged: !editable
                              ? null
                              : (value) => setState(
                                  () => _cashbackDestinationId = value,
                                ),
                        ),
                      ],
                    ],
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'For others?',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        flex: 3,
                        child: FinarcTextField(
                          controller: _recoverableParty,
                          label: 'Person name',
                          readOnly: !editable,
                          onChanged: !editable
                              ? null
                              : (value) => setState(
                                  () => _forOthers = value.trim().isNotEmpty,
                                ),
                        ),
                      ),
                    ],
                  ),
                  if (_forOthers)
                    FinarcCard(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recoverable: ${inr(recoverableBase)} from ${_recoverableParty.text.trim()}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Recovered ${inr(recoveredAmount)} • Remaining ${inr(remainingRecoverable)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          _RecoverableStatusPill(
                            status: txn.recoverableStatus,
                            recoveredAt: txn.recoveredAt,
                          ),
                          if (editable &&
                              txn.isForOthers &&
                              txn.recoverableStatus != 'recovered') ...[
                            const SizedBox(height: AppSpacing.sm),
                            FinarcPrimaryButton(
                              onPressed: () => _markRecovered(txn.id),
                              label: 'Mark as Recovered',
                              icon: Icons.verified_outlined,
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  FinarcTextField(
                    controller: _notes,
                    label: 'Notes',
                    maxLines: 2,
                    readOnly: !editable,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (editable)
                    FinarcPrimaryButton(
                      onPressed: () => _save(txn),
                      label: 'Save Changes',
                      icon: Icons.check_circle_outline,
                    ),
                  if (editable) const SizedBox(height: AppSpacing.xs),
                  if (editable)
                    FinarcSecondaryButton(
                      onPressed: () => _delete(txn.id),
                      label: 'Delete Transaction',
                      icon: Icons.delete_outline,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<FinarcPaymentModeOption> _sourceModesForType(String txnType) {
    if (txnType == TransactionType.income) return _incomeModes;
    if (txnType == TransactionType.creditCard) return _cardOnlyModes;
    return _allModes;
  }

  void _syncSourceSelection(List<FinarcPaymentSourceOption> options) {
    final next = resolveAutoSelectedSourceId(_sourceId, options);
    if (next == _sourceId) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _sourceId = next);
    });
  }

  Future<void> _save(dynamic txn) async {
    if (!_formKey.currentState!.validate()) return;
    final sources = ref.read(paymentSourcesProvider).valueOrNull;
    final sourceConfig = sourceConfigForMode(
      sources ??
          const PaymentSourcesData(banks: [], cards: [], cashWallets: []),
      _sourceType,
      destination: txn.type == TransactionType.income,
    );
    final sourceId = resolveAutoSelectedSourceId(
      _sourceId,
      sourceConfig.options,
    );
    if (sourceId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(sourceConfig.emptyMessage ?? 'Source required')),
      );
      return;
    }

    try {
      final amount = double.parse(_amount.text);
      final cashback =
          _supportsCashback(
            sources ??
                const PaymentSourcesData(banks: [], cards: [], cashWallets: []),
          )
          ? (double.tryParse(_cashback.text) ?? 0.0)
          : 0.0;
      final recoverableParty = _recoverableParty.text.trim();
      final forOthers = recoverableParty.isNotEmpty;
      final recoverableBase = forOthers
          ? (amount - cashback).clamp(0, amount).toDouble()
          : 0.0;
      final recoveredAmount = forOthers
          ? txn.recoveredAmount.clamp(0, recoverableBase).toDouble()
          : 0.0;
      final selectedCard = _sourceType == PaymentSourceType.creditCard
          ? _cardById(sources?.cards ?? const [], sourceId)
          : null;
      final transactionImpactType =
          _sourceType == PaymentSourceType.creditCard && selectedCard != null
          ? creditCardTransactionImpactTypeForDate(
              card: selectedCard,
              transactionDate: _date,
              now: DateTime.now(),
              transactionType: _type,
            )
          : _dateOnly(_date).isBefore(_dateOnlyNow())
          ? TransactionImpactType.historicalNoBalance
          : null;

      await ref
          .read(transactionEngineProvider)
          .updateTransaction(
            txn.id,
            AddTransactionInput(
              type: _type,
              amount: amount,
              title: _title.text.trim(),
              category: _category.text.trim(),
              transactionDate: _date,
              paymentSourceType: _sourceType,
              paymentSourceId: sourceId,
              cashbackAmount: cashback,
              cashbackDestinationType: _resolvedCashbackDestinationType(
                sources ??
                    const PaymentSourcesData(
                      banks: [],
                      cards: [],
                      cashWallets: [],
                    ),
              ),
              cashbackDestinationId: _resolvedCashbackDestinationId(
                sources ??
                    const PaymentSourcesData(
                      banks: [],
                      cards: [],
                      cashWallets: [],
                    ),
              ),
              isForOthers: forOthers,
              recoverableAmount: forOthers
                  ? (recoverableBase - recoveredAmount)
                        .clamp(0, recoverableBase)
                        .toDouble()
                  : null,
              recoveredAmount: recoveredAmount,
              recoverablePartyName: forOthers ? recoverableParty : null,
              recoveredAt: txn.recoveredAt,
              notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
              transactionImpactType: transactionImpactType,
            ),
          );
      _invalidateAll();
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to update: $e')));
    }
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  DateTime _dateOnlyNow() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  CreditCard? _cardById(List<CreditCard> cards, int cardId) {
    for (final card in cards) {
      if (card.id == cardId) return card;
    }
    return null;
  }

  bool _supportsCashback(PaymentSourcesData sources) {
    if (_sourceType != PaymentSourceType.cash) return true;
    final walletId = resolveAutoSelectedSourceId(
      _sourceId,
      sourceConfigForMode(sources, _sourceType).options,
    );
    if (walletId == null) return false;
    for (final wallet in sources.cashWallets) {
      if (wallet.id == walletId) {
        return !WalletType.matches(wallet, WalletType.cash);
      }
    }
    return false;
  }

  void _syncCashbackDestinationSelection(PaymentSourcesData sources) {
    if (!_shouldShowCashbackDestinationSourcePicker) return;
    final items = _cashbackDestinationSourceItems(sources);
    final exists = items.any((item) => item.value == _cashbackDestinationId);
    if (exists || items.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _cashbackDestinationId = items.first.value);
    });
  }

  List<DropdownMenuItem<String>> _cashbackDestinationMenuItems() {
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem(
        value: CashbackDestinationType.unknown,
        child: Text('Unknown / not received yet'),
      ),
    ];
    if (_sourceId != null) {
      items.add(
        const DropdownMenuItem(
          value: _sameSourceCashbackDestination,
          child: Text('Same source'),
        ),
      );
    }
    items.addAll(const [
      DropdownMenuItem(
        value: CashbackDestinationType.bank,
        child: Text('Bank account'),
      ),
      DropdownMenuItem(
        value: CashbackDestinationType.cash,
        child: Text('Cash wallet'),
      ),
      DropdownMenuItem(
        value: CashbackDestinationType.amazonPay,
        child: Text('Amazon Pay wallet'),
      ),
      DropdownMenuItem(
        value: CashbackDestinationType.otherWallet,
        child: Text('Other wallet'),
      ),
    ]);
    if (_sourceType == PaymentSourceType.creditCard && _sourceId != null) {
      items.add(
        const DropdownMenuItem(
          value: CashbackDestinationType.creditCard,
          child: Text('Same credit card'),
        ),
      );
    }
    return items;
  }

  List<DropdownMenuItem<int>> _cashbackDestinationSourceItems(
    PaymentSourcesData sources,
  ) {
    switch (_cashbackDestinationType) {
      case CashbackDestinationType.bank:
        return sources.banks
            .map(
              (bank) => DropdownMenuItem(
                value: bank.id,
                child: Text('${bank.accountName} • ${bank.bankName}'),
              ),
            )
            .toList(growable: false);
      case CashbackDestinationType.cash:
      case CashbackDestinationType.amazonPay:
      case CashbackDestinationType.otherWallet:
        return sources.cashWallets
            .where((wallet) {
              if (_cashbackDestinationType == CashbackDestinationType.cash) {
                return WalletType.matches(wallet, WalletType.cash);
              }
              if (_cashbackDestinationType ==
                  CashbackDestinationType.amazonPay) {
                return WalletType.matches(wallet, WalletType.amazonPay);
              }
              return WalletType.matches(wallet, WalletType.otherWallet);
            })
            .map(
              (wallet) => DropdownMenuItem(
                value: wallet.id,
                child: Text(WalletType.displayName(wallet)),
              ),
            )
            .toList(growable: false);
      case CashbackDestinationType.creditCard:
      case CashbackDestinationType.unknown:
      case _sameSourceCashbackDestination:
      default:
        return const [];
    }
  }

  bool get _shouldShowCashbackDestinationSourcePicker {
    return _cashbackDestinationType != CashbackDestinationType.unknown &&
        _cashbackDestinationType != CashbackDestinationType.creditCard &&
        _cashbackDestinationType != _sameSourceCashbackDestination;
  }

  String get _cashbackDestinationSourceLabel {
    switch (_cashbackDestinationType) {
      case CashbackDestinationType.bank:
        return 'Select bank account';
      case CashbackDestinationType.cash:
        return 'Select cash wallet';
      case CashbackDestinationType.amazonPay:
        return 'Select Amazon Pay wallet';
      case CashbackDestinationType.otherWallet:
        return 'Select other wallet';
      default:
        return 'Select destination';
    }
  }

  String? _resolvedCashbackDestinationType(PaymentSourcesData sources) {
    final cashback = double.tryParse(_cashback.text.trim()) ?? 0;
    if (cashback <= 0) return null;
    if (_cashbackDestinationType == _sameSourceCashbackDestination) {
      if (_sourceType == PaymentSourceType.bank ||
          _sourceType == PaymentSourceType.upi) {
        return CashbackDestinationType.bank;
      }
      if (_sourceType == PaymentSourceType.creditCard) {
        return CashbackDestinationType.creditCard;
      }
      for (final wallet in sources.cashWallets) {
        if (wallet.id == _sourceId) {
          return switch (WalletType.normalize(wallet.walletType)) {
            WalletType.amazonPay => CashbackDestinationType.amazonPay,
            WalletType.otherWallet => CashbackDestinationType.otherWallet,
            _ => CashbackDestinationType.cash,
          };
        }
      }
      return CashbackDestinationType.unknown;
    }
    return _cashbackDestinationType == CashbackDestinationType.unknown
        ? CashbackDestinationType.unknown
        : _cashbackDestinationType;
  }

  int? _resolvedCashbackDestinationId(PaymentSourcesData sources) {
    final type = _resolvedCashbackDestinationType(sources);
    if (type == null || type == CashbackDestinationType.unknown) return null;
    if (type == CashbackDestinationType.creditCard ||
        _cashbackDestinationType == _sameSourceCashbackDestination) {
      return _sourceId;
    }
    return _cashbackDestinationId;
  }

  Future<void> _markRecovered(int transactionId) async {
    try {
      await ref.read(transactionEngineProvider).markRecovered(transactionId);
      _invalidateAll();
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to mark as recovered: $e')),
      );
    }
  }

  Future<void> _delete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('This will reverse its balance effect.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(transactionEngineProvider).deleteTransaction(id);
      _invalidateAll();
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to delete: $e')));
    }
  }

  void _invalidateAll() {
    ref.invalidate(expenseListProvider);
    ref.invalidate(dashboardProvider);
    ref.invalidate(analyticsSnapshotProvider);
    ref.invalidate(recoverablesSnapshotProvider);
    ref.invalidate(transactionByIdProvider(widget.transactionId));
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.labelMedium),
        ),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _RecoverableStatusPill extends StatelessWidget {
  const _RecoverableStatusPill({
    required this.status,
    required this.recoveredAt,
  });

  final String? status;
  final DateTime? recoveredAt;

  @override
  Widget build(BuildContext context) {
    final normalized = (status ?? 'unpaid').toLowerCase();
    final isRecovered = normalized == 'recovered';
    final isPartial = normalized == 'partial';
    final label = isRecovered
        ? 'Recovered${recoveredAt == null ? '' : ' • ${recoveredAt!.day}/${recoveredAt!.month}/${recoveredAt!.year}'}'
        : isPartial
        ? 'Partially Recovered'
        : 'Unpaid';
    return FinarcStatusBadge(
      label: label,
      tone: isRecovered
          ? FinarcStatusTone.success
          : isPartial
          ? FinarcStatusTone.info
          : FinarcStatusTone.warning,
    );
  }
}
