# Finarc Play Release Checklist

## Build and platform
- [ ] Target SDK meets current Play requirement (API 35+ preferred)
- [ ] Signed release AAB generated
- [ ] Version code/name incremented
- [ ] Final app ID verified

## Permissions and policy
- [ ] Play release manifest has `READ_SMS` for local transaction SMS recovery
- [ ] Play release manifest has `RECEIVE_SMS` for local transaction SMS detection
- [ ] Play release manifest has `FinarcSmsReceiver`
- [ ] Play release manifest has Notification Listener service for optional user-enabled local detection
- [ ] SMS/Call Log permission declaration completed in Play Console, if required
- [ ] Privacy policy URL prepared and hosted
- [ ] Data Safety form completed accurately
- [ ] Content rating questionnaire completed

## Store setup
- [ ] App access instructions reviewed (test account not required)
- [ ] Screenshots prepared
- [ ] Feature graphic/icon assets ready
- [ ] App icon and splash behavior verified on device

## In-app disclosures
- [ ] Backup/export warning visible to users
- [ ] Financial disclaimer included (not a bank, no financial advice)

## QA sign-off
- [ ] Full release QA checklist completed
