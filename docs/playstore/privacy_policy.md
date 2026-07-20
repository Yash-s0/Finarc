# Finarc Privacy Policy Notes (Draft)

_Last updated: 2026-06-18_

Canonical hosted policy page for release:

- `docs/privacy-policy.html`

## Overview
Finarc is an offline-first, local-first personal finance tracker. Financial data is stored locally on the user's device during normal app usage.

## Data Handling
- Finarc does not require an account or login.
- Finarc does not provide backend upload or cloud sync during normal app usage.
- Finarc does not sell personal data.
- Finarc does not share financial data with third parties.
- Finarc is not a bank, lender, broker, payment processor, insurer, tax advisor, or financial advisor.

## Local Storage
- Accounts, wallets, cards, transactions, splits, recoverables, loans, alerts, settings, and diagnostics are stored in an on-device local database.
- The local SQLite database is plaintext.
- Data remains on-device unless the user manually exports, backs up, imports, restores, shares, or otherwise moves files outside the app.
- Finarc does not store CVV, card expiry, full card number, full bank account number, or bank credentials.

## Backups and Exports
- Backup/export files are user-controlled local files.
- Full backups and CSV exports are plaintext.
- Backup/export files are not automatically transmitted to any server by Finarc.
- Users should store exported backup files securely and delete them when no longer needed.
- Developer Space missed-message exports are separate, user-triggered diagnostic files and may include raw financial message text.

## Notifications and Reminders
- Local reminders and alerts are generated and shown on-device.
- Notification access is optional.
- If the user grants notification access and enables detection, supported financial notifications can be processed locally to create pending transactions.
- Detected transactions require user confirmation before they affect tracked records.
- Chat, social, and email apps are blocked or ignored.
- UPI, payment, wallet, and CRED notification detection is optional and disabled by default unless enabled by the user.

## Play Store Release Scope
- The Play Store/release build may request SMS permissions for local transaction SMS detection and recovery.
- If the user grants SMS permission, Finarc can read transaction-like SMS on-device to create pending transactions for review.
- SMS contents are processed locally for app functionality and are not uploaded by Finarc in normal app usage.
- The Play Store/release build may include the notification listener service for optional, user-enabled transaction-like notification detection.
- Missed-message diagnostic samples remain on-device unless the user explicitly exports them from Developer Space.

## Personal/Debug Builds
- Optional personal/debug builds may include additional local testing capabilities.
- These personal/debug builds are not the Play Store release build.

## Contact
Use `arcnestlabs@gmail.com` unless replaced before publishing.
