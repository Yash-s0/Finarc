import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database_providers.dart';
import 'backup_service.dart';
import 'import_service.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.read(appDatabaseProvider));
});

final importServiceProvider = Provider<ImportService>((ref) {
  return ImportService(ref.read(appDatabaseProvider));
});
