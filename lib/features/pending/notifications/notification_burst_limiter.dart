class NotificationBurstLimiter {
  NotificationBurstLimiter({
    this.maxEvents = 24,
    this.window = const Duration(minutes: 1),
  }) : assert(maxEvents > 0);

  final int maxEvents;
  final Duration window;
  final Map<String, List<DateTime>> _eventsBySource = {};

  bool isAllowed(String sourceKey, DateTime now) {
    final normalizedKey = sourceKey.trim().toLowerCase();
    final key = normalizedKey.isEmpty ? 'unknown' : normalizedKey;
    final cutoff = now.subtract(window);
    final events = _eventsBySource.putIfAbsent(key, () => <DateTime>[])
      ..removeWhere((eventAt) => eventAt.isBefore(cutoff));

    if (events.length >= maxEvents) {
      return false;
    }

    events.add(now);
    return true;
  }
}
