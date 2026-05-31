DateTime mergeDateWithExistingTime({
  required DateTime pickedDate,
  required DateTime existing,
}) {
  return DateTime(
    pickedDate.year,
    pickedDate.month,
    pickedDate.day,
    existing.hour,
    existing.minute,
    existing.second,
    existing.millisecond,
    existing.microsecond,
  );
}
