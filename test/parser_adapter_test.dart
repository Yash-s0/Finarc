import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/features/expenses/data/transaction_engine.dart';
import 'package:finarc/features/pending/data/pending_service.dart';
import 'package:finarc/features/pending/parsing/category_suggester.dart';
import 'package:finarc/features/pending/parsing/counterparty_normalizer.dart';
import 'package:finarc/features/pending/parsing/merchant_normalizer.dart';
import 'package:finarc/features/pending/parsing/parser_confidence_scorer.dart';
import 'package:finarc/features/pending/parsing/parser_models.dart';
import 'package:finarc/features/pending/parsing/pending_ingestion_service.dart';
import 'package:finarc/features/pending/parsing/transaction_parser_registry.dart';
import 'package:finarc/features/pending/parsing/parsers/card_notification_parser.dart';
import 'package:finarc/features/pending/parsing/parsers/generic_bank_sms_parser.dart';
import 'package:finarc/features/pending/parsing/parsers/generic_fallback_parser.dart';
import 'package:finarc/features/pending/parsing/parsers/upi_notification_parser.dart';

void main() {
  late AppDatabase db;
  late PendingService pendingService;
  late TransactionParserRegistry registry;
  late PendingIngestionService ingestion;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    pendingService = PendingService(db, TransactionEngine(db));
    registry = TransactionParserRegistry(
      parsers: [
        UpiNotificationParser(),
        CardNotificationParser(),
        GenericBankSmsParser(),
      ],
      fallbackParser: GenericFallbackParser(),
    );
    ingestion = PendingIngestionService(db, pendingService, registry);

    await db
        .into(db.bankAccounts)
        .insert(
          BankAccountsCompanion.insert(
            bankName: 'Test Bank',
            accountName: 'Primary',
            accountType: 'savings',
            last4: const Value('7821'),
            currentBalance: const Value(50000),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  test('amount extraction and merchant extraction from bank SMS', () {
    final result = registry.parseInput(
      ParserInput(
        rawText:
            'INR 1499 spent on your HDFC Bank Credit Card XX1234 at SWIGGY on 24-May. Avl limit INR 50000.',
        sourceType: 'sms',
        receivedAt: DateTime(2026, 5, 24, 10, 0),
      ),
    );

    expect(result.candidates, isNotEmpty);
    final candidate = result.candidates.first;
    expect(candidate.amount, 1499);
    expect(candidate.merchant, 'Swiggy');
    expect(candidate.paymentSourceTypeSuggestion, 'creditCard');
    expect(candidate.paymentSourceHint, contains('1234'));
  });

  test('UPI recipient extraction works', () {
    final result = registry.parseInput(
      ParserInput(
        rawText:
            'Rs.700.00 debited from A/c XX7821 for UPI payment to Rahul Kumar. UPI Ref 123456789.',
        sourceType: 'upiNotification',
        receivedAt: DateTime(2026, 5, 24, 12, 0),
      ),
    );

    final candidate = result.candidates.first;
    expect(candidate.amount, 700);
    expect(candidate.merchant, 'Rahul Kumar');
    expect(candidate.paymentSourceTypeSuggestion, 'upi');
  });

  test('parses received upi alert as income with destination hint', () {
    final result = registry.parseInput(
      ParserInput(
        rawText:
            'Received Rs.1.00 in your Kotak Bank AC X0754 from yas21606-4@okaxis on 30-05-26. UPI Ref:651638004295.',
        sourceType: 'appNotification',
        packageName: 'com.google.android.apps.messaging',
        sender: 'VM-KOTAKB-S',
        receivedAt: DateTime(2026, 5, 30, 12, 0),
      ),
    );

    final candidate = result.candidates.first;
    expect(candidate.amount, 1);
    expect(candidate.merchant.toLowerCase(), contains('yas21606'));
    expect(candidate.merchant.toLowerCase(), contains('okaxis'));
    expect(candidate.categorySuggestion, 'Transfer');
    expect(candidate.paymentSourceTypeSuggestion, 'bank');
    expect(candidate.paymentSourceHint, contains('Kotak Bank AC X0754'));
    expect(candidate.metadata?['transactionRef'], '651638004295');
    expect(candidate.metadata?['direction'], 'income');
  });

  test('parses credited bank sender notification as income transfer', () {
    final result = registry.parseInput(
      ParserInput(
        rawText:
            'A/C *XX5661 credited by Rs 1.00 from yas21606-3@okaxis. RRN:615087788229. Avl Bal:3111.74.',
        sourceType: 'appNotification',
        packageName: 'com.google.android.apps.messaging',
        sender: 'AD-INDUSB-S',
        receivedAt: DateTime(2026, 5, 30, 12, 0),
      ),
    );

    final candidate = result.candidates.first;
    expect(candidate.amount, 1);
    expect(candidate.merchant.toLowerCase(), contains('yas21606'));
    expect(candidate.merchant.toLowerCase(), contains('okaxis'));
    expect(candidate.categorySuggestion, 'Transfer');
    expect(candidate.metadata?['transactionRef'], '615087788229');
    expect(candidate.metadata?['direction'], 'income');
  });

  test('parses sent upi alert with account hint', () {
    final result = registry.parseInput(
      ParserInput(
        rawText:
            'Sent Rs.1.00 from Kotak Bank AC X0754 to yas21606-4@okaxis on 30-05-26.UPI Ref 123938960566.',
        sourceType: 'appNotification',
        packageName: 'com.google.android.apps.messaging',
        sender: 'VM-KOTAKB-S',
        receivedAt: DateTime(2026, 5, 30, 12, 0),
      ),
    );

    final candidate = result.candidates.first;
    expect(candidate.amount, 1);
    expect(candidate.paymentSourceHint, contains('Kotak Bank AC X0754'));
    expect(candidate.metadata?['transactionRef'], '123938960566');
    expect(candidate.metadata?['direction'], 'expense');
    expect(candidate.categorySuggestion, 'Transfer');
  });

  test('parses salary transfer as income', () {
    final result = registry.parseInput(
      ParserInput(
        rawText:
            'Hi! Your Feb 2026 salary transfer of Rs 59,700 from Stackera has been initiated. - RazorpayX Payroll',
        sourceType: 'appNotification',
        packageName: 'com.google.android.apps.messaging',
        sender: 'CP-RZRPAY-S',
        receivedAt: DateTime(2026, 5, 30, 12, 0),
      ),
    );

    final candidate = result.candidates.first;
    expect(candidate.amount, 59700);
    expect(candidate.merchant.toLowerCase(), contains('stackera'));
    expect(candidate.categorySuggestion, 'Income');
    expect(candidate.metadata?['direction'], 'income');
  });

  test('splits two references into two candidates', () {
    final result = registry.parseInput(
      ParserInput(
        rawText:
            'A/C *XX5661 credited by Rs 1.00 from yas21606-3@okaxis. RRN:615087788229. '
            'A/C *XX5661 credited by Rs 1.00 from yas21606-3@okhdfcbank. RRN:123938960566.',
        sourceType: 'appNotification',
        packageName: 'com.google.android.apps.messaging',
        sender: 'AD-INDUSB-S',
        receivedAt: DateTime(2026, 5, 30, 12, 0),
      ),
    );

    expect(result.candidates.length, 2);
    expect(result.candidates[0].metadata?['transactionRef'], '615087788229');
    expect(result.candidates[1].metadata?['transactionRef'], '123938960566');
  });

  test('card parser extracts merchant and last4 hint', () {
    final result = registry.parseInput(
      ParserInput(
        rawText:
            'Your SBI Credit Card ending 4567 was used for INR 2999 at AMAZON.',
        sourceType: 'appNotification',
        receivedAt: DateTime(2026, 5, 24, 13, 0),
      ),
    );

    final candidate = result.candidates.first;
    expect(candidate.amount, 2999);
    expect(candidate.merchant, 'Amazon');
    expect(candidate.paymentSourceTypeSuggestion, 'creditCard');
    expect(candidate.paymentSourceHint, contains('4567'));
  });

  test('card parser extracts Axis style merchant from timestamp line', () {
    final result = registry.parseInput(
      ParserInput(
        rawText:
            'Spent INR 33275.73\n'
            'Axis Bank Card no. XX0374\n'
            '07-07-26 13:04:46 IST\n'
            'TRAVELPORTAL\n'
            'Avl Limit: INR 114844.17\n'
            'Not you? SMS BLOCK 0374 to 919951860002',
        sourceType: 'sms',
        receivedAt: DateTime(2026, 7, 7, 13, 4),
      ),
    );

    expect(result.parserName, 'CardNotificationParser');
    final candidate = result.candidates.single;
    expect(candidate.amount, 33275.73);
    expect(candidate.merchant, 'Travelportal');
    expect(candidate.paymentSourceHint, contains('0374'));
    expect(candidate.transactionDate, DateTime(2026, 7, 7, 13, 4, 46));
    expect(
      candidate.metadata?['merchantExtractionStrategy'],
      'line-after-timestamp',
    );
    expect(
      candidate.metadata?['amountExtractionStrategy'],
      'nearest-spend-action',
    );
    expect(candidate.metadata?['cardLast4'], '0374');
    expect(candidate.metadata?['hasParsedDate'], isTrue);
    expect(candidate.metadata?['hasParsedTime'], isTrue);
  });

  test('card parser extracts YES style merchant from UPI descriptor', () {
    final result = registry.parseInput(
      ParserInput(
        rawText:
            'INR 20,929.19 spent on YES BANK\n'
            'Card X8731 @UPI_HOTELBOOKING\n'
            'PAYMENTS IN 07-07-2026\n'
            '01:08:48 pm. Avl Lmt INR\n'
            '35,645.51. SMS BLKCC 8731 to\n'
            '9840909000 if not you',
        sourceType: 'sms',
        receivedAt: DateTime(2026, 7, 7, 13, 8),
      ),
    );

    expect(result.parserName, 'CardNotificationParser');
    final candidate = result.candidates.single;
    expect(candidate.amount, 20929.19);
    expect(candidate.merchant, 'Hotelbooking');
    expect(candidate.paymentSourceHint, contains('8731'));
    expect(candidate.transactionDate, DateTime(2026, 7, 7, 13, 8, 48));
    expect(candidate.metadata?['merchantExtractionStrategy'], 'upi-descriptor');
  });

  test('card parser extracts ICICI style merchant after date keyword', () {
    final result = registry.parseInput(
      ParserInput(
        rawText:
            'INR 328 spent using ICICI Bank Card XX9000 on 04-Jul-26 '
            'on AMAZON PAY IN E. Avl Limit: INR 48,347.00. '
            'If not you, call 1800 2662/SMS BLOCK 9000 to 9215676766.',
        sourceType: 'sms',
        receivedAt: DateTime(2026, 7, 4, 12, 50),
      ),
    );

    expect(result.parserName, 'CardNotificationParser');
    final candidate = result.candidates.single;
    expect(candidate.amount, 328);
    expect(candidate.merchant, 'Amazon');
    expect(candidate.paymentSourceHint, contains('9000'));
    expect(candidate.transactionDate, DateTime(2026, 7, 4, 12, 50));
    expect(
      candidate.metadata?['merchantExtractionStrategy'],
      'merchant-keyword',
    );
  });

  test('card parser creates fallback merchant when merchant is absent', () {
    final result = registry.parseInput(
      ParserInput(
        rawText:
            'INR 9999 spent using Test Bank Card XX1234 on 07-07-26 '
            '10:11:12 IST. Avl Limit: INR 50,000.',
        sourceType: 'sms',
        receivedAt: DateTime(2026, 7, 7, 10, 11),
      ),
    );

    expect(result.parserName, 'CardNotificationParser');
    final candidate = result.candidates.single;
    expect(candidate.amount, 9999);
    expect(candidate.merchant, 'Card spend XX1234');
    expect(candidate.confidenceLevel, 'MEDIUM');
    expect(
      candidate.metadata?['merchantExtractionStrategy'],
      'fallback-card-spend',
    );
  });

  test('non-expense card messages do not produce parser candidates', () {
    final samples = [
      'Axis Bank Card no. XX6865 Avl Limit: INR 147406.9. Not you? SMS BLOCK 6865.',
      'Dear Cardmember, transaction restriction setting(s) on your YES BANK Credit Card ending 8731 has been modified.',
      'URGENT: Bill Overdue! Credit card bill of ₹4,126.95 for Yes Bank card - 8731 was due on 4th Jul. Ignore if already paid!',
      'Payment of INR 1145 has been received towards your Axis Bank Credit Card XX0374 on 01-07-26 - Axis Bank',
    ];

    for (final sample in samples) {
      final result = registry.parseInput(
        ParserInput(
          rawText: sample,
          sourceType: 'sms',
          receivedAt: DateTime(2026, 7, 7, 12),
        ),
      );
      expect(result.candidates, isEmpty, reason: sample);
    }
  });

  test('merchant normalization maps known merchants', () {
    expect(MerchantNormalizer.normalize('SWIGGY INSTAMART UPI TXN'), 'Swiggy');
    expect(MerchantNormalizer.normalize('AMAZON PAY INFO'), 'Amazon');
    expect(MerchantNormalizer.normalize('DOMINOS CARD PAYMENT'), "Domino's");
  });

  test('counterparty normalization matches UPI handle variants', () {
    expect(
      CounterpartyNormalizer.isSameOrNearMatch(
        'Yas21606 4 Okaxis',
        'yas21606-4@okaxis',
      ),
      isTrue,
    );
    expect(
      CounterpartyNormalizer.isSameOrNearMatch(
        'yas21606 4@okaxis',
        'yas21606-4@okaxis',
      ),
      isTrue,
    );
  });

  test('category suggestion returns mapped categories', () {
    expect(CategorySuggester.suggest('Swiggy'), 'Food');
    expect(CategorySuggester.suggest('Amazon Marketplace'), 'Shopping');
    expect(CategorySuggester.suggest('Uber Ride'), 'Travel');
    expect(CategorySuggester.suggest('Blinkit Order'), 'Groceries');
    expect(CategorySuggester.suggest('Airtel Recharge'), 'Bills');
    expect(CategorySuggester.suggest('Unknown Merchant'), 'Others');
  });

  test('confidence scoring tiers behave as expected', () {
    final high = ParserConfidenceScorer.assess(
      hasAmount: true,
      hasMerchant: true,
      hasSourceHint: true,
      hasPatternMatch: true,
      hasDate: true,
      isFallback: false,
    );
    final medium = ParserConfidenceScorer.assess(
      hasAmount: true,
      hasMerchant: false,
      hasSourceHint: false,
      hasPatternMatch: true,
      hasDate: false,
      isFallback: false,
    );
    final low = ParserConfidenceScorer.assess(
      hasAmount: true,
      hasMerchant: false,
      hasSourceHint: false,
      hasPatternMatch: false,
      hasDate: false,
      isFallback: true,
    );

    expect(high.score, greaterThanOrEqualTo(0.85));
    expect(high.level.name.toUpperCase(), 'HIGH');
    expect(medium.score, inInclusiveRange(0.55, 0.75));
    expect(medium.level.name.toUpperCase(), 'MEDIUM');
    expect(low.score, inInclusiveRange(0.40, 0.60));
    expect(low.level.name.toUpperCase(), 'LOW');
  });

  test('pending ingestion creates pending transaction records', () async {
    final ids = await ingestion.ingestParserInput(
      ParserInput(
        rawText: 'Paid ₹250 to Zomato via UPI.',
        sourceType: 'upiNotification',
        receivedAt: DateTime(2026, 5, 24, 14, 0),
      ),
    );

    expect(ids.length, 1);
    final pending = await (db.select(
      db.pendingTransactions,
    )..where((p) => p.id.equals(ids.first))).getSingle();
    expect(pending.status, 'pending');
    expect(pending.merchant, 'Zomato');
    expect(pending.amount, 250);
  });

  test(
    'pending ingestion auto-matches bank source by last4 when available',
    () async {
      await db
          .into(db.bankAccounts)
          .insert(
            BankAccountsCompanion.insert(
              bankName: 'Kotak',
              accountName: 'Salary',
              accountType: 'savings',
              last4: const Value('0754'),
              currentBalance: const Value(20000),
            ),
          );

      final ids = await ingestion.ingestParserInput(
        ParserInput(
          rawText:
              'Sent Rs.1.00 from Kotak Bank AC X0754 to yas21606-4@okaxis on 30-05-26. UPI Ref 123938960566.',
          sourceType: 'appNotification',
          packageName: 'com.google.android.apps.messaging',
          sender: 'VM-KOTAKB-S',
          receivedAt: DateTime(2026, 5, 30, 12, 0),
        ),
      );

      expect(ids, hasLength(1));
      final pending = await (db.select(
        db.pendingTransactions,
      )..where((p) => p.id.equals(ids.first))).getSingle();
      expect(pending.paymentSourceIdSuggestion, 2);
      expect(pending.rawText, contains('X0754'));
    },
  );

  test('fallback parser produces low-confidence candidate', () {
    final result = registry.parseInput(
      ParserInput(
        rawText: 'Amount ₹1200 captured',
        sourceType: 'manualImport',
        receivedAt: DateTime(2026, 5, 24, 15, 0),
      ),
    );

    expect(result.parserName, 'GenericFallbackParser');
    expect(result.candidates, isNotEmpty);
    expect(result.candidates.first.confidenceScore, lessThanOrEqualTo(0.60));
    expect(result.candidates.first.confidenceLevel, 'LOW');
  });

  test('low-confidence candidates are skipped from pending creation', () async {
    final ids = await ingestion.ingestParserInput(
      ParserInput(
        rawText: '₹1200',
        sourceType: 'appNotification',
        receivedAt: DateTime(2026, 5, 24, 16, 0),
      ),
    );

    expect(ids, isEmpty);
  });
}
