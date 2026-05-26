import '../../../core/config/app_mode.dart';
import '../../../core/database/app_database.dart';

class ReleaseDiagnostics {
  const ReleaseDiagnostics({
    required this.schemaVersion,
    required this.appMode,
    required this.bankAccountsCount,
    required this.cashWalletsCount,
    required this.creditCardsCount,
    required this.transactionsCount,
    required this.pendingTransactionsCount,
    required this.alertsCount,
  });

  final int schemaVersion;
  final String appMode;
  final int bankAccountsCount;
  final int cashWalletsCount;
  final int creditCardsCount;
  final int transactionsCount;
  final int pendingTransactionsCount;
  final int alertsCount;
}

class ReleaseDiagnosticsService {
  const ReleaseDiagnosticsService(this._db);

  final AppDatabase _db;

  Future<ReleaseDiagnostics> load() async {
    Future<int> countTable(String table) async {
      final row = await _db
          .customSelect('SELECT COUNT(*) AS c FROM $table')
          .getSingle();
      return row.read<int>('c');
    }

    return ReleaseDiagnostics(
      schemaVersion: _db.schemaVersion,
      appMode: AppModeConfig.label,
      bankAccountsCount: await countTable('bank_accounts'),
      cashWalletsCount: await countTable('cash_wallets'),
      creditCardsCount: await countTable('credit_cards'),
      transactionsCount: await countTable('transactions'),
      pendingTransactionsCount: await countTable('pending_transactions'),
      alertsCount: await countTable('alerts'),
    );
  }
}
