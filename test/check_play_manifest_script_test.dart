import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  final repoRoot = Directory.current.path;
  final scriptPath = p.join(repoRoot, 'scripts', 'check_play_manifest.sh');
  final fixturesDir = p.join(repoRoot, 'test', 'fixtures', 'manifests');

  Future<ProcessResult> runScriptWithFixture(String fixtureFileName) {
    final manifestPath = p.join(fixturesDir, fixtureFileName);
    return Process.run(
      'bash',
      [scriptPath],
      environment: {'MERGED_MANIFEST_OVERRIDE': manifestPath},
      workingDirectory: repoRoot,
    );
  }

  test('allows valid Play release manifest fixture', () async {
    final result = await runScriptWithFixture('play_release_valid.xml');
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(
      result.stdout.toString(),
      contains('Notification listener and SMS recovery entries present.'),
    );
  });

  test('fails when READ_SMS is missing', () async {
    final result = await runScriptWithFixture(
      'play_release_invalid_read_sms.xml',
    );
    expect(result.exitCode, isNot(0));
    expect(
      result.stdout.toString(),
      contains(
        'FAIL: Missing required release manifest entry: READ_SMS permission',
      ),
    );
  });

  test('fails when RECEIVE_SMS is missing', () async {
    final result = await runScriptWithFixture(
      'play_release_invalid_receive_sms.xml',
    );
    expect(result.exitCode, isNot(0));
    expect(
      result.stdout.toString(),
      contains(
        'FAIL: Missing required release manifest entry: RECEIVE_SMS permission',
      ),
    );
  });

  test('fails when SMS receiver declaration is missing', () async {
    final result = await runScriptWithFixture(
      'play_release_invalid_sms_receiver.xml',
    );
    expect(result.exitCode, isNot(0));
    expect(
      result.stdout.toString(),
      contains(
        'FAIL: Missing required release manifest entry: FinarcSmsReceiver declaration',
      ),
    );
  });

  test('fails when SMS_RECEIVED intent filter is missing', () async {
    final result = await runScriptWithFixture(
      'play_release_invalid_sms_received_intent.xml',
    );
    expect(result.exitCode, isNot(0));
    expect(
      result.stdout.toString(),
      contains(
        'FAIL: Missing required release manifest entry: SMS_RECEIVED intent filter',
      ),
    );
  });

  test('fails when notification listener service is missing', () async {
    final result = await runScriptWithFixture(
      'play_release_missing_listener_service.xml',
    );
    expect(result.exitCode, isNot(0));
    expect(
      result.stdout.toString(),
      contains(
        'FAIL: Missing required release manifest entry: Notification listener service declaration',
      ),
    );
  });

  test('fails when notification listener permission is missing', () async {
    final result = await runScriptWithFixture(
      'play_release_missing_listener_permission.xml',
    );
    expect(result.exitCode, isNot(0));
    expect(
      result.stdout.toString(),
      contains(
        'FAIL: Missing required release manifest entry: Notification listener service permission',
      ),
    );
  });

  test('fails when notification listener action is missing', () async {
    final result = await runScriptWithFixture(
      'play_release_missing_listener_action.xml',
    );
    expect(result.exitCode, isNot(0));
    expect(
      result.stdout.toString(),
      contains(
        'FAIL: Missing required release manifest entry: Notification listener intent action',
      ),
    );
  });
}
