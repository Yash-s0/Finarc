import 'package:intl/intl.dart';

final _inrPattern = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 2,
);
final _timePattern = DateFormat('h:mm a');
final _dayMonthPattern = DateFormat('d MMM');
final _dayMonthYearPattern = DateFormat('d MMM yyyy');

String inr(num value) {
  return _inrPattern.format(value);
}

String moneyInput(num value) => value.toStringAsFixed(2);

String transactionDateLabel(
  DateTime date, {
  DateTime? now,
  bool includeTimeForToday = true,
}) {
  final current = now ?? DateTime.now();
  final d = DateTime(date.year, date.month, date.day);
  final today = DateTime(current.year, current.month, current.day);
  if (d == today) {
    if (!includeTimeForToday) return 'Today';
    return 'Today, ${_timePattern.format(date.toLocal())}';
  }
  final yesterday = today.subtract(const Duration(days: 1));
  if (d == yesterday) return 'Yesterday';
  if (date.year == current.year) {
    return _dayMonthPattern.format(date.toLocal());
  }
  return _dayMonthYearPattern.format(date.toLocal());
}

String transactionMetaLabel(
  DateTime date, {
  String? sourceLabel,
  DateTime? now,
}) {
  final dateLabel = transactionDateLabel(date, now: now);
  final source = sourceLabel?.trim();
  if (source == null || source.isEmpty) return dateLabel;
  return '$dateLabel • $source';
}
