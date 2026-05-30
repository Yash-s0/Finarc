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
}
