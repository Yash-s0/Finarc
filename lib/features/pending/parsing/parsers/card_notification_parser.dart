import '../../../expenses/models/transaction_types.dart';
import '../category_suggester.dart';
import '../merchant_normalizer.dart';
import '../parser_confidence_scorer.dart';
import '../parser_models.dart';
import '../parser_text_utils.dart';
import '../transaction_parser.dart';

class CardNotificationParser implements TransactionParser {
  @override
  String get parserName => 'CardNotificationParser';

  @override
  bool canParse(ParserInput input) {
    final text = _textForParsing(input);
    if (_isExcludedCardMessage(text)) return false;
    return _mentionsCard(text) &&
        _hasSpendIntent(text) &&
        _extractSpendAmount(text) != null;
  }

  @override
  ParserResult parse(ParserInput input) {
    final text = _textForParsing(input);
    if (_isExcludedCardMessage(text)) {
      return ParserResult(
        candidates: const [],
        warnings: const ['Skipped non-expense card message'],
        parserName: parserName,
        parsedAt: DateTime.now(),
      );
    }

    final extraction = _extractCardSpend(text, input);
    if (extraction == null) {
      return ParserResult(
        candidates: const [],
        warnings: const ['No card spend extraction matched this message'],
        parserName: parserName,
        parsedAt: DateTime.now(),
      );
    }

    final confidence = ParserConfidenceScorer.assess(
      hasAmount: true,
      hasMerchant: !extraction.usedFallbackMerchant,
      hasSourceHint: extraction.cardLast4 != null,
      hasPatternMatch: true,
      hasDate: extraction.parsedDateTime?.hasDate == true,
      isFallback: false,
    );

    return ParserResult(
      candidates: [
        DetectedTransactionCandidate(
          amount: extraction.amount,
          merchant: extraction.merchant,
          transactionDate:
              extraction.parsedDateTime?.value ?? input.captureTime,
          sourceType: input.sourceType,
          paymentSourceTypeSuggestion: PaymentSourceType.creditCard,
          paymentSourceHint: extraction.cardLast4 == null
              ? null
              : 'card-ending-${extraction.cardLast4}',
          categorySuggestion: CategorySuggester.suggest(extraction.merchant),
          rawText: input.rawText,
          confidenceScore: confidence.score,
          confidenceLevel: confidence.level.name.toUpperCase(),
          parserName: parserName,
          metadata: {
            'merchantExtractionStrategy': extraction.merchantExtractionStrategy,
            'amountExtractionStrategy': extraction.amountExtractionStrategy,
            'cardLast4': extraction.cardLast4,
            'hasParsedDate': extraction.parsedDateTime?.hasDate == true,
            'hasParsedTime': extraction.parsedDateTime?.hasTime == true,
          },
        ),
      ],
      parserName: parserName,
      parsedAt: DateTime.now(),
    );
  }

  _CardSpendExtraction? _extractCardSpend(String text, ParserInput input) {
    final amount = _extractSpendAmount(text);
    if (amount == null) return null;

    final cardLast4 = _extractCardLast4(text);
    final parsedDateTime = ParserTextUtils.extractDateTime(
      text,
      input.captureTime,
    );
    final merchantCandidate = _extractMerchantCandidate(text);
    final fallbackMerchant = _fallbackMerchant(cardLast4);
    final merchant = merchantCandidate == null
        ? fallbackMerchant
        : MerchantNormalizer.normalize(merchantCandidate.value);

    return _CardSpendExtraction(
      amount: amount.value,
      amountExtractionStrategy: amount.strategy,
      merchant: merchant == 'Unknown Merchant' ? fallbackMerchant : merchant,
      merchantExtractionStrategy:
          merchantCandidate?.strategy ?? 'fallback-card-spend',
      usedFallbackMerchant: merchantCandidate == null,
      cardLast4: cardLast4,
      parsedDateTime: parsedDateTime,
    );
  }

  String _textForParsing(ParserInput input) {
    final raw = input.rawText.trim();
    if (raw.isNotEmpty) return raw;
    return input.fullText;
  }

  bool _isExcludedCardMessage(String text) {
    return ParserTextUtils.looksLikeNonExpenseCardMessage(text);
  }

  bool _mentionsCard(String text) {
    return RegExp(
      r'\b(?:credit\s+)?card\b|card\s*(?:no\.?|number)?\s*[x* -]*\d{3,4}|ending\s+\d{3,4}',
      caseSensitive: false,
    ).hasMatch(text);
  }

  bool _hasSpendIntent(String text) {
    return _actionPattern.hasMatch(text);
  }

  _AmountExtraction? _extractSpendAmount(String text) {
    final actions = _actionPattern.allMatches(text).toList(growable: false);
    if (actions.isEmpty) return null;

    final amounts = _amountPattern
        .allMatches(text)
        .map((match) {
          final raw = (match.group(1) ?? '').replaceAll(',', '').trim();
          final value = double.tryParse(raw);
          if (value == null) return null;
          return _AmountMatch(value: value, start: match.start, end: match.end);
        })
        .whereType<_AmountMatch>()
        .where((amount) => !_isNoiseAmount(text, amount))
        .toList(growable: false);
    if (amounts.isEmpty) return null;

    _AmountMatch? best;
    var bestScore = 1 << 30;
    for (final amount in amounts) {
      final distance = actions
          .map((action) => _distanceBetween(amount.start, amount.end, action))
          .reduce((a, b) => a < b ? a : b);
      if (distance < bestScore) {
        best = amount;
        bestScore = distance;
      }
    }

    if (best == null) return null;
    return _AmountExtraction(
      value: best.value,
      strategy: bestScore <= 40
          ? 'nearest-spend-action'
          : 'first-non-limit-amount',
    );
  }

  int _distanceBetween(int start, int end, RegExpMatch match) {
    if (end < match.start) return match.start - end;
    if (match.end < start) return start - match.end;
    return 0;
  }

  bool _isNoiseAmount(String text, _AmountMatch amount) {
    final lower = text.toLowerCase();
    final before = lower.substring(
      amount.start - 60 < 0 ? 0 : amount.start - 60,
      amount.start,
    );
    final after = lower.substring(
      amount.end,
      amount.end + 40 > lower.length ? lower.length : amount.end + 40,
    );
    final window = '$before $after';
    const markers = [
      'avl limit',
      'avl lmt',
      'available limit',
      'credit limit',
      'limit:',
      'limit ',
      'balance',
      'min due',
      'minimum due',
      'total due',
      'amount due',
      'outstanding amount',
      'updated balance',
    ];
    return markers.any(window.contains);
  }

  String? _extractCardLast4(String text) {
    final direct = ParserTextUtils.extractLast4Hint(text);
    if (direct != null) return direct;

    final patterns = [
      RegExp(
        r'\bcard\s*(?:no\.?|number)?\s*[-:]?\s*[x* -]*(\d{3,4})\b',
        caseSensitive: false,
      ),
      RegExp(r'\bending\s+(\d{3,4})\b', caseSensitive: false),
      RegExp(r'\bcard\s*[-:]\s*(\d{3,4})\b', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      final value = match?.group(1);
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  _MerchantCandidate? _extractMerchantCandidate(String text) {
    final candidates = <_MerchantCandidate>[
      ..._merchantCandidatesFromTimestamp(text),
      ..._merchantCandidatesFromUpiDescriptor(text),
      ..._merchantCandidatesFromKeyword(text),
    ];
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.score.compareTo(a.score));
    return candidates.first;
  }

  List<_MerchantCandidate> _merchantCandidatesFromTimestamp(String text) {
    final lines = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    final candidates = <_MerchantCandidate>[];

    for (var i = 0; i < lines.length; i += 1) {
      final line = lines[i];
      final date = _dateOnlyPattern.firstMatch(line);
      if (date == null) continue;
      final time = _timeOnlyPattern.firstMatch(line.substring(date.end));
      final cut = time == null ? date.end : date.end + time.end;
      if (cut < line.length) {
        final tail = line.substring(cut).trim();
        final keywordTail = RegExp(
          r'^(?:at|on|for)\s+(.+)$',
          caseSensitive: false,
        ).firstMatch(tail);
        _addMerchantCandidate(
          candidates,
          raw: keywordTail?.group(1) ?? tail,
          strategy: keywordTail == null ? 'timestamp-tail' : 'merchant-keyword',
          score: 90,
        );
      }
      if (i + 1 < lines.length) {
        _addMerchantCandidate(
          candidates,
          raw: lines[i + 1],
          strategy: 'line-after-timestamp',
          score: 86,
        );
      }
    }

    return candidates;
  }

  List<_MerchantCandidate> _merchantCandidatesFromUpiDescriptor(String text) {
    final candidates = <_MerchantCandidate>[];
    for (final match in RegExp(
      r'@\s*([A-Za-z0-9_ .&\-]{2,120})',
      caseSensitive: false,
    ).allMatches(text)) {
      _addMerchantCandidate(
        candidates,
        raw: match.group(1),
        strategy: 'upi-descriptor',
        score: 84,
      );
    }
    return candidates;
  }

  List<_MerchantCandidate> _merchantCandidatesFromKeyword(String text) {
    final candidates = <_MerchantCandidate>[];
    for (final match in RegExp(
      r'\b(?:at|on|for)\s+([A-Za-z0-9_@.&\- ]{2,140})',
      caseSensitive: false,
    ).allMatches(text)) {
      _addMerchantCandidate(
        candidates,
        raw: match.group(1),
        strategy: 'merchant-keyword',
        score: 70,
      );
    }
    return candidates;
  }

  void _addMerchantCandidate(
    List<_MerchantCandidate> candidates, {
    required String? raw,
    required String strategy,
    required int score,
  }) {
    final cleaned = _cleanMerchantCandidate(raw);
    if (cleaned == null) return;
    candidates.add(
      _MerchantCandidate(value: cleaned, strategy: strategy, score: score),
    );
  }

  String? _cleanMerchantCandidate(String? raw) {
    if (raw == null) return null;
    var value = raw
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'[\[\]()]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (value.isEmpty) return null;

    value = _truncateMerchantTail(value);
    value = value
        .replaceAll(RegExp(r'[^A-Za-z0-9@.&\- ]'), ' ')
        .replaceAll(RegExp(r'\bIN\s+[A-Z]\b$', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    var tokens = value
        .split(RegExp(r'\s+'))
        .where((token) => token.trim().isNotEmpty)
        .toList();
    while (tokens.isNotEmpty &&
        _railSuffixTokens.contains(tokens.last.toUpperCase())) {
      tokens = tokens.sublist(0, tokens.length - 1);
    }
    while (tokens.isNotEmpty && tokens.first.toUpperCase() == 'UPI') {
      tokens = tokens.sublist(1);
    }
    value = tokens.join(' ').trim();

    if (_isRejectedMerchantCandidate(value)) return null;
    return value;
  }

  String _truncateMerchantTail(String raw) {
    final lower = raw.toLowerCase();
    final markers = [
      ' avl ',
      ' avl limit',
      ' avl lmt',
      ' available ',
      ' sms ',
      ' if not',
      ' not you',
      ' block ',
      ' blkcc ',
      ' call ',
      ' http',
      '://',
      ' due ',
      ' balance',
      ' limit',
      ' ref ',
      ' rrn ',
    ];
    var cut = raw.length;
    for (final marker in markers) {
      final index = lower.indexOf(marker);
      if (index != -1 && index < cut) cut = index;
    }

    final date = _dateOnlyPattern.firstMatch(raw);
    if (date != null && date.start < cut) cut = date.start;
    final time = _timeOnlyPattern.firstMatch(raw);
    if (time != null && time.start < cut) cut = time.start;

    final sentenceBreak = RegExp(r'[.;,]').firstMatch(raw);
    if (sentenceBreak != null && sentenceBreak.start < cut) {
      cut = sentenceBreak.start;
    }

    return raw.substring(0, cut).trim();
  }

  bool _isRejectedMerchantCandidate(String value) {
    final cleaned = value.trim();
    if (cleaned.length < 2) return true;
    final lower = cleaned.toLowerCase();
    if (lower.startsWith('http') || lower.contains('://')) return true;
    if (_dateOnlyPattern.hasMatch(cleaned) ||
        _timeOnlyPattern.hasMatch(cleaned)) {
      return true;
    }
    if (RegExp(r'^\+?\d[\d\s-]{5,}$').hasMatch(cleaned)) return true;
    if (RegExp(r'^[x* -]*\d{3,4}$', caseSensitive: false).hasMatch(cleaned)) {
      return true;
    }
    if (RegExp(
      r'\b(?:credit\s+)?card\b',
      caseSensitive: false,
    ).hasMatch(cleaned)) {
      return true;
    }
    if (RegExp(
      r'\b(?:avl|available|limit|lmt|balance|sms|block|blkcc|otp|password|due|bill)\b',
      caseSensitive: false,
    ).hasMatch(cleaned)) {
      return true;
    }
    if (RegExp(r'\bbank\b', caseSensitive: false).hasMatch(cleaned)) {
      return true;
    }

    final tokens = cleaned
        .toUpperCase()
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
    if (tokens.isEmpty) return true;
    if (tokens.every(_genericFinanceTokens.contains)) return true;
    return false;
  }

  String _fallbackMerchant(String? cardLast4) {
    if (cardLast4 == null || cardLast4.isEmpty) return 'Card spend';
    return 'Card spend XX$cardLast4';
  }

  static final RegExp _amountPattern = RegExp(
    r'(?:INR|Rs\.?|₹)\s*((?:[0-9]{1,3}(?:,[0-9]{2,3})+|[0-9]+)(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );

  static final RegExp _actionPattern = RegExp(
    r'\b(?:spent|used|purchase(?:d)?|charged|transaction|txn|debit(?:ed)?|paid)\b',
    caseSensitive: false,
  );

  static final RegExp _dateOnlyPattern = RegExp(
    r'\b(?:\d{1,2}[-/]\d{1,2}[-/]\d{2,4}|\d{1,2}[-\s](?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)(?:[-\s]\d{2,4})?)\b',
    caseSensitive: false,
  );

  static final RegExp _timeOnlyPattern = RegExp(
    r'\b\d{1,2}:\d{2}(?::\d{2})?\s*(?:IST|[AaPp][Mm])?\b',
    caseSensitive: false,
  );

  static const Set<String> _railSuffixTokens = {
    'UPI',
    'PAYMENT',
    'PAYMENTS',
    'IN',
  };

  static const Set<String> _genericFinanceTokens = {
    'UPI',
    'PAY',
    'PAYMENT',
    'PAYMENTS',
    'IN',
    'CARD',
    'BANK',
    'LIMIT',
    'LMT',
    'AVL',
    'SMS',
    'BLOCK',
    'BLKCC',
    'TRANSACTION',
    'TXN',
    'PURCHASE',
    'DEBIT',
    'DEBITED',
    'CREDIT',
    'CREDITED',
    'NOT',
    'YOU',
    'IF',
    'BALANCE',
    'DUE',
    'BILL',
  };
}

class _CardSpendExtraction {
  const _CardSpendExtraction({
    required this.amount,
    required this.amountExtractionStrategy,
    required this.merchant,
    required this.merchantExtractionStrategy,
    required this.usedFallbackMerchant,
    required this.cardLast4,
    required this.parsedDateTime,
  });

  final double amount;
  final String amountExtractionStrategy;
  final String merchant;
  final String merchantExtractionStrategy;
  final bool usedFallbackMerchant;
  final String? cardLast4;
  final ParsedDateTime? parsedDateTime;
}

class _AmountExtraction {
  const _AmountExtraction({required this.value, required this.strategy});

  final double value;
  final String strategy;
}

class _AmountMatch {
  const _AmountMatch({
    required this.value,
    required this.start,
    required this.end,
  });

  final double value;
  final int start;
  final int end;
}

class _MerchantCandidate {
  const _MerchantCandidate({
    required this.value,
    required this.strategy,
    required this.score,
  });

  final String value;
  final String strategy;
  final int score;
}
