import '../../../expenses/models/transaction_types.dart';
import '../category_suggester.dart';
import '../merchant_normalizer.dart';
import '../parser_confidence_scorer.dart';
import '../parser_models.dart';
import '../parser_text_utils.dart';
import '../transaction_parser.dart';

class GenericBankSmsParser implements TransactionParser {
  @override
  String get parserName => 'GenericBankSmsParser';

  @override
  bool canParse(ParserInput input) {
    final t = input.fullText.toLowerCase();
    return input.sourceType == 'sms' ||
        t.contains('bank') ||
        t.contains('a/c') ||
        t.contains('card') ||
        t.contains('debited') ||
        t.contains('credited') ||
        t.contains('spent') ||
        t.contains('paid') ||
        t.contains('used') ||
        t.contains('txn') ||
        t.contains('transaction') ||
        t.contains('upi') ||
        t.contains('imps') ||
        t.contains('neft') ||
        t.contains('purchase');
  }

  @override
  ParserResult parse(ParserInput input) {
    final text = input.fullText;
    final amount = ParserTextUtils.extractAmount(text);
    if (amount == null) {
      return ParserResult(
        candidates: const [],
        warnings: const ['No amount detected in bank SMS pattern'],
        parserName: parserName,
        parsedAt: DateTime.now(),
      );
    }

    final merchantRaw = ParserTextUtils.extractMerchantAfterKeyword(text, [
      'at',
      'to',
      'via',
      'info:',
      'info',
      'on',
    ]);
    final merchant = MerchantNormalizer.normalize(
      merchantRaw ?? 'Unknown Merchant',
    );

    final hintLast4 = ParserTextUtils.extractLast4Hint(text);
    final date =
        ParserTextUtils.extractDate(text, input.receivedAt) ?? input.receivedAt;

    final sourceSuggestion = text.toLowerCase().contains('card')
        ? PaymentSourceType.creditCard
        : text.toLowerCase().contains('upi')
        ? PaymentSourceType.upi
        : PaymentSourceType.bank;

    final confidence = ParserConfidenceScorer.score(
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
          paymentSourceTypeSuggestion: sourceSuggestion,
          paymentSourceHint: hintLast4 == null ? null : 'ending $hintLast4',
          categorySuggestion: CategorySuggester.suggest(merchant),
          rawText: input.rawText,
          confidenceScore: confidence,
          parserName: parserName,
          metadata: {
            'sender': input.sender,
            'sourceSuggestion': sourceSuggestion,
          },
        ),
      ],
      parserName: parserName,
      parsedAt: DateTime.now(),
    );
  }
}
