import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/features/expenses/data/transaction_engine.dart';
import 'package:finarc/features/pending/data/pending_service.dart';
import 'package:finarc/features/pending/parsing/category_suggester.dart';
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

  test('merchant normalization maps known merchants', () {
    expect(MerchantNormalizer.normalize('SWIGGY INSTAMART UPI TXN'), 'Swiggy');
    expect(MerchantNormalizer.normalize('AMAZON PAY INFO'), 'Amazon');
    expect(MerchantNormalizer.normalize('DOMINOS CARD PAYMENT'), "Domino's");
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
    final high = ParserConfidenceScorer.score(
      hasAmount: true,
      hasMerchant: true,
      hasSourceHint: true,
      hasPatternMatch: true,
      hasDate: true,
      isFallback: false,
    );
    final medium = ParserConfidenceScorer.score(
      hasAmount: true,
      hasMerchant: true,
      hasSourceHint: false,
      hasPatternMatch: false,
      hasDate: false,
      isFallback: false,
    );
    final low = ParserConfidenceScorer.score(
      hasAmount: true,
      hasMerchant: false,
      hasSourceHint: false,
      hasPatternMatch: false,
      hasDate: false,
      isFallback: true,
    );

    expect(high, greaterThanOrEqualTo(0.85));
    expect(medium, inInclusiveRange(0.65, 0.80));
    expect(low, inInclusiveRange(0.40, 0.60));
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
  });
}
