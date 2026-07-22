import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'finarc_primary_button.dart';
import 'finarc_section_header.dart';
import 'finarc_source_dropdown.dart';

class FinarcPaymentModeOption {
  const FinarcPaymentModeOption({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;
}

class FinarcPaymentSourceOption {
  const FinarcPaymentSourceOption({required this.id, required this.label});

  final int id;
  final String label;
}

class FinarcPaymentSourceEmptyState {
  const FinarcPaymentSourceEmptyState({
    required this.message,
    required this.ctaLabel,
    required this.onTap,
  });

  final String message;
  final String ctaLabel;
  final VoidCallback onTap;
}

class FinarcPaymentSelector extends StatelessWidget {
  const FinarcPaymentSelector({
    super.key,
    required this.title,
    required this.selectedMode,
    required this.modes,
    required this.onModeChanged,
    required this.sources,
    required this.selectedSourceId,
    required this.onSourceChanged,
    this.sourceLabel = 'Source',
    this.singleSourcePrefix = 'Using',
    this.emptyState,
    this.sourceValidator,
    this.enabled = true,
    this.compactModeTiles = false,
    this.useSourceCardPicker = false,
    this.modeTestPrefix = 'payment-mode',
  });

  final String title;
  final String selectedMode;
  final List<FinarcPaymentModeOption> modes;
  final ValueChanged<String> onModeChanged;
  final List<FinarcPaymentSourceOption> sources;
  final int? selectedSourceId;
  final ValueChanged<int?> onSourceChanged;
  final String sourceLabel;
  final String singleSourcePrefix;
  final FinarcPaymentSourceEmptyState? emptyState;
  final FormFieldValidator<int>? sourceValidator;
  final bool enabled;
  final bool compactModeTiles;
  final bool useSourceCardPicker;
  final String modeTestPrefix;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FinarcSectionHeader(title: title),
        const SizedBox(height: AppSpacing.xs),
        compactModeTiles
            ? _buildCompactModeGrid(context)
            : Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: modes
                    .map((mode) => _buildModePill(context, mode))
                    .toList(growable: false),
              ),
        const SizedBox(height: AppSpacing.sm),
        if (emptyState != null) ...[
          Text(
            emptyState!.message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.darkWarning : AppColors.lightWarning,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          FinarcPrimaryButton(
            onPressed: emptyState!.onTap,
            icon: Icons.add_circle_outline_rounded,
            label: emptyState!.ctaLabel,
          ),
        ] else if (sources.length == 1) ...[
          useSourceCardPicker
              ? _buildSingleSourceCard(context, sources.first)
              : Text(
                  '$singleSourcePrefix: ${sources.first.label}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
        ] else if (sources.length > 1) ...[
          if (useSourceCardPicker)
            _buildSourcePickerCard(context)
          else
            DropdownButtonFormField<int>(
              initialValue: selectedSourceId,
              decoration: InputDecoration(labelText: sourceLabel),
              items: sources
                  .map(
                    (item) => DropdownMenuItem<int>(
                      value: item.id,
                      child: Text(item.label),
                    ),
                  )
                  .toList(growable: false),
              onChanged: enabled ? onSourceChanged : null,
              validator: sourceValidator,
            ),
        ],
      ],
    );
  }

  Widget _buildCompactModeGrid(BuildContext context) {
    const spacing = AppSpacing.xs;
    return LayoutBuilder(
      builder: (context, constraints) {
        final perRow = modes.length <= 4 ? modes.length : 4;
        if (perRow <= 0) return const SizedBox.shrink();
        final width = (constraints.maxWidth - spacing * (perRow - 1)) / perRow;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: modes
              .map(
                (mode) => SizedBox(
                  width: width,
                  child: _buildModeSquare(context, mode),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }

  Widget _buildModePill(BuildContext context, FinarcPaymentModeOption mode) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = selectedMode == mode.value;
    return InkWell(
      onTap: enabled ? () => onModeChanged(mode.value) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? AppColors.darkPrimarySoft
                    : AppColors.lightPrimarySoft)
              : (isDark
                    ? AppColors.darkSurfaceLow
                    : AppColors.lightSurfaceHigh),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.darkAccent : AppColors.lightAccent)
                      .withValues(alpha: 0.8)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              mode.icon,
              size: 14,
              color: isSelected
                  ? (isDark ? AppColors.darkAccent : AppColors.lightAccent)
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.75),
            ),
            const SizedBox(width: 6),
            Text(mode.label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSquare(BuildContext context, FinarcPaymentModeOption mode) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = selectedMode == mode.value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('$modeTestPrefix-${mode.value}'),
        onTap: enabled ? () => onModeChanged(mode.value) : null,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 72,
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                : (isDark
                      ? AppColors.darkSurfaceLow
                      : AppColors.lightSurfaceHigh),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? (isDark ? AppColors.darkAccent : AppColors.lightAccent)
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                mode.icon,
                size: 18,
                color: isSelected
                    ? Colors.white
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.75),
              ),
              const SizedBox(height: 4),
              Text(
                mode.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isSelected ? Colors.white : null,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleSourceCard(
    BuildContext context,
    FinarcPaymentSourceOption source,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceLow : AppColors.lightSurfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$singleSourcePrefix: ${source.label}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourcePickerCard(BuildContext context) {
    return FinarcSourceDropdown<int>(
      key: ValueKey('source-picker-$selectedMode'),
      label: sourceLabel,
      placeholder: 'Select $sourceLabel',
      value: selectedSourceId,
      enabled: enabled,
      options: sources
          .map(
            (source) => FinarcSourceDropdownOption<int>(
              value: source.id,
              label: source.label,
            ),
          )
          .toList(growable: false),
      onChanged: onSourceChanged,
      validator: sourceValidator,
    );
  }
}
