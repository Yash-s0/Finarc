import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../data/loan_service.dart';
import '../data/loans_providers.dart';

class AddEditLoanScreen extends ConsumerStatefulWidget {
  const AddEditLoanScreen({super.key, this.loanId});

  final int? loanId;

  @override
  ConsumerState<AddEditLoanScreen> createState() => _AddEditLoanScreenState();
}

class _AddEditLoanScreenState extends ConsumerState<AddEditLoanScreen> {
  final _formKey = GlobalKey<FormState>();

  final _title = TextEditingController();
  final _lender = TextEditingController();
  final _principal = TextEditingController(text: '0');
  final _outstanding = TextEditingController(text: '0');
  final _emi = TextEditingController();
  final _emiDay = TextEditingController();
  final _interest = TextEditingController();
  final _tenure = TextEditingController();
  final _linkedAccountId = TextEditingController();
  final _notes = TextEditingController();

  String _loanType = LoanType.personal;
  String _lenderType = LoanLenderType.company;
  bool _initialized = false;

  @override
  void dispose() {
    _title.dispose();
    _lender.dispose();
    _principal.dispose();
    _outstanding.dispose();
    _emi.dispose();
    _emiDay.dispose();
    _interest.dispose();
    _tenure.dispose();
    _linkedAccountId.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.loanId == null
        ? null
        : ref.watch(loanDetailProvider(widget.loanId!));

    if (widget.loanId != null && existing != null) {
      if (existing case AsyncData(:final value)) {
        if (!_initialized) {
          _initialized = true;
          _title.text = value.loan.title;
          _lender.text = value.loan.lenderName;
          _principal.text = value.loan.principalAmount.toString();
          _outstanding.text = value.loan.currentOutstanding.toString();
          _emi.text = value.loan.emiAmount?.toString() ?? '';
          _emiDay.text = value.loan.emiDay?.toString() ?? '';
          _interest.text = value.loan.interestRate?.toString() ?? '';
          _tenure.text = value.loan.tenureMonths?.toString() ?? '';
          _linkedAccountId.text = value.loan.linkedAccountId?.toString() ?? '';
          _notes.text = value.loan.notes ?? '';
          _loanType = value.loan.loanType;
          _lenderType = value.loan.lenderType ?? LoanLenderType.company;
        }
      }
    }

    return FinarcScaffold(
      appBar: FinarcAppBar(
        title: widget.loanId == null ? 'Add Loan' : 'Edit Loan',
      ),
      body: widget.loanId != null && existing is AsyncLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  FinarcCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FinarcSectionHeader(title: 'Loan Details'),
                        const SizedBox(height: AppSpacing.sm),
                        FinarcTextField(
                          controller: _title,
                          label: 'Title',
                          hint: 'Vehicle Loan',
                          validator: _required,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        FinarcTextField(
                          controller: _lender,
                          label: 'Lender name',
                          hint: 'HDFC / Friend name',
                          validator: _required,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Lender type',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: LoanLenderType.all
                              .map(
                                (type) => FinarcActionChip(
                                  label: _lenderTypeLabel(type),
                                  selected: _lenderType == type,
                                  onTap: () =>
                                      setState(() => _lenderType = type),
                                ),
                              )
                              .toList(growable: false),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Loan type',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: LoanType.all
                              .map(
                                (type) => FinarcActionChip(
                                  label: type.toUpperCase(),
                                  selected: _loanType == type,
                                  onTap: () => setState(() => _loanType = type),
                                ),
                              )
                              .toList(growable: false),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        FinarcTextField(
                          controller: _principal,
                          label: 'Principal amount',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: _amount,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        FinarcTextField(
                          controller: _outstanding,
                          label: 'Current outstanding',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: _amount,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FinarcCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FinarcSectionHeader(title: 'EMI & Terms'),
                        const SizedBox(height: AppSpacing.sm),
                        FinarcTextField(
                          controller: _emi,
                          label: 'EMI amount (optional)',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        FinarcTextField(
                          controller: _emiDay,
                          label: 'EMI day (1-31 optional)',
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            final day = int.tryParse(v.trim());
                            if (day == null || day < 1 || day > 31) {
                              return 'EMI day must be 1 to 31';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        FinarcTextField(
                          controller: _interest,
                          label: 'Interest rate % (optional)',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        FinarcTextField(
                          controller: _tenure,
                          label: 'Tenure months (optional)',
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        FinarcTextField(
                          controller: _linkedAccountId,
                          label: 'Linked repayment account ID (optional)',
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        FinarcTextField(
                          controller: _notes,
                          label: 'Notes',
                          maxLines: 3,
                          textInputAction: TextInputAction.done,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FinarcPrimaryButton(
                    onPressed: _save,
                    icon: Icons.check_circle_outline,
                    label: widget.loanId == null
                        ? 'Create Loan'
                        : 'Save Changes',
                  ),
                ],
              ),
            ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  String? _amount(String? value) {
    if (double.tryParse(value ?? '') == null) return 'Enter valid amount';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final principal = double.parse(_principal.text);
    final outstanding = double.parse(_outstanding.text);
    final emiAmount = _parseDouble(_emi.text);
    final emiDay = _parseInt(_emiDay.text);
    final interest = _parseDouble(_interest.text);
    final tenure = _parseInt(_tenure.text);
    final linkedId = _parseInt(_linkedAccountId.text);

    if (principal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Principal amount must be greater than 0'),
        ),
      );
      return;
    }
    if (outstanding < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Outstanding amount cannot be negative')),
      );
      return;
    }
    if (emiAmount != null && emiAmount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('EMI amount cannot be negative')),
      );
      return;
    }
    if (emiAmount != null && emiAmount > outstanding) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('EMI amount cannot exceed current outstanding'),
        ),
      );
      return;
    }
    if (outstanding > principal) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Outstanding exceeds principal'),
          content: const Text(
            'Current outstanding is greater than principal. Continue anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (shouldContinue != true) return;
    }

    final actions = ref.read(loanActionsProvider);
    if (widget.loanId == null) {
      await actions.createLoan(
        title: _title.text.trim(),
        lenderName: _lender.text.trim(),
        lenderType: _lenderType,
        loanType: _loanType,
        principalAmount: principal,
        currentOutstanding: outstanding,
        emiAmount: emiAmount,
        emiDay: emiDay,
        interestRate: interest,
        tenureMonths: tenure,
        linkedAccountId: linkedId,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
    } else {
      await actions.updateLoan(
        widget.loanId!,
        title: _title.text.trim(),
        lenderName: _lender.text.trim(),
        lenderType: _lenderType,
        loanType: _loanType,
        principalAmount: principal,
        currentOutstanding: outstanding,
        emiAmount: emiAmount,
        emiDay: emiDay,
        interestRate: interest,
        tenureMonths: tenure,
        linkedAccountId: linkedId,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  double? _parseDouble(String text) {
    if (text.trim().isEmpty) return null;
    return double.tryParse(text.trim());
  }

  int? _parseInt(String text) {
    if (text.trim().isEmpty) return null;
    return int.tryParse(text.trim());
  }

  String _lenderTypeLabel(String type) {
    switch (type) {
      case LoanLenderType.company:
        return 'Company';
      case LoanLenderType.bankNbfc:
        return 'Bank / NBFC';
      case LoanLenderType.person:
        return 'Person';
      default:
        return 'Other';
    }
  }
}
