import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/features/pending/notifications/notification_provider_catalog.dart';

void main() {
  test('allowlist includes required finance providers', () {
    expect(
      NotificationProviderCatalog.providerForPackage(
        'com.google.android.apps.nbu.paisa.user',
      )?.providerName,
      'Google Pay',
    );
    expect(
      NotificationProviderCatalog.providerForPackage(
        'com.google.android.apps.nbu.paisa.user',
      )?.category,
      NotificationSourceCategory.upiPaymentApp,
    );
    expect(
      NotificationProviderCatalog.providerForPackage(
        'com.phonepe.app',
      )?.providerName,
      'PhonePe',
    );
    expect(
      NotificationProviderCatalog.providerForPackage(
        'net.one97.paytm',
      )?.providerName,
      'Paytm',
    );
    expect(
      NotificationProviderCatalog.providerForPackage(
        'com.dreamplug.androidapp',
      )?.providerName,
      'CRED',
    );
    expect(
      NotificationProviderCatalog.providerForPackage(
        'com.snapwork.hdfc',
      )?.providerName,
      'HDFC Bank',
    );
    expect(
      NotificationProviderCatalog.providerForPackage(
        'com.csam.icici.bank.imobile',
      )?.providerName,
      'ICICI Bank',
    );
    expect(
      NotificationProviderCatalog.providerForPackage(
        'com.sbi.lotusintouch',
      )?.providerName,
      'SBI',
    );
    expect(
      NotificationProviderCatalog.providerForPackage(
        'com.axis.mobile',
      )?.providerName,
      'Axis Bank',
    );
    expect(
      NotificationProviderCatalog.providerForPackage(
        'com.msf.indusmob',
      )?.providerName,
      'IndusInd Bank',
    );
    expect(
      NotificationProviderCatalog.providerForPackage(
        'com.msf.kbank.mobile',
      )?.providerName,
      'Kotak',
    );
  });

  test('unknown package is rejected', () {
    expect(
      NotificationProviderCatalog.isAllowedPackage('com.whatsapp'),
      isFalse,
    );
  });

  test('blocked chat and social packages are hard blocked', () {
    expect(
      NotificationProviderCatalog.isBlockedPackage('com.whatsapp'),
      isTrue,
    );
    expect(
      NotificationProviderCatalog.isBlockedPackage('org.telegram.messenger'),
      isTrue,
    );
    expect(
      NotificationProviderCatalog.isBlockedPackage('com.google.android.gm'),
      isTrue,
    );
  });

  test('payment and wallet providers are optional sources', () {
    expect(
      NotificationProviderCatalog.isOptionalPackage('com.phonepe.app'),
      isTrue,
    );
    expect(
      NotificationProviderCatalog.isOptionalPackage(
        'com.amazon.mshop.android.shopping',
      ),
      isTrue,
    );
    expect(
      NotificationProviderCatalog.isOptionalPackage('com.dreamplug.androidapp'),
      isTrue,
    );
    expect(
      NotificationProviderCatalog.isOptionalPackage('com.snapwork.hdfc'),
      isFalse,
    );
  });
}
