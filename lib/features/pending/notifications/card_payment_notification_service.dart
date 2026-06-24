import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/logging/app_log_service.dart';
import '../../expenses/models/transaction_types.dart';
import '../data/pending_service.dart';
import '../parsing/bank_account_matcher.dart';
import '../parsing/parser_text_utils.dart';
import 'card_payment_pending_codec.dart';
import 'notification_payload.dart';

class CardPaymentNotification {
  const CardPaymentNotification({
    required this.kind,
    required this.amount,
    required this.transactionDate,
    required this.rawText,
    this.issuer,
    this.cardLast4,
    this.sourceHint,
    this.sourceAccountId,
    this.sourceTypeSuggestion,
    this.transactionRef,
    this.destinationCardId,
  });

  final String kind;
  final double amount;
  final DateTime transactionDate;
  final String rawText;
  final String? issuer;
  final String? cardLast4;
  final String? sourceHint;
  final int? sourceAccountId;
  final String? sourceTypeSuggestion;
  final String? transactionRef;
  final int? destinationCardId;

  String get merchantLabel {
    final issuerLabel = issuer?.trim();
    if (issuerLabel != null && issuerLabel.isNotEmpty && cardLast4 != null) {
      return '$issuerLabel Card XX$cardLast4';
    }
    if (issuerLabel != null && issuerLabel.isNotEmpty) {
      return '$issuerLabel Card Payment';
    }
    if (cardLast4 != null) return 'Card Payment XX$cardLast4';
    return 'Card Bill Payment';
  }

  CardPaymentPendingData toPendingData() {
    return CardPaymentPendingData(
      issuer: issuer,
      cardLast4: cardLast4,
      destinationCardId: destinationCardId,
      sourceHint: sourceHint,
      sourceAccountId: sourceAccountId,
      sourceTypeSuggestion: sourceTypeSuggestion,
      transactionRef: transactionRef,
      kinds: [kind],
    );
  }
}

class CardPaymentHandlingResult {
  const CardPaymentHandlingResult({
    required this.parsed,
    required this.action,
    this.pendingId,
    this.mergedIntoPendingId,
  });

  final CardPaymentNotification parsed;
  final String action;
  final int? pendingId;
  final int? mergedIntoPendingId;
}

class CardPaymentNotificationService {
  CardPaymentNotificationService({
    required AppDatabase database,
    required this._pendingService,
  }) : _db = database;

  final AppDatabase _db;
  final PendingService _pendingService;
  static const Duration _mergeWindow = Duration(minutes: 20);

  Future<CardPaymentHandlingResult?> handleIfCardPayment(
    NotificationPayload payload,
  ) async {
    final parsed = await parse(payload);
    if (parsed == null) return null;

    final existing = await _findExistingPending(parsed);
    if (existing != null) {
      await _mergeIntoPending(existing, parsed);
      await _log('mergedIntoPending', parsed, {'pendingId': existing.id});
      return CardPaymentHandlingResult(
        parsed: parsed,
        action: 'mergedIntoPending',
        mergedIntoPendingId: existing.id,
      );
    }

    final pendingId = await _pendingService.createPendingTransaction(
      amount: parsed.amount,
      merchant: parsed.merchantLabel,
      categorySuggestion: 'Transfer',
      paymentSourceTypeSuggestion:
          parsed.sourceTypeSuggestion ?? PaymentSourceType.bank,
      paymentSourceIdSuggestion: parsed.sourceAccountId,
      transactionDate: parsed.transactionDate,
      sourceType: 'cardPaymentNotification',
      rawText: CardPaymentPendingCodec.wrap(
        rawText: parsed.rawText,
        data: parsed.toPendingData(),
      ),
      confidenceScore: 0.98,
    );
    await _log('pendingCreated', parsed, {'pendingId': pendingId});
    return CardPaymentHandlingResult(
      parsed: parsed,
      action: 'pendingCreated',
      pendingId: pendingId,
    );
  }

  Future<CardPaymentNotification?> parse(NotificationPayload payload) async {
    final text = payload.combinedText;
    if (!ParserTextUtils.looksLikeCardPaymentSettlementMessage(text)) {
      return null;
    }

    final amount = ParserTextUtils.extractAmount(text);
    if (amount == null) return null;

    final parsedDateTime = ParserTextUtils.extractDateTime(
      text,
      payload.captureTime,
    );
    final date = parsedDateTime?.value ?? payload.captureTime;
    final lower = text.toLowerCase();
    final kind = _detectKind(lower);
    final issuer = _extractIssuer(text);
    final cardLast4 = _extractCardLast4(text);
    final sourceHint = ParserTextUtils.extractAccountHint(text);
    final sourceAccountId = await _matchSourceAccountId(sourceHint);
    final transactionRef = ParserTextUtils.extractTransactionReference(text);
    final sourceTypeSuggestion = sourceHint != null
        ? PaymentSourceType.bank
        : lower.contains('upi')
        ? PaymentSourceType.upi
        : PaymentSourceType.bank;
    final destinationCardId = await _matchDestinationCardId(
      issuer: issuer,
      cardLast4: cardLast4,
    );

    return CardPaymentNotification(
      kind: kind,
      amount: amount,
      transactionDate: date,
      rawText: text.trim(),
      issuer: issuer,
      cardLast4: cardLast4,
      sourceHint: sourceHint,
      sourceAccountId: sourceAccountId,
      sourceTypeSuggestion: sourceTypeSuggestion,
      transactionRef: transactionRef,
      destinationCardId: destinationCardId,
    );
  }

  Future<PendingTransaction?> _findExistingPending(
    CardPaymentNotification parsed,
  ) async {
    final start = parsed.transactionDate.subtract(_mergeWindow);
    final end = parsed.transactionDate.add(_mergeWindow);
    final rows =
        await (_db.select(_db.pendingTransactions)..where(
              (p) =>
                  p.status.equals('pending') &
                  p.sourceType.equals('cardPaymentNotification') &
                  p.transactionDate.isBiggerOrEqualValue(start) &
                  p.transactionDate.isSmallerOrEqualValue(end),
            ))
            .get();

    PendingTransaction? best;
    var bestScore = -1;
    for (final row in rows) {
      final score = _matchScore(parsed, row);
      if (score > bestScore) {
        bestScore = score;
        best = row;
      }
    }
    return bestScore >= 3 ? best : null;
  }

  int _matchScore(CardPaymentNotification parsed, PendingTransaction row) {
    final data = CardPaymentPendingCodec.tryDecode(row.rawText);
    if (data == null) return -1;

    final ref = _normalize(parsed.transactionRef);
    final rowRef = _normalize(data.transactionRef);
    if (ref != null && rowRef != null && ref == rowRef) return 100;

    final amountDiff = (parsed.amount - row.amount).abs();
    var score = amountDiff <= 0.01
        ? 3
        : amountDiff <= 10
        ? 1
        : -10;

    final issuer = _normalize(parsed.issuer);
    final rowIssuer = _normalize(data.issuer);
    if (issuer != null && rowIssuer != null && issuer == rowIssuer) {
      score += 2;
    }

    if (parsed.cardLast4 != null &&
        data.cardLast4 != null &&
        parsed.cardLast4 == data.cardLast4) {
      score += 3;
    }

    final sourceHint = _normalize(parsed.sourceHint);
    final rowSourceHint = _normalize(data.sourceHint);
    if (sourceHint != null &&
        rowSourceHint != null &&
        sourceHint == rowSourceHint) {
      score += 2;
    }

    if (parsed.sourceAccountId != null &&
        data.sourceAccountId != null &&
        parsed.sourceAccountId == data.sourceAccountId) {
      score += 2;
    }
    return score;
  }

  Future<void> _mergeIntoPending(
    PendingTransaction existing,
    CardPaymentNotification incoming,
  ) async {
    final current =
        CardPaymentPendingCodec.tryDecode(existing.rawText) ??
        const CardPaymentPendingData();
    final mergedKinds = <String>{
      ...current.kinds,
      incoming.kind,
    }.toList(growable: false);
    final merged = current.copyWith(
      issuer: incoming.issuer ?? current.issuer,
      cardLast4: incoming.cardLast4 ?? current.cardLast4,
      destinationCardId:
          incoming.destinationCardId ?? current.destinationCardId,
      sourceHint: incoming.sourceHint ?? current.sourceHint,
      sourceAccountId: incoming.sourceAccountId ?? current.sourceAccountId,
      sourceTypeSuggestion:
          incoming.sourceTypeSuggestion ?? current.sourceTypeSuggestion,
      transactionRef: incoming.transactionRef ?? current.transactionRef,
      kinds: mergedKinds,
    );

    final effectiveAmount = _preferredAmount(
      existingAmount: existing.amount,
      existingKinds: current.kinds,
      incoming: incoming,
    );
    final effectiveMerchant = _preferredMerchant(
      existingMerchant: existing.merchant,
      merged: merged,
    );
    final effectiveSourceType =
        merged.sourceTypeSuggestion ?? existing.paymentSourceTypeSuggestion;
    final nextRawText = CardPaymentPendingCodec.wrap(
      rawText: CardPaymentPendingCodec.appendAuditText(
        existing.rawText,
        incoming.rawText,
      ),
      data: merged,
    );

    await (_db.update(
      _db.pendingTransactions,
    )..where((p) => p.id.equals(existing.id))).write(
      PendingTransactionsCompanion(
        amount: Value(effectiveAmount),
        merchant: Value(effectiveMerchant),
        paymentSourceTypeSuggestion: Value(effectiveSourceType),
        paymentSourceIdSuggestion: Value(
          merged.sourceAccountId ?? existing.paymentSourceIdSuggestion,
        ),
        transactionDate: Value(
          incoming.transactionDate.isBefore(existing.transactionDate)
              ? incoming.transactionDate
              : existing.transactionDate,
        ),
        rawText: Value(nextRawText),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  double _preferredAmount({
    required double existingAmount,
    required List<String> existingKinds,
    required CardPaymentNotification incoming,
  }) {
    final existingPriority = _kindPriority(existingKinds);
    final incomingPriority = _kindPriority([incoming.kind]);
    if (incomingPriority > existingPriority) return incoming.amount;
    return existingAmount;
  }

  String _preferredMerchant({
    required String existingMerchant,
    required CardPaymentPendingData merged,
  }) {
    final next = CardPaymentNotification(
      kind: merged.kinds.isEmpty ? 'unknown' : merged.kinds.first,
      amount: 0,
      transactionDate: DateTime.now(),
      rawText: '',
      issuer: merged.issuer,
      cardLast4: merged.cardLast4,
    ).merchantLabel;
    if (existingMerchant == 'Card Bill Payment') return next;
    if (merged.cardLast4 != null &&
        !existingMerchant.contains(merged.cardLast4!)) {
      return next;
    }
    return existingMerchant;
  }

  int _kindPriority(List<String> kinds) {
    if (kinds.contains('destinationReceipt')) return 3;
    if (kinds.contains('processorProcessed')) return 2;
    if (kinds.contains('sourceDebit')) return 1;
    return 0;
  }

  String _detectKind(String lower) {
    if ((lower.contains('received towards your') ||
            lower.contains('payment received') ||
            lower.contains('bbps payment received') ||
            lower.contains('credit card payment received')) &&
        lower.contains('credit card')) {
      return 'destinationReceipt';
    }
    if (lower.contains('has been processed') ||
        lower.contains('paid instantly to')) {
      return 'processorProcessed';
    }
    return 'sourceDebit';
  }

  String? _extractCardLast4(String text) {
    final direct = RegExp(
      r'credit\s*card[^0-9]{0,20}(?:xx|x{2,}|[*-]{2,})[- ]?(\d{4})',
      caseSensitive: false,
    ).firstMatch(text);
    final directValue = direct?.group(1)?.trim();
    if (directValue != null && directValue.isNotEmpty) return directValue;

    final fallback = RegExp(
      r'card[^0-9]{0,20}(\d{4})',
      caseSensitive: false,
    ).firstMatch(text);
    return fallback?.group(1)?.trim();
  }

  String? _extractIssuer(String text) {
    final known = _issuerFromKnownBankTerms(text);
    if (known != null) return known;

    final toward = RegExp(
      r'towards\s+your\s+([A-Za-z0-9&.\- ]{2,32})\s+credit\s*card',
      caseSensitive: false,
    ).firstMatch(text);
    final towardClean = _cleanIssuer(toward?.group(1));
    if (towardClean != null) return towardClean;

    final onYour = RegExp(
      r'on\s+your\s+([A-Za-z0-9&.\- ]{2,32})\s+credit\s*card',
      caseSensitive: false,
    ).firstMatch(text);
    final onYourClean = _cleanIssuer(onYour?.group(1));
    if (onYourClean != null) return onYourClean;

    final paidTo = RegExp(
      r'paid\s+instantly\s+to\s+([A-Za-z0-9&.\- ]{2,32})',
      caseSensitive: false,
    ).firstMatch(text);
    final paidToClean = _cleanIssuer(paidTo?.group(1));
    if (paidToClean != null) return paidToClean;

    final upiHandle = RegExp(
      r'@([a-z]{2,}b)\b',
      caseSensitive: false,
    ).firstMatch(text);
    final handleBank = _issuerFromHandle(upiHandle?.group(1));
    if (handleBank != null) return handleBank;
    return null;
  }

  String? _issuerFromKnownBankTerms(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('icici')) return 'ICICI';
    if (lower.contains('hdfc')) return 'HDFC';
    if (lower.contains('axis')) return 'Axis';
    if (lower.contains('sbi')) return 'SBI';
    if (lower.contains('kotak')) return 'Kotak';
    if (lower.contains('indusind')) return 'IndusInd';
    if (lower.contains('yes bank') || lower.contains('yesbank')) {
      return 'Yes';
    }
    return null;
  }

  String? _issuerFromHandle(String? handle) {
    final value = handle?.toLowerCase().trim();
    if (value == null || value.isEmpty) return null;
    if (value == 'axisb') return 'Axis';
    if (value == 'hdfcb') return 'HDFC';
    if (value == 'sbib') return 'SBI';
    if (value == 'icicib') return 'ICICI';
    return null;
  }

  String? _cleanIssuer(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final cleaned = raw
        .replaceAll(
          RegExp(
            r'\b(that was fast|tap to check|check your latest bank balance|bank|credit|card)\b',
            caseSensitive: false,
          ),
          ' ',
        )
        .replaceAll(RegExp(r'[^A-Za-z0-9&.\- ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) return null;
    return cleaned
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  Future<int?> _matchDestinationCardId({
    required String? issuer,
    required String? cardLast4,
  }) async {
    final cards = cardLast4 == null
        ? await _db.select(_db.creditCards).get()
        : await (_db.select(
            _db.creditCards,
          )..where((c) => c.last4.equals(cardLast4))).get();
    if (cards.isEmpty) return null;
    if (issuer == null) {
      return cardLast4 != null && cards.length == 1 ? cards.first.id : null;
    }
    final issuerNorm = _normalize(issuer);
    final matches = cards
        .where((card) {
          final bank = _normalize(card.bankName);
          final nick = _normalize(card.nickname);
          return bank == issuerNorm ||
              nick == issuerNorm ||
              (bank?.contains(issuerNorm ?? '') ?? false) ||
              (nick?.contains(issuerNorm ?? '') ?? false);
        })
        .toList(growable: false);
    if (matches.length == 1) return matches.first.id;
    return null;
  }

  Future<int?> _matchSourceAccountId(String? sourceHint) async {
    final banks = await _db.select(_db.bankAccounts).get();
    return BankAccountMatcher.match(
      accounts: banks,
      sourceHint: sourceHint,
    ).accountId;
  }

  String? _normalize(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();
    if (normalized.isEmpty) return null;
    return normalized;
  }

  Future<void> _log(
    String action,
    CardPaymentNotification parsed,
    Map<String, Object?> extra,
  ) {
    return globalAppLogService.log(
      category: 'card_payment_notification',
      message: action,
      meta: <String, Object?>{
        'kind': parsed.kind,
        'amount': parsed.amount,
        'issuer': parsed.issuer,
        'cardLast4': parsed.cardLast4,
        'sourceHint': parsed.sourceHint,
        'sourceAccountId': parsed.sourceAccountId,
        'transactionRef': parsed.transactionRef,
        'destinationCardId': parsed.destinationCardId,
        'merchantLabel': parsed.merchantLabel,
        ...extra,
      },
    );
  }
}
