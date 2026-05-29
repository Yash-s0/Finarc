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
- Real SMS/listener ingestion enabled for personal testing (Android + permission + component availability).
- May trigger Play Protect warnings; install only on your own device.

### `playRelease`
- Play-safe release path.
- No `READ_SMS`/`RECEIVE_SMS`.
- No SMS receiver registration.
- No notification-listener service registration.
- Ingestion appears unavailable in app instead of broken.

## Build Scripts

```bash
./scripts/build_debug.sh
./scripts/build_personal_debug.sh
./scripts/install_debug.sh
./scripts/install_personal_debug.sh
./scripts/check_play_manifest.sh
./scripts/build_play_release.sh
```

What each script does:
- `build_debug.sh`: builds safe debug APK (`APP_MODE=safeDebug`).
- `build_personal_debug.sh`: builds `personalDebug` via Gradle (`assemblePersonalDebug`) when Java runtime is available; otherwise falls back to Flutter debug build with `APP_MODE=personalDebug`.
- `install_debug.sh`: builds (if needed) and installs safe debug APK via `adb install -r`.
- `install_personal_debug.sh`: builds and installs personalDebug APK via `adb install -r`.
- `check_play_manifest.sh`: validates merged release manifest and fails on restricted SMS/listener entries.
- `build_play_release.sh`: runs analyze + tests + release AAB build + manifest validation.

## Signing Setup (Local Only)

Do not commit signing secrets.

1. Generate upload keystore (example):
```bash
keytool -genkeypair -v -storetype PKCS12 -keystore android/app/upload-keystore.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

2. Create `android/key.properties` locally:
```properties
storeFile=app/upload-keystore.jks
storePassword=YOUR_STORE_PASSWORD
keyAlias=upload
keyPassword=YOUR_KEY_PASSWORD
```

3. Ensure secrets are ignored by git:
- `android/key.properties`
- `*.jks`
- `*.keystore`

4. Build signed AAB:
```bash
flutter build appbundle --release --dart-define=APP_MODE=release
```

Output path:
- `build/app/outputs/bundle/release/app-release.aab`

## Internal Diagnostics

In debug/profile builds:
- Profile -> `Open Release Checklist` shows DB schema, build mode, ingestion availability, permissions, and table counts.
- Profile -> `Open Debug Logs` shows local parser/ingestion/alert/migration logs with clear option.

## App Icon / Splash Checklist

Icon and splash verification notes:
- Android launcher icons: `android/app/src/main/res/mipmap-*/ic_launcher.png`
- Android adaptive icon config: `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`
- Android splash config: `android/app/src/main/res/drawable/launch_background.xml` and `android/app/src/main/res/drawable-v21/launch_background.xml`
- iOS app icons: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- If old launcher icon persists after updates: uninstall and reinstall (launcher cache can keep stale icon).
