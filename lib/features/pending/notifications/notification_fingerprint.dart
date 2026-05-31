import 'notification_payload.dart';

class NotificationFingerprint {
  final Map<String, DateTime> _seen = {};

  String build({
    required NotificationPayload payload,
    double? amount,
    String? merchant,
  }) {
    final input = [
      payload.packageName,
      payload.sourceType,
      payload.title ?? '',
      payload.body ?? '',
      amount?.toStringAsFixed(2) ?? '',
      merchant?.toLowerCase() ?? '',
    ].join('|');
    return _fnv1a64(input);
  }

  bool isDuplicate(
    String fingerprint,
    DateTime now, {
    Duration window = const Duration(minutes: 3),
  }) {
    final existing = _seen[fingerprint];
    if (existing != null && now.difference(existing) <= window) {
      return true;
    }
    _seen[fingerprint] = now;

    _seen.removeWhere(
      (_, seenAt) => now.difference(seenAt) > const Duration(minutes: 10),
    );
    return false;
  }

  String _fnv1a64(String input) {
    var hash = 0xcbf29ce484222325;
    const prime = 0x100000001b3;
    for (final code in input.codeUnits) {
      hash ^= code;
      hash = (hash * prime) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16);
  }
}
