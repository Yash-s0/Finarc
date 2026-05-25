import '../../../expenses/models/transaction_types.dart';
import '../category_suggester.dart';
import '../merchant_normalizer.dart';
import '../parser_confidence_scorer.dart';
import '../parser_models.dart';
import '../parser_text_utils.dart';
import '../transaction_parser.dart';

class UpiNotificationParser implements TransactionParser {
  @override
  String get parserName => 'UpiNotificationParser';

  @override
  bool canParse(ParserInput input) {
    final t = input.fullText.toLowerCase();
    return input.sourceType == 'upiNotification' ||
        t.contains('upi') ||
        t.contains('paid to') ||
        t.contains('sent to') ||
        t.contains('upi ref') ||
        t.contains('collect paid');
  }

  @override
  ParserResult parse(ParserInput input) {
    final text = input.fullText;
    final amount = ParserTextUtils.extractAmount(text);
    if (amount == null) {
      return ParserResult(
        candidates: const [],
        warnings: const ['No amount detected in UPI notification pattern'],
        parserName: parserName,
        parsedAt: DateTime.now(),
      );
    }

    final merchantRaw = ParserTextUtils.extractMerchantAfterKeyword(text, [
      'paid to',
      'sent to',
      'to',
      'for upi payment to',
      'collect paid to',
    ]);

    final merchant = MerchantNormalizer.normalize(
      merchantRaw ?? 'Unknown Merchant',
    );
    final date =
        ParserTextUtils.extractDate(text, input.receivedAt) ?? input.receivedAt;

    final confidence = ParserConfidenceScorer.score(
      hasAmount: true,
      hasMerchant: merchant != 'Unknown Merchant',
      hasSourceHint: text.toLowerCase().contains('upi ref'),
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
          paymentSourceTypeSuggestion: PaymentSourceType.upi,
          paymentSourceHint: text.toLowerCase().contains('upi ref')
              ? 'upi-ref-present'
              : null,
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
}
