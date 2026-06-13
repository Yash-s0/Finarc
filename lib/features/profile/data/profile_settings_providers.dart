import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import 'profile_settings_service.dart';

final profileSettingsServiceProvider = Provider<ProfileSettingsService>((ref) {
  return ProfileSettingsService(ref.read(appDatabaseProvider));
});

final userProfileSettingsProvider = FutureProvider<UserProfileSettings>((
  ref,
) async {
  await ref.watch(seedProvider.future);
  return ref.read(profileSettingsServiceProvider).load();
});

final greetingNameProvider = Provider<String>((ref) {
  final profile = ref.watch(userProfileSettingsProvider).valueOrNull;
  return profile?.effectiveGreetingName ?? 'Welcome';
});
