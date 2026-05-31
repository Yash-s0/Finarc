import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import '../../expenses/data/expenses_providers.dart';
import 'transaction_import_service.dart';

final transactionImportServiceProvider = Provider<TransactionImportService>((
  ref,
) {
  return TransactionImportService(
    ref.read(appDatabaseProvider),
    ref.read(transactionEngineProvider),
  );
});
