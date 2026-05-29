#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "Running flutter analyze..."
flutter analyze

echo "Running flutter test..."
flutter test

echo "Building Play-safe release app bundle..."
flutter build appbundle --release --dart-define=APP_MODE=release

echo "Validating release merged manifest..."
"$ROOT_DIR/scripts/check_play_manifest.sh"

AAB_PATH="$ROOT_DIR/build/app/outputs/bundle/release/app-release.aab"
if [[ -f "$AAB_PATH" ]]; then
  echo
  echo "Play release AAB ready: $AAB_PATH"
else
  echo
  echo "WARNING: AAB path not found at expected location: $AAB_PATH"
fi
