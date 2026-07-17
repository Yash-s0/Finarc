import '../../../expenses/models/transaction_types.dart';
import '../category_suggester.dart';
import '../merchant_normalizer.dart';
import '../parser_confidence_scorer.dart';
import '../parser_models.dart';
import '../parser_text_utils.dart';
import '../transaction_parser.dart';

class GenericFallbackParser implements TransactionParser {
  @override
  String get parserName => 'GenericFallbackParser';

  @override
  bool canParse(ParserInput input) => true;

  @override
  ParserResult parse(ParserInput input) {
    if (ParserTextUtils.looksLikeNonTransactionMessage(input.fullText)) {
      return ParserResult(
        candidates: const [],
        warnings: const ['Skipped non-transaction message'],
        parserName: parserName,
        parsedAt: DateTime.now(),
      );
    }
    final amount = ParserTextUtils.extractAmount(input.fullText);
    if (amount == null) {
      return ParserResult(
        candidates: const [],
        warnings: const ['Fallback parser found no amount'],
        parserName: parserName,
        parsedAt: DateTime.now(),
      );
    }

    final merchantRaw = ParserTextUtils.extractMerchantAfterKeyword(
      input.fullText,
      ['to', 'at', 'for', 'on'],
    );

    final merchant = MerchantNormalizer.normalize(
      merchantRaw ??
          _extractPossibleProperNoun(input.fullText) ??
          'Unknown Merchant',
    );

    final suggestion = _sourceSuggestion(input);
    final sourceHint = _sourceHint(input);
    final confidence = ParserConfidenceScorer.assess(
      hasAmount: true,
      hasMerchant: merchant != 'Unknown Merchant',
      hasSourceHint: sourceHint != null,
      hasPatternMatch: false,
      hasDate: false,
      isFallback: true,
    );

    return ParserResult(
      candidates: [
        DetectedTransactionCandidate(
          amount: amount,
          merchant: merchant,
          transactionDate: input.captureTime,
          sourceType: input.sourceType,
          paymentSourceTypeSuggestion: suggestion,
          paymentSourceHint: sourceHint,
          categorySuggestion: CategorySuggester.suggest(merchant),
          rawText: input.rawText,
          confidenceScore: confidence.score,
          confidenceLevel: confidence.level.name.toUpperCase(),
          parserName: parserName,
        ),
      ],
      parserName: parserName,
      parsedAt: DateTime.now(),
    );
  }

  String _sourceSuggestion(ParserInput input) {
    final text = input.fullText.toLowerCase();
    if (_looksLikeAmazonPayBalance(text)) return PaymentSourceType.cash;
    if (text.contains('upi')) return PaymentSourceType.upi;
    if (text.contains('card')) return PaymentSourceType.creditCard;
    if (input.sourceType == 'sms') return PaymentSourceType.bank;
    return PaymentSourceType.cash;
  }

  String? _sourceHint(ParserInput input) {
    final text = input.fullText.toLowerCase();
    if (_looksLikeAmazonPayBalance(text)) return 'amazonpay';
    return null;
  }

  bool _looksLikeAmazonPayBalance(String text) {
    return text.contains('amazon pay balance') ||
        text.contains('amazonpay') ||
        text.contains('apay balance') ||
        text.contains('using apay');
  }

  String? _extractPossibleProperNoun(String text) {
    final match = RegExp(
      r'\b([A-Z][A-Za-z]{2,}(?:\s+[A-Z][A-Za-z]{2,})?)\b',
    ).firstMatch(text);
    return match?.group(1);
  }
}
