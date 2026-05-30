import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/utils/formatters.dart';

void main() {
  test('transactionDateLabel formats today with time', () {
    final now = DateTime(2026, 5, 28, 20, 0);
    final date = DateTime(2026, 5, 28, 19, 42);

    final label = transactionDateLabel(date, now: now);

    expect(label, 'Today, 7:42 PM');
  });

  test('transactionDateLabel formats yesterday and older dates', () {
    final now = DateTime(2026, 5, 28, 10, 0);

    expect(
      transactionDateLabel(DateTime(2026, 5, 27, 9, 10), now: now),
      'Yesterday',
    );
    expect(
      transactionDateLabel(DateTime(2026, 5, 24, 15, 0), now: now),
      '24 May',
    );
    expect(
      transactionDateLabel(DateTime(2025, 5, 24, 15, 0), now: now),
      '24 May 2025',
    );
  });

  test('transactionMetaLabel combines date and source consistently', () {
    final now = DateTime(2026, 5, 28, 20, 0);
    final date = DateTime(2026, 5, 28, 19, 42);

    expect(
      transactionMetaLabel(date, sourceLabel: 'Card', now: now),
      'Today, 7:42 PM • Card',
    );
    expect(
      transactionMetaLabel(
        DateTime(2026, 5, 27, 9, 10),
        sourceLabel: 'Bank',
        now: now,
      ),
      'Yesterday • Bank',
    );
    expect(transactionMetaLabel(date, now: now), 'Today, 7:42 PM');
  });
}
