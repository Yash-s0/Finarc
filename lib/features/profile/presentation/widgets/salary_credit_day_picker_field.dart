import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/salary_credit_schedule.dart';

class SalaryCreditDayPickerField extends StatelessWidget {
  const SalaryCreditDayPickerField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
  });

  final SalaryCreditSchedule? value;
  final ValueChanged<SalaryCreditSchedule?> onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = value == null
        ? (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
        : Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
        ],
        Material(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceHigh,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            onTap: () => _showPicker(context),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value?.displayLabel ?? 'Select day (1 - 31)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: textColor),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showPicker(BuildContext context) async {
    final picked = await showModalBottomSheet<SalaryCreditSchedule?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _SalaryCreditDayPickerSheet(value: value),
    );
    if (picked != null) onChanged(picked);
  }
}

class _SalaryCreditDayPickerSheet extends StatelessWidget {
  const _SalaryCreditDayPickerSheet({required this.value});

  final SalaryCreditSchedule? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Salary credit day',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SemanticChoice(
            title: 'First day of month',
            selected: value?.rule == SalaryCreditRule.firstDayOfMonth,
            onTap: () => Navigator.of(
              context,
            ).pop(const SalaryCreditSchedule.firstDayOfMonth()),
          ),
          const SizedBox(height: AppSpacing.xs),
          _SemanticChoice(
            title: 'Last day of month',
            selected: value?.rule == SalaryCreditRule.lastDayOfMonth,
            onTap: () => Navigator.of(
              context,
            ).pop(const SalaryCreditSchedule.lastDayOfMonth()),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Choose a specific day',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 31,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: AppSpacing.xs,
              crossAxisSpacing: AppSpacing.xs,
              childAspectRatio: 1.12,
            ),
            itemBuilder: (context, index) {
              final day = index + 1;
              return _DayChoice(
                day: day,
                selected:
                    value?.rule == SalaryCreditRule.fixedDay &&
                    value?.fixedDay == day,
                onTap: () => Navigator.of(
                  context,
                ).pop(SalaryCreditSchedule.fixedDay(day)),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SemanticChoice extends StatelessWidget {
  const _SemanticChoice({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        alignment: Alignment.centerLeft,
      ),
      child: Row(
        children: [
          Expanded(child: Text(title)),
          if (selected) const Icon(Icons.check_rounded, size: 18),
        ],
      ),
    );
  }
}

class _DayChoice extends StatelessWidget {
  const _DayChoice({
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final int day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: selected
          ? Theme.of(context).colorScheme.primary
          : (isDark ? AppColors.darkSurfaceLow : AppColors.lightSurfaceHigh),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Center(
          child: Text(
            '$day',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected ? Colors.white : null,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
