import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/logging/app_log_service.dart';
import '../../../core/utils/formatters.dart';
import '../../alerts/data/alert_service.dart';
import '../../alerts/data/alert_types.dart';
import '../../cards/data/billing_service.dart';
import 'notification_payload.dart';

class CardBillDueNotification {
  const CardBillDueNotification({
    required this.totalAmountDue,
    required this.minimumAmountDue,
    required this.dueDate,
    required this.cardLast4,
    required this.issuer,
    required this.rawText,
  });

  final double totalAmountDue;
  final double? minimumAmountDue;
  final DateTime dueDate;
  final String cardLast4;
  final String? issuer;
  final String rawText;
}

class CardBillDueHandlingResult {
  const CardBillDueHandlingResult({
    required this.parsed,
    required this.action,
    this.matchedCardId,
    this.alertCreated = false,
  });

  final CardBillDueNotification parsed;
  final String action;
  final int? matchedCardId;
  final bool alertCreated;
}

class CardBillDueNotificationService {
  CardBillDueNotificationService({
    required AppDatabase database,
    AlertService? alertService,
    BillingService? billingService,
    DateTime Function()? now,
  }) : _db = database,
       _alertService = alertService ?? AlertService(database),
       _billingService = billingService ?? BillingService(database, now: now),
       _now = now ?? DateTime.now;

  final AppDatabase _db;
  final AlertService _alertService;
  final BillingService _billingService;
  final DateTime Function() _now;

  static final RegExp _totalDuePattern = RegExp(
    r'(?:pay\s+)?total\s+amount\s+due(?:\s+of)?(?:\s+is)?\s*(?:inr|rs\.?|₹)\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );
  static final RegExp _minimumDuePattern = RegExp(
    r'minimum\s+amount\s+due(?:\s+of)?(?:\s+is)?\s*(?:inr|rs\.?|₹)\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );
  static final RegExp _genericAmountDuePattern = RegExp(
    r'amount\s+due(?:\s+of)?(?:\s+is)?\s*(?:inr|rs\.?|₹)\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );
  static final RegExp _last4Pattern = RegExp(
    r'(?:credit\s*card|card)[^0-9]{0,24}(?:ending\s*|xx|x{2,}|\*{2,})?(\d{4})',
    caseSensitive: false,
  );

  static const List<String> _months = [
    'jan',
    'feb',
    'mar',
    'apr',
    'may',
    'jun',
    'jul',
    'aug',
    'sep',
    'oct',
    'nov',
    'dec',
  ];

  CardBillDueNotification? parse(NotificationPayload payload) {
    final text = payload.combinedText;
    if (!_isBillDueMessage(text)) return null;

    final totalAmountDue =
        _extractAmount(text, _totalDuePattern) ??
        _extractGenericAmountDue(text);
    final minimumAmountDue = _extractAmount(text, _minimumDuePattern);
    final dueDate = _extractDueDate(text, payload.captureTime);
    final cardLast4 = _extractCardLast4(text);
    final issuer = _extractIssuer(text);

    if (totalAmountDue == null || dueDate == null || cardLast4 == null) {
      return null;
    }

    return CardBillDueNotification(
      totalAmountDue: totalAmountDue,
      minimumAmountDue: minimumAmountDue,
      dueDate: _dateOnly(dueDate),
      cardLast4: cardLast4,
      issuer: issuer,
      rawText: text,
    );
  }

  Future<CardBillDueHandlingResult?> handleIfBillDue(
    NotificationPayload payload,
  ) async {
    final parsed = parse(payload);
    if (parsed == null) return null;

    final dedupeKey = _notificationDedupeKey(parsed);
    if (await _hasProcessedNotification(dedupeKey)) {
      await _logAction(
        parsed,
        action: 'ignoredDuplicate',
        meta: {'dedupeKey': dedupeKey},
      );
      return CardBillDueHandlingResult(
        parsed: parsed,
        action: 'ignoredDuplicate',
      );
    }

    final matchedCards = await _findMatchingCards(parsed);
    if (matchedCards.isEmpty) {
      final created = await _createNoMatchingCardAlert(
        parsed,
        dedupeKey: dedupeKey,
      );
      await _logAction(
        parsed,
        action: 'noMatchingCard',
        meta: {'dedupeKey': dedupeKey},
      );
      return CardBillDueHandlingResult(
        parsed: parsed,
        action: 'noMatchingCard',
        alertCreated: created,
      );
    }

    if (matchedCards.length > 1) {
      final created = await _createMultipleCardAlert(
        parsed,
        matchedCards,
        dedupeKey: dedupeKey,
      );
      await _logAction(
        parsed,
        action: 'multipleMatchingCards',
        meta: {
          'dedupeKey': dedupeKey,
          'matchedCardIds': matchedCards.map((c) => c.id).toList(),
        },
      );
      return CardBillDueHandlingResult(
        parsed: parsed,
        action: 'multipleMatchingCards',
        alertCreated: created,
      );
    }

    final card = matchedCards.first;
    final bills =
        await (_db.select(_db.cardBills)
              ..where((b) => b.cardId.equals(card.id))
              ..orderBy([(b) => OrderingTerm.desc(b.billingDate)]))
            .get();

    final unpaidBill = _findBestBillForCycle(
      bills,
      parsed.dueDate,
      predicate: (bill) => !_isBillPaidLike(bill),
    );
    if (unpaidBill != null) {
      final action = await _handleAgainstUnpaidBill(
        card: card,
        bill: unpaidBill,
        parsed: parsed,
        dedupeKey: dedupeKey,
      );
      return CardBillDueHandlingResult(
        parsed: parsed,
        action: action,
        matchedCardId: card.id,
        alertCreated: true,
      );
    }

    final paidBill = _findBestBillForCycle(
      bills,
      parsed.dueDate,
      predicate: _isBillPaidLike,
    );
    if (paidBill != null) {
      final action = await _handleAgainstPaidBill(
        card: card,
        bill: paidBill,
        parsed: parsed,
        dedupeKey: dedupeKey,
      );
      return CardBillDueHandlingResult(
        parsed: parsed,
        action: action,
        matchedCardId: card.id,
        alertCreated: true,
      );
    }

    final action = await _createExternalBillFromNotification(
      card: card,
      parsed: parsed,
      dedupeKey: dedupeKey,
    );
    return CardBillDueHandlingResult(
      parsed: parsed,
      action: action,
      matchedCardId: card.id,
      alertCreated: true,
    );
  }

  Future<String> _handleAgainstUnpaidBill({
    required CreditCard card,
    required CardBill bill,
    required CardBillDueNotification parsed,
    required String dedupeKey,
  }) async {
    final amountDiff = (bill.billedAmount - parsed.totalAmountDue).abs();
    final issuer = _issuerDisplay(parsed, card);
    if (amountDiff <= 1) {
      final dueDateChanged =
          _dateOnly(bill.dueDate) != _dateOnly(parsed.dueDate);
      if (dueDateChanged) {
        final nextStatus = _billingService.getDueStatusFromDate(
          isPaid: false,
          dueDate: parsed.dueDate,
          now: _now(),
        );
        await (_db.update(
          _db.cardBills,
        )..where((b) => b.id.equals(bill.id))).write(
          CardBillsCompanion(
            dueDate: Value(parsed.dueDate),
            status: Value(nextStatus),
          ),
        );
      }

      await _alertService.createAlert(
        CreateAlertInput(
          alertType: AlertType.cardDue,
          title:
              '$issuer bill verified: ${inr(parsed.totalAmountDue)} due ${_dayMonth(parsed.dueDate)}',
          body:
              'Matched with existing unpaid bill for card XX${parsed.cardLast4}.',
          priority: AlertPriority.info,
          actionRoute: '/cards/${card.id}',
          dedupeKey: dedupeKey,
          payload: {
            'kind': 'cardBillDueNotification',
            'action': dueDateChanged ? 'updatedDueDate' : 'verified',
            'cardId': card.id,
            'billId': bill.id,
            'totalAmountDue': parsed.totalAmountDue,
            'minimumAmountDue': parsed.minimumAmountDue,
            'dueDate': parsed.dueDate.toIso8601String(),
            'last4': parsed.cardLast4,
            'issuer': parsed.issuer,
            'source': 'verifiedFromNotification',
          },
        ),
        dedupeWindow: const Duration(days: 90),
      );

      final action = dueDateChanged ? 'updatedDueDate' : 'verified';
      await _logAction(
        parsed,
        cardId: card.id,
        billId: bill.id,
        action: action,
        meta: {'dedupeKey': dedupeKey},
      );
      return action;
    }

    await _alertService.createAlert(
      CreateAlertInput(
        alertType: AlertType.cardDue,
        title: '$issuer bill amount mismatch',
        body:
            'App: ${inr(bill.billedAmount)}\nNotification: ${inr(parsed.totalAmountDue)}\nPlease review card XX${parsed.cardLast4}.',
        priority: AlertPriority.warning,
        actionRoute: '/cards/${card.id}',
        dedupeKey: dedupeKey,
        payload: {
          'kind': 'cardBillDueNotification',
          'action': 'mismatchAlert',
          'cardId': card.id,
          'billId': bill.id,
          'appAmount': bill.billedAmount,
          'notificationAmount': parsed.totalAmountDue,
          'dueDate': parsed.dueDate.toIso8601String(),
          'last4': parsed.cardLast4,
          'issuer': parsed.issuer,
        },
      ),
      dedupeWindow: const Duration(days: 90),
    );

    await _logAction(
      parsed,
      cardId: card.id,
      billId: bill.id,
      action: 'mismatchAlert',
      meta: {
        'appAmount': bill.billedAmount,
        'notificationAmount': parsed.totalAmountDue,
        'dedupeKey': dedupeKey,
      },
    );
    return 'mismatchAlert';
  }

  Future<String> _handleAgainstPaidBill({
    required CreditCard card,
    required CardBill bill,
    required CardBillDueNotification parsed,
    required String dedupeKey,
  }) async {
    final amountDiff = (bill.billedAmount - parsed.totalAmountDue).abs();
    final isMatch = amountDiff <= 1;

    await _alertService.createAlert(
      CreateAlertInput(
        alertType: AlertType.cardDue,
        title: isMatch
            ? 'Paid bill notification matches your record'
            : 'Paid bill amount differs from notification',
        body: isMatch
            ? '${_issuerDisplay(parsed, card)} XX${parsed.cardLast4} • ${inr(parsed.totalAmountDue)} due ${_dayMonth(parsed.dueDate)}'
            : 'App: ${inr(bill.billedAmount)}\nNotification: ${inr(parsed.totalAmountDue)}\nPlease review card XX${parsed.cardLast4}.',
        priority: isMatch ? AlertPriority.info : AlertPriority.warning,
        actionRoute: '/cards/${card.id}',
        dedupeKey: dedupeKey,
        payload: {
          'kind': 'cardBillDueNotification',
          'action': isMatch ? 'paidBillVerified' : 'paidBillMismatch',
          'cardId': card.id,
          'billId': bill.id,
          'appAmount': bill.billedAmount,
          'notificationAmount': parsed.totalAmountDue,
          'dueDate': parsed.dueDate.toIso8601String(),
          'last4': parsed.cardLast4,
          'issuer': parsed.issuer,
        },
      ),
      dedupeWindow: const Duration(days: 90),
    );

    final action = isMatch ? 'paidBillVerified' : 'paidBillMismatch';
    await _logAction(
      parsed,
      cardId: card.id,
      billId: bill.id,
      action: action,
      meta: {
        'appAmount': bill.billedAmount,
        'notificationAmount': parsed.totalAmountDue,
        'dedupeKey': dedupeKey,
      },
    );
    return action;
  }

  Future<String> _createExternalBillFromNotification({
    required CreditCard card,
    required CardBillDueNotification parsed,
    required String dedupeKey,
  }) async {
    final dueDate = _dateOnly(parsed.dueDate);
    final billingDate = dueDate.subtract(const Duration(days: 1));
    final cycleEndDate = billingDate.subtract(const Duration(days: 1));
    final cycleStartDate = cycleEndDate.subtract(const Duration(days: 29));
    final status = _billingService.getDueStatusFromDate(
      isPaid: false,
      dueDate: dueDate,
      now: _now(),
    );

    final billId = await _db
        .into(_db.cardBills)
        .insert(
          CardBillsCompanion.insert(
            cardId: card.id,
            cycleStartDate: Value(cycleStartDate),
            cycleEndDate: Value(cycleEndDate),
            billingDate: Value(billingDate),
            billedAmount: parsed.totalAmountDue,
            paidAmount: const Value(0),
            dueDate: Value(dueDate),
            status: Value(status),
          ),
        );

    final estimatedLocalAmount = await _estimateLocalCycleAmount(
      card.id,
      dueDate,
    );
    final needsReview =
        (estimatedLocalAmount - parsed.totalAmountDue).abs() > 1;
    final issuer = _issuerDisplay(parsed, card);

    await _alertService.createAlert(
      CreateAlertInput(
        alertType: AlertType.cardDue,
        title: needsReview
            ? '$issuer bill captured from notification (review needed)'
            : '$issuer bill captured from notification',
        body: needsReview
            ? 'Detected ${inr(parsed.totalAmountDue)} due ${_dayMonth(dueDate)}. Local cycle estimate ${inr(estimatedLocalAmount)}. Please review.'
            : 'Detected ${inr(parsed.totalAmountDue)} due ${_dayMonth(dueDate)} for card XX${parsed.cardLast4}.',
        priority: needsReview ? AlertPriority.warning : AlertPriority.info,
        actionRoute: '/cards/${card.id}',
        dedupeKey: dedupeKey,
        payload: {
          'kind': 'cardBillDueNotification',
          'action': 'createdExternalBill',
          'cardId': card.id,
          'billId': billId,
          'totalAmountDue': parsed.totalAmountDue,
          'minimumAmountDue': parsed.minimumAmountDue,
          'dueDate': dueDate.toIso8601String(),
          'last4': parsed.cardLast4,
          'issuer': parsed.issuer,
          'source': 'notification',
          'needsReview': needsReview,
          'estimatedLocalAmount': estimatedLocalAmount,
        },
      ),
      dedupeWindow: const Duration(days: 90),
    );

    await _logAction(
      parsed,
      cardId: card.id,
      billId: billId,
      action: 'createdExternalBill',
      meta: {
        'needsReview': needsReview,
        'estimatedLocalAmount': estimatedLocalAmount,
        'dedupeKey': dedupeKey,
      },
    );
    return 'createdExternalBill';
  }

  Future<bool> _createNoMatchingCardAlert(
    CardBillDueNotification parsed, {
    required String dedupeKey,
  }) async {
    final alert = await _alertService.createAlert(
      CreateAlertInput(
        alertType: AlertType.cardDue,
        title: 'Card bill detected but no matching card found',
        body:
            '${_issuerDisplay(parsed, null)} XX${parsed.cardLast4} • ${inr(parsed.totalAmountDue)} due ${_dayMonth(parsed.dueDate)}',
        priority: AlertPriority.warning,
        dedupeKey: dedupeKey,
        payload: {
          'kind': 'cardBillDueNotification',
          'action': 'noMatchingCard',
          'totalAmountDue': parsed.totalAmountDue,
          'minimumAmountDue': parsed.minimumAmountDue,
          'dueDate': parsed.dueDate.toIso8601String(),
          'last4': parsed.cardLast4,
          'issuer': parsed.issuer,
        },
      ),
      dedupeWindow: const Duration(days: 90),
    );
    return alert != null;
  }

  Future<bool> _createMultipleCardAlert(
    CardBillDueNotification parsed,
    List<CreditCard> cards, {
    required String dedupeKey,
  }) async {
    final alert = await _alertService.createAlert(
      CreateAlertInput(
        alertType: AlertType.cardDue,
        title: 'Card bill detected: multiple matching cards found',
        body:
            '${_issuerDisplay(parsed, null)} XX${parsed.cardLast4} • ${inr(parsed.totalAmountDue)} due ${_dayMonth(parsed.dueDate)}. Please review.',
        priority: AlertPriority.warning,
        dedupeKey: dedupeKey,
        payload: {
          'kind': 'cardBillDueNotification',
          'action': 'multipleMatchingCards',
          'totalAmountDue': parsed.totalAmountDue,
          'minimumAmountDue': parsed.minimumAmountDue,
          'dueDate': parsed.dueDate.toIso8601String(),
          'last4': parsed.cardLast4,
          'issuer': parsed.issuer,
          'cardIds': cards.map((c) => c.id).toList(),
        },
      ),
      dedupeWindow: const Duration(days: 90),
    );
    return alert != null;
  }

  Future<List<CreditCard>> _findMatchingCards(
    CardBillDueNotification parsed,
  ) async {
    final cards = await (_db.select(
      _db.creditCards,
    )..where((c) => c.last4.equals(parsed.cardLast4))).get();
    if (cards.isEmpty) return const [];

    final issuer = _normalize(parsed.issuer);
    if (issuer == null) return cards;

    final issuerMatches = cards
        .where((card) {
          final bank = _normalize(card.bankName) ?? '';
          final nickname = _normalize(card.nickname) ?? '';
          return bank.contains(issuer) || nickname.contains(issuer);
        })
        .toList(growable: false);

    return issuerMatches.isEmpty ? cards : issuerMatches;
  }

  CardBill? _findBestBillForCycle(
    List<CardBill> bills,
    DateTime dueDate, {
    required bool Function(CardBill bill) predicate,
  }) {
    final candidates = bills.where(predicate).toList(growable: false);
    if (candidates.isEmpty) return null;

    final sameMonth = candidates
        .where((bill) {
          final due = _dateOnly(bill.dueDate);
          return due.year == dueDate.year && due.month == dueDate.month;
        })
        .toList(growable: false);

    final pool = sameMonth.isNotEmpty ? sameMonth : candidates;
    final sorted = [...pool]
      ..sort((a, b) {
        final ad = _absDays(_dateOnly(a.dueDate), dueDate);
        final bd = _absDays(_dateOnly(b.dueDate), dueDate);
        if (ad != bd) return ad.compareTo(bd);
        return b.billingDate.compareTo(a.billingDate);
      });

    final best = sorted.first;
    if (_absDays(_dateOnly(best.dueDate), dueDate) > 45) return null;
    return best;
  }

  bool _isBillPaidLike(CardBill bill) {
    if (bill.status == 'paid' || bill.status == 'needsReview') return true;
    if (bill.billedAmount <= 0.009) return false;
    return bill.paidAmount >= bill.billedAmount;
  }

  Future<bool> _hasProcessedNotification(String dedupeKey) async {
    final cutoff = _now().subtract(const Duration(days: 90));
    final existing =
        await (_db.select(_db.alerts)
              ..where(
                (a) =>
                    a.dedupeKey.equals(dedupeKey) &
                    a.createdAt.isBiggerOrEqualValue(cutoff),
              )
              ..orderBy([(a) => OrderingTerm.desc(a.createdAt)])
              ..limit(1))
            .getSingleOrNull();
    return existing != null;
  }

  Future<double> _estimateLocalCycleAmount(int cardId, DateTime dueDate) async {
    final rangeStart = _dateOnly(dueDate.subtract(const Duration(days: 45)));
    final rangeEnd = _dateOnly(dueDate.subtract(const Duration(days: 1)));
    final txns =
        await (_db.select(_db.transactions)..where(
              (t) =>
                  t.paymentSourceType.equals('creditCard') &
                  t.paymentSourceId.equals(cardId) &
                  t.type.equals('creditCard') &
                  t.transactionDate.isBiggerOrEqualValue(rangeStart) &
                  t.transactionDate.isSmallerOrEqualValue(rangeEnd),
            ))
            .get();
    return txns.fold<double>(0, (sum, txn) => sum + txn.amount);
  }

  Future<void> _logAction(
    CardBillDueNotification parsed, {
    required String action,
    int? cardId,
    int? billId,
    Map<String, Object?> meta = const <String, Object?>{},
  }) async {
    await globalAppLogService.log(
      category: 'card_bill_due',
      message: action,
      meta: <String, Object?>{
        'issuer': parsed.issuer,
        'cardLast4': parsed.cardLast4,
        'totalAmountDue': parsed.totalAmountDue,
        'minimumAmountDue': parsed.minimumAmountDue,
        'dueDate': parsed.dueDate.toIso8601String(),
        'cardId': cardId,
        'billId': billId,
        ...meta,
      },
    );
  }

  bool _isBillDueMessage(String text) {
    final lower = text.toLowerCase();
    final dueKeywords = [
      'total amount due',
      'minimum amount due',
      'amount due',
      'pay total amount due',
      'due by',
      'due date',
    ];
    final cardKeywords = [
      'credit card xx',
      'credit card ending',
      'credit card',
    ];
    final complianceKeywords = [
      'ignore if paid',
      'delay/non-payment',
      'credit bureaus',
    ];

    final dueHits = dueKeywords.where(lower.contains).length;
    final hasCard =
        cardKeywords.any(lower.contains) ||
        RegExp(r'card\s*[x*]{2,}\d{4}', caseSensitive: false).hasMatch(text);
    final hasCompliance = complianceKeywords.any(lower.contains);

    if (!hasCard) return false;
    if (dueHits >= 2) return true;
    return dueHits >= 1 && hasCompliance;
  }

  double? _extractAmount(String text, RegExp pattern) {
    final match = pattern.firstMatch(text);
    final value = match?.group(1);
    return _toAmount(value);
  }

  double? _extractGenericAmountDue(String text) {
    for (final match in _genericAmountDuePattern.allMatches(text)) {
      final prefixStart = (match.start - 20).clamp(0, match.start);
      final prefix = text.substring(prefixStart, match.start).toLowerCase();
      if (prefix.contains('minimum') || prefix.contains('total')) {
        continue;
      }
      final value = _toAmount(match.group(1));
      if (value != null) return value;
    }
    return null;
  }

  double? _toAmount(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return double.tryParse(value.replaceAll(',', '').trim());
  }

  DateTime? _extractDueDate(String text, DateTime fallback) {
    final byOrDueMatch = RegExp(
      r'(?:due\s+date\s*[:\-]?|due\s+by|\bby)\s*(\d{1,2}[-/](?:[A-Za-z]{3}|\d{1,2})[-/](?:\d{2,4}))',
      caseSensitive: false,
    ).firstMatch(text);
    final token = byOrDueMatch?.group(1)?.trim();
    if (token != null) {
      final parsed = _parseDateToken(token, fallback.year);
      if (parsed != null) return parsed;
    }

    final standalone = RegExp(
      r'\b(\d{1,2}[-/](?:[A-Za-z]{3}|\d{1,2})[-/](?:\d{2,4}))\b',
      caseSensitive: false,
    ).firstMatch(text);
    final standaloneToken = standalone?.group(1)?.trim();
    if (standaloneToken != null) {
      return _parseDateToken(standaloneToken, fallback.year);
    }
    return null;
  }

  DateTime? _parseDateToken(String token, int fallbackYear) {
    final monthName = RegExp(
      r'^(\d{1,2})[-/](Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[-/](\d{2,4})$',
      caseSensitive: false,
    ).firstMatch(token);
    if (monthName != null) {
      final day = int.tryParse(monthName.group(1) ?? '');
      final monthLabel = (monthName.group(2) ?? '').toLowerCase();
      final year = _resolveYear(monthName.group(3), fallbackYear);
      final month = _months.indexOf(monthLabel) + 1;
      if (day != null && month >= 1 && month <= 12 && year != null) {
        return DateTime(year, month, day);
      }
    }

    final numeric = RegExp(
      r'^(\d{1,2})[-/](\d{1,2})[-/](\d{2,4})$',
      caseSensitive: false,
    ).firstMatch(token);
    if (numeric != null) {
      final day = int.tryParse(numeric.group(1) ?? '');
      final month = int.tryParse(numeric.group(2) ?? '');
      final year = _resolveYear(numeric.group(3), fallbackYear);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    return null;
  }

  int? _resolveYear(String? value, int fallbackYear) {
    if (value == null || value.isEmpty) return fallbackYear;
    final raw = int.tryParse(value);
    if (raw == null) return null;
    if (value.length == 2) return 2000 + raw;
    return raw;
  }

  String? _extractCardLast4(String text) {
    final match = _last4Pattern.firstMatch(text);
    return match?.group(1)?.trim();
  }

  String? _extractIssuer(String text) {
    final towards = RegExp(
      r'towards\s+([A-Za-z0-9&.\- ]{2,40})\s+credit\s*card',
      caseSensitive: false,
    ).firstMatch(text);
    final towardRaw = towards?.group(1);
    final towardClean = _cleanIssuer(towardRaw);
    if (towardClean != null) return towardClean;

    final direct = RegExp(
      r'([A-Za-z0-9&.\- ]{2,40})\s+credit\s*card',
      caseSensitive: false,
    ).allMatches(text);
    for (final match in direct) {
      final clean = _cleanIssuer(match.group(1));
      if (clean != null) return clean;
    }
    return null;
  }

  String? _cleanIssuer(String? raw) {
    if (raw == null) return null;
    final cleaned = raw
        .replaceAll(RegExp(r'\b(bank|card|credit)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'[^A-Za-z0-9&.\- ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) return null;
    final parts = cleaned.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return null;
    return parts.first.toUpperCase();
  }

  String _notificationDedupeKey(CardBillDueNotification parsed) {
    final issuer = _normalize(parsed.issuer) ?? 'unknown';
    final date = _dateOnly(parsed.dueDate).toIso8601String();
    final amount = parsed.totalAmountDue.toStringAsFixed(2);
    return 'card_bill_due|$issuer|${parsed.cardLast4}|$amount|$date';
  }

  String _issuerDisplay(CardBillDueNotification parsed, CreditCard? card) {
    final issuer = parsed.issuer?.trim();
    if (issuer != null && issuer.isNotEmpty) return issuer;
    return card?.bankName.trim().isNotEmpty == true
        ? card!.bankName.trim().toUpperCase()
        : 'Card';
  }

  String? _normalize(String? text) {
    if (text == null) return null;
    final normalized = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();
    if (normalized.isEmpty) return null;
    return normalized;
  }

  String _dayMonth(DateTime date) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${monthNames[date.month - 1]}';
  }

  int _absDays(DateTime a, DateTime b) {
    return _dateOnly(a).difference(_dateOnly(b)).inDays.abs();
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
