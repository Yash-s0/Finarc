import '../../accounts/data/wallet_types.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/finarc/finarc_payment_selector.dart';
import '../data/expenses_providers.dart';
import '../models/transaction_types.dart';

class PaymentSourceSelectionConfig {
  const PaymentSourceSelectionConfig({
    required this.options,
    required this.fieldLabel,
    this.emptyMessage,
    this.emptyCtaLabel,
    this.emptyCtaRoute,
    this.singlePrefix = 'Using',
  });

  final List<FinarcPaymentSourceOption> options;
  final String fieldLabel;
  final String? emptyMessage;
  final String? emptyCtaLabel;
  final String? emptyCtaRoute;
  final String singlePrefix;
}

PaymentSourceSelectionConfig sourceConfigForMode(
  PaymentSourcesData sources,
  String mode, {
  bool destination = false,
}) {
  if (mode == PaymentSourceType.cash) {
    return PaymentSourceSelectionConfig(
      options: sources.cashWallets
          .map(
            (w) => FinarcPaymentSourceOption(
              id: w.id,
              label: WalletType.displayName(w),
            ),
          )
          .toList(growable: false),
      fieldLabel: destination ? 'Destination cash source' : 'Cash source',
      emptyMessage: 'No wallet found. Add one from Accounts.',
      emptyCtaLabel: 'Add wallet',
      emptyCtaRoute: '/accounts/add?type=cash',
      singlePrefix: destination ? 'Receiving into' : 'Using cash source',
    );
  }

  if (mode == PaymentSourceType.creditCard) {
    return PaymentSourceSelectionConfig(
      options: sources.cards
          .map(
            (c) => FinarcPaymentSourceOption(
              id: c.id,
              label: '${c.bankName} • ${c.last4}',
            ),
          )
          .toList(growable: false),
      fieldLabel: destination ? 'Destination card' : 'Card',
      emptyMessage: 'No card found. Add one from Cards.',
      emptyCtaLabel: 'Add card',
      emptyCtaRoute: '/cards/add',
      singlePrefix: destination ? 'Receiving into' : 'Using card',
    );
  }

  final isUpi = mode == PaymentSourceType.upi;
  return PaymentSourceSelectionConfig(
    options: sources.banks
        .map(
          (b) => FinarcPaymentSourceOption(
            id: b.id,
            label: '${b.accountName} • ${inr(b.currentBalance)}',
          ),
        )
        .toList(growable: false),
    fieldLabel: destination
        ? 'Destination account'
        : (isUpi ? 'UPI-linked account' : 'Bank account'),
    emptyMessage: isUpi
        ? 'No UPI/bank account found. Add bank account first.'
        : 'No bank account found. Add one from Accounts.',
    emptyCtaLabel: 'Add bank account',
    emptyCtaRoute: '/accounts/add?type=bank',
    singlePrefix: destination ? 'Receiving into' : 'Using account',
  );
}

int? resolveAutoSelectedSourceId(
  int? currentId,
  List<FinarcPaymentSourceOption> options,
) {
  if (options.isEmpty) return null;
  if (options.length == 1) return options.first.id;
  final exists = options.any((o) => o.id == currentId);
  return exists ? currentId : null;
}
