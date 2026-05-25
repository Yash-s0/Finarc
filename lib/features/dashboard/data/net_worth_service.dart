import '../../../core/database/app_database.dart';
import '../../loans/data/loan_service.dart';
import '../../split/data/split_service.dart';

class NetWorthBreakdown {
  const NetWorthBreakdown({
    required this.bankBalance,
    required this.cashBalance,
    required this.cardDues,
    required this.loanOutstanding,
    required this.recoverables,
    required this.splitReceivables,
    required this.splitPayables,
    required this.monthlyEmiBurden,
  });

  final double bankBalance;
  final double cashBalance;
  final double cardDues;
  final double loanOutstanding;
  final double recoverables;
  final double splitReceivables;
  final double splitPayables;
  final double monthlyEmiBurden;

  double get liquidAssets => bankBalance + cashBalance;

  double get totalAssets => liquidAssets + recoverables + splitReceivables;

  double get totalLiabilities => cardDues + loanOutstanding + splitPayables;

  double get netWorth => totalAssets - totalLiabilities;

  double get debtRatio {
    if (totalAssets <= 0) return totalLiabilities > 0 ? 1 : 0;
    return totalLiabilities / totalAssets;
  }

  double get payableAmount => splitPayables;
}

class NetWorthService {
  const NetWorthService(this._db, this._loanService, this._splitService);

  final AppDatabase _db;
  final LoanService _loanService;
  final SplitService _splitService;

  Future<NetWorthBreakdown> calculate() async {
    final banks = await _db.select(_db.bankAccounts).get();
    final wallets = await _db.select(_db.cashWallets).get();
    final cards = await _db.select(_db.creditCards).get();
    final txns = await _db.select(_db.transactions).get();

    final splitReceivables = await _splitService.getCurrentUserReceivables();
    final splitPayables = await _splitService.getCurrentUserPayables();

    final bankBalance = banks.fold<double>(
      0,
      (sum, item) => sum + item.currentBalance,
    );
    final cashBalance = wallets.fold<double>(
      0,
      (sum, item) => sum + item.currentBalance,
    );
    final cardDues = cards.fold<double>(
      0,
      (sum, item) => sum + item.currentOutstanding,
    );
    final loanOutstanding = await _loanService.getTotalLoanOutstanding();
    final monthlyEmiBurden = await _loanService.getMonthlyEmiBurden();

    final recoverables = txns.fold<double>(
      0,
      (sum, txn) =>
          sum +
          (txn.linkedSplitExpenseId == null ? (txn.recoverableAmount ?? 0) : 0),
    );

    return NetWorthBreakdown(
      bankBalance: bankBalance,
      cashBalance: cashBalance,
      cardDues: cardDues,
      loanOutstanding: loanOutstanding,
      recoverables: recoverables,
      splitReceivables: splitReceivables,
      splitPayables: splitPayables,
      monthlyEmiBurden: monthlyEmiBurden,
    );
  }
}
