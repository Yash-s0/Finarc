#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GRADLE_APK="$ROOT_DIR/android/app/build/outputs/apk/personalDebug/app-personalDebug.apk"
FALLBACK_APK="$ROOT_DIR/build/app/outputs/flutter-apk/app-debug.apk"

"$ROOT_DIR/scripts/build_personal_debug.sh"

if [[ -f "$GRADLE_APK" ]]; then
  adb install -r "$GRADLE_APK"
  echo "Installed personalDebug APK from: $GRADLE_APK"
else
  adb install -r "$FALLBACK_APK"
  echo "Installed personalDebug fallback APK from: $FALLBACK_APK"
fi
