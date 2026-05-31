import '../../expenses/data/transaction_engine.dart';

class TransactionImportValidationIssue {
  const TransactionImportValidationIssue({
    required this.message,
    this.isWarning = false,
  });

  final String message;
  final bool isWarning;
}

class TransactionImportResolvedRow {
  const TransactionImportResolvedRow({
    required this.rowNumber,
    required this.originalType,
    required this.paymentMode,
    required this.sourceId,
    required this.sourceLabel,
    required this.input,
  });

  final int rowNumber;
  final String originalType;
  final String paymentMode;
  final int sourceId;
  final String sourceLabel;
  final AddTransactionInput input;
}

class TransactionImportPreviewRow {
  const TransactionImportPreviewRow({
    required this.rowNumber,
    required this.raw,
    required this.issues,
    this.resolved,
  });

  final int rowNumber;
  final Map<String, dynamic> raw;
  final List<TransactionImportValidationIssue> issues;
  final TransactionImportResolvedRow? resolved;

  bool get isValid => resolved != null;
  bool get hasWarnings => issues.any((issue) => issue.isWarning);
}

class TransactionImportPreview {
  const TransactionImportPreview({
    required this.totalRows,
    required this.rows,
    required this.totalExpenseAmount,
    required this.totalIncomeAmount,
    required this.generalWarnings,
  });

  final int totalRows;
  final List<TransactionImportPreviewRow> rows;
  final double totalExpenseAmount;
  final double totalIncomeAmount;
  final List<String> generalWarnings;

  int get validRows => rows.where((row) => row.isValid).length;
  int get invalidRows => totalRows - validRows;

  List<TransactionImportResolvedRow> get validResolvedRows => rows
      .map((row) => row.resolved)
      .whereType<TransactionImportResolvedRow>()
      .toList(growable: false);
}

class TransactionImportParseResult {
  const TransactionImportParseResult({
    required this.isValidJson,
    required this.message,
    this.preview,
  });

  final bool isValidJson;
  final String message;
  final TransactionImportPreview? preview;
}

class TransactionImportExecutionResult {
  const TransactionImportExecutionResult({
    required this.totalRows,
    required this.importedCount,
    required this.skippedCount,
    required this.failedCount,
    required this.failureReasons,
  });

  final int totalRows;
  final int importedCount;
  final int skippedCount;
  final int failedCount;
  final List<String> failureReasons;
}
