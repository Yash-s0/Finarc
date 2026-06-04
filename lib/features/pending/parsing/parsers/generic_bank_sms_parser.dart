import '../../../expenses/models/transaction_types.dart';
import '../category_suggester.dart';
import '../merchant_normalizer.dart';
import '../parser_confidence_scorer.dart';
import '../parser_models.dart';
import '../parser_text_utils.dart';
import '../transaction_direction_classifier.dart';
import '../transaction_parser.dart';

class GenericBankSmsParser implements TransactionParser {
  @override
  String get parserName => 'GenericBankSmsParser';

  @override
  bool canParse(ParserInput input) {
    final t = input.fullText.toLowerCase();
    if (ParserTextUtils.looksLikeCardBillDueMessage(input.fullText) ||
        ParserTextUtils.looksLikeCardPaymentSettlementMessage(input.fullText)) {
      return false;
    }
    return input.sourceType == 'sms' ||
        t.contains('bank') ||
        t.contains('a/c') ||
        t.contains('card') ||
        t.contains('debited') ||
        t.contains('credited') ||
        t.contains('received') ||
        t.contains('spent') ||
        t.contains('paid') ||
        t.contains('sent') ||
        t.contains('used') ||
        t.contains('txn') ||
        t.contains('transaction') ||
        t.contains('salary') ||
        t.contains('payroll') ||
        t.contains('transfer') ||
        t.contains('upi') ||
        t.contains('imps') ||
        t.contains('neft') ||
        t.contains('purchase');
  }

  @override
  ParserResult parse(ParserInput input) {
    if (ParserTextUtils.looksLikeCardBillDueMessage(input.fullText) ||
        ParserTextUtils.looksLikeCardPaymentSettlementMessage(input.fullText)) {
      return ParserResult(
        candidates: const [],
        warnings: const ['Skipped bill due/card payment settlement message'],
        parserName: parserName,
        parsedAt: DateTime.now(),
      );
    }
    final text = input.fullText;
    final segments = _splitTransactionSegments(text);
    final candidates = <DetectedTransactionCandidate>[];

    for (final segment in segments) {
      final amount = ParserTextUtils.extractAmount(segment);
      if (amount == null) continue;

      final direction = _detectDirection(segment);
      final counterparty = _extractCounterparty(segment, direction);
      final merchant = MerchantNormalizer.normalize(
        counterparty ?? 'Unknown Merchant',
      );

      final hintLast4 = ParserTextUtils.extractLast4Hint(segment);
      final accountHint = ParserTextUtils.extractAccountHint(segment);
      final paymentSourceHint =
          accountHint ?? (hintLast4 == null ? null : 'ending $hintLast4');
      final ref = ParserTextUtils.extractTransactionReference(segment);
      final parsedDateTime = ParserTextUtils.extractDateTime(
        segment,
        input.captureTime,
      );
      final date = parsedDateTime?.value ?? input.captureTime;
      final sourceSuggestion = _sourceSuggestionForSegment(
        segment: segment,
        direction: direction,
        accountHint: accountHint,
      );

      final confidence = ParserConfidenceScorer.assess(
        hasAmount: true,
        hasMerchant: merchant != 'Unknown Merchant',
        hasSourceHint: paymentSourceHint != null || ref != null,
        hasPatternMatch: direction != _TxnDirection.unknown,
        hasDate: parsedDateTime?.hasDate == true,
        isFallback: false,
      );

      candidates.add(
        DetectedTransactionCandidate(
          amount: amount,
          merchant: merchant,
          transactionDate: date,
          sourceType: input.sourceType,
          paymentSourceTypeSuggestion: sourceSuggestion,
          paymentSourceHint: paymentSourceHint,
          categorySuggestion: _categoryForSegment(
            segment: segment,
            direction: direction,
            merchant: merchant,
          ),
          rawText: segment,
          confidenceScore: confidence.score,
          confidenceLevel: confidence.level.name.toUpperCase(),
          parserName: parserName,
          metadata: {
            'sender': input.sender ?? input.notificationTitle,
            'counterparty': counterparty ?? merchant,
            'sourceSuggestion': sourceSuggestion,
            'transactionRef': ref,
            'direction': direction.name,
            'hasParsedDate': parsedDateTime?.hasDate == true,
            'hasParsedTime': parsedDateTime?.hasTime == true,
          },
        ),
      );
    }

    if (candidates.isEmpty) {
      return ParserResult(
        candidates: const [],
        warnings: const ['No amount detected in bank SMS pattern'],
        parserName: parserName,
        parsedAt: DateTime.now(),
      );
    }

    return ParserResult(
      candidates: candidates,
      parserName: parserName,
      parsedAt: DateTime.now(),
    );
  }

  List<String> _splitTransactionSegments(String text) {
    final normalized = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) return const [];

    final parts = normalized
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList(growable: false);
    if (parts.length <= 1) return [normalized];

    final segments = <String>[];
    var buffer = '';
    for (final part in parts) {
      final startsNew = _looksLikeTransactionStart(part);
      final hasAmount = ParserTextUtils.extractAmount(part) != null;
      if (buffer.isEmpty) {
        buffer = part;
        continue;
      }
      if (startsNew && hasAmount) {
        segments.add(buffer.trim());
        buffer = part;
      } else {
        buffer = '$buffer $part'.trim();
      }
    }
    if (buffer.isNotEmpty) {
      segments.add(buffer.trim());
    }

    final transactionLike = segments
        .where((segment) {
          final lowered = segment.toLowerCase();
          return ParserTextUtils.extractAmount(segment) != null &&
              (lowered.contains('credited') ||
                  lowered.contains('debited') ||
                  lowered.contains('sent') ||
                  lowered.contains('paid') ||
                  lowered.contains('salary') ||
                  lowered.contains('transfer'));
        })
        .toList(growable: false);

    if (transactionLike.isNotEmpty) {
      return _dedupeByReference(transactionLike);
    }
    return [normalized];
  }

  bool _looksLikeTransactionStart(String segment) {
    final lower = segment.toLowerCase().trimLeft();
    return lower.startsWith('a/c') ||
        lower.startsWith('ac ') ||
        lower.startsWith('account ') ||
        lower.startsWith('sent rs') ||
        lower.startsWith('sent ₹') ||
        lower.startsWith('rs') ||
        lower.startsWith('inr') ||
        lower.startsWith('your ') ||
        lower.startsWith('hi! your');
  }

  _TxnDirection _detectDirection(String text) {
    final direction = PendingDirectionClassifier.detect(text: text);
    switch (direction) {
      case PendingTransactionDirection.income:
        return _TxnDirection.income;
      case PendingTransactionDirection.expense:
        return _TxnDirection.expense;
      case PendingTransactionDirection.unknown:
        return _TxnDirection.unknown;
    }
  }

  String? _extractCounterparty(String text, _TxnDirection direction) {
    final lowered = text.toLowerCase();
    if (lowered.contains('salary') || lowered.contains('payroll')) {
      final salaryFromMatch = RegExp(
        r'\bfrom\s+([A-Za-z0-9&._\- ]{2,})',
        caseSensitive: false,
      ).firstMatch(text);
      final salarySource = _cleanCounterparty(
        _truncateCounterparty(salaryFromMatch?.group(1) ?? ''),
      );
      if (salarySource != null) return salarySource;
    }
    if (direction == _TxnDirection.income) {
      final fromMatch = RegExp(
        r'\bfrom\s+([A-Za-z0-9@._\- ]{2,})',
        caseSensitive: false,
      ).firstMatch(text);
      final from = _cleanCounterparty(
        _truncateCounterparty(fromMatch?.group(1) ?? ''),
      );
      if (from != null) return from;
    }
    if (direction == _TxnDirection.expense) {
      final toMatch = RegExp(
        r'\bto\s+([A-Za-z0-9@._\- ]{2,})',
        caseSensitive: false,
      ).firstMatch(text);
      final to = _cleanCounterparty(
        _truncateCounterparty(toMatch?.group(1) ?? ''),
      );
      if (to != null) return to;
    }

    final fallback = ParserTextUtils.extractMerchantAfterKeyword(text, [
      'to',
      'from',
      'at',
      'via',
      'on',
    ]);
    return _cleanCounterparty(fallback ?? '');
  }

  String _truncateCounterparty(String raw) {
    var value = raw;
    final markers = [
      ' on ',
      ' upi ref',
      ' rrn',
      ' avl bal',
      ' not you',
      ' http',
      ' has ',
      ' txn',
      ' transaction',
      '.',
      ',',
    ];
    final lower = value.toLowerCase();
    var cut = value.length;
    for (final marker in markers) {
      final index = lower.indexOf(marker);
      if (index != -1 && index < cut) {
        cut = index;
      }
    }
    value = value.substring(0, cut);
    return value.trim();
  }

  String? _cleanCounterparty(String raw) {
    final cleaned = raw
        .replaceAll(RegExp(r'[^A-Za-z0-9@._\- ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) return null;
    return cleaned;
  }

  List<String> _dedupeByReference(List<String> segments) {
    final seenReferences = <String>{};
    final output = <String>[];
    for (final segment in segments) {
      final ref = ParserTextUtils.extractTransactionReference(segment);
      if (ref == null) {
        output.add(segment);
        continue;
      }
      final key = ref.toLowerCase();
      if (seenReferences.contains(key)) continue;
      seenReferences.add(key);
      output.add(segment);
    }
    return output;
  }

  String _sourceSuggestionForSegment({
    required String segment,
    required _TxnDirection direction,
    required String? accountHint,
  }) {
    final lower = segment.toLowerCase();
    if (lower.contains('card')) return PaymentSourceType.creditCard;
    if (direction == _TxnDirection.income && accountHint != null) {
      return PaymentSourceType.bank;
    }
    if (lower.contains('upi')) return PaymentSourceType.upi;
    return PaymentSourceType.bank;
  }

  String _categoryForSegment({
    required String segment,
    required _TxnDirection direction,
    required String merchant,
  }) {
    final lower = segment.toLowerCase();
    if (direction == _TxnDirection.income) {
      if (lower.contains('salary') || lower.contains('payroll')) {
        return 'Income';
      }
      if (lower.contains('refund') || lower.contains('cashback')) {
        return 'Refund';
      }
      return 'Transfer';
    }
    if (direction == _TxnDirection.expense &&
        (lower.contains('upi') || lower.contains('sent'))) {
      return 'Transfer';
    }
    return CategorySuggester.suggest(merchant);
  }
}

enum _TxnDirection { income, expense, unknown }
