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
    if (ParserTextUtils.looksLikeCardBillDueMessage(input.fullText) ||
        ParserTextUtils.looksLikeCardPaymentSettlementMessage(input.fullText)) {
      return false;
    }
    return t.contains('card') &&
        (t.contains('spent') ||
            t.contains('used for') ||
            t.contains('transaction on card') ||
            t.contains('authorization'));
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
    final parsedDateTime = ParserTextUtils.extractDateTime(
      text,
      input.captureTime,
    );
    final date = parsedDateTime?.value ?? input.captureTime;

    final confidence = ParserConfidenceScorer.assess(
      hasAmount: true,
      hasMerchant: merchant != 'Unknown Merchant',
      hasSourceHint: hintLast4 != null,
      hasPatternMatch: true,
      hasDate: parsedDateTime?.hasDate == true,
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
          metadata: {
            'hasParsedDate': parsedDateTime?.hasDate == true,
            'hasParsedTime': parsedDateTime?.hasTime == true,
          },
        ),
      ],
      parserName: parserName,
      parsedAt: DateTime.now(),
    );
  }
}
