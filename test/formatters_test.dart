import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/utils/formatters.dart';

void main() {
  test('inr preserves paise and formats with two decimals', () {
    expect(inr(7736.04), '₹7,736.04');
    expect(inr(8384.59), '₹8,384.59');
    expect(inr(29542.02), '₹29,542.02');
    expect(inr(17435.5), '₹17,435.50');
    expect(inr(187), '₹187.00');
  });

  test('moneyInput preserves two-decimal editing values', () {
    expect(moneyInput(8384.59), '8384.59');
    expect(moneyInput(2000), '2000.00');
  });
}
