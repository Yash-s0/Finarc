class NotificationPayload {
  const NotificationPayload({
    required this.packageName,
    required this.sourceType,
    required this.receivedAt,
    this.postTime,
    this.appName,
    this.sender,
    this.title,
    this.body,
    this.bigText,
    this.subText,
    this.isOngoing = false,
    this.category,
  });

  final String packageName;
  final String? appName;
  final String? sender;
  final String? title;
  final String? body;
  final String? bigText;
  final String? subText;
  final DateTime receivedAt;
  final DateTime? postTime;
  final String sourceType;
  final bool isOngoing;
  final String? category;

  DateTime get captureTime => postTime ?? receivedAt;

  String get combinedText {
    return _dedupeTextParts([
      if (title != null && title!.trim().isNotEmpty) title!.trim(),
      if (body != null && body!.trim().isNotEmpty) body!.trim(),
      if (bigText != null && bigText!.trim().isNotEmpty) bigText!.trim(),
      if (subText != null && subText!.trim().isNotEmpty) subText!.trim(),
    ]).join(' ').trim();
  }

  factory NotificationPayload.fromMap(Map<dynamic, dynamic> map) {
    final receivedAtMillis =
        (map['receivedAt'] as num?)?.toInt() ??
        DateTime.now().millisecondsSinceEpoch;
    final postTimeMillis = (map['postTime'] as num?)?.toInt();
    return NotificationPayload(
      packageName: (map['packageName'] as String?) ?? '',
      appName: map['appName'] as String?,
      sender: map['sender'] as String?,
      title: map['title'] as String?,
      body: map['body'] as String?,
      bigText: map['bigText'] as String?,
      subText: map['subText'] as String?,
      receivedAt: DateTime.fromMillisecondsSinceEpoch(receivedAtMillis),
      postTime: postTimeMillis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(postTimeMillis),
      sourceType: (map['sourceType'] as String?) ?? 'appNotification',
      isOngoing: (map['isOngoing'] as bool?) ?? false,
      category: map['category'] as String?,
    );
  }
}

List<String> _dedupeTextParts(List<String> parts) {
  final seen = <String>{};
  final output = <String>[];
  for (final part in parts) {
    final normalized = part
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty || seen.contains(normalized)) continue;
    seen.add(normalized);
    output.add(part);
  }
  return output;
}
