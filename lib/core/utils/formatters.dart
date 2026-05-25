import 'package:intl/intl.dart';

final _inrPattern = NumberFormat.decimalPattern('en_IN');

String inr(num value) {
  final sign = value < 0 ? '-' : '';
  final abs = value.abs();
  return '$sign₹${_inrPattern.format(abs)}';
}
