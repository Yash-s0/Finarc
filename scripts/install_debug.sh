#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APK_PATH="$ROOT_DIR/build/app/outputs/flutter-apk/app-debug.apk"

if [[ ! -f "$APK_PATH" ]]; then
  "$ROOT_DIR/scripts/build_debug.sh"
fi

adb install -r "$APK_PATH"
echo "Installed safe debug APK from: $APK_PATH"
