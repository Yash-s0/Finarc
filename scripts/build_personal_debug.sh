#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

if command -v java >/dev/null 2>&1 && java -version >/dev/null 2>&1; then
  (
    cd android
    ./gradlew assemblePersonalDebug
  )
  echo "Built personalDebug APK at: android/app/build/outputs/apk/personalDebug/app-personalDebug.apk"
else
  echo "Java runtime not found. Falling back to Flutter debug build with personalDebug mode define."
  flutter build apk --debug --dart-define=APP_MODE=personalDebug
  echo "Built fallback personalDebug APK at: build/app/outputs/flutter-apk/app-debug.apk"
fi
