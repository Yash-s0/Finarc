import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';

class ForOthersScreen extends StatefulWidget {
  const ForOthersScreen({super.key});

  @override
  State<ForOthersScreen> createState() => _ForOthersScreenState();
}

class _ForOthersScreenState extends State<ForOthersScreen> {
  final _name = TextEditingController();
  final _total = TextEditingController();
  final _myShare = TextEditingController();
  final _recoverable = TextEditingController();
  final _notes = TextEditingController();
  bool _recoverableToggle = true;

  @override
  void dispose() {
    _name.dispose();
    _total.dispose();
    _myShare.dispose();
    _recoverable.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = double.tryParse(_total.text) ?? 0;
    final myShare = double.tryParse(_myShare.text) ?? 0;
    final recoverable = _recoverableToggle
        ? (double.tryParse(_recoverable.text) ??
              (total - myShare).clamp(0, total))
        : 0;

    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'For Others'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          FinarcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FinarcSectionHeader(title: 'People & Split'),
                const SizedBox(height: AppSpacing.sm),
                FinarcTextField(
                  controller: _name,
                  label: 'Person/Contact Name',
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['Rahul', 'Neha', 'Aman', 'Roommate']
                      .map(
                        (p) => FinarcActionChip(
                          label: p,
                          selected:
                              _name.text.trim().toLowerCase() ==
                              p.toLowerCase(),
                          onTap: () => setState(() => _name.text = p),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.sm),
                FinarcTextField(
                  controller: _total,
                  label: 'Total paid',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onTap: () => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.sm),
                FinarcTextField(
                  controller: _myShare,
                  label: 'My share',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onTap: () => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.xs),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _recoverableToggle,
                  onChanged: (v) => setState(() => _recoverableToggle = v),
                  title: const Text('Recoverable'),
                ),
                if (_recoverableToggle)
                  FinarcTextField(
                    controller: _recoverable,
                    label: 'Recoverable amount',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onTap: () => setState(() {}),
                  ),
                const SizedBox(height: AppSpacing.sm),
                FinarcTextField(
                  controller: _notes,
                  label: 'Notes',
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FinarcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FinarcSectionHeader(title: 'Summary'),
                const SizedBox(height: AppSpacing.sm),
                _summaryLine(context, 'Total Paid', inr(total)),
                _summaryLine(context, 'My Expense', inr(myShare)),
                _summaryLine(context, 'Recoverable Amount', inr(recoverable)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FinarcPrimaryButton(
            onPressed: () => Navigator.pop(context),
            label: 'Save',
            icon: Icons.check_circle_outline,
          ),
        ],
      ),
    );
  }

  Widget _summaryLine(BuildContext context, String label, String amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          Text(amount, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}
