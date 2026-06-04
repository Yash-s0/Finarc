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

  static final RegExp _dateNumericWithOptionalTimePattern = RegExp(
    r'\b(\d{1,2})[-/](\d{1,2})[-/](\d{2,4})(?:[,\s]+(?:at\s*)?(\d{1,2}):(\d{2})(?:\s*([AaPp][Mm]))?)?\b',
  );

  static final RegExp _dateMonthWithOptionalTimePattern = RegExp(
    r'\b(\d{1,2})[-\s](Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\b(?:[,\s]+(?:at\s*)?(\d{1,2}):(\d{2})(?:\s*([AaPp][Mm]))?)?',
    caseSensitive: false,
  );

  static final RegExp _timeOnlyPattern = RegExp(
    r'\b(?:at\s*)?(\d{1,2}):(\d{2})(?:\s*([AaPp][Mm]))?\b',
  );

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
    return extractDateTime(text, fallbackYearSource)?.value;
  }

  static DateTime? extractDateWithNumericSupport(
    String text,
    DateTime fallbackYearSource,
  ) {
    return extractDateTime(text, fallbackYearSource)?.value;
  }

  static ParsedDateTime? extractDateTime(String text, DateTime captureTime) {
    final numeric = _dateNumericWithOptionalTimePattern.firstMatch(text);
    if (numeric != null) {
      final day = int.tryParse(numeric.group(1) ?? '');
      final month = int.tryParse(numeric.group(2) ?? '');
      final yearRaw = int.tryParse(numeric.group(3) ?? '');
      if (day != null &&
          month != null &&
          yearRaw != null &&
          month >= 1 &&
          month <= 12 &&
          day >= 1 &&
          day <= 31) {
        final year = yearRaw < 100 ? 2000 + yearRaw : yearRaw;
        final resolvedTime = _resolveTime(
          hourText: numeric.group(4),
          minuteText: numeric.group(5),
          periodText: numeric.group(6),
          fallback: captureTime,
        );
        return ParsedDateTime(
          value: DateTime(
            year,
            month,
            day,
            resolvedTime.hour,
            resolvedTime.minute,
            resolvedTime.second,
          ),
          hasDate: true,
          hasTime: resolvedTime.explicit,
        );
      }
    }

    final dayMonth = _dateMonthWithOptionalTimePattern.firstMatch(text);
    if (dayMonth != null) {
      final day = int.tryParse(dayMonth.group(1) ?? '');
      final monthName = (dayMonth.group(2) ?? '').toLowerCase();
      final month = _months[monthName];
      if (day != null && month != null) {
        final resolvedTime = _resolveTime(
          hourText: dayMonth.group(3),
          minuteText: dayMonth.group(4),
          periodText: dayMonth.group(5),
          fallback: captureTime,
        );
        return ParsedDateTime(
          value: DateTime(
            captureTime.year,
            month,
            day,
            resolvedTime.hour,
            resolvedTime.minute,
            resolvedTime.second,
          ),
          hasDate: true,
          hasTime: resolvedTime.explicit,
        );
      }
    }

    final timeOnly = _timeOnlyPattern.firstMatch(text);
    if (timeOnly != null) {
      final resolvedTime = _resolveTime(
        hourText: timeOnly.group(1),
        minuteText: timeOnly.group(2),
        periodText: timeOnly.group(3),
        fallback: captureTime,
      );
      return ParsedDateTime(
        value: DateTime(
          captureTime.year,
          captureTime.month,
          captureTime.day,
          resolvedTime.hour,
          resolvedTime.minute,
          resolvedTime.second,
        ),
        hasDate: false,
        hasTime: resolvedTime.explicit,
      );
    }

    return null;
  }

  static String compactSpaces(String input) {
    return input.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static bool looksLikeCardBillDueMessage(String text) {
    final lower = text.toLowerCase();
    final hasCard =
        lower.contains('credit card') ||
        RegExp(
          r'card\s*[x*]{1,}[- ]?\d{4}',
          caseSensitive: false,
        ).hasMatch(text);
    if (!hasCard) return false;

    final duePhrases = [
      'min due',
      'minimum due',
      'total due',
      'amount due',
      'payment of credit card',
      'pay before last date',
      'avoid charges',
      'due date',
      'due by',
    ];
    return duePhrases.any(lower.contains);
  }

  static bool looksLikeCardPaymentSettlementMessage(String text) {
    final lower = text.toLowerCase();
    final hasCreditCard = lower.contains('credit card');
    final hasSettlementReceipt =
        (lower.contains('payment received') ||
            lower.contains('received towards your') ||
            lower.contains('credit card payment received')) &&
        hasCreditCard;
    if (hasSettlementReceipt) return true;

    final hasProcessedSettlement =
        (lower.contains('paid instantly to') ||
            lower.contains('has been processed') ||
            lower.contains('credit card bill payment')) &&
        hasCreditCard;
    if (hasProcessedSettlement) return true;

    final hasSourceDebit =
        (lower.contains('sent ') ||
            lower.contains('paid ') ||
            lower.contains('debited')) &&
        (lower.contains('cred.club') ||
            lower.contains(' to cred') ||
            lower.contains(' credit card bill') ||
            RegExp(r'@[a-z]{2,}b\b', caseSensitive: false).hasMatch(lower));
    return hasSourceDebit;
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

  static _ResolvedTime _resolveTime({
    required String? hourText,
    required String? minuteText,
    required String? periodText,
    required DateTime fallback,
  }) {
    if (hourText == null || minuteText == null) {
      return _ResolvedTime(
        hour: fallback.hour,
        minute: fallback.minute,
        second: fallback.second,
        explicit: false,
      );
    }

    var hour = int.tryParse(hourText);
    final minute = int.tryParse(minuteText);
    if (hour == null || minute == null || minute < 0 || minute > 59) {
      return _ResolvedTime(
        hour: fallback.hour,
        minute: fallback.minute,
        second: fallback.second,
        explicit: false,
      );
    }

    final period = periodText?.toLowerCase();
    if (period == 'am' || period == 'pm') {
      if (hour < 1 || hour > 12) {
        return _ResolvedTime(
          hour: fallback.hour,
          minute: fallback.minute,
          second: fallback.second,
          explicit: false,
        );
      }
      if (period == 'pm' && hour != 12) hour += 12;
      if (period == 'am' && hour == 12) hour = 0;
    } else {
      if (hour < 0 || hour > 23) {
        return _ResolvedTime(
          hour: fallback.hour,
          minute: fallback.minute,
          second: fallback.second,
          explicit: false,
        );
      }
    }

    return _ResolvedTime(
      hour: hour,
      minute: minute,
      second: fallback.second,
      explicit: true,
    );
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
      ' that was fast',
      ' tap to check',
      ' check your latest bank balance',
      ' check balance',
      ' open link',
      ' mark as read',
      ' not you',
      ' pay before last date',
      ' avoid charges',
      ' http',
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
    var cleaned = compactSpaces(
      raw.replaceAll(RegExp(r"[^A-Za-z0-9&.\-' ]"), ' '),
    );
    const noisePhrases = [
      'that was fast',
      'avoid charges',
      'check balance',
      'tap to check',
      'open link',
      'mark as read',
      'not you',
      'pay before last date',
    ];
    for (final phrase in noisePhrases) {
      final idx = cleaned.toLowerCase().indexOf(phrase);
      if (idx != -1) {
        cleaned = compactSpaces(cleaned.substring(0, idx));
      }
    }
    return cleaned;
  }
}

class ParsedDateTime {
  const ParsedDateTime({
    required this.value,
    required this.hasDate,
    required this.hasTime,
  });

  final DateTime value;
  final bool hasDate;
  final bool hasTime;
}

class _ResolvedTime {
  const _ResolvedTime({
    required this.hour,
    required this.minute,
    required this.second,
    required this.explicit,
  });

  final int hour;
  final int minute;
  final int second;
  final bool explicit;
}
