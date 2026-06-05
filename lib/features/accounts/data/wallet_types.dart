import '../../../core/database/app_database.dart';

class WalletType {
  static const cash = 'cash';
  static const amazonPay = 'amazonPay';
  static const otherWallet = 'otherWallet';

  static String normalize(String? value) {
    switch ((value ?? '').trim()) {
      case amazonPay:
        return amazonPay;
      case otherWallet:
        return otherWallet;
      case cash:
      default:
        return cash;
    }
  }

  static String displayName(CashWallet wallet) {
    switch (normalize(wallet.walletType)) {
      case amazonPay:
        return 'Amazon Pay';
      default:
        return wallet.walletName;
    }
  }

  static String subtitle(CashWallet wallet) {
    switch (normalize(wallet.walletType)) {
      case amazonPay:
        return 'Amazon Pay wallet';
      case otherWallet:
        return 'Wallet';
      case cash:
      default:
        return 'Cash wallet';
    }
  }

  static String badge(CashWallet wallet) {
    switch (normalize(wallet.walletType)) {
      case amazonPay:
        return 'APAY';
      case otherWallet:
        return 'WALLET';
      case cash:
      default:
        return 'CASH';
    }
  }

  static bool matches(CashWallet wallet, String type) {
    return normalize(wallet.walletType) == normalize(type);
  }
}
