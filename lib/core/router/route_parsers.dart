class RouteParsers {
  static int? pathInt(Map<String, String> pathParameters, String key) {
    final raw = pathParameters[key];
    if (raw == null || raw.isEmpty) return null;
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  static int? queryInt(Map<String, String> queryParameters, String key) {
    final raw = queryParameters[key];
    if (raw == null || raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  static double queryDouble(
    Map<String, String> queryParameters,
    String key, {
    double fallback = 0,
  }) {
    final raw = queryParameters[key];
    return double.tryParse(raw ?? '') ?? fallback;
  }
}
