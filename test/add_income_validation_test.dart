import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/core/database/app_database.dart';
import 'package:finarc/features/expenses/data/transaction_engine.dart';
import 'package:finarc/features/expenses/models/transaction_types.dart';

void main() {
  test('invalid income payload is blocked', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final engine = TransactionEngine(db);

    expect(
      () => engine.addTransaction(
        AddTransactionInput(
          type: TransactionType.income,
          amount: 0,
          title: 'Salary',
          category: 'Salary',
          transactionDate: DateTime(2026, 5, 26),
          paymentSourceType: PaymentSourceType.bank,
          paymentSourceId: 1,
        ),
      ),
      throwsArgumentError,
    );

    expect(
      () => engine.addTransaction(
        AddTransactionInput(
          type: TransactionType.income,
          amount: 1000,
          title: 'Salary',
          category: 'Salary',
          transactionDate: DateTime(2026, 5, 26),
          paymentSourceType: PaymentSourceType.bank,
          paymentSourceId: null,
        ),
      ),
      throwsArgumentError,
    );
  });
}
