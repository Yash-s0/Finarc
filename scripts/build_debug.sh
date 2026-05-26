#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
flutter build apk --debug --dart-define=APP_MODE=safeDebug

echo "Built safe debug APK at: build/app/outputs/flutter-apk/app-debug.apk"
