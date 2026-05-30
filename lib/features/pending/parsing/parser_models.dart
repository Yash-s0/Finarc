class DetectedTransactionCandidate {
  const DetectedTransactionCandidate({
    required this.amount,
    required this.merchant,
    required this.transactionDate,
    required this.sourceType,
    required this.rawText,
    required this.confidenceScore,
    this.confidenceLevel,
    required this.parserName,
    this.paymentSourceTypeSuggestion,
    this.paymentSourceHint,
    this.categorySuggestion,
    this.metadata,
  });

  final double amount;
  final String merchant;
  final DateTime transactionDate;
  final String sourceType;
  final String? paymentSourceTypeSuggestion;
  final String? paymentSourceHint;
  final String? categorySuggestion;
  final String rawText;
  final double confidenceScore;
  final String? confidenceLevel;
  final String parserName;
  final Map<String, Object?>? metadata;
}

class ParserResult {
  const ParserResult({
    required this.candidates,
    required this.parserName,
    required this.parsedAt,
    this.warnings,
    this.errors,
  });

  final List<DetectedTransactionCandidate> candidates;
  final List<String>? warnings;
  final List<String>? errors;
  final String parserName;
  final DateTime parsedAt;
}

class ParserInput {
  const ParserInput({
    required this.rawText,
    required this.sourceType,
    required this.receivedAt,
    this.packageName,
    this.sender,
    this.notificationTitle,
    this.notificationBody,
  });

  final String rawText;
  final String sourceType;
  final String? packageName;
  final String? sender;
  final DateTime receivedAt;
  final String? notificationTitle;
  final String? notificationBody;

  String get fullText {
    final parts = <String>[
      if (notificationTitle != null && notificationTitle!.trim().isNotEmpty)
        notificationTitle!.trim(),
      if (notificationBody != null && notificationBody!.trim().isNotEmpty)
        notificationBody!.trim(),
      rawText.trim(),
    ];
    return parts.join(' ').trim();
  }
}
