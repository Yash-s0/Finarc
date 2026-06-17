import 'notification_payload.dart';
import 'notification_provider_catalog.dart';
import 'sms_sender_filter.dart';

class NotificationFilterResult {
  const NotificationFilterResult({
    required this.accepted,
    required this.reason,
    this.providerId,
    this.providerName,
    this.senderFilterResult,
    this.amountCandidate,
    this.blockedContext,
  });

  final bool accepted;
  final String reason;
  final String? providerId;
  final String? providerName;
  final String? senderFilterResult;
  final String? amountCandidate;
  final String? blockedContext;
}

class NotificationKeywordFilter {
  static const SmsSenderFilter _smsSenderFilter = SmsSenderFilter();
  static const Set<String> _transactionKeywords = {
    'debited',
    'credited',
    'spent',
    'paid',
    'used',
    'sent',
    'received',
    'txn',
    'transaction',
    'purchase',
    'upi',
    'imps',
    'neft',
    'inr',
    'rs',
    '₹',
    'card',
    'account',
    'a/c',
    'payment',
    'refund',
    'cashback',
    'salary',
    'payroll',
    'transfer',
    'withdrawn',
    'avl bal',
    'available balance',
  };

  static const Set<String> _chatHints = {
    'message',
    'typing',
    'replied',
    'sticker',
    'sent a photo',
    'whatsapp',
    'snapchat',
    'telegram',
    'instagram',
  };

  static const Set<String> _otpHints = {
    'otp',
    'one-time password',
    'one time password',
    'do not disclose',
    'do not share',
    'passcode',
    'secret',
  };

  static const List<String> _promoPhrases = [
    'offer',
    'discount',
    'sale',
    'wishlist',
    'gift card',
    'voucher',
    'coupon',
    'cashback offer',
    'reward',
    'claim',
    'deal',
    'limited time',
    'expires',
    'shop now',
    'tap to claim',
    'win',
    'chance to win',
    'worth',
    'upto',
    'up to',
  ];

  static const List<String> _transactionActionKeywords = [
    'paid',
    'spent',
    'debited',
    'sent',
    'deducted',
    'purchase successful',
    'transaction successful',
    'used for',
    'charged',
    'credited',
    'received',
    'deposited',
    'salary',
    'payroll',
    'refund credited',
  ];

  NotificationFilterResult evaluate(NotificationPayload payload) {
    if (payload.packageName == 'com.yashsharma.finarc') {
      return const NotificationFilterResult(
        accepted: false,
        reason: 'ignored-own-package',
      );
    }

    if (payload.isOngoing) {
      return const NotificationFilterResult(
        accepted: false,
        reason: 'ignored-ongoing-notification',
      );
    }

    if (payload.combinedText.trim().isEmpty) {
      return const NotificationFilterResult(
        accepted: false,
        reason: 'ignored-empty-content',
      );
    }

    if (payload.sourceType != 'sms') {
      if (NotificationProviderCatalog.isMessagingPackage(payload.packageName)) {
        return _evaluateMessagingNotification(payload);
      }

      final isLikelyBankingApp = NotificationProviderCatalog.isLikelyBankingApp(
        packageName: payload.packageName,
        appName: payload.appName,
      );
      if (isLikelyBankingApp) {
        return _evaluateBankingAppNotification(payload);
      }

      final provider = NotificationProviderCatalog.providerForPackage(
        payload.packageName,
      );
      if (provider == null) {
        return const NotificationFilterResult(
          accepted: false,
          reason: 'ignored-package-not-allowlisted',
        );
      }

      final text = payload.combinedText.toLowerCase();
      final hasKeyword = _transactionKeywords.any(text.contains);
      if (!hasKeyword) {
        return NotificationFilterResult(
          accepted: false,
          reason: 'ignored-no-finance-keyword',
          providerId: provider.providerId,
          providerName: provider.providerName,
          senderFilterResult: 'not-applicable',
        );
      }
      final promoSignal = _promotionalSignal(payload.combinedText);
      if (promoSignal.blocked) {
        return NotificationFilterResult(
          accepted: false,
          reason: 'promotional_offer_detected',
          providerId: provider.providerId,
          providerName: provider.providerName,
          senderFilterResult: 'not-applicable',
          amountCandidate: promoSignal.amountCandidate,
          blockedContext: promoSignal.blockedContext,
        );
      }
      final amountCandidate = _extractAmountCandidate(payload.combinedText);
      if (amountCandidate == null) {
        return NotificationFilterResult(
          accepted: false,
          reason: 'ignored-no-amount',
          providerId: provider.providerId,
          providerName: provider.providerName,
          senderFilterResult: 'not-applicable',
        );
      }
      return NotificationFilterResult(
        accepted: true,
        reason: 'accepted-provider-keyword-match',
        providerId: provider.providerId,
        providerName: provider.providerName,
        senderFilterResult: 'not-applicable',
        amountCandidate: amountCandidate,
      );
    }

    final text = payload.combinedText.toLowerCase();
    final hasKeyword = _transactionKeywords.any(text.contains);
    final isChatLike = _chatHints.any(text.contains);
    final isOtpLike = _otpHints.any(text.contains);

    if (!hasKeyword) {
      return const NotificationFilterResult(
        accepted: false,
        reason: 'ignored-no-finance-keyword',
      );
    }

    if (isChatLike) {
      return const NotificationFilterResult(
        accepted: false,
        reason: 'ignored-chat-social-notification',
      );
    }

    if (isOtpLike) {
      return const NotificationFilterResult(
        accepted: false,
        reason: 'ignored-otp-message',
      );
    }

    final promoSignal = _promotionalSignal(payload.combinedText);
    if (promoSignal.blocked) {
      return NotificationFilterResult(
        accepted: false,
        reason: 'promotional_offer_detected',
        senderFilterResult: 'not-applicable',
        amountCandidate: promoSignal.amountCandidate,
        blockedContext: promoSignal.blockedContext,
      );
    }

    return const NotificationFilterResult(
      accepted: true,
      reason: 'accepted-keyword-match',
      senderFilterResult: 'not-applicable',
    );
  }

  NotificationFilterResult _evaluateMessagingNotification(
    NotificationPayload payload,
  ) {
    final sender = _extractMessagingSender(payload);
    final senderResult = _smsSenderFilter.evaluate(sender);
    if (!senderResult.accepted) {
      return NotificationFilterResult(
        accepted: false,
        reason: senderResult.reason,
        senderFilterResult: senderResult.reason,
      );
    }

    final text = payload.combinedText.toLowerCase();
    final hasKeyword = _transactionKeywords.any(text.contains);
    final isChatLike = _chatHints.any(text.contains);
    final isOtpLike = _otpHints.any(text.contains);

    if (!hasKeyword) {
      return NotificationFilterResult(
        accepted: false,
        reason: 'ignored-no-finance-keyword',
        senderFilterResult: senderResult.reason,
      );
    }

    if (isChatLike) {
      return NotificationFilterResult(
        accepted: false,
        reason: 'ignored-chat-social-notification',
        senderFilterResult: senderResult.reason,
      );
    }

    if (isOtpLike) {
      return NotificationFilterResult(
        accepted: false,
        reason: 'ignored-otp-message',
        senderFilterResult: senderResult.reason,
      );
    }

    final promoSignal = _promotionalSignal(payload.combinedText);
    if (promoSignal.blocked) {
      return NotificationFilterResult(
        accepted: false,
        reason: 'promotional_offer_detected',
        senderFilterResult: senderResult.reason,
        amountCandidate: promoSignal.amountCandidate,
        blockedContext: promoSignal.blockedContext,
      );
    }

    return NotificationFilterResult(
      accepted: true,
      reason: 'accepted-messaging-sms-notification',
      senderFilterResult: senderResult.reason,
      amountCandidate: _extractAmountCandidate(payload.combinedText),
    );
  }

  NotificationFilterResult _evaluateBankingAppNotification(
    NotificationPayload payload,
  ) {
    final text = payload.combinedText.toLowerCase();
    final hasKeyword = _transactionKeywords.any(text.contains);
    final isChatLike = _chatHints.any(text.contains);
    final isOtpLike = _otpHints.any(text.contains);

    if (!hasKeyword) {
      return const NotificationFilterResult(
        accepted: false,
        reason: 'ignored-no-finance-keyword',
      );
    }

    if (isChatLike) {
      return const NotificationFilterResult(
        accepted: false,
        reason: 'ignored-chat-social-notification',
      );
    }

    if (isOtpLike) {
      return const NotificationFilterResult(
        accepted: false,
        reason: 'ignored-otp-message',
      );
    }

    final promoSignal = _promotionalSignal(payload.combinedText);
    if (promoSignal.blocked) {
      return NotificationFilterResult(
        accepted: false,
        reason: 'promotional_offer_detected',
        amountCandidate: promoSignal.amountCandidate,
        blockedContext: promoSignal.blockedContext,
      );
    }

    final amountCandidate = _extractAmountCandidate(payload.combinedText);
    if (amountCandidate == null) {
      return const NotificationFilterResult(
        accepted: false,
        reason: 'ignored-no-amount',
      );
    }

    return NotificationFilterResult(
      accepted: true,
      reason: 'accepted-banking-app-heuristic',
      amountCandidate: amountCandidate,
    );
  }

  String? _extractMessagingSender(NotificationPayload payload) {
    final sender = payload.sender?.trim();
    if (sender != null && sender.isNotEmpty) return sender;
    final title = payload.title?.trim();
    if (title != null && title.isNotEmpty) return title;
    return null;
  }

  _PromotionalSignal _promotionalSignal(String text) {
    final lower = text.toLowerCase();
    final amount = _extractAmountCandidate(text);
    final hasAction = _transactionActionKeywords.any(lower.contains);
    final contexts = <String>[];
    final misleadingCreditPromo =
        lower.contains('credited upto') || lower.contains('credited up to');

    for (final phrase in _promoPhrases) {
      if (lower.contains(phrase)) {
        contexts.add(phrase);
      }
    }

    final percentOffMatch = RegExp(
      r'\b\d{1,3}\s*%\s*off\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (percentOffMatch != null) {
      contexts.add(percentOffMatch.group(0)!.toLowerCase());
    }

    final amountInPromoContext = RegExp(
      r'(?:worth|off|discount|voucher|gift card|coupon|cashback offer|reward|deal)\s*(?:of\s*)?(?:₹|rs\.?|inr)\s*[0-9][0-9,]*(?:\.[0-9]{1,2})?',
      caseSensitive: false,
    ).hasMatch(text);
    final amountWithPromoTail = RegExp(
      r'(?:₹|rs\.?|inr)\s*[0-9][0-9,]*(?:\.[0-9]{1,2})?\s*(?:off|discount|voucher|gift card|coupon|reward)',
      caseSensitive: false,
    ).hasMatch(text);

    final hasPromo =
        contexts.isNotEmpty || amountInPromoContext || amountWithPromoTail;
    if (!hasPromo) {
      return _PromotionalSignal(
        blocked: false,
        amountCandidate: amount,
        blockedContext: null,
      );
    }

    final blocked =
        misleadingCreditPromo ||
        (!hasAction &&
            (contexts.isNotEmpty ||
                amountInPromoContext ||
                amountWithPromoTail ||
                amount != null));

    if (!blocked) {
      return _PromotionalSignal(
        blocked: false,
        amountCandidate: amount,
        blockedContext: misleadingCreditPromo
            ? 'credited upto'
            : contexts.take(3).join(' / '),
      );
    }

    return _PromotionalSignal(
      blocked: true,
      amountCandidate: amount,
      blockedContext: misleadingCreditPromo
          ? 'credited upto'
          : contexts.take(3).join(' / '),
    );
  }

  String? _extractAmountCandidate(String text) {
    final match = RegExp(
      r'(?:INR|Rs\.?|₹)\s*[0-9][0-9,]*(?:\.[0-9]{1,2})?',
      caseSensitive: false,
    ).firstMatch(text);
    final value = match?.group(0)?.trim();
    if (value == null || value.isEmpty) return null;
    return value.replaceAll('INR', '₹').replaceAll('Rs.', '₹').trim();
  }
}

class _PromotionalSignal {
  const _PromotionalSignal({
    required this.blocked,
    required this.amountCandidate,
    required this.blockedContext,
  });

  final bool blocked;
  final String? amountCandidate;
  final String? blockedContext;
}
