import 'transaction_types.dart';

class CashbackDestinationType {
  static const unknown = 'unknown';
  static const bank = 'bank';
  static const cash = 'cash';
  static const amazonPay = 'amazonPay';
  static const otherWallet = 'otherWallet';
  static const creditCard = 'creditCard';

  static bool requiresDestinationId(String? type) {
    switch (normalize(type)) {
      case bank:
      case cash:
      case amazonPay:
      case otherWallet:
      case creditCard:
        return true;
      case unknown:
      default:
        return false;
    }
  }

  static bool appliesBalanceMutation(String? type) {
    switch (normalize(type)) {
      case bank:
      case cash:
      case amazonPay:
      case otherWallet:
        return true;
      case creditCard:
      case unknown:
      default:
        return false;
    }
  }

  static String? toPaymentSourceType(String? type) {
    switch (normalize(type)) {
      case bank:
        return PaymentSourceType.bank;
      case cash:
      case amazonPay:
      case otherWallet:
        return PaymentSourceType.cash;
      case creditCard:
        return PaymentSourceType.creditCard;
      case unknown:
      default:
        return null;
    }
  }

  static String normalize(String? type) {
    switch ((type ?? '').trim()) {
      case bank:
        return bank;
      case cash:
        return cash;
      case amazonPay:
        return amazonPay;
      case otherWallet:
        return otherWallet;
      case creditCard:
        return creditCard;
      case unknown:
      default:
        return unknown;
    }
  }
}
