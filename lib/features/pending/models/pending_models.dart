class PendingEditData {
  PendingEditData({
    required this.amount,
    required this.merchant,
    required this.category,
    required this.paymentSourceType,
    required this.paymentSourceId,
    required this.transactionDate,
    this.cashbackAmount,
    this.isForOthers = false,
    this.recoverableAmount,
    this.recoveredAmount,
    this.recoverablePartyName,
    this.notes,
  });

  final double amount;
  final String merchant;
  final String category;
  final String paymentSourceType;
  final int? paymentSourceId;
  final DateTime transactionDate;
  final double? cashbackAmount;
  final bool isForOthers;
  final double? recoverableAmount;
  final double? recoveredAmount;
  final String? recoverablePartyName;
  final String? notes;
}
