import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import 'notification_local_notifier.dart';
import 'reminder_service.dart';

final notificationLocalNotifierProvider = Provider<NotificationLocalNotifier>((
  ref,
) {
  return NotificationLocalNotifier();
});

final reminderServiceProvider = Provider<ReminderService>((ref) {
  return ReminderService(
    ref.read(appDatabaseProvider),
    ref.read(notificationLocalNotifierProvider),
  );
});
