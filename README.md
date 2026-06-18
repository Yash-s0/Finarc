# Finarc

Finarc is an offline-first, local-first personal finance tracker built with Flutter. It helps track accounts, wallets, credit cards, income, expenses, loans, recoverables, split expenses, alerts, and financial snapshots without requiring an account, login, backend, or cloud sync.

Finarc is a personal record-keeping tool only. It does not provide banking, payment processing, lending, insurance, investment, crypto, trading, money-transfer services, or financial advice.

## App Overview

Finarc is designed for users who want a private, on-device view of their personal finances. The app stores financial records locally, keeps automated detection workflows behind user confirmation, and gives users direct control over backups, exports, imports, and reset actions.

Primary workflows include:

- Tracking bank accounts, cash wallets, Amazon Pay wallet balances, credit cards, loans, transactions, recoverables, and split expenses.
- Reviewing dashboard summaries such as net worth, recent activity, financial snapshots, dues, reminders, and mismatches.
- Detecting transaction-like financial notifications into pending transactions for manual user review.
- Exporting, importing, backing up, and resetting app data from profile controls.

## Key Features

- **Accounts and wallets:** Bank accounts, cash wallets, Amazon Pay wallet, balances, transfers, reconciliation, and adjustment entries.
- **Expenses and income:** Income/expense transactions processed through a transaction engine.
- **Credit cards:** Card tracking, billing cycles, dues, refunds, cashback, card payment transactions, and partial or full bill payment flows.
- **Dashboard:** Net worth, summaries, recent activity, financial snapshots, dues, and alerts.
- **Pending transactions:** Optional notification-based transaction detection that creates pending items for review.
- **Alerts and reminders:** Dues, reminders, mismatches, recurring merchant alerts, and financial events.
- **Loans:** Loan and EMI tracking, including company deduction support.
- **Split expenses:** Split expense groups with guarded edit/delete behavior.
- **Recoverables:** Person-level recoverables and partial recovery tracking.
- **Analytics:** Spending, income, net worth, card, and loan insights.
- **Profile and data controls:** Settings, backup, restore, import, export, privacy/security controls, diagnostics, and reset actions.

## Privacy-First / Local-First Design

- Finarc is offline-first and local-first.
- No account or login is required.
- There is no backend service or cloud sync in normal app usage.
- Financial data stays on the device unless the user explicitly exports, backs up, imports, restores, shares, or otherwise moves a file outside the app.
- Notification access is optional and is used only for detecting transaction-like financial notifications.
- Detected notification transactions are not posted automatically. They become pending transactions and require user confirmation before becoming app records.
- Chat, social, and email apps are blocked or ignored by the notification detection policy.
- UPI, payment, wallet, and CRED notification detection is optional and disabled by default unless enabled by the user.

## Architecture Overview

Finarc uses a modular Flutter architecture:

- `lib/core`: Routing, theme, app configuration, database access, backup/import/reset services, and shared utilities.
- `lib/shared`: Reusable UI components and app-wide presentation widgets.
- `lib/features/accounts`: Account, wallet, transfer, reconciliation, and adjustment workflows.
- `lib/features/expenses`: Income and expense entry, validation, and transaction behavior.
- `lib/features/cards`: Credit card billing, dues, payments, refunds, and cashback behavior.
- `lib/features/dashboard`: Summaries, snapshots, recent activity, alerts, and drilldowns.
- `lib/features/pending`: Notification ingestion, parsing, pending transaction review, diagnostics, and detection settings.
- `lib/features/alerts`: Reminder and alert behavior.
- `lib/features/loans`: Loan and EMI tracking.
- `lib/features/split`: Split expense groups.
- `lib/features/recoverables`: Recoverable balances and repayments.
- `lib/features/analytics`: Analytics models, services, and charts.
- `lib/features/profile`: Settings, data controls, release diagnostics, backup/restore, import/export, and reset workflows.

State and service access are handled with Riverpod providers. Persistent data is stored on-device through Drift over SQLite. Android-specific notification and ingestion integration is implemented in Kotlin under `android/app/src`.

## Tech Stack

- Flutter and Dart
- Riverpod
- Drift and SQLite
- GoRouter
- Kotlin Android native integration
- Android `NotificationListenerService`
- Local notifications
- JSON backup/import
- CSV export
- Flutter tests and Android manifest checks

## Release Build Policy

Finarc has separate build modes for safe development, personal testing, and Play Store release behavior.

Runtime mode is controlled with `--dart-define=APP_MODE=...`.

### `safeDebug`

- Play Protect friendly baseline for development and testing.
- No real SMS/listener ingestion.
- Mock ingestion and test tools can be used.

### `personalDebug`

- Personal testing only.
- May include additional local ingestion tools for personal testing.
- May trigger platform warnings depending on enabled Android components and permissions.
- Not intended for Play Store release.

### `playRelease` / release

- Play-safe release path.
- No `READ_SMS` permission.
- No `RECEIVE_SMS` permission.
- No SMS receiver registration.
- Notification listener service is present for optional, user-enabled transaction-like notification detection.
- Release manifest checks fail if restricted SMS permissions or SMS receivers are present.

## Notification Detection Behavior

Notification access is optional. If the user grants access and enables detection settings, Finarc can inspect supported financial notifications locally to identify transaction-like events.

Important behavior:

- Notifications are processed locally on the device.
- Notification contents are not uploaded to a backend during normal app usage.
- Detected events become pending transactions.
- Pending transactions require user confirmation before they affect account, wallet, card, loan, recoverable, or split expense records.
- Unsupported or blocked app categories such as chat, social, and email apps are ignored.
- Optional UPI/payment/wallet/CRED provider detection remains disabled until the user enables it.

## Data Storage and Backup/Export Behavior

- App data is stored in an on-device SQLite database managed through Drift.
- The local database is plaintext SQLite.
- Backups and exports are user-controlled files.
- Full backups and CSV exports are plaintext files.
- Backup/export/restore UI warns users to keep files private.
- Android platform backup is disabled.
- JSON backup/import and CSV export are intended for user-controlled portability and recovery.
- Finarc does not automatically transmit backup or export files to any server.

## Security and Privacy Notes

- Finarc does not store CVV, card expiry, full card number, full bank account number, or bank credentials.
- Only masked or last-four card/account details may be stored.
- Local database files and exported files may be readable on compromised, rooted, or poorly secured devices.
- Plaintext backups and CSV exports should be stored privately and deleted when no longer needed.
- Users can reset/delete local app data from profile data controls.
- Finarc is not a bank, broker, lender, payment processor, insurer, tax advisor, or financial advisor.

Privacy policy:

- [docs/privacy-policy.html](docs/privacy-policy.html)
- Draft Play Store policy notes: [docs/playstore/privacy_policy.md](docs/playstore/privacy_policy.md)
- Play Data Safety guidance: [docs/playstore/data_safety.md](docs/playstore/data_safety.md)

## Build and Test Commands

Common local commands:

```bash
flutter pub get
flutter analyze
flutter test
dart run build_runner build --delete-conflicting-outputs
```

Build and install scripts:

```bash
./scripts/build_debug.sh
./scripts/build_personal_debug.sh
./scripts/install_debug.sh
./scripts/install_personal_debug.sh
./scripts/check_play_manifest.sh
./scripts/build_play_release.sh
```

Script summary:

- `build_debug.sh`: Builds safe debug APK with `APP_MODE=safeDebug`.
- `build_personal_debug.sh`: Builds `personalDebug` for local personal testing.
- `install_debug.sh`: Builds if needed and installs the safe debug APK with `adb install -r`.
- `install_personal_debug.sh`: Builds and installs the personal debug APK with `adb install -r`.
- `check_play_manifest.sh`: Validates merged Play/release manifests and fails on restricted SMS permissions or receivers.
- `build_play_release.sh`: Runs analyze, tests, release APK/AAB builds, manifest validation, and release APK audit.

Play release output paths:

- AAB: `build/app/outputs/bundle/release/app-release.aab`
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- R8 mapping: `build/app/outputs/mapping/release/mapping.txt`

## Project Structure

```text
android/                  Android native integration, manifests, Gradle config
assets/                   App fonts and static assets
docs/playstore/           Play Store release notes, checklists, and data safety drafts
ios/                      iOS runner project
lib/core/                 App core: routing, theme, database, backup/import/reset, config
lib/features/             Feature modules for finance workflows
lib/shared/               Shared UI components and presentation helpers
scripts/                  Build, install, release, and manifest audit scripts
test/                     Flutter unit and widget tests
web/                      Flutter web shell assets
```

## Known Limitations / Future Improvements

- The local SQLite database is plaintext. Database encryption is a future security improvement.
- Backup and export files are plaintext. Users must protect exported files.
- There is no cloud sync or multi-device account system.
- Notification detection depends on Android notification availability, user permission, provider formats, and local parser support.
- Notification detection can require user correction because provider message formats can change.
- Finarc does not integrate with bank APIs and cannot verify account balances against financial institutions.
- Finarc does not move money, process payments, provide credit, or make investment recommendations.

## Play Store Release Notes

Release documentation is maintained under `docs/playstore/`:

- [Release checklist](docs/playstore/release_checklist.md)
- [Release QA checklist](docs/playstore/release_qa_checklist.md)
- [Store listing draft](docs/playstore/store_listing.md)
- [Data Safety guidance](docs/playstore/data_safety.md)
- [Privacy policy draft](docs/playstore/privacy_policy.md)

Before Play Store submission:

- Host `docs/privacy-policy.html` or equivalent static page and add the final hosted URL in Play Console.
- Verify `./scripts/build_play_release.sh` passes for the exact submitted artifact.
- Re-check the final merged manifest for no SMS permissions or SMS receiver.
- Confirm Data Safety answers match the exact released binary and privacy policy.

## Signing Setup (Local Only)

Do not commit signing secrets.

1. Generate upload keystore:

```bash
keytool -genkeypair -v -storetype PKCS12 -keystore android/app/upload-keystore.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

2. Create `android/key.properties` locally:

```properties
storeFile=app/upload-keystore.jks
storePassword=YOUR_STORE_PASSWORD
keyAlias=upload
keyPassword=YOUR_KEY_PASSWORD
```

3. Ensure secrets are ignored by git:

- `android/key.properties`
- `*.jks`
- `*.keystore`

## Internal Diagnostics

In debug/profile builds:

- Profile -> `Open Release Checklist` shows DB schema, build mode, ingestion availability, permissions, and table counts.
- Profile -> `Open Debug Logs` shows local parser, ingestion, alert, and migration logs with a clear option.

## App Icon / Splash Checklist

Icon and splash verification notes:

- Android launcher icons: `android/app/src/main/res/mipmap-*/ic_launcher.png`
- Android adaptive icon config: `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`
- Android splash config: `android/app/src/main/res/drawable/launch_background.xml` and `android/app/src/main/res/drawable-v21/launch_background.xml`
- iOS app icons: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- If an old launcher icon persists after updates, uninstall and reinstall because launcher cache can keep stale icons.
