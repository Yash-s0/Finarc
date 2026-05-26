import 'package:flutter/services.dart';

class StripLeadingZeroFormatter extends TextInputFormatter {
  StripLeadingZeroFormatter({this.allowDecimal = true});

  final bool allowDecimal;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    if (!allowDecimal) {
      final trimmed = text.replaceFirst(RegExp(r'^0+(?=\d)'), '');
      final safe = trimmed.isEmpty ? '0' : trimmed;
      return newValue.copyWith(
        text: safe,
        selection: TextSelection.collapsed(offset: safe.length),
      );
    }

    if (text.startsWith('0') && text.length > 1 && !text.startsWith('0.')) {
      final trimmed = text.replaceFirst(RegExp(r'^0+(?=\d)'), '');
      final safe = trimmed.isEmpty ? '0' : trimmed;
      return newValue.copyWith(
        text: safe,
        selection: TextSelection.collapsed(offset: safe.length),
      );
    }

    return newValue;
  }
}
