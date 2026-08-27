enum SalaryCreditRule {
  fixedDay,
  firstDayOfMonth,
  lastDayOfMonth;

  static SalaryCreditRule fromStorage(String? value) {
    switch (value) {
      case 'firstDayOfMonth':
        return SalaryCreditRule.firstDayOfMonth;
      case 'lastDayOfMonth':
        return SalaryCreditRule.lastDayOfMonth;
      case 'fixedDay':
      default:
        return SalaryCreditRule.fixedDay;
    }
  }

  String? get storageValue {
    switch (this) {
      case SalaryCreditRule.fixedDay:
        return null;
      case SalaryCreditRule.firstDayOfMonth:
        return 'firstDayOfMonth';
      case SalaryCreditRule.lastDayOfMonth:
        return 'lastDayOfMonth';
    }
  }
}

class SalaryCreditSchedule {
  const SalaryCreditSchedule.fixedDay(int day)
    : rule = SalaryCreditRule.fixedDay,
      fixedDay = day;

  const SalaryCreditSchedule.firstDayOfMonth()
    : rule = SalaryCreditRule.firstDayOfMonth,
      fixedDay = null;

  const SalaryCreditSchedule.lastDayOfMonth()
    : rule = SalaryCreditRule.lastDayOfMonth,
      fixedDay = null;

  final SalaryCreditRule rule;
  final int? fixedDay;

  static SalaryCreditSchedule? fromStorage({
    required int? salaryCreditDay,
    required String? salaryCreditRule,
  }) {
    final rule = SalaryCreditRule.fromStorage(salaryCreditRule);
    switch (rule) {
      case SalaryCreditRule.fixedDay:
        if (salaryCreditDay == null) return null;
        return SalaryCreditSchedule.fixedDay(salaryCreditDay);
      case SalaryCreditRule.firstDayOfMonth:
        return const SalaryCreditSchedule.firstDayOfMonth();
      case SalaryCreditRule.lastDayOfMonth:
        return const SalaryCreditSchedule.lastDayOfMonth();
    }
  }

  int resolveDay(int year, int month) {
    final lastDay = daysInMonth(year, month);
    switch (rule) {
      case SalaryCreditRule.fixedDay:
        final day = fixedDay ?? 1;
        if (day < 1) return 1;
        if (day > lastDay) return lastDay;
        return day;
      case SalaryCreditRule.firstDayOfMonth:
        return 1;
      case SalaryCreditRule.lastDayOfMonth:
        return lastDay;
    }
  }

  DateTime resolveDate(int year, int month) {
    return DateTime(year, month, resolveDay(year, month));
  }

  String get displayLabel {
    switch (rule) {
      case SalaryCreditRule.fixedDay:
        return fixedDay == null ? 'Select day (1 - 31)' : '$fixedDay';
      case SalaryCreditRule.firstDayOfMonth:
        return 'First day of month';
      case SalaryCreditRule.lastDayOfMonth:
        return 'Last day of month';
    }
  }

  String get profileLabel {
    switch (rule) {
      case SalaryCreditRule.fixedDay:
        return fixedDay == null ? 'Add salary day' : '$fixedDay';
      case SalaryCreditRule.firstDayOfMonth:
        return 'First day of month';
      case SalaryCreditRule.lastDayOfMonth:
        return 'Last day of month';
    }
  }

  String get salaryInsightPrefix {
    switch (rule) {
      case SalaryCreditRule.fixedDay:
        return 'Salary expected';
      case SalaryCreditRule.firstDayOfMonth:
        return 'Salary expected on the first day of the month';
      case SalaryCreditRule.lastDayOfMonth:
        return 'Salary expected on the last day of the month';
    }
  }
}

int daysInMonth(int year, int month) {
  return DateTime(year, month + 1, 0).day;
}
