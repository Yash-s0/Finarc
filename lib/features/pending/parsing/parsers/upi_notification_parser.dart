import '../../../expenses/models/transaction_types.dart';
import '../category_suggester.dart';
import '../merchant_normalizer.dart';
import '../parser_confidence_scorer.dart';
import '../parser_models.dart';
import '../parser_text_utils.dart';
import '../transaction_direction_classifier.dart';
import '../transaction_parser.dart';

class UpiNotificationParser implements TransactionParser {
  @override
  String get parserName => 'UpiNotificationParser';

  @override
  bool canParse(ParserInput input) {
    final t = input.fullText.toLowerCase();
    if (ParserTextUtils.looksLikeNonExpenseCardMessage(input.fullText)) {
      return false;
    }
    return input.sourceType == 'upiNotification' ||
        t.contains('upi') ||
        t.contains('paid to') ||
        t.contains('sent to') ||
        t.contains('upi ref') ||
        t.contains('collect paid');
  }

  @override
  ParserResult parse(ParserInput input) {
    if (ParserTextUtils.looksLikeNonExpenseCardMessage(input.fullText)) {
      return ParserResult(
        candidates: const [],
        warnings: const ['Skipped non-expense card message'],
        parserName: parserName,
        parsedAt: DateTime.now(),
      );
    }
    final text = input.fullText;
    final lower = text.toLowerCase();
    final amount = ParserTextUtils.extractAmount(text);
    if (amount == null) {
      return ParserResult(
        candidates: const [],
        warnings: const ['No amount detected in UPI notification pattern'],
        parserName: parserName,
        parsedAt: DateTime.now(),
      );
    }

    final direction = PendingDirectionClassifier.detect(text: text);
    final merchantRaw = _extractCounterpartyByDirection(text, direction);

    final merchant = MerchantNormalizer.normalize(
      merchantRaw ?? 'Unknown Merchant',
    );
    final parsedDateTime = ParserTextUtils.extractDateTime(
      text,
      input.captureTime,
    );
    final date = parsedDateTime?.value ?? input.captureTime;
    final hasTransactionAction =
        lower.contains('paid') ||
        lower.contains('sent') ||
        lower.contains('debited') ||
        lower.contains('credited') ||
        lower.contains('received') ||
        lower.contains('refunded') ||
        lower.contains('collect paid');

    final confidence = ParserConfidenceScorer.assess(
      hasAmount: true,
      hasMerchant: merchant != 'Unknown Merchant',
      hasSourceHint: text.toLowerCase().contains('upi ref'),
      hasPatternMatch: hasTransactionAction,
      hasDate: parsedDateTime?.hasDate == true,
      isFallback: false,
    );
    final accountHint = ParserTextUtils.extractAccountHint(text);
    final paymentSourceSuggestion = _paymentSourceSuggestion(
      text: text,
      direction: direction,
      accountHint: accountHint,
    );
    final categorySuggestion = _categoryForDirection(
      direction: direction,
      text: text,
      merchant: merchant,
    );
    final transactionRef = ParserTextUtils.extractTransactionReference(text);

    return ParserResult(
      candidates: [
        DetectedTransactionCandidate(
          amount: amount,
          merchant: merchant,
          transactionDate: date,
          sourceType: input.sourceType,
          paymentSourceTypeSuggestion: paymentSourceSuggestion,
          paymentSourceHint:
              accountHint ??
              (lower.contains('upi ref') ? 'upi-ref-present' : null),
          categorySuggestion: categorySuggestion,
          rawText: input.rawText,
          confidenceScore: confidence.score,
          confidenceLevel: confidence.level.name.toUpperCase(),
          parserName: parserName,
          metadata: {
            'direction': direction.name,
            'counterparty': merchant,
            'sender': input.sender ?? input.notificationTitle,
            'transactionRef': transactionRef,
            'hasParsedDate': parsedDateTime?.hasDate == true,
            'hasParsedTime': parsedDateTime?.hasTime == true,
          },
        ),
      ],
      parserName: parserName,
      parsedAt: DateTime.now(),
    );
  }

  String? _extractCounterpartyByDirection(
    String text,
    PendingTransactionDirection direction,
  ) {
    if (direction == PendingTransactionDirection.income) {
      return ParserTextUtils.extractMerchantAfterKeyword(text, [
        'from',
        'received from',
        'credited from',
      ]);
    }
    if (direction == PendingTransactionDirection.expense) {
      return ParserTextUtils.extractMerchantAfterKeyword(text, [
        'paid to',
        'sent to',
        'to',
        'for upi payment to',
        'collect paid to',
      ]);
    }
    return ParserTextUtils.extractMerchantAfterKeyword(text, [
      'to',
      'from',
      'paid to',
      'sent to',
    ]);
  }

  String _paymentSourceSuggestion({
    required String text,
    required PendingTransactionDirection direction,
    required String? accountHint,
  }) {
    final lower = text.toLowerCase();
    if (direction == PendingTransactionDirection.income &&
        accountHint != null) {
      return PaymentSourceType.bank;
    }
    if (lower.contains('upi')) {
      return PaymentSourceType.upi;
    }
    return PaymentSourceType.bank;
  }

  String _categoryForDirection({
    required PendingTransactionDirection direction,
    required String text,
    required String merchant,
  }) {
    final lower = text.toLowerCase();
    if (direction == PendingTransactionDirection.income) {
      if (lower.contains('salary') || lower.contains('payroll')) {
        return 'Income';
      }
      if (lower.contains('refund')) {
        return 'Refund';
      }
      return 'Transfer';
    }
    if (direction == PendingTransactionDirection.expense) {
      return 'Transfer';
    }
    return CategorySuggester.suggest(merchant);
  }
}
