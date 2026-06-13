import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/numeric_input_formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../accounts/data/wallet_types.dart';
import '../../alerts/data/alerts_providers.dart';
import '../../cards/data/cards_providers.dart';
import '../data/expenses_providers.dart';
import '../data/transaction_engine.dart';
import '../models/cashback_destination_types.dart';
import '../models/transaction_types.dart';
import 'entry_date_time_utils.dart';
import 'payment_source_selector_support.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({
    super.key,
    this.isIncome = false,
    this.initialDateTime,
  });

  final bool isIncome;
  final DateTime? initialDateTime;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  static const _sameSourceCashbackDestination = '_sameSource';
  static const _paymentModes = [
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

  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _title = TextEditingController();
  final _category = TextEditingController(text: 'General');
  final _cashback = TextEditingController(text: '0');
  final _recoverableParty = TextEditingController();
  final _notes = TextEditingController();
  final _dateController = TextEditingController();

  String _paymentMode = PaymentSourceType.cash;
  int? _sourceId;
  String _cashbackDestinationType = CashbackDestinationType.unknown;
  int? _cashbackDestinationId;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDateTime ?? DateTime.now();
    _dateController.text = _dateText(_date);
  }

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    _category.dispose();
    _cashback.dispose();
    _recoverableParty.dispose();
    _notes.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sourceState = ref.watch(paymentSourcesProvider);
    final amount = double.tryParse(_amount.text.trim()) ?? 0;
    final recoverableParty = _recoverableParty.text.trim();
    final recoverableSuggestions = ref.watch(
      recoverablePartySuggestionsProvider,
    );

    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Add Expense'),
      body: sourceState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (sources) {
          final cashbackSupported = _supportsCashback(sources);
          final cashback = cashbackSupported
              ? (double.tryParse(_cashback.text.trim()) ?? 0)
              : 0.0;
          final forOthers = recoverableParty.isNotEmpty;
          final recoverable = forOthers
              ? (amount - cashback).clamp(0, amount).toDouble()
              : 0.0;
          final sourceConfig = sourceConfigForMode(
            sources,
            _resolvedPaymentMode,
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
          return Column(
            children: [
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    children: [
                      FinarcCard(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        child: SegmentedButton<String>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment<String>(
                              value: 'expense',
                              label: Text('Expense'),
                            ),
                            ButtonSegment<String>(
                              value: 'income',
                              label: Text('Income'),
                            ),
                          ],
                          selected: const {'expense'},
                          onSelectionChanged: (selection) {
                            if (selection.first == 'income') {
                              context.go('/income/add');
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      FinarcCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              inr(amount),
                              style: AppTextStyles.amountStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                size: 33,
                                weight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            TextFormField(
                              controller: _amount,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              textInputAction: TextInputAction.next,
                              inputFormatters: [StripLeadingZeroFormatter()],
                              onChanged: (_) => setState(() {}),
                              style: AppTextStyles.amountStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                size: 40,
                                weight: FontWeight.w800,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Enter amount',
                                prefixText: '₹ ',
                              ),
                              validator: (v) {
                                final amt = double.tryParse(v ?? '');
                                if (amt == null || amt <= 0) {
                                  return 'Amount must be greater than 0';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            FinarcTextField(
                              controller: _title,
                              label: 'Merchant / Title (optional)',
                              prefixIcon: const Icon(
                                Icons.storefront_rounded,
                                size: 18,
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
                            FinarcPaymentSelector(
                              title: 'Payment Mode',
                              selectedMode: _paymentMode,
                              modes: _paymentModes,
                              onModeChanged: (mode) => setState(() {
                                _paymentMode = mode;
                                _sourceId = null;
                              }),
                              sources: sourceConfig.options,
                              selectedSourceId: _sourceId,
                              onSourceChanged: (v) =>
                                  setState(() => _sourceId = v),
                              sourceLabel: sourceConfig.fieldLabel,
                              singleSourcePrefix: sourceConfig.singlePrefix,
                              emptyState: emptyState,
                              compactModeTiles: true,
                              useSourceCardPicker: true,
                              modeTestPrefix: 'expense-mode',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      FinarcCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FinarcSectionHeader(title: 'Category'),
                            const SizedBox(height: AppSpacing.xs),
                            FinarcTextField(
                              controller: _category,
                              label: 'Category',
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Wrap(
                              spacing: AppSpacing.xs,
                              runSpacing: AppSpacing.xs,
                              children:
                                  [
                                        'Food',
                                        'Groceries',
                                        'Bills',
                                        'Travel',
                                        'Health',
                                      ]
                                      .map(
                                        (c) => FinarcActionChip(
                                          label: c,
                                          selected:
                                              _category.text
                                                  .trim()
                                                  .toLowerCase() ==
                                              c.toLowerCase(),
                                          onTap: () => setState(
                                            () => _category.text = c,
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      FinarcCard(
                        child: FinarcTextField(
                          controller: _dateController,
                          label: 'Transaction date',
                          readOnly: true,
                          suffixIcon: const Icon(Icons.calendar_month_outlined),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _date,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                _date = mergeDateWithExistingTime(
                                  pickedDate: picked,
                                  existing: _date,
                                );
                                _dateController.text = _dateText(_date);
                              });
                            }
                          },
                        ),
                      ),
                      if (cashbackSupported) ...[
                        const SizedBox(height: AppSpacing.sm),
                        FinarcCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FinarcTextField(
                                controller: _cashback,
                                label: 'Cashback amount',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [StripLeadingZeroFormatter()],
                                onChanged: (_) => setState(() {}),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return null;
                                  }
                                  final value = double.tryParse(v.trim());
                                  if (value == null || value < 0) {
                                    return 'Enter valid cashback';
                                  }
                                  final enteredAmount =
                                      double.tryParse(_amount.text.trim()) ?? 0;
                                  if (value > enteredAmount &&
                                      enteredAmount > 0) {
                                    return 'Cashback cannot exceed amount';
                                  }
                                  return null;
                                },
                              ),
                              if (cashback > 0) ...[
                                const SizedBox(height: AppSpacing.sm),
                                DropdownButtonFormField<String>(
                                  initialValue: _cashbackDestinationType,
                                  decoration: const InputDecoration(
                                    labelText: 'Cashback destination',
                                  ),
                                  items: _cashbackDestinationMenuItems(sources),
                                  onChanged: (value) => setState(() {
                                    _cashbackDestinationType =
                                        value ??
                                        CashbackDestinationType.unknown;
                                    _cashbackDestinationId = null;
                                  }),
                                ),
                                if (_shouldShowCashbackDestinationSourcePicker)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: AppSpacing.sm,
                                    ),
                                    child: DropdownButtonFormField<int>(
                                      initialValue: _cashbackDestinationId,
                                      decoration: InputDecoration(
                                        labelText:
                                            _cashbackDestinationSourceLabel,
                                      ),
                                      items: _cashbackDestinationSourceItems(
                                        sources,
                                      ),
                                      onChanged: (value) => setState(
                                        () => _cashbackDestinationId = value,
                                      ),
                                      validator: (value) {
                                        if (cashback <= 0 ||
                                            !_shouldShowCashbackDestinationSourcePicker) {
                                          return null;
                                        }
                                        return value == null
                                            ? 'Destination required'
                                            : null;
                                      },
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      FinarcCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'For others?',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    key: const Key('expense-for-others-person'),
                                    controller: _recoverableParty,
                                    decoration: const InputDecoration(
                                      labelText: 'Person name',
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                              ],
                            ),
                            if (recoverableSuggestions.hasValue &&
                                (recoverableSuggestions.valueOrNull ?? [])
                                    .isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Wrap(
                                spacing: AppSpacing.xs,
                                runSpacing: AppSpacing.xs,
                                children: recoverableSuggestions.valueOrNull!
                                    .take(6)
                                    .map(
                                      (name) => FinarcActionChip(
                                        label: name,
                                        selected: recoverableParty == name,
                                        onTap: () => setState(
                                          () => _recoverableParty.text = name,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      FinarcCard(
                        child: FinarcTextField(
                          controller: _notes,
                          label: 'Notes',
                          maxLines: 2,
                          textInputAction: TextInputAction.done,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      FinarcCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.darkPrimarySoft,
                              child: Icon(
                                Icons.receipt_long_outlined,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                forOthers
                                    ? 'Recoverable: ${inr(recoverable)} from $recoverableParty'
                                    : 'Preview amount: ${inr(amount)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs,
                  AppSpacing.md,
                  MediaQuery.of(context).viewInsets.bottom + AppSpacing.xs,
                ),
                child: FinarcPrimaryButton(
                  onPressed: _submit,
                  label: 'Save Expense',
                  icon: Icons.check_circle_outline,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _dateText(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  void _syncSourceSelection(List<FinarcPaymentSourceOption> options) {
    final next = resolveAutoSelectedSourceId(_sourceId, options);
    if (next == _sourceId) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _sourceId = next);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final sources = ref.read(paymentSourcesProvider).valueOrNull;
    final config = sourceConfigForMode(
      sources ??
          const PaymentSourcesData(banks: [], cards: [], cashWallets: []),
      _resolvedPaymentMode,
    );
    final sourceId = resolveAutoSelectedSourceId(_sourceId, config.options);
    if (sourceId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(config.emptyMessage ?? 'Select payment source')),
      );
      return;
    }
    _sourceId = sourceId;

    final amount = double.parse(_amount.text.trim());
    final cashback =
        _supportsCashback(
          sources ??
              const PaymentSourcesData(banks: [], cards: [], cashWallets: []),
        )
        ? (double.tryParse(_cashback.text.trim()) ?? 0)
        : 0.0;
    final recoverableParty = _recoverableParty.text.trim();
    final forOthers = recoverableParty.isNotEmpty;
    final recoverableBase = forOthers
        ? (amount - cashback).clamp(0, amount).toDouble()
        : 0.0;
    const recovered = 0.0;
    if (cashback > amount) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cashback cannot exceed amount')),
      );
      return;
    }

    final type = widget.isIncome
        ? TransactionType.income
        : _resolvedPaymentMode == PaymentSourceType.creditCard
        ? TransactionType.creditCard
        : _resolvedPaymentMode;
    final category = _category.text.trim();
    final title = _title.text.trim().isEmpty
        ? ((category.isEmpty || category.toLowerCase() == 'general')
              ? 'General Expense'
              : '$category Expense')
        : _title.text.trim();
    final transactionImpactType = _dateOnly(_date).isBefore(_dateOnlyNow())
        ? TransactionImpactType.historicalNoBalance
        : null;

    try {
      await ref
          .read(transactionEngineProvider)
          .addTransaction(
            AddTransactionInput(
              type: type,
              amount: amount,
              title: title,
              category: category.isEmpty ? 'General' : category,
              notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
              transactionDate: _date,
              paymentSourceType: _resolvedPaymentMode,
              paymentSourceId: _sourceId,
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
                  ? (recoverableBase - recovered)
                        .clamp(0, recoverableBase)
                        .toDouble()
                  : null,
              recoveredAmount: recovered,
              recoverablePartyName: forOthers ? recoverableParty : null,
              transactionImpactType: transactionImpactType,
            ),
          );

      final db = ref.read(appDatabaseProvider);
      final latest =
          await (db.select(db.transactions)
                ..orderBy([(t) => OrderingTerm.desc(t.id)])
                ..limit(1))
              .getSingleOrNull();
      if (latest != null) {
        await ref
            .read(alertEvaluationActionsProvider)
            .evaluateAfterTransaction(latest);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to save transaction: $e')));
      return;
    }

    ref.invalidate(expenseListProvider);
    ref.invalidate(cardsOverviewProvider);
    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  DateTime _dateOnlyNow() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  String get _resolvedPaymentMode => _paymentMode;

  bool _supportsCashback(PaymentSourcesData sources) {
    if (_resolvedPaymentMode != PaymentSourceType.cash) return true;
    final walletId = resolveAutoSelectedSourceId(
      _sourceId,
      sourceConfigForMode(sources, _resolvedPaymentMode).options,
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

  List<DropdownMenuItem<String>> _cashbackDestinationMenuItems(
    PaymentSourcesData sources,
  ) {
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
    if (_resolvedPaymentMode == PaymentSourceType.creditCard &&
        _sourceId != null) {
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
        return const [];
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
      if (_resolvedPaymentMode == PaymentSourceType.bank ||
          _resolvedPaymentMode == PaymentSourceType.upi) {
        return CashbackDestinationType.bank;
      }
      if (_resolvedPaymentMode == PaymentSourceType.creditCard) {
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
}
