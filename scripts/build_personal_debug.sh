#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

ANDROID_STUDIO_JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"

if command -v java >/dev/null 2>&1 && java -version >/dev/null 2>&1; then
  (
    cd android
    ./gradlew -Ptarget=lib/main_personal.dart assemblePersonalDebug
  )
  echo "Built personalDebug APK at: build/app/outputs/apk/personalDebug/app-personalDebug.apk"
elif [[ -x "$ANDROID_STUDIO_JAVA_HOME/bin/java" ]]; then
  (
    cd android
    JAVA_HOME="$ANDROID_STUDIO_JAVA_HOME" ./gradlew -Ptarget=lib/main_personal.dart assemblePersonalDebug
  )
  echo "Built personalDebug APK at: build/app/outputs/apk/personalDebug/app-personalDebug.apk"
else
  echo "Java runtime not found. Falling back to Flutter debug build with personalDebug mode define."
  flutter build apk --debug -t lib/main_personal.dart --dart-define=APP_MODE=personalDebug
  echo "Built fallback personalDebug APK at: build/app/outputs/flutter-apk/app-debug.apk"
fi
