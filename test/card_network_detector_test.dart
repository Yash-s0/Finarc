import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/features/cards/data/card_network_detector.dart';
import 'package:finarc/features/cards/data/cards_providers.dart';

void main() {
  group('detectCardNetwork', () {
    test('detects Visa from BIN starting with 4', () {
      expect(detectCardNetwork('411111'), CardNetwork.visa);
    });

    test('detects Mastercard from BIN 51-55 range', () {
      expect(detectCardNetwork('542523'), CardNetwork.mastercard);
    });

    test('detects Mastercard from BIN 2221-2720 range', () {
      expect(detectCardNetwork('222100'), CardNetwork.mastercard);
    });

    test('detects Mastercard at upper bound of 2221-2720', () {
      expect(detectCardNetwork('272000'), CardNetwork.mastercard);
    });

    test('detects Amex from BIN starting with 37', () {
      expect(detectCardNetwork('371449'), CardNetwork.amex);
    });

    test('detects Amex from BIN starting with 34', () {
      expect(detectCardNetwork('340000'), CardNetwork.amex);
    });

    test('detects RuPay from 508 range', () {
      expect(detectCardNetwork('508227'), CardNetwork.rupay);
    });

    test('detects RuPay from 607 range', () {
      expect(detectCardNetwork('607114'), CardNetwork.rupay);
    });

    test('detects RuPay from 652 range', () {
      expect(detectCardNetwork('652150'), CardNetwork.rupay);
    });

    test('detects RuPay from 81 range', () {
      expect(detectCardNetwork('817200'), CardNetwork.rupay);
    });

    test('detects RuPay from 353 range (JCB)', () {
      expect(detectCardNetwork('353800'), CardNetwork.rupay);
    });

    test('returns null for unknown BIN', () {
      expect(detectCardNetwork('123456'), isNull);
    });

    test('returns null for input shorter than 6 digits', () {
      expect(detectCardNetwork('4111'), isNull);
    });

    test('returns null for non-numeric input', () {
      expect(detectCardNetwork('abcdef'), isNull);
    });

    test('returns null for empty input', () {
      expect(detectCardNetwork(''), isNull);
    });

    test('handles 8-digit BIN correctly', () {
      expect(detectCardNetwork('41111111'), CardNetwork.visa);
    });

    test('handles whitespace-padded input', () {
      expect(detectCardNetwork('  411111  '), CardNetwork.visa);
    });
  });
}
