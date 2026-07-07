import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/logging/app_log_service.dart';
import '../../../core/utils/formatters.dart';
import '../../alerts/data/alert_service.dart';
import '../../alerts/data/alert_types.dart';
import '../../cards/data/billing_service.dart';
import '../parsing/parser_text_utils.dart';
import 'notification_payload.dart';

class CardBillDueNotification {
  const CardBillDueNotification({
    required this.totalAmountDue,
    required this.minimumAmountDue,
    this.minimumDueOnly = false,
    required this.dueDate,
    required this.receivedAt,
    required this.cardLast4,
    required this.issuer,
    required this.rawText,
  });

  final double totalAmountDue;
  final double? minimumAmountDue;
  final bool minimumDueOnly;
  final DateTime dueDate;
  final DateTime receivedAt;
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
    r'(?:pay\s+)?total(?:\s+amount)?\s+due(?:\s+of)?(?:\s+is)?\s*(?:inr|rs\.?|₹)\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );
  static final RegExp _minimumDuePattern = RegExp(
    r'(?:min|minimum)(?:\s+amount)?\s+due(?:\s+of)?(?:\s+is)?\s*(?:inr|rs\.?|₹)\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );
  static final RegExp _genericAmountDuePattern = RegExp(
    r'amount\s+due(?:\s+of)?(?:\s+is)?\s*(?:inr|rs\.?|₹)\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );
  static final RegExp _billOfAmountPattern = RegExp(
    r'(?:credit\s*card\s*)?bill\s+of\s*(?:inr|rs\.?|₹)\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)',
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
        _extractGenericAmountDue(text) ??
        _extractAmount(text, _billOfAmountPattern);
    final minimumAmountDue = _extractAmount(text, _minimumDuePattern);
    final dueDate = _extractDueDate(text, payload.captureTime);
    final cardLast4 = _extractCardLast4(text);
    final issuer = _extractIssuer(text);

    if ((totalAmountDue == null && minimumAmountDue == null) ||
        dueDate == null ||
        cardLast4 == null) {
      return null;
    }

    return CardBillDueNotification(
      totalAmountDue: totalAmountDue ?? minimumAmountDue!,
      minimumAmountDue: minimumAmountDue,
      minimumDueOnly: totalAmountDue == null && minimumAmountDue != null,
      dueDate: _dateOnly(dueDate),
      receivedAt: _dateOnly(payload.captureTime),
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
    if (parsed.minimumDueOnly) {
      final created = await _createMinimumDueOnlyAlert(
        card: card,
        parsed: parsed,
        dedupeKey: dedupeKey,
      );
      await _logAction(
        parsed,
        cardId: card.id,
        action: 'minimumDueOnly',
        meta: {'dedupeKey': dedupeKey},
      );
      return CardBillDueHandlingResult(
        parsed: parsed,
        action: 'minimumDueOnly',
        matchedCardId: card.id,
        alertCreated: created,
      );
    }

    final bills =
        await (_db.select(_db.cardBills)
              ..where((b) => b.cardId.equals(card.id))
              ..orderBy([(b) => OrderingTerm.desc(b.billingDate)]))
            .get();

    final unpaidBill = _findBestBillForCycle(
      bills,
      parsed,
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
      parsed,
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
    final remainingDue = _remainingDue(bill);
    final matchesBilledAmount = _amountsMatch(
      bill.billedAmount,
      parsed.totalAmountDue,
    );
    final matchesRemainingDue =
        bill.paidAmount > 0 &&
        _amountsMatch(remainingDue, parsed.totalAmountDue);
    final issuer = _issuerDisplay(parsed, card);
    if (matchesBilledAmount || matchesRemainingDue) {
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
          title: matchesRemainingDue
              ? '$issuer remaining bill verified: ${inr(parsed.totalAmountDue)} due ${_dayMonth(parsed.dueDate)}'
              : '$issuer bill verified: ${inr(parsed.totalAmountDue)} due ${_dayMonth(parsed.dueDate)}',
          body: matchesRemainingDue
              ? 'Matched with remaining due after partial payments for card XX${parsed.cardLast4}.'
              : 'Matched with existing unpaid bill for card XX${parsed.cardLast4}.',
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
            'appBilledAmount': bill.billedAmount,
            'appPaidAmount': bill.paidAmount,
            'appRemainingDue': remainingDue,
            'notificationAmountBasis': matchesRemainingDue
                ? 'remainingDue'
                : 'billedAmount',
            'source': 'verifiedFromNotification',
          },
        ),
        dedupeWindow: const Duration(days: 90),
      );

      final action = dueDateChanged
          ? 'updatedDueDate'
          : matchesRemainingDue
          ? 'remainingDueVerified'
          : 'verified';
      await _logAction(
        parsed,
        cardId: card.id,
        billId: bill.id,
        action: action,
        meta: {
          'dedupeKey': dedupeKey,
          'appBilledAmount': bill.billedAmount,
          'appPaidAmount': bill.paidAmount,
          'appRemainingDue': remainingDue,
          'notificationAmountBasis': matchesRemainingDue
              ? 'remainingDue'
              : 'billedAmount',
        },
      );
      return action;
    }

    await _alertService.createAlert(
      CreateAlertInput(
        alertType: AlertType.cardDue,
        title: '$issuer bill amount mismatch',
        body:
            'App bill: ${inr(bill.billedAmount)}\nApp remaining: ${inr(remainingDue)}\nNotification: ${inr(parsed.totalAmountDue)}\nPlease review card XX${parsed.cardLast4}.',
        priority: AlertPriority.warning,
        actionRoute: _billMismatchReviewRoute(
          card: card,
          bill: bill,
          parsed: parsed,
        ),
        dedupeKey: dedupeKey,
        payload: {
          'kind': 'cardBillDueNotification',
          'action': 'mismatchAlert',
          'cardId': card.id,
          'billId': bill.id,
          'appAmount': bill.billedAmount,
          'appPaidAmount': bill.paidAmount,
          'appRemainingDue': remainingDue,
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
        'appPaidAmount': bill.paidAmount,
        'appRemainingDue': remainingDue,
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

    if (isMatch) {
      await _logAction(
        parsed,
        cardId: card.id,
        billId: bill.id,
        action: 'paidBillIgnored',
        meta: {
          'appAmount': bill.billedAmount,
          'notificationAmount': parsed.totalAmountDue,
          'dedupeKey': dedupeKey,
        },
      );
      return 'paidBillIgnored';
    }

    await _alertService.createAlert(
      CreateAlertInput(
        alertType: AlertType.cardDue,
        title: 'Paid bill amount differs from notification',
        body:
            'App: ${inr(bill.billedAmount)}\nNotification: ${inr(parsed.totalAmountDue)}\nPlease review card XX${parsed.cardLast4}.',
        priority: AlertPriority.warning,
        actionRoute: _billMismatchReviewRoute(
          card: card,
          bill: bill,
          parsed: parsed,
        ),
        dedupeKey: dedupeKey,
        payload: {
          'kind': 'cardBillDueNotification',
          'action': 'paidBillMismatch',
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
      action: 'paidBillMismatch',
      meta: {
        'appAmount': bill.billedAmount,
        'notificationAmount': parsed.totalAmountDue,
        'dedupeKey': dedupeKey,
      },
    );
    return 'paidBillMismatch';
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
    final amount = parsed.minimumDueOnly
        ? parsed.minimumAmountDue ?? parsed.totalAmountDue
        : parsed.totalAmountDue;
    final alert = await _alertService.createAlert(
      CreateAlertInput(
        alertType: AlertType.cardDue,
        title: parsed.minimumDueOnly
            ? 'Minimum due detected but no matching card found'
            : 'Card bill detected but no matching card found',
        body:
            '${_issuerDisplay(parsed, null)} XX${parsed.cardLast4} • ${parsed.minimumDueOnly ? 'minimum due ' : ''}${inr(amount)} due ${_dayMonth(parsed.dueDate)}',
        priority: AlertPriority.warning,
        dedupeKey: dedupeKey,
        payload: {
          'kind': 'cardBillDueNotification',
          'action': 'noMatchingCard',
          if (!parsed.minimumDueOnly) 'totalAmountDue': parsed.totalAmountDue,
          'minimumAmountDue': parsed.minimumAmountDue,
          'minimumDueOnly': parsed.minimumDueOnly,
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
    final amount = parsed.minimumDueOnly
        ? parsed.minimumAmountDue ?? parsed.totalAmountDue
        : parsed.totalAmountDue;
    final alert = await _alertService.createAlert(
      CreateAlertInput(
        alertType: AlertType.cardDue,
        title: parsed.minimumDueOnly
            ? 'Minimum due detected: multiple matching cards found'
            : 'Card bill detected: multiple matching cards found',
        body:
            '${_issuerDisplay(parsed, null)} XX${parsed.cardLast4} • ${parsed.minimumDueOnly ? 'minimum due ' : ''}${inr(amount)} due ${_dayMonth(parsed.dueDate)}. Please review.',
        priority: AlertPriority.warning,
        dedupeKey: dedupeKey,
        payload: {
          'kind': 'cardBillDueNotification',
          'action': 'multipleMatchingCards',
          if (!parsed.minimumDueOnly) 'totalAmountDue': parsed.totalAmountDue,
          'minimumAmountDue': parsed.minimumAmountDue,
          'minimumDueOnly': parsed.minimumDueOnly,
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

  Future<bool> _createMinimumDueOnlyAlert({
    required CreditCard card,
    required CardBillDueNotification parsed,
    required String dedupeKey,
  }) async {
    final issuer = _issuerDisplay(parsed, card);
    final alert = await _alertService.createAlert(
      CreateAlertInput(
        alertType: AlertType.cardDue,
        title: '$issuer minimum due detected',
        body:
            'Minimum due ${inr(parsed.minimumAmountDue ?? parsed.totalAmountDue)} is due ${_dayMonth(parsed.dueDate)} for card XX${parsed.cardLast4}. Total bill amount was not present in the notification, so no bill was created or updated.',
        priority: AlertPriority.warning,
        actionRoute: '/cards/${card.id}',
        dedupeKey: dedupeKey,
        payload: {
          'kind': 'cardBillDueNotification',
          'action': 'minimumDueOnly',
          'cardId': card.id,
          'minimumAmountDue': parsed.minimumAmountDue,
          'dueDate': parsed.dueDate.toIso8601String(),
          'last4': parsed.cardLast4,
          'issuer': parsed.issuer,
          'source': 'notification',
          'needsReview': true,
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
    CardBillDueNotification parsed, {
    required bool Function(CardBill bill) predicate,
  }) {
    final matches = bills
        .where(predicate)
        .map((bill) => _scoreBillCycleMatch(bill, parsed))
        .whereType<_BillCycleMatch>()
        .toList(growable: false);
    if (matches.isEmpty) return null;

    final sorted = [...matches]
      ..sort((a, b) {
        final score = a.score.compareTo(b.score);
        if (score != 0) return score;
        final due = a.dueDays.compareTo(b.dueDays);
        if (due != 0) return due;
        return b.bill.billingDate.compareTo(a.bill.billingDate);
      });

    return sorted.first.bill;
  }

  _BillCycleMatch? _scoreBillCycleMatch(
    CardBill bill,
    CardBillDueNotification parsed,
  ) {
    final dueDays = _absDays(_dateOnly(bill.dueDate), parsed.dueDate);
    if (dueDays > 45) return null;

    final sameDueMonth =
        bill.dueDate.year == parsed.dueDate.year &&
        bill.dueDate.month == parsed.dueDate.month;
    final amountDistance = _bestAmountDistance(bill, parsed.totalAmountDue);
    final amountBucket = _amountDistanceBucket(amountDistance);
    final notificationPenalty = _notificationCyclePenalty(bill, parsed);
    final dueMonthPenalty = sameDueMonth ? 0 : 30;
    final score =
        (dueDays * 10) +
        dueMonthPenalty +
        (amountBucket * 8) +
        notificationPenalty;
    return _BillCycleMatch(bill: bill, score: score, dueDays: dueDays);
  }

  double _bestAmountDistance(CardBill bill, double notificationAmount) {
    final distances = <double>[(bill.billedAmount - notificationAmount).abs()];
    final remainingDue = _remainingDue(bill);
    if (bill.paidAmount > 0) {
      distances.add((remainingDue - notificationAmount).abs());
    }
    distances.sort();
    return distances.first;
  }

  int _amountDistanceBucket(double diff) {
    if (diff <= 1) return 0;
    if (diff <= 50) return 1;
    if (diff <= 500) return 2;
    return 3;
  }

  int _notificationCyclePenalty(CardBill bill, CardBillDueNotification parsed) {
    final receivedAt = parsed.receivedAt;
    final cycleStart = _dateOnly(bill.cycleStartDate);
    final cycleEnd = _dateOnly(bill.cycleEndDate);
    final billingDate = _dateOnly(bill.billingDate);
    final dueDate = _dateOnly(bill.dueDate);

    if (receivedAt.isBefore(cycleStart.subtract(const Duration(days: 2)))) {
      return 60;
    }
    if (receivedAt.isBefore(cycleEnd.subtract(const Duration(days: 1)))) {
      return 45;
    }
    if (receivedAt.isBefore(billingDate.subtract(const Duration(days: 3)))) {
      return 18;
    }
    if (receivedAt.isAfter(dueDate.add(const Duration(days: 45)))) {
      return 25;
    }
    if (receivedAt.isAfter(dueDate.add(const Duration(days: 14)))) {
      return 10;
    }
    return 0;
  }

  bool _isBillPaidLike(CardBill bill) {
    if (bill.status == 'paid' || bill.status == 'needsReview') return true;
    if (bill.billedAmount <= 0.009) return false;
    return bill.paidAmount >= bill.billedAmount;
  }

  bool _amountsMatch(double left, double right) => (left - right).abs() <= 1;

  double _remainingDue(CardBill bill) => (bill.billedAmount - bill.paidAmount)
      .clamp(0, bill.billedAmount)
      .toDouble();

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
        'minimumDueOnly': parsed.minimumDueOnly,
        'dueDate': parsed.dueDate.toIso8601String(),
        'cardId': cardId,
        'billId': billId,
        ...meta,
      },
    );
  }

  bool _isBillDueMessage(String text) {
    return ParserTextUtils.looksLikeCardBillDueMessage(text);
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

    final ordinalDueMatch = RegExp(
      r'(?:due|was\s+due)\s+on\s+(\d{1,2})(?:st|nd|rd|th)?\s+([A-Za-z]{3,9})(?:\s+(\d{2,4}))?',
      caseSensitive: false,
    ).firstMatch(text);
    if (ordinalDueMatch != null) {
      final parsed = _parseOrdinalDateToken(
        dayText: ordinalDueMatch.group(1),
        monthText: ordinalDueMatch.group(2),
        yearText: ordinalDueMatch.group(3),
        fallback: fallback,
      );
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

  DateTime? _parseOrdinalDateToken({
    required String? dayText,
    required String? monthText,
    required String? yearText,
    required DateTime fallback,
  }) {
    final day = int.tryParse(dayText ?? '');
    final monthKey = (monthText ?? '').toLowerCase();
    final month = _months.indexWhere((m) => monthKey.startsWith(m)) + 1;
    final year = _resolveOrdinalYear(
      yearText: yearText,
      month: month,
      fallback: fallback,
    );
    if (day == null || month < 1 || month > 12 || year == null) return null;
    return DateTime(year, month, day);
  }

  int? _resolveOrdinalYear({
    required String? yearText,
    required int month,
    required DateTime fallback,
  }) {
    final explicitYear = _resolveYear(yearText, fallback.year);
    if (yearText != null && yearText.isNotEmpty) return explicitYear;
    if (month < 1 || month > 12) return null;

    if (fallback.month == DateTime.december && month == DateTime.january) {
      return fallback.year + 1;
    }
    if (fallback.month == DateTime.january && month == DateTime.december) {
      return fallback.year - 1;
    }
    return fallback.year;
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
    final cardDash = RegExp(
      r'for\s+([A-Za-z0-9&.\- ]{2,40})\s+card\s*[-–]\s*\d{3,4}',
      caseSensitive: false,
    ).firstMatch(text);
    final cardDashClean = _cleanIssuer(cardDash?.group(1));
    if (cardDashClean != null) return cardDashClean;

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
    if (parts.length > 1 && _looksLikeSenderIssuerPrefix(parts.first)) {
      return parts[1].toUpperCase();
    }
    return parts.first.toUpperCase();
  }

  bool _looksLikeSenderIssuerPrefix(String value) {
    final upper = value.toUpperCase();
    return upper.endsWith('BK') || upper.endsWith('BNK');
  }

  String _notificationDedupeKey(CardBillDueNotification parsed) {
    final issuer = _normalize(parsed.issuer) ?? 'unknown';
    final date = _dateOnly(parsed.dueDate).toIso8601String();
    final amount = parsed.totalAmountDue.toStringAsFixed(2);
    final basis = parsed.minimumDueOnly ? 'minimum' : 'total';
    return 'card_bill_due|$issuer|${parsed.cardLast4}|$basis|$amount|$date';
  }

  String _billMismatchReviewRoute({
    required CreditCard card,
    required CardBill bill,
    required CardBillDueNotification parsed,
  }) {
    return Uri(
      path: '/cards/${card.id}/bills/${bill.id}',
      queryParameters: {
        'review': 'billMismatch',
        'appAmount': bill.billedAmount.toStringAsFixed(2),
        'notificationAmount': parsed.totalAmountDue.toStringAsFixed(2),
      },
    ).toString();
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

class _BillCycleMatch {
  const _BillCycleMatch({
    required this.bill,
    required this.score,
    required this.dueDays,
  });

  final CardBill bill;
  final int score;
  final int dueDays;
}
