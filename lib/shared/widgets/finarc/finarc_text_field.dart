import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FinarcTextField extends StatelessWidget {
  const FinarcTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.readOnly = false,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.validator,
    this.onTap,
    this.onChanged,
    this.suffixIcon,
    this.prefixIcon,
    this.inputFormatters,
    this.textInputAction,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final bool readOnly;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;

  TextInputAction? _resolvedTextInputAction() {
    if (textInputAction != null) return textInputAction;
    if (readOnly) return null;
    if (maxLines == 1) return TextInputAction.next;
    return TextInputAction.newline;
  }

  @override
  Widget build(BuildContext context) {
    final resolvedTextInputAction = _resolvedTextInputAction();

    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textInputAction: resolvedTextInputAction,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
      onTap: onTap,
      onChanged: onChanged,
      onFieldSubmitted: (_) {
        if (resolvedTextInputAction == TextInputAction.next) {
          FocusScope.of(context).nextFocus();
          return;
        }
        if (resolvedTextInputAction == TextInputAction.done) {
          FocusScope.of(context).unfocus();
        }
      },
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
      ),
    );
  }
}
