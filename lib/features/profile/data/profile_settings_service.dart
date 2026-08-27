import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import 'salary_credit_schedule.dart';

class UserProfileSettings {
  const UserProfileSettings({
    this.name,
    this.monthlySalary,
    this.salaryCreditDay,
    this.salaryCreditRule,
    this.companyName,
  });

  final String? name;
  final double? monthlySalary;
  final int? salaryCreditDay;
  final String? salaryCreditRule;
  final String? companyName;

  SalaryCreditSchedule? get salaryCreditSchedule =>
      SalaryCreditSchedule.fromStorage(
        salaryCreditDay: salaryCreditDay,
        salaryCreditRule: salaryCreditRule,
      );

  String get effectiveGreetingName {
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty) return 'Welcome';
    return trimmed;
  }
}

class ProfileSettingsService {
  const ProfileSettingsService(this._db);

  final AppDatabase _db;

  Future<UserProfileSettings> load() async {
    final row = await _ensureSettingsRow();
    return UserProfileSettings(
      name: row.userName,
      monthlySalary: row.monthlySalary,
      salaryCreditDay: row.salaryCreditDay,
      salaryCreditRule: row.salaryCreditRule,
      companyName: row.companyName,
    );
  }

  Future<void> save(UserProfileSettings profile) async {
    if (profile.monthlySalary != null && profile.monthlySalary! <= 0) {
      throw ArgumentError('Monthly salary must be positive');
    }
    if (profile.salaryCreditDay != null &&
        (profile.salaryCreditDay! < 1 || profile.salaryCreditDay! > 31)) {
      throw ArgumentError('Salary credit day must be between 1 and 31');
    }
    final salaryRule = SalaryCreditRule.fromStorage(profile.salaryCreditRule);
    if (salaryRule != SalaryCreditRule.fixedDay &&
        profile.salaryCreditDay != null) {
      throw ArgumentError(
        'Semantic salary credit rules must not store a fixed day',
      );
    }
    final row = await _ensureSettingsRow();
    await (_db.update(
      _db.appSettings,
    )..where((t) => t.id.equals(row.id))).write(
      AppSettingsCompanion(
        userName: Value(_normalize(profile.name)),
        monthlySalary: Value(profile.monthlySalary),
        salaryCreditDay: Value(profile.salaryCreditDay),
        salaryCreditRule: Value(salaryRule.storageValue),
        companyName: Value(_normalize(profile.companyName)),
      ),
    );
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

  String? _normalize(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
