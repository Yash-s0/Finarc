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

  PendingEditData copyWith({
    double? amount,
    String? merchant,
    String? category,
    String? paymentSourceType,
    int? paymentSourceId,
    DateTime? transactionDate,
    double? cashbackAmount,
    bool? isForOthers,
    double? recoverableAmount,
    double? recoveredAmount,
    String? recoverablePartyName,
    String? notes,
  }) {
    return PendingEditData(
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      category: category ?? this.category,
      paymentSourceType: paymentSourceType ?? this.paymentSourceType,
      paymentSourceId: paymentSourceId ?? this.paymentSourceId,
      transactionDate: transactionDate ?? this.transactionDate,
      cashbackAmount: cashbackAmount ?? this.cashbackAmount,
      isForOthers: isForOthers ?? this.isForOthers,
      recoverableAmount: recoverableAmount ?? this.recoverableAmount,
      recoveredAmount: recoveredAmount ?? this.recoveredAmount,
      recoverablePartyName: recoverablePartyName ?? this.recoverablePartyName,
      notes: notes ?? this.notes,
    );
  }
}
