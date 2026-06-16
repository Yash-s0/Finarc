import 'dart:io';

import 'lib/features/cards/data/card_network_detector.dart';

void main() {
  final realWorldRuPayBins = {
    '508227': 'SBI RuPay Classic',
    '508125': 'PNB RuPay',
    '607094': 'SBI RuPay Platinum',
    '607114': 'BOB RuPay',
    '607384': 'HDFC RuPay',
    '607027': 'PNB RuPay',
    '608117': 'Kotak RuPay',
    '652820': 'SBI RuPay',
    '353800': 'RuPay JCB co-badge',
    '356000': 'RuPay JCB co-badge',
    '508500': 'in-range control',
    '652150': 'in-range control',
    '817200': 'in-range control',
    '607985': 'gap between ranges',
    '608000': 'gap between ranges',
    '508100': 'below 508500 range',
    '508499': 'just below 508500',
    '606900': 'below 606985',
  };

  for (final entry in realWorldRuPayBins.entries) {
    final result = detectCardNetwork(entry.key);
    final status = result == 'rupay' ? 'OK' : 'FAIL got ${result ?? "null"}';
    stdout.writeln('${entry.key} (${entry.value}): $status');
  }
}
