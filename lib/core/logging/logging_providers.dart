import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_log_service.dart';

final appLogServiceProvider = Provider<AppLogService>((ref) {
  return globalAppLogService;
});

final appDiskLogsProvider = FutureProvider<List<AppLogEntry>>((ref) async {
  return ref.read(appLogServiceProvider).readFromDisk();
});
