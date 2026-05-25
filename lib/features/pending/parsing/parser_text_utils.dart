class ParserTextUtils {
  static final RegExp _amountPattern = RegExp(
    r'(?:INR|Rs\.?|₹)\s*((?:[0-9]{1,3}(?:,[0-9]{2,3})+|[0-9]+)(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );

  static final RegExp _last4Pattern = RegExp(
    r'(?:card|a\/c|account)[^0-9]{0,24}(?:ending\s*|xx|x{2,}|\*{2,})?(\d{4})',
    caseSensitive: false,
  );

  static final Map<String, int> _months = {
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dec': 12,
  };

  static double? extractAmount(String text) {
    final match = _amountPattern.firstMatch(text);
    if (match == null) return null;
    final raw = (match.group(1) ?? '').replaceAll(',', '').trim();
    return double.tryParse(raw);
  }

  static String? extractLast4Hint(String text) {
    final match = _last4Pattern.firstMatch(text);
    return match?.group(1);
  }

  static DateTime? extractDate(String text, DateTime fallbackYearSource) {
    final match = RegExp(
      r'\b(\d{1,2})[-\s](Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\b',
      caseSensitive: false,
    ).firstMatch(text);

    if (match != null) {
      final day = int.tryParse(match.group(1) ?? '');
      final monthName = (match.group(2) ?? '').toLowerCase();
      final month = _months[monthName];
      if (day != null && month != null) {
        return DateTime(fallbackYearSource.year, month, day);
      }
    }

    return null;
  }

  static String compactSpaces(String input) {
    return input.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String? extractMerchantAfterKeyword(
    String text,
    List<String> keywords,
  ) {
    final lowered = text.toLowerCase();
    for (final keyword in keywords) {
      final idx = lowered.indexOf('$keyword ');
      if (idx == -1) continue;

      final start = idx + keyword.length + 1;
      if (start >= text.length) continue;

      final tail = text.substring(start);
      final boundary = _firstBoundary(tail);
      final raw = (boundary == -1 ? tail : tail.substring(0, boundary));
      final cleaned = _cleanMerchant(raw);
      if (cleaned.isNotEmpty) return cleaned;
    }
    return null;
  }

  static int _firstBoundary(String text) {
    final markers = [
      ' on ',
      ' via ',
      ' using ',
      ' info',
      ' ref',
      ' upi',
      ',',
      '.',
      ';',
      ' from ',
      ' avl',
      ' txn',
      ' transaction',
    ];

    var boundary = -1;
    final lowered = text.toLowerCase();
    for (final marker in markers) {
      final pos = lowered.indexOf(marker);
      if (pos == -1) continue;
      if (boundary == -1 || pos < boundary) boundary = pos;
    }

    return boundary;
  }

  static String _cleanMerchant(String raw) {
    return compactSpaces(raw.replaceAll(RegExp(r"[^A-Za-z0-9&.\-' ]"), ''));
  }
}
