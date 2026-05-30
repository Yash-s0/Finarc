import 'package:finarc/core/config/app_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    AppModeConfig.debugOverride = null;
  });

  test('default mode in non-release is safeDebug', () {
    expect(AppModeConfig.current, AppMode.safeDebug);
    expect(AppModeConfig.isSafeDebug, isTrue);
    expect(AppModeConfig.label, 'safeDebug');
  });
}
