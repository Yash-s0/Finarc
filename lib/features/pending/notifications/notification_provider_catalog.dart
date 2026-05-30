class NotificationProviderInfo {
  const NotificationProviderInfo({
    required this.providerId,
    required this.providerName,
  });

  final String providerId;
  final String providerName;
}

class NotificationProviderCatalog {
  static const Map<String, NotificationProviderInfo> _packageMap = {
    'com.google.android.apps.nbu.paisa.user': NotificationProviderInfo(
      providerId: 'google_pay',
      providerName: 'Google Pay',
    ),
    'com.phonepe.app': NotificationProviderInfo(
      providerId: 'phonepe',
      providerName: 'PhonePe',
    ),
    'net.one97.paytm': NotificationProviderInfo(
      providerId: 'paytm',
      providerName: 'Paytm',
    ),
    'in.org.npci.upiapp': NotificationProviderInfo(
      providerId: 'bhim',
      providerName: 'BHIM',
    ),
    'com.bhim.upi': NotificationProviderInfo(
      providerId: 'bhim',
      providerName: 'BHIM',
    ),
    'com.dreamplug.androidapp': NotificationProviderInfo(
      providerId: 'cred',
      providerName: 'CRED',
    ),
    'in.amazon.mshop.android.shopping': NotificationProviderInfo(
      providerId: 'amazon_pay',
      providerName: 'Amazon Pay',
    ),
    'com.amazon.mshop.android.shopping': NotificationProviderInfo(
      providerId: 'amazon_pay',
      providerName: 'Amazon Pay',
    ),
    'com.snapwork.hdfc': NotificationProviderInfo(
      providerId: 'hdfc',
      providerName: 'HDFC Bank',
    ),
    'com.csam.icici.bank.imobile': NotificationProviderInfo(
      providerId: 'icici',
      providerName: 'ICICI Bank',
    ),
    'com.sbi.lotusintouch': NotificationProviderInfo(
      providerId: 'sbi',
      providerName: 'SBI',
    ),
    'com.axis.mobile': NotificationProviderInfo(
      providerId: 'axis',
      providerName: 'Axis Bank',
    ),
    'com.msf.indusmob': NotificationProviderInfo(
      providerId: 'indusind',
      providerName: 'IndusInd Bank',
    ),
    'com.msf.kbank.mobile': NotificationProviderInfo(
      providerId: 'kotak',
      providerName: 'Kotak',
    ),
  };

  static NotificationProviderInfo? providerForPackage(String packageName) {
    return _packageMap[packageName.toLowerCase().trim()];
  }

  static bool isAllowedPackage(String packageName) {
    return providerForPackage(packageName) != null;
  }
}
