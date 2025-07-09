# ZimLearn – Developer Setup Guide

_Last updated • 09 Jul 2025_

---

## 1  Prerequisites & System Requirements

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| **OS** | Windows 10 / macOS 12 / Ubuntu 22.04 | Latest LTS |
| **CPU** | x64 / Apple Silicon | 4+ cores |
| **RAM** | 8 GB | 16 GB+ |
| **Disk** | 10 GB free | SSD with 25 GB+ |
| **Flutter SDK** | 3.13 | 3.19+ (stable) |
| **Dart** | Bundled with Flutter | ≥ 3.1 |
| **Android Studio / Xcode** | Flamingo / 15 | Latest stable |
| **Node (for hooks)** | 18 | 20 |
| **Git** | 2.40 | latest |

> Tip: On Apple Silicon install Flutter via `brew install --cask flutter`.

---

## 2  Development Environment Setup

### 2.1 Clone the Repository

```bash
git clone https://github.com/djval79/ZimLearn.git
cd ZimLearn
```

### 2.2 Install Flutter Dependencies

```bash
flutter doctor       # verify tool-chain
flutter pub get      # fetch packages
```

### 2.3 Environment Variables

1. Copy example file:

```bash
cp assets/.env.example assets/.env
```

2. Fill in API URLs, Firebase keys, feature flags.  
   **Never commit the real `.env`.**

### 2.4 Generate Code

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This creates Hive adapters & JSON serialisable files.

### 2.5 Run the App

```bash
# Choose device – e.g. emulator or physical
flutter run -d <device-id>
```

---

## 3  IDE Configuration

### 3.1 VS Code

* Install extensions:  
  * Dart & Flutter, Bloc Extension, Error Lens, Flutter Intl.
* `.vscode/` folder already contains recommended settings & launch configs.
* Enable **Format on Save** (`editor.formatOnSave`).

### 3.2 Android Studio / IntelliJ

* Install **Flutter** & **Dart** plugins.
* Enable _Analyze ➜ Inspect Code_ on commit.
* Use the _Flutter ➜ Select Device_ toolbar to switch emulators.

### 3.3 Pre-Commit Hooks _(optional)_

```bash
git config core.hooksPath .git/hooks
```

Add in `.git/hooks/pre-commit`:

```bash
#!/bin/sh
dart format .
flutter analyze
```

Make executable `chmod +x .git/hooks/pre-commit`.

---

## 4  Firebase Setup

1. **Create Project** → _ZimLearn Dev_ in Firebase Console.  
2. **Add App** per platform (`android`, `ios`, `web`).  
3. Download `google-services.json` (Android) & `GoogleService-Info.plist` (iOS) into:
   * `android/app/`
   * `ios/Runner/`
4. Add **Web config** to `web/firebase.js` if targeting web.
5. Enable services:
   * **Authentication** → Email/Password, Google.
   * **Firestore** _(road-map)_ / **Realtime DB** _(optional)_.
   * **Crashlytics**, **Analytics**.
6. Update values in `assets/.env`:

```
FIREBASE_API_KEY=...
FIREBASE_APP_ID=...
```

7. Run `flutterfire configure` (requires `dart pub global activate flutterfire_cli`) to auto-generate `firebase_options.dart`.

---

## 5  Testing Setup

| Layer | Command |
|-------|---------|
| **Unit / Widget** | `flutter test` |
| **Coverage** | `flutter test --coverage` |
| **Golden** | `flutter test --update-goldens` |
| **Integration** | `flutter drive --target=test_driver/app.dart` |

### 5.1 Mocking

* Use **mocktail** in tests: `when(() => authService.login(...)).thenAnswer(...)`.

### 5.2 Continuous Integration

The repo includes **GitHub Actions**:

```
.github/workflows/flutter.yml
```

Stages: _format → analyze → test → build_.

---

## 6  Build & Deployment

### 6.1 Android

```bash
flutter build apk --flavor production --dart-define-from-file=assets/.env
```

### 6.2 iOS

```bash
flutter build ipa --flavor production --dart-define-from-file=assets/.env
```

Requires Xcode code-signing & provisioning profile.

### 6.3 Web

```bash
flutter build web --release --base-href / --pwa-strategy offline-first
```

Host on Firebase Hosting or Netlify.

### 6.4 Firebase App Distribution

```
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-production.apk \
  --app <FIREBASE_APP_ID> --groups "internal-testers"
```

---

## 7  Troubleshooting Common Issues

| Symptom | Fix |
|---------|-----|
| `Command PhaseScriptExecution failed with a nonzero exit code` (iOS) | `cd ios && pod install --repo-update` then clean build folder. |
| Android build fails with `minSdkVersion` | Ensure `android/local.properties` sets `flutter.minSdkVersion=21`. |
| `MissingPluginException` hot reload | Fully stop & restart the app; plugins registered at startup. |
| Hive error: _box not found_ | Run code-gen, ensure adapters registered in `ServiceLocator.init()`. |
| `Gradle JVM out of memory` | Edit `gradle.properties`: `org.gradle.jvmargs=-Xmx4096m`. |
| Firebase auth returns `BLOCKED_BY_CORS` (web) | Add domain to Authorized Domains in Firebase console. |
| `flutter doctor` shows Xcode issues | Accept Xcode license: `sudo xcodebuild -license accept`. |
| Lint failures on CI | Run `dart format . && flutter analyze` locally before PR. |
| Emulator no network | Toggle airplane mode or restart `adb` server. |

---

Happy hacking! For questions ping **@djval79** or open a GitHub Discussion.
