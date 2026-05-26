import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import 'release_diagnostics_service.dart';

final releaseDiagnosticsServiceProvider = Provider<ReleaseDiagnosticsService>((
  ref,
) {
  return ReleaseDiagnosticsService(ref.read(appDatabaseProvider));
});

final releaseDiagnosticsProvider = FutureProvider<ReleaseDiagnostics>((
  ref,
) async {
  return ref.read(releaseDiagnosticsServiceProvider).load();
});
