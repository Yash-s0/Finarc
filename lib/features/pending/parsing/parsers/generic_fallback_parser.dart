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
    final confidence = ParserConfidenceScorer.score(
      hasAmount: true,
      hasMerchant: merchant != 'Unknown Merchant',
      hasSourceHint: false,
      hasPatternMatch: false,
      hasDate: false,
      isFallback: true,
    );

    return ParserResult(
      candidates: [
        DetectedTransactionCandidate(
          amount: amount,
          merchant: merchant,
          transactionDate: input.receivedAt,
          sourceType: input.sourceType,
          paymentSourceTypeSuggestion: suggestion,
          paymentSourceHint: null,
          categorySuggestion: CategorySuggester.suggest(merchant),
          rawText: input.rawText,
          confidenceScore: confidence,
          parserName: parserName,
        ),
      ],
      parserName: parserName,
      parsedAt: DateTime.now(),
    );
  }

  String _sourceSuggestion(ParserInput input) {
    final text = input.fullText.toLowerCase();
    if (text.contains('upi')) return PaymentSourceType.upi;
    if (text.contains('card')) return PaymentSourceType.creditCard;
    if (input.sourceType == 'sms') return PaymentSourceType.bank;
    return PaymentSourceType.cash;
  }

  String? _extractPossibleProperNoun(String text) {
    final match = RegExp(
      r'\b([A-Z][A-Za-z]{2,}(?:\s+[A-Z][A-Za-z]{2,})?)\b',
    ).firstMatch(text);
    return match?.group(1);
  }
}
