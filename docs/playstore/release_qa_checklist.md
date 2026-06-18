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

## Notifications and reminders
- [ ] Local reminders/alerts work as expected
- [ ] Release mode does not expose SMS permission or SMS ingestion flows
- [ ] Optional notification access setup works only after user action
- [ ] Detected notification transactions remain pending until user confirmation

## Stability
- [ ] No crashes during smoke test
- [ ] Release mode does not expose debug-only screens/tools
