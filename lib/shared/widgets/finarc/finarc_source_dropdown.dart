import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

class FinarcSourceDropdownOption<T> {
  const FinarcSourceDropdownOption({required this.value, required this.label});

  final T value;
  final String label;
}

class FinarcSourceDropdown<T> extends StatelessWidget {
  const FinarcSourceDropdown({
    super.key,
    required this.label,
    required this.placeholder,
    required this.options,
    required this.value,
    required this.onChanged,
    this.validator,
    this.enabled = true,
    this.icon = Icons.account_balance_wallet_outlined,
    this.emptyText = 'No sources available',
  });

  final String label;
  final String placeholder;
  final List<FinarcSourceDropdownOption<T>> options;
  final T? value;
  final ValueChanged<T?> onChanged;
  final FormFieldValidator<T>? validator;
  final bool enabled;
  final IconData icon;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      initialValue: value,
      validator: validator,
      builder: (field) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final selectedValue = options.any((option) => option.value == value)
            ? value
            : null;
        final displayText = selectedValue == null
            ? placeholder
            : options
                  .firstWhere((option) => option.value == selectedValue)
                  .label;
        final menuBackground = isDark
            ? AppColors.darkSurfaceHigh
            : AppColors.lightSurface;
        final borderColor = isDark
            ? AppColors.darkBorder
            : AppColors.lightBorder;
        final menuTextStyle = theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        );
        final placeholderStyle = menuTextStyle?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.hasBoundedWidth
                ? constraints.maxWidth
                : null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownMenu<T?>(
                  key: key,
                  enabled: enabled && options.isNotEmpty,
                  initialSelection: selectedValue,
                  width: width,
                  expandedInsets: EdgeInsets.zero,
                  requestFocusOnTap: false,
                  menuHeight: 360,
                  leadingIcon: Icon(
                    icon,
                    color: isDark
                        ? AppColors.darkAccent
                        : AppColors.lightAccent,
                  ),
                  label: Text(label),
                  hintText: options.isEmpty ? emptyText : displayText,
                  menuStyle: MenuStyle(
                    backgroundColor: WidgetStatePropertyAll(menuBackground),
                    surfaceTintColor: const WidgetStatePropertyAll(
                      Colors.transparent,
                    ),
                    elevation: const WidgetStatePropertyAll(8),
                    shadowColor: WidgetStatePropertyAll(
                      Colors.black.withValues(alpha: isDark ? 0.32 : 0.12),
                    ),
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    ),
                    side: WidgetStatePropertyAll(
                      BorderSide(color: borderColor),
                    ),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                    ),
                  ),
                  dropdownMenuEntries: [
                    DropdownMenuEntry<T?>(
                      value: null,
                      label: placeholder,
                      style: ButtonStyle(
                        textStyle: WidgetStatePropertyAll(placeholderStyle),
                        foregroundColor: WidgetStatePropertyAll(
                          theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        padding: const WidgetStatePropertyAll(
                          EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                        ),
                        overlayColor: WidgetStatePropertyAll(
                          theme.colorScheme.onSurface.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    ...options.map(
                      (option) => DropdownMenuEntry<T?>(
                        value: option.value,
                        label: option.label,
                        style: ButtonStyle(
                          textStyle: WidgetStatePropertyAll(menuTextStyle),
                          padding: const WidgetStatePropertyAll(
                            EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                          ),
                          overlayColor: WidgetStatePropertyAll(
                            theme.colorScheme.onSurface.withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                    ),
                  ],
                  onSelected: enabled
                      ? (selected) {
                          field.didChange(selected);
                          onChanged(selected);
                        }
                      : null,
                ),
                if (field.hasError) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      field.errorText!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}
