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
  final _cashback = TextEditingController(text: '0');
  final _notes = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _total.dispose();
    _cashback.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = double.tryParse(_total.text) ?? 0;
    final cashback = double.tryParse(_cashback.text) ?? 0;
    final recoverable = (total - cashback).clamp(0, total);

    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'For Others'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          FinarcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FinarcSectionHeader(title: 'Who owes this?'),
                const SizedBox(height: AppSpacing.sm),
                FinarcTextField(
                  controller: _name,
                  label: 'Paid for whom?',
                  onChanged: (_) => setState(() {}),
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
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.sm),
                FinarcTextField(
                  controller: _cashback,
                  label: 'Cashback received',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.sm),
                FinarcTextField(
                  controller: _notes,
                  label: 'Notes',
                  maxLines: 2,
                  textInputAction: TextInputAction.done,
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
                _summaryLine(context, 'Paid for', _name.text.isEmpty ? '-' : _name.text),
                _summaryLine(context, 'Total Paid', inr(total)),
                _summaryLine(context, 'Cashback', inr(cashback)),
                _summaryLine(context, 'Recoverable', inr(recoverable)),
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
