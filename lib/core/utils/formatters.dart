import 'package:intl/intl.dart';

final _inrPattern = NumberFormat.decimalPattern('en_IN');
final _timePattern = DateFormat('h:mm a');
final _dayMonthPattern = DateFormat('d MMM');
final _dayMonthYearPattern = DateFormat('d MMM yyyy');

String inr(num value) {
  final sign = value < 0 ? '-' : '';
  final abs = value.abs();
  return '$sign₹${_inrPattern.format(abs)}';
}

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
