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

class AlertTypeDisplay {
  const AlertTypeDisplay._();

  static const groups = {
    'Transactions': [
      AlertType.pendingTransaction,
      AlertType.largeExpense,
      AlertType.unusualSpending,
    ],
    'Bills & payments': [
      AlertType.cardDue,
      AlertType.emiDue,
      AlertType.splitSettlement,
      AlertType.lowBalance,
    ],
    'Insights': [
      AlertType.recurringMerchant,
      AlertType.weeklySummary,
      AlertType.monthlySummary,
    ],
    'General': [AlertType.reminder, AlertType.info],
  };

  static String label(String? type) {
    switch (type) {
      case AlertType.pendingTransaction:
        return 'Pending transactions';
      case AlertType.cardDue:
        return 'Card bills';
      case AlertType.emiDue:
        return 'EMI reminders';
      case AlertType.splitSettlement:
        return 'Split settlements';
      case AlertType.lowBalance:
        return 'Low balance';
      case AlertType.unusualSpending:
        return 'Unusual spending';
      case AlertType.recurringMerchant:
        return 'Recurring payments';
      case AlertType.largeExpense:
        return 'Large expenses';
      case AlertType.weeklySummary:
        return 'Weekly summary';
      case AlertType.monthlySummary:
        return 'Monthly summary';
      case AlertType.reminder:
        return 'Reminders';
      case AlertType.info:
        return 'Information';
      default:
        return 'Alert';
    }
  }
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
