enum NotificationSourceCategory {
  bankCardIssuer,
  upiPaymentApp,
  walletApp,
  cardBillPaymentApp,
}

class NotificationProviderInfo {
  const NotificationProviderInfo({
    required this.providerId,
    required this.providerName,
    required this.category,
  });

  final String providerId;
  final String providerName;
  final NotificationSourceCategory category;
}

class NotificationProviderCatalog {
  static const List<String> _bankingHints = [
    'bank',
    'kotak',
    'kotak811',
    'hdfc',
    'icici',
    'sbi',
    'axis',
    'indusind',
    'yesbank',
    'federal',
    'canara',
    'pnb',
    'idfc',
    'idbi',
    'hsbc',
    'rbl',
    'dbs',
    'citi',
    'citibank',
    'bob',
    'bankofbaroda',
    'unionbank',
    'iob',
    'boi',
    'bandhan',
    'ujjivan',
    'au bank',
    'aubank',
  ];

  static const Set<String> _messagingPackages = {
    'com.google.android.apps.messaging',
    'com.android.mms',
    'com.samsung.android.messaging',
    'com.miui.smsextra',
    'com.coloros.mms',
    'com.oneplus.mms',
    'com.vivo.messaging',
    'com.huawei.message',
  };

  static const Set<String> _blockedPackages = {
    'com.whatsapp',
    'com.whatsapp.w4b',
    'com.snapchat.android',
    'org.telegram.messenger',
    'org.thunderdog.challegram',
    'com.instagram.android',
    'com.facebook.katana',
    'com.facebook.orca',
    'com.google.android.gm',
    'com.microsoft.office.outlook',
    'com.samsung.android.email.provider',
    ..._messagingPackages,
  };

  static const Map<String, NotificationProviderInfo> _packageMap = {
    'com.google.android.apps.nbu.paisa.user': NotificationProviderInfo(
      providerId: 'google_pay',
      providerName: 'Google Pay',
      category: NotificationSourceCategory.upiPaymentApp,
    ),
    'com.phonepe.app': NotificationProviderInfo(
      providerId: 'phonepe',
      providerName: 'PhonePe',
      category: NotificationSourceCategory.upiPaymentApp,
    ),
    'net.one97.paytm': NotificationProviderInfo(
      providerId: 'paytm',
      providerName: 'Paytm',
      category: NotificationSourceCategory.upiPaymentApp,
    ),
    'in.org.npci.upiapp': NotificationProviderInfo(
      providerId: 'bhim',
      providerName: 'BHIM',
      category: NotificationSourceCategory.upiPaymentApp,
    ),
    'com.bhim.upi': NotificationProviderInfo(
      providerId: 'bhim',
      providerName: 'BHIM',
      category: NotificationSourceCategory.upiPaymentApp,
    ),
    'com.dreamplug.androidapp': NotificationProviderInfo(
      providerId: 'cred',
      providerName: 'CRED',
      category: NotificationSourceCategory.cardBillPaymentApp,
    ),
    'in.amazon.mshop.android.shopping': NotificationProviderInfo(
      providerId: 'amazon_pay',
      providerName: 'Amazon Pay',
      category: NotificationSourceCategory.walletApp,
    ),
    'com.amazon.mshop.android.shopping': NotificationProviderInfo(
      providerId: 'amazon_pay',
      providerName: 'Amazon Pay',
      category: NotificationSourceCategory.walletApp,
    ),
    'com.snapwork.hdfc': NotificationProviderInfo(
      providerId: 'hdfc',
      providerName: 'HDFC Bank',
      category: NotificationSourceCategory.bankCardIssuer,
    ),
    'com.csam.icici.bank.imobile': NotificationProviderInfo(
      providerId: 'icici',
      providerName: 'ICICI Bank',
      category: NotificationSourceCategory.bankCardIssuer,
    ),
    'com.sbi.lotusintouch': NotificationProviderInfo(
      providerId: 'sbi',
      providerName: 'SBI',
      category: NotificationSourceCategory.bankCardIssuer,
    ),
    'com.axis.mobile': NotificationProviderInfo(
      providerId: 'axis',
      providerName: 'Axis Bank',
      category: NotificationSourceCategory.bankCardIssuer,
    ),
    'com.msf.indusmob': NotificationProviderInfo(
      providerId: 'indusind',
      providerName: 'IndusInd Bank',
      category: NotificationSourceCategory.bankCardIssuer,
    ),
    'com.msf.kbank.mobile': NotificationProviderInfo(
      providerId: 'kotak',
      providerName: 'Kotak',
      category: NotificationSourceCategory.bankCardIssuer,
    ),
  };

  static NotificationProviderInfo? providerForPackage(String packageName) {
    return _packageMap[packageName.toLowerCase().trim()];
  }

  static bool isAllowedPackage(String packageName) {
    return providerForPackage(packageName) != null;
  }

  static bool isBlockedPackage(String packageName) {
    return _blockedPackages.contains(packageName.toLowerCase().trim());
  }

  static bool isMessagingPackage(String packageName) {
    return _messagingPackages.contains(packageName.toLowerCase().trim());
  }

  static bool isLikelyBankingApp({
    required String packageName,
    String? appName,
  }) {
    final normalizedPackage = packageName.toLowerCase().trim();
    final normalizedApp = (appName ?? '').toLowerCase().trim();
    return _bankingHints.any(
      (hint) =>
          normalizedPackage.contains(hint) || normalizedApp.contains(hint),
    );
  }

  static bool isOptionalPackage(String packageName) {
    final provider = providerForPackage(packageName);
    if (provider == null) {
      return false;
    }
    return provider.category == NotificationSourceCategory.upiPaymentApp ||
        provider.category == NotificationSourceCategory.walletApp ||
        provider.category == NotificationSourceCategory.cardBillPaymentApp;
  }
}
