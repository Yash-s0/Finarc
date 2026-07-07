import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SmsRuntimeDiagnostics {
  const SmsRuntimeDiagnostics({
    required this.readSmsGranted,
    required this.receiveSmsGranted,
    required this.smsPermissionGranted,
    required this.receiverDeclared,
    required this.receiverEnabled,
    this.lastReceivedAt,
    this.lastSender,
    this.lastCallbackSuccessAt,
    this.lastError,
  });

  final bool readSmsGranted;
  final bool receiveSmsGranted;
  final bool smsPermissionGranted;
  final bool receiverDeclared;
  final bool receiverEnabled;
  final DateTime? lastReceivedAt;
  final String? lastSender;
  final DateTime? lastCallbackSuccessAt;
  final String? lastError;

  static SmsRuntimeDiagnostics empty = const SmsRuntimeDiagnostics(
    readSmsGranted: false,
    receiveSmsGranted: false,
    smsPermissionGranted: false,
    receiverDeclared: false,
    receiverEnabled: false,
  );

  factory SmsRuntimeDiagnostics.fromMap(Map<dynamic, dynamic> map) {
    DateTime? toDate(dynamic value) {
      final millis = (value is num) ? value.toInt() : 0;
      if (millis <= 0) return null;
      return DateTime.fromMillisecondsSinceEpoch(millis);
    }

    return SmsRuntimeDiagnostics(
      readSmsGranted: map['readSmsGranted'] == true,
      receiveSmsGranted: map['receiveSmsGranted'] == true,
      smsPermissionGranted: map['smsPermissionGranted'] == true,
      receiverDeclared: map['receiverDeclared'] == true,
      receiverEnabled: map['receiverEnabled'] == true,
      lastReceivedAt: toDate(map['lastReceivedAtMillis']),
      lastSender: map['lastSender'] as String?,
      lastCallbackSuccessAt: toDate(map['lastCallbackSuccessAtMillis']),
      lastError: map['lastError'] as String?,
    );
  }
}

class SmsPreviewRow {
  const SmsPreviewRow({
    required this.packageName,
    required this.appName,
    required this.sender,
    required this.title,
    required this.body,
    required this.receivedAt,
    required this.sourceType,
    required this.isOngoing,
    required this.category,
  });

  final String packageName;
  final String appName;
  final String sender;
  final String title;
  final String body;
  final DateTime receivedAt;
  final String sourceType;
  final bool isOngoing;
  final String category;

  factory SmsPreviewRow.fromMap(Map<dynamic, dynamic> map) {
    final receivedAtMillis =
        (map['receivedAt'] as num?)?.toInt() ??
        DateTime.now().millisecondsSinceEpoch;
    return SmsPreviewRow(
      packageName: (map['packageName'] as String?) ?? 'android.sms',
      appName: (map['appName'] as String?) ?? 'SMS',
      sender: (map['sender'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      body: (map['body'] as String?) ?? '',
      receivedAt: DateTime.fromMillisecondsSinceEpoch(receivedAtMillis),
      sourceType: (map['sourceType'] as String?) ?? 'sms',
      isOngoing: (map['isOngoing'] as bool?) ?? false,
      category: (map['category'] as String?) ?? 'sms',
    );
  }

  Map<String, Object?> toPayloadMap() {
    return {
      'packageName': packageName,
      'appName': appName,
      'sender': sender,
      'title': title,
      'body': body,
      'bigText': null,
      'subText': null,
      'receivedAt': receivedAt.millisecondsSinceEpoch,
      'sourceType': sourceType,
      'isOngoing': isOngoing,
      'category': category,
    };
  }
}

class SmsPermissionService {
  static const MethodChannel _channel = MethodChannel(
    'finarc/notification_control',
  );

  Future<bool> isPermissionGranted() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final granted = await _channel.invokeMethod<bool>(
        'isSmsPermissionGranted',
      );
      return granted ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> isReadPermissionGranted() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final granted = await _channel.invokeMethod<bool>(
        'isReadSmsPermissionGranted',
      );
      return granted ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> isReceivePermissionGranted() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final granted = await _channel.invokeMethod<bool>(
        'isReceiveSmsPermissionGranted',
      );
      return granted ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> isReceiverComponentAvailable() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final available = await _channel.invokeMethod<bool>(
        'isSmsReceiverComponentAvailable',
      );
      return available ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> isReceiverComponentEnabled() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final enabled = await _channel.invokeMethod<bool>(
        'isSmsReceiverComponentEnabled',
      );
      return enabled ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> shouldShowPermissionRationale() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final show = await _channel.invokeMethod<bool>(
        'shouldShowSmsPermissionRationale',
      );
      return show ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<SmsRuntimeDiagnostics> getRuntimeDiagnostics() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return SmsRuntimeDiagnostics.empty;
    }
    try {
      final map = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getSmsReceiverDiagnostics',
      );
      if (map == null) return SmsRuntimeDiagnostics.empty;
      return SmsRuntimeDiagnostics.fromMap(map);
    } on MissingPluginException {
      return SmsRuntimeDiagnostics.empty;
    } on PlatformException {
      return SmsRuntimeDiagnostics.empty;
    }
  }

  Future<bool> requestPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final granted = await _channel.invokeMethod<bool>('requestSmsPermission');
      return granted ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> openAppPermissionSettings() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>('openAppPermissionSettings');
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  Future<int> scanRecentSms(int days) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return 0;
    try {
      final count = await _channel.invokeMethod<int>('scanRecentSms', {
        'days': days,
      });
      return count ?? 0;
    } on MissingPluginException {
      return 0;
    } on PlatformException {
      return 0;
    }
  }

  Future<List<SmsPreviewRow>> previewRecentSms(int days) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const [];
    }
    try {
      final rows = await _channel.invokeMethod<List<dynamic>>(
        'previewRecentSms',
        {'days': days},
      );
      if (rows == null) return const [];
      return rows
          .whereType<Map<dynamic, dynamic>>()
          .map(SmsPreviewRow.fromMap)
          .toList(growable: false);
    } on MissingPluginException {
      return const [];
    } on PlatformException {
      return const [];
    }
  }

  Future<List<SmsPreviewRow>> previewSmsRange({
    required DateTime from,
    required DateTime to,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const [];
    }
    try {
      final rows = await _channel
          .invokeMethod<List<dynamic>>('previewSmsRange', {
            'fromMillis': from.millisecondsSinceEpoch,
            'toMillis': to.millisecondsSinceEpoch,
          });
      if (rows == null) return const [];
      return rows
          .whereType<Map<dynamic, dynamic>>()
          .map(SmsPreviewRow.fromMap)
          .toList(growable: false);
    } on MissingPluginException {
      return const [];
    } on PlatformException {
      return const [];
    }
  }
}
