# Pending Transaction and Notification Improvements

Date: 2026-07-06

## What We Have Done

### Notification ingestion and parsing

- Added stronger handling for card payment settlement notifications so CRED, bank SMS, and destination-card receipt messages are treated as card payment confirmations instead of normal expenses.
- Added merge logic for multi-message card payments so source debit, destination receipt, and processor confirmation can collapse into one pending card payment.
- Improved mirrored SMS handling from messaging apps for transactional senders.
- Added support for Amazon Pay wallet spend notifications.
- Added Amazon Pay balance sync from notifications that include an updated balance.
- Added local notification feedback when Amazon Pay balance changes.
- Added duplicate suppression for repeated notification bodies, UPI references, and near-duplicate transactions.

### Bill due notification handling

- Added card bill due classification so bill reminders do not become expense transactions.
- Added support for total due and minimum due style card bill messages.
- Added support for overdue reminder wording like:
  `Credit card bill of ₹4,126.95 for Yes Bank card - 8731 was due on 4th Jul`
- Added ordinal date parsing for due dates like `4th Jul`.
- Ordinal due dates without a year now handle New Year boundaries, so `1st Jan` from December resolves to the next year and `31st Dec` from January resolves to the previous year.
- If a bill due notification matches an already paid bill with the same amount, it is ignored quietly.
- If a bill due notification matches the remaining due on a partially paid bill, it is verified as a remaining-due reminder instead of treated as a mismatch.
- Bill matching now scores due date, statement cycle timing, notification date, and amount closeness to avoid matching stale or future duplicate bill rows.
- If the notification amount differs from the paid bill amount, the app creates a warning alert instead of reopening or overwriting the bill.
- If the notification amount differs from an unpaid local bill, the app creates a mismatch warning and does not overwrite the local amount.
- If no matching card exists, the app creates a review alert instead of creating a pending expense.
- Bill mismatch alerts now open the bill detail screen in a review state with app amount, notification amount, difference, remaining due, and next-action guidance.

### Manual recovery and developer visibility

- Added a `Paste Message` screen at `/pending/paste` so users can manually paste missed SMS/notification text.
- Added a home FAB quick action for `Paste Missed Message`.
- Added pending-screen empty-state and app-bar access to the paste flow.
- Manual pasted messages are previewed before ingestion and show a short parse explanation.
- Manual paste attempts are logged into Developer Space so missed patterns can be inspected later.
- Developer Space now keeps manual paste diagnostics visible.

### Pending transaction UX

- Made the confirm transaction sheet scrollable so long raw text does not block actions like `Ignore`.
- Added better pending history visibility for ignored/duplicate/failed parse decisions.
- Avoided auto-clearing useful developer diagnostics for ignored notifications.

### Tests and verification

- Added and updated focused tests in `test/notification_ingestion_test.dart`.
- Added service-level tests for Amazon Pay wallet balance sync behavior.
- Verified with:
  - `flutter test test/notification_ingestion_test.dart`
  - `flutter test test/app_shell_test.dart test/app_shell_responsive_test.dart test/pending_service_test.dart test/notification_diagnostics_service_test.dart`
  - `flutter analyze`

## Current Expected Behavior

- Normal card spends should still create pending expense transactions.
- Card payment settlement messages should create or merge into card payment pending entries.
- Card bill due reminders should not create expense transactions.
- Paid bill reminders with matching amount should be ignored quietly.
- Paid or unpaid bill reminders with amount mismatch should notify the user with a warning.
- Amazon Pay wallet spend notifications should create a wallet pending transaction and update wallet balance when the notification includes updated balance.
- Missed messages can be pasted manually from an always-available app entry point.

## Known Edge Cases

- A paid bill reminder can match the wrong bill cycle if several bills for the same card have nearby due dates.
- Partial payments need careful handling: a reminder for the full amount should not be treated as fully paid unless the local bill is actually settled.
- The current amount match tolerance is `₹1`, which handles rounding but could hide a small fee or interest mismatch.
- Messages that only include minimum due should not be treated as the total bill amount.
- Cards from different issuers can share the same last four digits; issuer extraction must stay strong.
- Date-only messages like `4th Jul` use the notification capture year, which can be wrong around New Year.
- Repeated bank reminders are deduped by issuer, card, amount, and due date, so later reminders may not create additional alerts.
- If no local bill exists, the notification can create an external bill; later billing reconciliation should avoid creating a duplicate cycle.
- Notification text that repeats the same message multiple times currently uses the first parsed amount/date/card.
- Promotional or fee amounts such as `₹0 fees` must not be selected as the transaction or bill amount.
- Messaging notifications without sender metadata may be blocked before parsing unless a transactional sender code is present.

## Recommended Next Steps

1. Done: Add an in-app review screen for bill mismatch alerts.
2. Done: Add explicit partial-payment rules for bill due notifications.
3. Done: Add cycle-aware bill matching that uses billing date, due date, amount, and notification date together.
4. Done: Add tests for year-boundary dates like `31st Dec` and `1st Jan`.
5. Next: Add tests for same last four digits across multiple issuers.
6. Add tests for minimum-due-only notifications.
7. Add developer-space filters for `bill due`, `card payment`, `wallet balance`, `manual paste`, and `parser failed`.
8. Persist manual paste learning samples in a structured table instead of only diagnostics/logs.
9. Add an export option for missed-message samples so parser improvements can be reviewed outside the app.
10. Add a small release QA checklist for notification capture, manual paste, ignore flow, bill mismatch, and wallet balance sync.

## Release Note Summary

- Improved notification detection for card payments, card bill reminders, and Amazon Pay wallet transactions.
- Added a manual paste option for missed messages.
- Added better developer diagnostics for ignored and missed notifications.
- Reduced false expense detection for card bill due reminders.
