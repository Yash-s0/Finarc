import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/features/alerts/data/alert_engine.dart';
import 'package:finarc/features/alerts/data/alert_service.dart';
import 'package:finarc/features/alerts/data/alert_types.dart';
import 'package:finarc/features/cards/data/billing_service.dart';
import 'package:finarc/features/expenses/data/transaction_engine.dart';
import 'package:finarc/features/expenses/models/transaction_types.dart';
import 'package:finarc/features/loans/data/loan_service.dart';
import 'package:finarc/features/pending/notifications/notification_local_notifier.dart';
import 'package:finarc/features/split/data/split_service.dart';

class _FakeNotifier extends NotificationLocalNotifier {
  final List<(String title, String body, String channelType)> sent = [];

  @override
  Future<void> showAlert({
    required String title,
    required String body,
    String route = '/alerts',
    String channelType = 'alerts',
  }) async {
    sent.add((title, body, channelType));
  }
}

void main() {
  late AppDatabase db;
  late AlertService alertService;
  late TransactionEngine engine;
  late SplitService splitService;
  late LoanService loanService;
  late _FakeNotifier notifier;
  late AlertEngine alertEngine;

  Future<void> enableSmartAlerts({
    bool smart = true,
    bool low = true,
    bool large = true,
    bool unusual = true,
    bool recurring = true,
    bool weekly = false,
    bool monthly = false,
    bool settlementReminder = true,
    int quietStartHour = 22,
    int quietStartMinute = 0,
    int quietEndHour = 7,
    int quietEndMinute = 0,
    double lowThreshold = 2000,
    double largeThreshold = 10000,
    double unusualMultiplier = 1.8,
  }) async {
    await db.seedIfEmpty();
    final row = await (db.select(db.appSettings)..limit(1)).getSingle();
    await (db.update(db.appSettings)..where((t) => t.id.equals(row.id))).write(
      AppSettingsCompanion(
        smartAlertsEnabled: Value(smart),
        lowBalanceAlertsEnabled: Value(low),
        lowBalanceThreshold: Value(lowThreshold),
        largeExpenseAlertsEnabled: Value(large),
        largeExpenseThreshold: Value(largeThreshold),
        unusualSpendingAlertsEnabled: Value(unusual),
        unusualSpendingMultiplier: Value(unusualMultiplier),
        recurringMerchantAlertsEnabled: Value(recurring),
        weeklySummaryAlertsEnabled: Value(weekly),
        monthlySummaryAlertsEnabled: Value(monthly),
        settlementReminderEnabled: Value(settlementReminder),
        quietHoursStartHour: Value(quietStartHour),
        quietHoursStartMinute: Value(quietStartMinute),
        quietHoursEndHour: Value(quietEndHour),
        quietHoursEndMinute: Value(quietEndMinute),
      ),
    );
  }

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    alertService = AlertService(db);
    engine = TransactionEngine(db);
    splitService = SplitService(db, engine);
    loanService = LoanService(db);
    notifier = _FakeNotifier();
    alertEngine = AlertEngine(
      database: db,
      alertService: alertService,
      notifier: notifier,
      billingService: BillingService(db),
      loanService: loanService,
      splitService: splitService,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('low balance and large expense alerts are generated', () async {
    await enableSmartAlerts();
    final bankId = await db
        .into(db.bankAccounts)
        .insert(
          BankAccountsCompanion.insert(
            bankName: 'HDFC',
            accountName: 'Primary',
            accountType: 'savings',
            currentBalance: const Value(13000),
          ),
        );

    await engine.addTransaction(
      AddTransactionInput(
        type: TransactionType.bank,
        amount: 12000,
        title: 'Amazon',
        category: 'Shopping',
        transactionDate: DateTime.now(),
        paymentSourceType: PaymentSourceType.bank,
        paymentSourceId: bankId,
      ),
    );
    final txn =
        await (db.select(db.transactions)
              ..orderBy([(t) => OrderingTerm.desc(t.id)])
              ..limit(1))
            .getSingle();
    await alertEngine.evaluateAfterTransaction(txn);

    final alerts = await alertService.getAlerts(
      query: const AlertQuery(includeDismissed: true),
    );
    final types = alerts.map((e) => e.alertType).toList();
    expect(types, contains(AlertType.largeExpense));
    expect(types, contains(AlertType.lowBalance));
  });

  test(
    'pending transaction alerts use structured pending data for copy',
    () async {
      final pendingId = await db
          .into(db.pendingTransactions)
          .insert(
            PendingTransactionsCompanion.insert(
              amount: 450,
              merchant: 'Zepto',
              categorySuggestion: 'Shopping',
              paymentSourceTypeSuggestion: 'bank',
              detectedAt: DateTime(2026, 8, 26, 10, 40),
              transactionDate: DateTime(2026, 8, 26, 10, 40),
              sourceType: 'appNotification',
              rawText: 'Your payment of ₹450 to Zepto was successful',
              confidenceScore: 0.96,
            ),
          );

      await alertEngine.onPendingDetected(
        pendingId: pendingId,
        title: '₹450 detected at ₹450 was paid on Zepto',
        body: 'Confirm this transaction in Finarc.',
      );

      final alerts = await alertService.getAlerts();
      expect(alerts.single.title, 'Transaction detected');
      expect(alerts.single.body, '₹450.00 paid to Zepto');
      expect(alerts.single.payload, contains('"pendingId":$pendingId'));
      expect(alerts.single.payload, contains('"merchant":"Zepto"'));
    },
  );

  test('recurring merchant alert is generated', () async {
    await enableSmartAlerts(
      low: false,
      large: false,
      unusual: false,
      recurring: true,
    );
    final bankId = await db
        .into(db.bankAccounts)
        .insert(
          BankAccountsCompanion.insert(
            bankName: 'SBI',
            accountName: 'Salary',
            accountType: 'savings',
            currentBalance: const Value(100000),
          ),
        );

    for (var i = 0; i < 6; i++) {
      await engine.addTransaction(
        AddTransactionInput(
          type: TransactionType.bank,
          amount: 300,
          title: 'Swiggy',
          category: 'Food',
          transactionDate: DateTime.now().subtract(Duration(days: i)),
          paymentSourceType: PaymentSourceType.bank,
          paymentSourceId: bankId,
        ),
      );
    }

    final latest =
        await (db.select(db.transactions)
              ..orderBy([(t) => OrderingTerm.desc(t.id)])
              ..limit(1))
            .getSingle();
    await alertEngine.evaluateAfterTransaction(latest);

    final alerts = await alertService.getAlerts();
    expect(
      alerts.any((a) => a.alertType == AlertType.recurringMerchant),
      isTrue,
    );
  });

  test('card due and EMI due alerts are generated', () async {
    await enableSmartAlerts(
      low: false,
      large: false,
      unusual: false,
      recurring: false,
    );
    final now = DateTime.now();
    final cardId = await db
        .into(db.creditCards)
        .insert(
          CreditCardsCompanion.insert(
            bankName: 'Axis',
            nickname: 'Axis Ace',
            last4: '1234',
            maskedNumber: '**** **** **** 1234',
            creditLimit: 50000,
            billingDay: 10,
            dueDay: 20,
            currentOutstanding: const Value(12000),
          ),
        );
    await db
        .into(db.cardBills)
        .insert(
          CardBillsCompanion.insert(
            cardId: cardId,
            cycleStartDate: Value(now.subtract(const Duration(days: 25))),
            cycleEndDate: Value(now.subtract(const Duration(days: 1))),
            billingDate: Value(now.subtract(const Duration(days: 1))),
            billedAmount: 12000,
            dueDate: Value(now.add(const Duration(days: 1))),
            status: const Value('billed'),
          ),
        );

    await loanService.createLoan(
      title: 'Vehicle Loan',
      lenderName: 'ICICI',
      loanType: 'vehicle',
      principalAmount: 300000,
      currentOutstanding: 150000,
      emiAmount: 8500,
      emiDay: now.day + 1 > 28 ? 28 : now.day + 1,
    );

    await alertEngine.evaluateDueAlerts();
    final alerts = await alertService.getAlerts();
    expect(alerts.any((a) => a.alertType == AlertType.cardDue), isTrue);
    expect(alerts.any((a) => a.alertType == AlertType.emiDue), isTrue);
  });

  test('paid card bills dismiss stale due alerts into history', () async {
    await enableSmartAlerts(
      low: false,
      large: false,
      unusual: false,
      recurring: false,
    );
    final now = DateTime.now();
    final cardId = await db
        .into(db.creditCards)
        .insert(
          CreditCardsCompanion.insert(
            bankName: 'Axis',
            nickname: 'Axis Ace',
            last4: '1234',
            maskedNumber: '**** **** **** 1234',
            creditLimit: 50000,
            billingDay: 10,
            dueDay: 20,
          ),
        );
    final billId = await db
        .into(db.cardBills)
        .insert(
          CardBillsCompanion.insert(
            cardId: cardId,
            cycleStartDate: Value(now.subtract(const Duration(days: 25))),
            cycleEndDate: Value(now.subtract(const Duration(days: 1))),
            billingDate: Value(now.subtract(const Duration(days: 1))),
            billedAmount: 12000,
            dueDate: Value(now),
            status: const Value('dueToday'),
          ),
        );

    await alertEngine.evaluateDueAlerts();
    expect(
      (await alertService.getAlerts()).single.alertType,
      AlertType.cardDue,
    );

    await (db.update(db.cardBills)..where((b) => b.id.equals(billId))).write(
      CardBillsCompanion(
        paidAmount: const Value(12000),
        status: const Value('paid'),
        paidAt: Value(now),
      ),
    );
    await alertEngine.evaluateDueAlerts();

    expect(await alertService.getAlerts(), isEmpty);
    final history = await alertService.getAlerts(
      query: const AlertQuery(includeDismissed: true),
    );
    expect(history.single.alertType, AlertType.cardDue);
    expect(history.single.dismissedAt, isNot(null));
    expect(history.single.readAt, isNot(null));
  });

  test('closed loans dismiss stale EMI alerts into history', () async {
    await enableSmartAlerts(
      low: false,
      large: false,
      unusual: false,
      recurring: false,
    );
    final now = DateTime.now();
    final loanId = await loanService.createLoan(
      title: 'Vehicle Loan',
      lenderName: 'ICICI',
      loanType: 'vehicle',
      principalAmount: 300000,
      currentOutstanding: 150000,
      emiAmount: 8500,
      emiDay: now.day,
    );

    await alertEngine.evaluateDueAlerts();
    expect((await alertService.getAlerts()).single.alertType, AlertType.emiDue);

    await loanService.closeLoan(loanId, closedAt: now);
    await alertEngine.evaluateDueAlerts();

    expect(await alertService.getAlerts(), isEmpty);
    final history = await alertService.getAlerts(
      query: const AlertQuery(includeDismissed: true),
    );
    expect(history.single.alertType, AlertType.emiDue);
    expect(history.single.dismissedAt, isNot(null));
  });

  test('split settlement reminder alert is generated', () async {
    await enableSmartAlerts(
      low: false,
      large: false,
      unusual: false,
      recurring: false,
    );
    final groupId = await splitService.createGroup('Goa Trip');
    final me = await splitService.addMember(
      groupId,
      name: 'Me',
      isCurrentUser: true,
    );
    final friend = await splitService.addMember(groupId, name: 'Rahul');
    final bankId = await db
        .into(db.bankAccounts)
        .insert(
          BankAccountsCompanion.insert(
            bankName: 'HDFC',
            accountName: 'Primary',
            accountType: 'savings',
            currentBalance: const Value(50000),
          ),
        );

    await splitService.addSplitExpense(
      AddSplitExpenseInput(
        groupId: groupId,
        title: 'Dinner',
        totalAmount: 1000,
        paidByMemberId: me,
        splitType: 'equal',
        expenseDate: DateTime.now(),
        category: 'Food',
        paymentSourceType: PaymentSourceType.bank,
        paymentSourceId: bankId,
        shares: splitService.calculateEqualSplit(
          memberIds: [me, friend],
          totalAmount: 1000,
        ),
      ),
    );

    await alertEngine.evaluateSplitAlerts();
    final alerts = await alertService.getAlerts();
    expect(alerts.any((a) => a.alertType == AlertType.splitSettlement), isTrue);
  });

  test('fully settled splits dismiss stale settlement alerts', () async {
    await enableSmartAlerts(
      low: false,
      large: false,
      unusual: false,
      recurring: false,
    );
    final groupId = await splitService.createGroup('Goa Trip');
    final me = await splitService.addMember(
      groupId,
      name: 'Me',
      isCurrentUser: true,
    );
    final friend = await splitService.addMember(groupId, name: 'Rahul');
    final bankId = await db
        .into(db.bankAccounts)
        .insert(
          BankAccountsCompanion.insert(
            bankName: 'HDFC',
            accountName: 'Primary',
            accountType: 'savings',
            currentBalance: const Value(50000),
          ),
        );

    await splitService.addSplitExpense(
      AddSplitExpenseInput(
        groupId: groupId,
        title: 'Dinner',
        totalAmount: 1000,
        paidByMemberId: me,
        splitType: 'equal',
        expenseDate: DateTime.now(),
        category: 'Food',
        paymentSourceType: PaymentSourceType.bank,
        paymentSourceId: bankId,
        shares: splitService.calculateEqualSplit(
          memberIds: [me, friend],
          totalAmount: 1000,
        ),
      ),
    );

    await alertEngine.evaluateSplitAlerts();
    expect(
      (await alertService.getAlerts()).single.alertType,
      AlertType.splitSettlement,
    );

    await splitService.addSettlement(
      groupId: groupId,
      fromMemberId: friend,
      toMemberId: me,
      amount: 500,
      settlementDate: DateTime.now(),
      paymentSourceType: PaymentSourceType.bank,
      paymentSourceId: bankId,
    );
    await alertEngine.evaluateSplitAlerts();

    expect(await alertService.getAlerts(), isEmpty);
    final history = await alertService.getAlerts(
      query: const AlertQuery(includeDismissed: true),
    );
    expect(history.single.alertType, AlertType.splitSettlement);
    expect(history.single.dismissedAt, isNot(null));
  });

  test('recovered balances dismiss stale low-balance alerts', () async {
    await enableSmartAlerts(
      large: false,
      unusual: false,
      recurring: false,
      lowThreshold: 2000,
    );
    final bankId = await db
        .into(db.bankAccounts)
        .insert(
          BankAccountsCompanion.insert(
            bankName: 'HDFC',
            accountName: 'Primary',
            accountType: 'savings',
            currentBalance: const Value(1500),
          ),
        );
    await engine.addTransaction(
      AddTransactionInput(
        type: TransactionType.income,
        amount: 1,
        title: 'Small credit',
        category: 'Income',
        transactionDate: DateTime.now(),
        paymentSourceType: PaymentSourceType.bank,
        paymentSourceId: bankId,
      ),
    );
    var txn =
        await (db.select(db.transactions)
              ..orderBy([(t) => OrderingTerm.desc(t.id)])
              ..limit(1))
            .getSingle();
    await alertEngine.evaluateAfterTransaction(txn);
    expect(
      (await alertService.getAlerts()).single.alertType,
      AlertType.lowBalance,
    );

    await engine.addTransaction(
      AddTransactionInput(
        type: TransactionType.income,
        amount: 1000,
        title: 'Top up',
        category: 'Income',
        transactionDate: DateTime.now(),
        paymentSourceType: PaymentSourceType.bank,
        paymentSourceId: bankId,
      ),
    );
    txn =
        await (db.select(db.transactions)
              ..orderBy([(t) => OrderingTerm.desc(t.id)])
              ..limit(1))
            .getSingle();
    await alertEngine.evaluateAfterTransaction(txn);

    expect(await alertService.getAlerts(), isEmpty);
    final history = await alertService.getAlerts(
      query: const AlertQuery(includeDismissed: true),
    );
    expect(history.single.alertType, AlertType.lowBalance);
    expect(history.single.dismissedAt, isNot(null));
  });

  test('quiet hours suppress local alert notifications', () async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(minutes: 30));
    final end = now.add(const Duration(minutes: 30));
    await enableSmartAlerts(
      low: false,
      unusual: false,
      recurring: false,
      quietStartHour: start.hour,
      quietStartMinute: start.minute,
      quietEndHour: end.hour,
      quietEndMinute: end.minute,
      largeThreshold: 1000,
    );
    final bankId = await db
        .into(db.bankAccounts)
        .insert(
          BankAccountsCompanion.insert(
            bankName: 'Kotak',
            accountName: 'Main',
            accountType: 'savings',
            currentBalance: const Value(20000),
          ),
        );

    await engine.addTransaction(
      AddTransactionInput(
        type: TransactionType.bank,
        amount: 5000,
        title: 'Flight',
        category: 'Travel',
        transactionDate: DateTime.now(),
        paymentSourceType: PaymentSourceType.bank,
        paymentSourceId: bankId,
      ),
    );
    final txn =
        await (db.select(db.transactions)
              ..orderBy([(t) => OrderingTerm.desc(t.id)])
              ..limit(1))
            .getSingle();
    await alertEngine.evaluateAfterTransaction(txn);

    expect(notifier.sent, isEmpty);
    final persisted = await alertService.getAlerts();
    expect(persisted.any((a) => a.alertType == AlertType.largeExpense), isTrue);
  });
}
