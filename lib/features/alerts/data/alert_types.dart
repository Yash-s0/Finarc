enum AlertPriority { critical, warning, info }

class AlertType {
  static const pendingTransaction = 'pendingTransaction';
  static const cardDue = 'cardDue';
  static const emiDue = 'emiDue';
  static const splitSettlement = 'splitSettlement';
  static const lowBalance = 'lowBalance';
  static const unusualSpending = 'unusualSpending';
  static const recurringMerchant = 'recurringMerchant';
  static const largeExpense = 'largeExpense';
  static const weeklySummary = 'weeklySummary';
  static const monthlySummary = 'monthlySummary';
  static const reminder = 'reminder';
  static const info = 'info';

  static const all = [
    pendingTransaction,
    cardDue,
    emiDue,
    splitSettlement,
    lowBalance,
    unusualSpending,
    recurringMerchant,
    largeExpense,
    weeklySummary,
    monthlySummary,
    reminder,
    info,
  ];
}

String alertPriorityLabel(AlertPriority priority) {
  switch (priority) {
    case AlertPriority.critical:
      return 'critical';
    case AlertPriority.warning:
      return 'warning';
    case AlertPriority.info:
      return 'info';
  }
}

AlertPriority parseAlertPriority(String value) {
  switch (value) {
    case 'critical':
      return AlertPriority.critical;
    case 'warning':
      return AlertPriority.warning;
    case 'info':
    default:
      return AlertPriority.info;
  }
}
