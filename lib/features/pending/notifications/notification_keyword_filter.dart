import 'notification_payload.dart';

class NotificationFilterResult {
  const NotificationFilterResult({
    required this.accepted,
    required this.reason,
  });

  final bool accepted;
  final String reason;
}

class NotificationKeywordFilter {
  static const Set<String> _transactionKeywords = {
    'debited',
    'credited',
    'spent',
    'paid',
    'sent',
    'received',
    'transaction',
    'purchase',
    'upi',
    'inr',
    'rs',
    '₹',
    'card',
    'account',
    'a/c',
    'payment',
    'refund',
    'cashback',
    'avl bal',
    'available balance',
  };

  static const Set<String> _likelyFinancePackages = {
    'com.phonepe.app',
    'net.one97.paytm',
    'com.google.android.apps.nbu.paisa.user',
    'in.amazon.mShop.android.shopping',
    'com.sbi.lotusintouch',
    'com.csam.icici.bank.imobile',
    'com.snapwork.hdfc',
    'com.axis.mobile',
  };

  static const Set<String> _chatHints = {
    'message',
    'typing',
    'replied',
    'sticker',
    'sent a photo',
    'whatsapp',
    'telegram',
    'instagram',
  };

  NotificationFilterResult evaluate(NotificationPayload payload) {
    if (payload.packageName == 'com.example.finarc') {
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

    final text = payload.combinedText.toLowerCase();
    final hasKeyword = _transactionKeywords.any(text.contains);
    final isFinancePackage = _likelyFinancePackages.contains(
      payload.packageName,
    );
    final isChatLike = _chatHints.any(text.contains);

    if (!hasKeyword && !isFinancePackage) {
      return const NotificationFilterResult(
        accepted: false,
        reason: 'ignored-no-finance-keyword',
      );
    }

    if (isChatLike && !hasKeyword) {
      return const NotificationFilterResult(
        accepted: false,
        reason: 'ignored-chat-social-notification',
      );
    }

    return NotificationFilterResult(
      accepted: true,
      reason: isFinancePackage
          ? 'accepted-finance-package'
          : 'accepted-keyword-match',
    );
  }
}
