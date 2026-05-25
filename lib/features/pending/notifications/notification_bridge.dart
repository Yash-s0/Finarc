import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'notification_payload.dart';

typedef NotificationPayloadHandler =
    Future<void> Function(NotificationPayload payload);
typedef NotificationRouteHandler = FutureOr<void> Function(String route);

class NotificationBridge with WidgetsBindingObserver {
  static const EventChannel _events = EventChannel(
    'finarc/notification_events',
  );
  static const MethodChannel _control = MethodChannel(
    'finarc/notification_control',
  );

  StreamSubscription<dynamic>? _subscription;
  NotificationPayloadHandler? _onPayload;
  NotificationRouteHandler? _onRoute;
  bool _initialized = false;

  Future<void> initialize({
    required NotificationPayloadHandler onPayload,
    required NotificationRouteHandler onRoute,
  }) async {
    if (_initialized) return;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    _initialized = true;
    _onPayload = onPayload;
    _onRoute = onRoute;

    WidgetsBinding.instance.addObserver(this);

    try {
      // Probe native channel first to avoid stream activation exceptions
      // during hot restart windows where channels are not ready yet.
      await _control.invokeMethod<bool>('isNotificationAccessEnabled');

      _subscription = _events.receiveBroadcastStream().listen(
        (event) async {
          if (event is Map<dynamic, dynamic>) {
            await _onPayload?.call(NotificationPayload.fromMap(event));
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (error is MissingPluginException || error is PlatformException) {
            unawaited(_subscription?.cancel());
            _subscription = null;
          }
        },
      );

      final queued =
          await _control.invokeMethod<List<dynamic>>(
            'drainCapturedNotifications',
          ) ??
          [];
      for (final item in queued) {
        if (item is Map<dynamic, dynamic>) {
          await _onPayload?.call(NotificationPayload.fromMap(item));
        }
      }
      await _consumeLaunchRoute();
    } on MissingPluginException {
      _subscription = null;
    } on PlatformException {
      _subscription = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_consumeLaunchRoute());
    }
  }

  Future<void> _consumeLaunchRoute() async {
    try {
      final route = await _control.invokeMethod<String>('consumeLaunchRoute');
      if (route != null && route.isNotEmpty) {
        await Future.sync(() => _onRoute?.call(route));
      }
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _subscription?.cancel();
    _subscription = null;
    _initialized = false;
  }
}
