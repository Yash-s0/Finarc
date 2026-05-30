import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  final repoRoot = Directory.current.path;
  final scriptPath = p.join(repoRoot, 'scripts', 'check_play_manifest.sh');

  Future<ProcessResult> runScriptWithManifest(String manifestContent) async {
    final tempDir = await Directory.systemTemp.createTemp(
      'finarc_manifest_check_',
    );
    final manifestPath = p.join(tempDir.path, 'AndroidManifest.xml');
    await File(manifestPath).writeAsString(manifestContent);

    final result = await Process.run(
      'bash',
      [scriptPath],
      environment: {'MERGED_MANIFEST_OVERRIDE': manifestPath},
      workingDirectory: repoRoot,
    );

    await tempDir.delete(recursive: true);
    return result;
  }

  test('allows notification listener and blocks no-SMS manifest', () async {
    const manifest = '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  <application>
    <service
      android:name=".FinarcNotificationListenerService"
      android:permission="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE">
      <intent-filter>
        <action android:name="android.service.notification.NotificationListenerService"/>
      </intent-filter>
    </service>
  </application>
</manifest>
''';
    final result = await runScriptWithManifest(manifest);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(
      result.stdout.toString(),
      contains('Notification listener allowed; SMS permissions absent.'),
    );
  });

  test('fails when READ_SMS is present', () async {
    const manifest = '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  <uses-permission android:name="android.permission.READ_SMS" />
  <application>
    <service
      android:name=".FinarcNotificationListenerService"
      android:permission="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE">
      <intent-filter>
        <action android:name="android.service.notification.NotificationListenerService"/>
      </intent-filter>
    </service>
  </application>
</manifest>
''';
    final result = await runScriptWithManifest(manifest);
    expect(result.exitCode, isNot(0));
    expect(
      result.stdout.toString(),
      contains(
        'FAIL: Found forbidden entry in release manifest: READ_SMS permission',
      ),
    );
  });
}
