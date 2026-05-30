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
    final t = input.fullText.toLowerCase();
    return t.contains('card') &&
        (t.contains('spent') ||
            t.contains('used for') ||
            t.contains('transaction on card') ||
            t.contains('authorization'));
  }

  @override
  ParserResult parse(ParserInput input) {
    final text = input.fullText;
    final amount = ParserTextUtils.extractAmount(text);
    if (amount == null) {
      return ParserResult(
        candidates: const [],
        warnings: const ['No amount detected in card notification pattern'],
        parserName: parserName,
        parsedAt: DateTime.now(),
      );
    }

    final merchantRaw = ParserTextUtils.extractMerchantAfterKeyword(text, [
      'at',
      'for',
      'on',
    ]);

    final merchant = MerchantNormalizer.normalize(
      merchantRaw ?? 'Unknown Merchant',
    );
    final hintLast4 = ParserTextUtils.extractLast4Hint(text);
    final date =
        ParserTextUtils.extractDate(text, input.receivedAt) ?? input.receivedAt;

    final confidence = ParserConfidenceScorer.assess(
      hasAmount: true,
      hasMerchant: merchant != 'Unknown Merchant',
      hasSourceHint: hintLast4 != null,
      hasPatternMatch: true,
      hasDate: ParserTextUtils.extractDate(text, input.receivedAt) != null,
      isFallback: false,
    );

    return ParserResult(
      candidates: [
        DetectedTransactionCandidate(
          amount: amount,
          merchant: merchant,
          transactionDate: date,
          sourceType: input.sourceType,
          paymentSourceTypeSuggestion: PaymentSourceType.creditCard,
          paymentSourceHint: hintLast4 == null
              ? null
              : 'card-ending-$hintLast4',
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
}
