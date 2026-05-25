class NotificationPayload {
  const NotificationPayload({
    required this.packageName,
    required this.sourceType,
    required this.receivedAt,
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
  final String sourceType;
  final bool isOngoing;
  final String? category;

  String get combinedText {
    return [
      if (title != null && title!.trim().isNotEmpty) title!.trim(),
      if (body != null && body!.trim().isNotEmpty) body!.trim(),
      if (bigText != null && bigText!.trim().isNotEmpty) bigText!.trim(),
      if (subText != null && subText!.trim().isNotEmpty) subText!.trim(),
    ].join(' ').trim();
  }

  factory NotificationPayload.fromMap(Map<dynamic, dynamic> map) {
    final millis =
        (map['receivedAt'] as num?)?.toInt() ??
        DateTime.now().millisecondsSinceEpoch;
    return NotificationPayload(
      packageName: (map['packageName'] as String?) ?? '',
      appName: map['appName'] as String?,
      sender: map['sender'] as String?,
      title: map['title'] as String?,
      body: map['body'] as String?,
      bigText: map['bigText'] as String?,
      subText: map['subText'] as String?,
      receivedAt: DateTime.fromMillisecondsSinceEpoch(millis),
      sourceType: (map['sourceType'] as String?) ?? 'appNotification',
      isOngoing: (map['isOngoing'] as bool?) ?? false,
      category: map['category'] as String?,
    );
  }
}
