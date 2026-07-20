# Finarc Release QA Checklist

## Core flows
- [ ] Fresh install succeeds
- [ ] Onboarding completes
- [ ] Add account flow works
- [ ] Add card flow works
- [ ] Add expense flow works
- [ ] Add income flow works
- [ ] Card bill flow works
- [ ] Split flow works
- [ ] Loan flow works

## Data and safety
- [ ] Backup/export works
- [ ] Import restore works
- [ ] Reset data works
- [ ] Normal backup/export does not include missed-message diagnostic samples
- [ ] Developer Space sample export warns that raw financial message text may be included

## Notifications and reminders
- [ ] Local reminders/alerts work as expected
- [ ] Optional SMS Access setup is visible only after user action
- [ ] SMS detection remains off until the user grants permission and enables it
- [ ] SMS recovery creates pending transactions only for user-selected local scans
- [ ] Optional notification access setup works only after user action
- [ ] Detected notification transactions remain pending until user confirmation
- [ ] Manual paste creates a pending item or saves a parser-failed sample for review
- [ ] Ignore and duplicate flows do not affect confirmed transactions
- [ ] Card bill mismatch review opens the expected bill review route
- [ ] Wallet balance sync updates the selected wallet without creating a false expense

## Stability
- [ ] No crashes during smoke test
- [ ] Release mode does not expose debug-only screens/tools
- [ ] Developer Space filters show bill due, card payment, wallet balance, manual paste, and parser failed samples correctly
