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

  static DateTime? extractDateWithNumericSupport(
    String text,
    DateTime fallbackYearSource,
  ) {
    final standard = extractDate(text, fallbackYearSource);
    if (standard != null) return standard;

    final match = RegExp(
      r'\b(\d{1,2})[-/](\d{1,2})[-/](\d{2,4})\b',
    ).firstMatch(text);
    if (match == null) return null;
    final day = int.tryParse(match.group(1) ?? '');
    final month = int.tryParse(match.group(2) ?? '');
    final yearRaw = int.tryParse(match.group(3) ?? '');
    if (day == null || month == null || yearRaw == null) return null;
    final year = yearRaw < 100 ? 2000 + yearRaw : yearRaw;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return DateTime(year, month, day);
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

  static String? extractTransactionReference(String text) {
    final match = RegExp(
      r'(?:RRN|UPI\s*Ref(?:erence)?|Txn(?:\s*ID)?|Ref(?:\s*No)?)\s*[:#.-]?\s*([A-Za-z0-9-]{6,})',
      caseSensitive: false,
    ).firstMatch(text);
    final ref = match?.group(1)?.trim();
    if (ref == null || ref.isEmpty) return null;
    return ref;
  }

  static String? extractAccountHint(String text) {
    final explicit = RegExp(
      r'(?:from|in)\s+([A-Za-z ]{2,}\s+Bank\s+AC\s*[Xx*]*\d{3,4})',
      caseSensitive: false,
    ).firstMatch(text);
    final explicitValue = explicit?.group(1)?.trim();
    if (explicitValue != null && explicitValue.isNotEmpty) {
      return explicitValue.replaceAll(RegExp(r'\s+'), ' ');
    }

    final ac = RegExp(
      r'(?:A\/C|AC|Account)\s*[*Xx]*([0-9]{3,4})',
      caseSensitive: false,
    ).firstMatch(text);
    final last = ac?.group(1);
    if (last == null || last.isEmpty) return null;
    return 'A/C ending $last';
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
