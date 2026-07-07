#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

APK_PATH="${1:-}"
if [[ -z "$APK_PATH" ]]; then
  if [[ -f "build/app/outputs/flutter-apk/app-release.apk" ]]; then
    APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
  elif [[ -f "build/app/outputs/apk/release/app-release.apk" ]]; then
    APK_PATH="build/app/outputs/apk/release/app-release.apk"
  else
    echo "Release APK not found. Building release APK first..."
    flutter build apk --release -t lib/main.dart --dart-define=APP_MODE=release
    APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
  fi
fi

if [[ ! -f "$APK_PATH" ]]; then
  echo "ERROR: APK not found at: $APK_PATH"
  exit 1
fi

echo "Auditing APK: $APK_PATH"

if ! command -v unzip >/dev/null 2>&1; then
  echo "ERROR: unzip is required for APK audit."
  exit 1
fi

if ! command -v strings >/dev/null 2>&1; then
  echo "ERROR: strings is required for APK audit."
  exit 1
fi

echo
echo "[1/4] Checking merged release manifest..."
"$ROOT_DIR/scripts/check_play_manifest.sh"

declare -a FORBIDDEN_PATTERNS=()

fail=0

print_result() {
  local status="$1"
  local label="$2"
  printf "%s %s\n" "$status" "$label"
}

echo
echo "[2/4] Scanning DEX entries..."
declare -a dex_entries=()
while IFS= read -r dex; do
  dex_entries+=("$dex")
done < <(unzip -l "$APK_PATH" | awk '{print $4}' | grep -E '^classes[0-9]*\.dex$')
if [[ "${#dex_entries[@]}" -eq 0 ]]; then
  echo "ERROR: No classes*.dex entries found in APK."
  exit 2
fi

echo "Found DEX files: ${dex_entries[*]}"

dex_tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$dex_tmp_dir"
}
trap cleanup EXIT

for dex in "${dex_entries[@]}"; do
  unzip -p "$APK_PATH" "$dex" > "$dex_tmp_dir/$dex"
done

if [[ "${#FORBIDDEN_PATTERNS[@]}" -eq 0 ]]; then
  echo "OK: No DEX string denylist is configured for this release."
fi

if [[ "${#FORBIDDEN_PATTERNS[@]}" -gt 0 ]]; then
  for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
    found=0
    for dex in "${dex_entries[@]}"; do
      if strings "$dex_tmp_dir/$dex" | grep -nE "$pattern" >"$dex_tmp_dir/finarc_apk_audit_match.txt" 2>/dev/null; then
        if [[ "$found" -eq 0 ]]; then
          print_result "FAIL:" "Forbidden pattern in DEX: $pattern"
          found=1
          fail=1
        fi
        echo "  in $dex"
        sed 's/^/    /' "$dex_tmp_dir/finarc_apk_audit_match.txt" | head -n 6
      fi
    done
    if [[ "$found" -eq 0 ]]; then
      print_result "OK:" "Forbidden pattern absent in DEX: $pattern"
    fi

  done
fi

echo
echo "[3/4] Scanning whole APK strings (strict gate)..."
if [[ "${#FORBIDDEN_PATTERNS[@]}" -eq 0 ]]; then
  echo "OK: No APK string denylist is configured for this release."
fi

if [[ "${#FORBIDDEN_PATTERNS[@]}" -gt 0 ]]; then
  for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
    if strings "$APK_PATH" | grep -nE "$pattern" >"$dex_tmp_dir/finarc_apk_audit_whole.txt" 2>/dev/null; then
      print_result "FAIL:" "Forbidden pattern in APK payload: $pattern"
      sed 's/^/    /' "$dex_tmp_dir/finarc_apk_audit_whole.txt" | head -n 6
      fail=1
    else
      print_result "OK:" "Forbidden pattern absent in APK payload: $pattern"
    fi
  done
fi

echo
echo "[4/4] Required checks are enforced via scripts/check_play_manifest.sh"
echo "OK: Notification listener and SMS recovery manifest requirements already validated."

if [[ "$fail" -ne 0 ]]; then
  echo
  echo "Release APK audit failed."
  exit 3
fi

echo
echo "Release APK audit passed: required release manifest entries validated."
