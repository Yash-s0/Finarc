import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

class OnboardingService {
  const OnboardingService(this._db);

  final AppDatabase _db;

  Future<bool> hasCompletedOnboarding() async {
    final row = await _ensureSettingsRow();
    return row.hasCompletedOnboarding;
  }

  Future<void> setCompleted(bool completed) async {
    final row = await _ensureSettingsRow();
    await (_db.update(_db.appSettings)..where((t) => t.id.equals(row.id)))
        .write(AppSettingsCompanion(hasCompletedOnboarding: Value(completed)));
  }

  Future<AppSetting> _ensureSettingsRow() async {
    final rows = await (_db.select(
      _db.appSettings,
    )..orderBy([(t) => OrderingTerm.desc(t.id)])).get();
    if (rows.isNotEmpty) {
      final primary = rows.first;
      if (rows.length > 1) {
        final extraIds = rows.skip(1).map((e) => e.id).toList(growable: false);
        await (_db.delete(
          _db.appSettings,
        )..where((t) => t.id.isIn(extraIds))).go();
      }
      return primary;
    }

    final id = await _db
        .into(_db.appSettings)
        .insert(
          AppSettingsCompanion.insert(
            isDarkMode: const Value(true),
            hasCompletedOnboarding: const Value(false),
          ),
        );
    return (_db.select(
      _db.appSettings,
    )..where((t) => t.id.equals(id))).getSingle();
  }
}
