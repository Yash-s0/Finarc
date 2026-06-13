import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';

class FinarcTextField extends StatefulWidget {
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
    this.focusNode,
    this.nextFocusNode,
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
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;

  @override
  State<FinarcTextField> createState() => _FinarcTextFieldState();
}

class _FinarcTextFieldState extends State<FinarcTextField> {
  FocusNode? _ownedFocusNode;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownedFocusNode ??= FocusNode());

  @override
  void dispose() {
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  TextInputAction? _resolvedTextInputAction() {
    if (widget.textInputAction != null) return widget.textInputAction;
    if (widget.readOnly) return null;
    if (widget.maxLines == 1) return TextInputAction.next;
    return TextInputAction.newline;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedTextInputAction = _resolvedTextInputAction();
    return AnimatedBuilder(
      animation: _focusNode,
      builder: (context, _) {
        final focused = _focusNode.hasFocus;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: focused
                ? [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(
                        alpha: isDark ? 0.18 : 0.10,
                      ),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            readOnly: widget.readOnly,
            keyboardType: widget.keyboardType,
            textInputAction: resolvedTextInputAction,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            validator: widget.validator,
            onTap: widget.onTap,
            onChanged: widget.onChanged,
            onEditingComplete: () {
              if (widget.nextFocusNode != null) {
                FocusScope.of(context).requestFocus(widget.nextFocusNode);
                return;
              }
              if (resolvedTextInputAction == TextInputAction.done) {
                FocusScope.of(context).unfocus();
              }
            },
            inputFormatters: widget.inputFormatters,
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              suffixIcon: widget.suffixIcon,
              prefixIcon: widget.prefixIcon,
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              prefixIconColor: focused
                  ? Theme.of(context).colorScheme.primary
                  : (isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted),
              suffixIconColor: focused
                  ? Theme.of(context).colorScheme.primary
                  : (isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted),
            ),
          ),
        );
      },
    );
  }
}
