# Finarc Play Data Safety Guidance (Draft)

_Last updated: 2026-06-18_

## Intended Play-safe release behavior
- Offline-first, local-only storage.
- No backend upload in v1.
- No cloud sync in v1.
- No SMS permissions or SMS receiver in Play release.
- Optional notification access may be used for local transaction-like notification detection when enabled by the user.

## Suggested Play Console Data Safety posture
Use final answers only after verifying the exact shipped binary and privacy policy URL.

1. Data collected
- If Play release truly does not transmit user data off-device, answer that data is not collected.

2. Data shared
- No data shared with third parties.

3. Processing scope
- Financial/accounting data is handled locally on-device for app functionality.

4. Backups/exports
- Disclose that users can export local data files manually and that exported files are user-controlled.

5. Permissions
- `POST_NOTIFICATIONS` may be used for local reminders/alerts.
- Play-safe release should not declare `READ_SMS`/`RECEIVE_SMS`.
- Play-safe release may declare a `NotificationListenerService` for optional, user-enabled local notification detection.
- Notification detection should be disclosed as local-only and confirmation-based.

## Plugin telemetry check
Current project dependencies reviewed in `pubspec.yaml` do not indicate analytics SDK/network telemetry by default.
- `package_info_plus`, `path_provider`, `drift`, `flutter_riverpod`, `go_router`, `intl` are not analytics SDKs.

Action: Re-verify before submission if dependencies change.
