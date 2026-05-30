enum PendingTransactionDirection { income, expense, unknown }

class PendingDirectionClassifier {
  static final RegExp _amountWordPattern = RegExp(
    r'(?:inr|rs\.?|₹)\s*[0-9,]+(?:\.[0-9]{1,2})?',
    caseSensitive: false,
  );

  static final RegExp _receivedInYourPattern = RegExp(
    r'\breceived\b[\s\S]{0,40}?(?:inr|rs\.?|₹)\s*[0-9,]+(?:\.[0-9]{1,2})?[\s\S]{0,40}?\bin\s+your\b',
    caseSensitive: false,
  );

  static final RegExp _creditedByPattern = RegExp(
    r'\bcredited\b\s+by\b[\s\S]{0,20}?(?:inr|rs\.?|₹)',
    caseSensitive: false,
  );

  static final RegExp _sentFromToPattern = RegExp(
    r'\bsent\b[\s\S]{0,40}?(?:inr|rs\.?|₹)\s*[0-9,]+(?:\.[0-9]{1,2})?[\s\S]{0,80}?\bfrom\b[\s\S]{0,80}?\bto\b',
    caseSensitive: false,
  );

  static final List<String> _incomeKeywords = <String>[
    'received',
    'credited',
    'deposited',
    'salary',
    'payroll',
    'refund credited',
    'cashback',
  ];

  static final List<String> _expenseKeywords = <String>[
    'sent',
    'paid',
    'debited',
    'spent',
    'deducted',
    'charged',
    'withdrawn',
  ];

  static PendingTransactionDirection detect({
    required String text,
    String? categoryHint,
  }) {
    final normalized = text.toLowerCase();
    final category = categoryHint?.trim().toLowerCase() ?? '';
    if (category == 'income' ||
        category == 'received' ||
        category == 'refund') {
      return PendingTransactionDirection.income;
    }

    var incomeScore = _countSignals(normalized, _incomeKeywords);
    var expenseScore = _countSignals(normalized, _expenseKeywords);

    if (_receivedInYourPattern.hasMatch(text)) {
      incomeScore += 3;
    }
    if (_creditedByPattern.hasMatch(text)) {
      incomeScore += 3;
    }
    if (_sentFromToPattern.hasMatch(text)) {
      expenseScore += 3;
    }

    if (_mentionsFromForIncome(normalized)) {
      incomeScore += 1;
    }
    if (_mentionsToForExpense(normalized)) {
      expenseScore += 1;
    }

    if (incomeScore > expenseScore) {
      return PendingTransactionDirection.income;
    }
    if (expenseScore > incomeScore) {
      return PendingTransactionDirection.expense;
    }
    return PendingTransactionDirection.unknown;
  }

  static bool looksLikeIncome({required String text, String? categoryHint}) {
    return detect(text: text, categoryHint: categoryHint) ==
        PendingTransactionDirection.income;
  }

  static bool looksLikeExpense({required String text, String? categoryHint}) {
    return detect(text: text, categoryHint: categoryHint) ==
        PendingTransactionDirection.expense;
  }

  static int _countSignals(String text, List<String> words) {
    var score = 0;
    for (final word in words) {
      if (text.contains(word)) score += 1;
    }
    return score;
  }

  static bool _mentionsFromForIncome(String text) {
    if (!text.contains(' from ')) return false;
    return text.contains('received') ||
        text.contains('credited') ||
        text.contains('salary') ||
        text.contains('payroll') ||
        text.contains('deposit');
  }

  static bool _mentionsToForExpense(String text) {
    if (!text.contains(' to ')) return false;
    return text.contains('sent') ||
        text.contains('paid') ||
        text.contains('debited') ||
        _sentFromToPattern.hasMatch(text);
  }

  static bool hasAmountWord(String text) => _amountWordPattern.hasMatch(text);
}
