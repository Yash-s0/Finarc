import '../../../core/database/app_database.dart';
import '../../cards/data/billing_service.dart';
import '../../loans/data/loan_service.dart';
import '../../split/data/split_service.dart';

class NetWorthBreakdown {
  const NetWorthBreakdown({
    required this.bankBalance,
    required this.cashBalance,
    required this.cardLiability,
    required this.loanOutstanding,
    required this.recoverables,
    required this.splitReceivables,
    required this.splitPayables,
    required this.monthlyEmiBurden,
  });

  final double bankBalance;
  final double cashBalance;
  final double cardLiability;
  final double loanOutstanding;
  final double recoverables;
  final double splitReceivables;
  final double splitPayables;
  final double monthlyEmiBurden;

  double get liquidAssets => bankBalance + cashBalance;

  double get totalAssets => liquidAssets + recoverables + splitReceivables;

  double get totalLiabilities =>
      cardLiability + loanOutstanding + splitPayables;

  @Deprecated('Use cardLiability')
  double get cardDues => cardLiability;

  double get netWorth => totalAssets - totalLiabilities;

  double get debtRatio {
    if (totalAssets <= 0) return totalLiabilities > 0 ? 1 : 0;
    return totalLiabilities / totalAssets;
  }

  double get payableAmount => splitPayables;
}

class NetWorthService {
  const NetWorthService(
    this._db,
    this._loanService,
    this._splitService,
    this._billingService,
  );

  final AppDatabase _db;
  final LoanService _loanService;
  final SplitService _splitService;
  final BillingService _billingService;

  Future<NetWorthBreakdown> calculate() async {
    final banks = await _db.select(_db.bankAccounts).get();
    final wallets = await _db.select(_db.cashWallets).get();
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
    final cardSnapshots = await _billingService.getAllCardBillingSnapshots();
    final cardLiability = cardSnapshots.fold<double>(
      0,
      (sum, snapshot) => sum + snapshot.totalOutstanding,
    );
    final loanOutstanding = await _loanService.getTotalLoanOutstanding();
    final monthlyEmiBurden = await _loanService.getMonthlyEmiBurden();

    final txns = await _db.select(_db.transactions).get();
    final recoverables = txns.fold<double>(0, (sum, txn) {
      if (txn.linkedSplitExpenseId != null || !txn.isForOthers) return sum;
      final base =
          txn.recoverableBaseAmount ??
          (txn.amount - txn.cashbackAmount).clamp(0, txn.amount).toDouble();
      final recovered = (txn.recoveredAmount).clamp(0, base).toDouble();
      final remaining = (base - recovered).clamp(0, base).toDouble();
      return sum + remaining;
    });

    return NetWorthBreakdown(
      bankBalance: bankBalance,
      cashBalance: cashBalance,
      cardLiability: cardLiability,
      loanOutstanding: loanOutstanding,
      recoverables: recoverables,
      splitReceivables: splitReceivables,
      splitPayables: splitPayables,
      monthlyEmiBurden: monthlyEmiBurden,
    );
  }
}
