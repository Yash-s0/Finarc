#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

MERGED_MANIFEST="${MERGED_MANIFEST_OVERRIDE:-}"

if [[ -z "$MERGED_MANIFEST" ]]; then
  CANDIDATE_PATHS=(
    "build/app/intermediates/merged_manifest/playRelease/processPlayReleaseMainManifest/AndroidManifest.xml"
    "build/app/intermediates/merged_manifests/playRelease/processPlayReleaseManifest/AndroidManifest.xml"
    "build/app/intermediates/bundle_manifest/playRelease/processApplicationManifestPlayReleaseForBundle/AndroidManifest.xml"
    "build/app/intermediates/merged_manifest/release/processReleaseMainManifest/AndroidManifest.xml"
    "build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml"
    "build/app/intermediates/bundle_manifest/release/processApplicationManifestReleaseForBundle/AndroidManifest.xml"
  )

  for p in "${CANDIDATE_PATHS[@]}"; do
    if [[ -f "$p" ]]; then
      MERGED_MANIFEST="$p"
      break
    fi
  done
fi

if [[ -z "$MERGED_MANIFEST" ]]; then
  echo "ERROR: Could not find a merged Play/release manifest."
  echo "Build the release artifact first, then rerun this check."
  echo "Checked paths:"
  for p in "${CANDIDATE_PATHS[@]}"; do
    echo "  - $p"
  done
  exit 1
fi

echo "Using merged manifest: $MERGED_MANIFEST"

fail=0

check_forbidden() {
  local pattern="$1"
  local label="$2"
  if grep -qE "$pattern" "$MERGED_MANIFEST"; then
    echo "FAIL: Found forbidden entry in release manifest: $label"
    grep -nE "$pattern" "$MERGED_MANIFEST" || true
    fail=1
  else
    echo "OK: $label not present"
  fi
}

check_forbidden "android\.permission\.READ_SMS" "READ_SMS permission"
check_forbidden "android\.permission\.RECEIVE_SMS" "RECEIVE_SMS permission"
check_forbidden "FinarcSmsReceiver" "FinarcSmsReceiver declaration"
check_forbidden "SMS_RECEIVED" "SMS_RECEIVED intent filter"

check_required() {
  local pattern="$1"
  local label="$2"
  if grep -qE "$pattern" "$MERGED_MANIFEST"; then
    echo "OK: $label present"
  else
    echo "FAIL: Missing required release manifest entry: $label"
    fail=1
  fi
}

check_required "FinarcNotificationListenerService" "Notification listener service declaration"
check_required "BIND_NOTIFICATION_LISTENER_SERVICE" "Notification listener service permission"
check_required "android\.service\.notification\.NotificationListenerService" "Notification listener intent action"

if [[ "$fail" -ne 0 ]]; then
  echo
  echo "Play manifest check failed."
  exit 2
fi

echo
echo "Notification listener allowed; SMS permissions absent."
echo "Play manifest check passed."
