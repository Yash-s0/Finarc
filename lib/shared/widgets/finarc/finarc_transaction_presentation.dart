import '../../../core/utils/formatters.dart';
import 'finarc_status_badge.dart';

class FinarcTransactionPresentation {
  static bool isPositive({
    required String type,
    required String paymentSourceType,
    String? title,
  }) {
    if (type == 'income' || type == 'refund') return true;
    if (type == 'transfer') {
      final normalizedTitle = title?.trim().toLowerCase() ?? '';
      return normalizedTitle.contains('transfer in');
    }
    if (type == 'cardPayment') {
      return paymentSourceType.trim() == 'creditCard';
    }
    return false;
  }

  static String sourceLabel(String sourceType) {
    switch (sourceType.trim()) {
      case 'creditCard':
        return 'Card';
      case 'bank':
        return 'Bank';
      case 'upi':
        return 'UPI';
      case 'cash':
        return 'Cash';
      case 'wallet':
        return 'Wallet';
      case 'transfer':
        return 'Transfer';
      case 'salaryDeduction':
        return 'Salary Deduction';
      default:
        return sourceType.toUpperCase();
    }
  }

  static String meta({required DateTime date, String? source, DateTime? now}) {
    return transactionMetaLabel(date, sourceLabel: source, now: now);
  }

  static FinarcStatusBadge billedBadge({required bool billed}) {
    return FinarcStatusBadge(
      label: billed ? 'Billed' : 'Unbilled',
      tone: billed ? FinarcStatusTone.info : FinarcStatusTone.warning,
      compact: true,
    );
  }

  static FinarcStatusBadge recoverableStatusBadge(String status) {
    final normalized = status.trim().toLowerCase();
    switch (normalized) {
      case 'recovered':
      case 'settled':
      case 'complete':
        return const FinarcStatusBadge(
          label: 'Recovered',
          tone: FinarcStatusTone.success,
          compact: true,
        );
      case 'partial':
      case 'partiallyrecovered':
        return const FinarcStatusBadge(
          label: 'Partial',
          tone: FinarcStatusTone.warning,
          compact: true,
        );
      default:
        return const FinarcStatusBadge(
          label: 'Unpaid',
          tone: FinarcStatusTone.error,
          compact: true,
        );
    }
  }

  static FinarcStatusBadge pendingStatusBadge(String status) {
    final normalized = status.trim().toLowerCase();
    switch (normalized) {
      case 'pending':
        return const FinarcStatusBadge(
          label: 'Pending',
          tone: FinarcStatusTone.warning,
          compact: true,
        );
      case 'ignored':
        return const FinarcStatusBadge(
          label: 'Ignored',
          tone: FinarcStatusTone.neutral,
          compact: true,
        );
      case 'duplicate':
      case 'merged':
        return const FinarcStatusBadge(
          label: 'Duplicate',
          tone: FinarcStatusTone.info,
          compact: true,
        );
      default:
        return FinarcStatusBadge(
          label: status,
          tone: FinarcStatusTone.neutral,
          compact: true,
        );
    }
  }

  static const FinarcStatusBadge emiBadge = FinarcStatusBadge(
    label: 'EMI',
    tone: FinarcStatusTone.warning,
    compact: true,
  );

  static const FinarcStatusBadge loanPaymentBadge = FinarcStatusBadge(
    label: 'Loan Payment',
    tone: FinarcStatusTone.success,
    compact: true,
  );

  static const FinarcStatusBadge cashbackBadge = FinarcStatusBadge(
    label: 'Cashback',
    tone: FinarcStatusTone.success,
    compact: true,
  );
}
