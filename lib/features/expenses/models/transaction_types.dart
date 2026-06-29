class TransactionType {
  static const creditCard = 'creditCard';
  static const bank = 'bank';
  static const cash = 'cash';
  static const upi = 'upi';
  static const income = 'income';
  static const refund = 'refund';
  static const transfer = 'transfer';
  static const cardPayment = 'cardPayment';
  static const loanEmi = 'loanEmi';
}

class TransactionImpactType {
  static const historicalNoBalance = 'historicalNoBalance';
  static const cardStatementBalanceNeutral = 'cardStatementBalanceNeutral';
}

class PaymentSourceType {
  static const cash = 'cash';
  static const upi = 'upi';
  static const bank = 'bank';
  static const creditCard = 'creditCard';
  static const salaryDeduction = 'salaryDeduction';
}
