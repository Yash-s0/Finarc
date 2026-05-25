import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/features/pending/notifications/notification_local_notifier.dart';
import 'package:finarc/features/pending/notifications/reminder_service.dart';

class _FakeLocalNotifier extends NotificationLocalNotifier {
  int shownCount = 0;
  int scheduledCount = 0;
  int cancelCount = 0;
  String? lastTitle;
  String? lastBody;
  int? lastReminderId;
  DateTime? lastTrigger;
  bool lastRepeatDaily = false;
  bool lastRepeatWeekly = false;

  @override
  Future<void> showReminder({
    required String title,
    required String body,
    String route = '/pending',
  }) async {
    shownCount += 1;
    lastTitle = title;
    lastBody = body;
  }

  @override
  Future<void> scheduleReminder({
    required int reminderId,
    required DateTime triggerAt,
    required String title,
    required String body,
    required String route,
    bool repeatDaily = false,
    bool repeatWeekly = false,
  }) async {
    scheduledCount += 1;
    lastReminderId = reminderId;
    lastTrigger = triggerAt;
    lastTitle = title;
    lastBody = body;
    lastRepeatDaily = repeatDaily;
    lastRepeatWeekly = repeatWeekly;
  }

  @override
  Future<void> cancelReminder(int reminderId) async {
    cancelCount += 1;
    lastReminderId = reminderId;
  }
}

void main() {
  late AppDatabase db;
  late _FakeLocalNotifier notifier;
  late ReminderService service;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    notifier = _FakeLocalNotifier();
    service = ReminderService(db, notifier);

    await db
        .into(db.creditCards)
        .insert(
          CreditCardsCompanion.insert(
            bankName: 'HDFC',
            nickname: 'Travel',
            last4: '1234',
            maskedNumber: '**** **** **** 1234',
            creditLimit: 100000,
            billingDay: 5,
            dueDay: 22,
            currentOutstanding: const Value(12400),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  test('pending reminder text generation', () {
    final text = service.pendingReminderText(3);
    expect(text, 'You have 3 transactions waiting for confirmation.');
  });

  test('daily summary generation', () async {
    final now = DateTime.now();
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            type: 'bank',
            amount: 1499,
            title: 'Swiggy',
            category: 'Food',
            transactionDate: now,
            paymentSourceType: 'bank',
            paymentSourceId: 1,
          ),
        );
    await db
        .into(db.pendingTransactions)
        .insert(
          PendingTransactionsCompanion.insert(
            amount: 250,
            merchant: 'Zomato',
            categorySuggestion: 'Food',
            paymentSourceTypeSuggestion: 'upi',
            detectedAt: now,
            transactionDate: now,
            sourceType: 'appNotification',
            rawText: 'Paid ₹250 to Zomato',
            confidenceScore: 0.88,
          ),
        );
    await db
        .into(db.cardBills)
        .insert(
          CardBillsCompanion.insert(
            cardId: 1,
            billedAmount: 12400,
            cycleStartDate: Value(now.subtract(const Duration(days: 30))),
            cycleEndDate: Value(now.subtract(const Duration(days: 1))),
            billingDate: Value(now.subtract(const Duration(days: 1))),
            dueDate: Value(now.add(const Duration(days: 2))),
            status: const Value('billed'),
          ),
        );

    final summary = await service.dailySummaryText();
    expect(summary, contains('Today:'));
    expect(summary, contains('₹1,499'));
    expect(summary, contains('1 pending'));
  });

  test('weekly summary generation', () async {
    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final insideWeek = startOfWeek.add(const Duration(days: 2));
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            type: 'bank',
            amount: 8420,
            title: 'Groceries',
            category: 'Food',
            transactionDate: insideWeek,
            paymentSourceType: 'bank',
            paymentSourceId: 1,
            recoverableAmount: const Value(700),
          ),
        );
    await db
        .into(db.pendingTransactions)
        .insert(
          PendingTransactionsCompanion.insert(
            amount: 300,
            merchant: 'Blinkit',
            categorySuggestion: 'Groceries',
            paymentSourceTypeSuggestion: 'upi',
            detectedAt: now,
            transactionDate: now,
            sourceType: 'appNotification',
            rawText: 'Paid ₹300 to Blinkit',
            confidenceScore: 0.82,
          ),
        );

    final summary = await service.weeklySummaryText();
    expect(summary, contains('This week:'));
    expect(summary, contains('₹8,420'));
    expect(summary, contains('₹700 recoverable'));
    expect(summary, contains('1 pending'));
  });

  test('due bill reminder generation', () async {
    final card = await (db.select(
      db.creditCards,
    )..where((c) => c.id.equals(1))).getSingle();
    final bill = CardBill(
      id: 1,
      cardId: card.id,
      cycleStartDate: DateTime.now().subtract(const Duration(days: 30)),
      cycleEndDate: DateTime.now().subtract(const Duration(days: 1)),
      billingDate: DateTime.now().subtract(const Duration(days: 1)),
      billedAmount: 12400,
      paidAmount: 0,
      dueDate: DateTime.now().add(const Duration(days: 2)),
      status: 'billed',
      createdAt: DateTime.now(),
      paidAt: null,
    );

    final text = service.dueBillReminderText(card, bill);
    expect(text, contains('₹12,400'));
    expect(text, contains('due in'));
  });
}
