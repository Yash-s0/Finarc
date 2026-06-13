import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

class FinarcPrimaryButton extends StatefulWidget {
  const FinarcPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final bool isLoading;

  @override
  State<FinarcPrimaryButton> createState() => _FinarcPrimaryButtonState();
}

class _FinarcPrimaryButtonState extends State<FinarcPrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    final child = widget.isLoading
        ? const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          )
        : widget.icon == null
        ? Text(widget.label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Text(widget.label),
            ],
          );

    final button = AnimatedScale(
      scale: _pressed && !isDisabled ? 0.985 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Listener(
        onPointerDown: isDisabled
            ? null
            : (_) => setState(() => _pressed = true),
        onPointerUp: isDisabled
            ? null
            : (_) => setState(() => _pressed = false),
        onPointerCancel: isDisabled
            ? null
            : (_) => setState(() => _pressed = false),
        child: FilledButton(
          onPressed: isDisabled ? null : widget.onPressed,
          style: FilledButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: Theme.of(context).brightness == Brightness.dark
                    ? const [AppColors.darkPrimary, AppColors.darkAccent]
                    : const [AppColors.lightPrimary, AppColors.lightAccent],
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: AnimatedOpacity(
              opacity: isDisabled ? 0.55 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                alignment: Alignment.center,
                constraints: const BoxConstraints(minHeight: 46),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: FittedBox(fit: BoxFit.scaleDown, child: child),
              ),
            ),
          ),
        ),
      ),
    );

    if (!widget.expand) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
