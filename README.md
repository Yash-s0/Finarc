# Finarc

Offline-first personal finance tracker with local storage only.

## Build Modes

Runtime mode is controlled via `--dart-define=APP_MODE=...`.

### `safeDebug`
- Play Protect friendly baseline for development/testing.
- No real SMS/listener ingestion.
- Mock ingestion/testing tools work.

### `personalDebug`
- Personal testing only.
- Real SMS/listener ingestion allowed (Android + permissions + component availability).
- May trigger Play Protect warnings; install only on your own device.

### `release`
- Production configuration.

## Build And Install Scripts

```bash
./scripts/build_debug.sh
./scripts/build_personal_debug.sh
./scripts/install_debug.sh
./scripts/install_personal_debug.sh
```

What each script does:
- `build_debug.sh`: builds safe debug APK (`APP_MODE=safeDebug`).
- `build_personal_debug.sh`: builds `personalDebug` via Gradle (`assemblePersonalDebug`) when Java is available; otherwise falls back to Flutter debug build with `APP_MODE=personalDebug`.
- `install_debug.sh`: builds (if needed) and installs safe debug APK through `adb install -r`.
- `install_personal_debug.sh`: builds and installs personalDebug APK through `adb install -r`.

## Internal Diagnostics

In debug/profile builds:
- Profile -> `Open Release Checklist` shows DB schema, build mode, ingestion availability, permissions, and table counts.
- Profile -> `Open Debug Logs` shows local parser/ingestion/alert/migration logs with clear option.

## App Icon / Splash Checklist

Icon and splash verification notes:
- Android launcher icon files: `android/app/src/main/res/mipmap-*/ic_launcher.png`.
- Adaptive icon config: `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`.
- Splash background/icon settings: `android/app/src/main/res/drawable/launch_background.xml` and `android/app/src/main/res/drawable-v21/launch_background.xml`.
- iOS app icon set: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`.
- If old launcher icon persists after changes, uninstall the app and reinstall (launcher cache can keep stale icon).
