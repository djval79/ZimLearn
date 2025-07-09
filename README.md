# ZimLearn 📚🇿🇼

ZimLearn is an **offline-first, multilingual educational platform** for Zimbabwean learners.  
It combines the official **ZIMSEC curriculum** with **entrepreneurship**, **gamified learning**, an **AI tutor**, and rich **glassmorphism UI** to create an engaging 21-st-century learning experience for children from **ECD to Form 4**.

---

## ✨ Core Features

| Category | Highlights |
|----------|------------|
| Curriculum | • Full ZIMSEC syllabus<br>• Grade-aware lessons & quizzes<br>• Offline content download |
| Pedagogy  | • Adaptive AI tutor (GPT-powered)<br>• Interactive games & simulations<br>• Business simulation module |
| UX / UI   | • Modern glassmorphic dashboard<br>• Light/Dark themes<br>• Vibrant animations for younger kids |
| Tech      | • Flutter 3.13 / Dart 3.1<br>• BLoC + Hydrated BLoC<br>• Hive encrypted local DB<br>• Service-locator with GetIt |
| Platform  | • Android, iOS, Web (beta)<br>• In-App Purchases & subscriptions<br>• Firebase analytics & crashlytics |

---

## 🏗️ Project Structure

```text
zimlearn/
├── lib/
│   ├── core/            # constants, services, localization
│   ├── data/            # Hive models, repositories
│   ├── features/        # feature-first folders (dashboard, auth, ai_tutor…)
│   ├── routing/         # GoRouter setup
│   └── main.dart
├── assets/              # images, audio, videos, curriculum JSON, .env
├── test/                # unit & widget tests
└── pubspec.yaml
```

### Architectural Overview

1. **Feature-First Packages** – UI, BLoC, and data live together per feature.  
2. **BLoC State Management** – `flutter_bloc` with `hydrated_bloc` for offline persistence.  
3. **Service Locator** – `GetIt` registers `StorageService`, `AuthService`, etc., via `ServiceLocator.init()`.  
4. **Local Storage** – Encrypted **Hive** boxes + secure keys in `flutter_secure_storage`.  
5. **Networking** – `dio` with interceptors (auth, logging, retry).  
6. **Presentation** – Glassmorphic widgets reusable across the app (`GlassmorphicCard`, `AnimatedGlassmorphicButton`…).  
7. **CI / CD** – GitHub Actions template (lint, test, build).  

---

## 🚀 Quick Start

### 1. Prerequisites

- Flutter ≥ 3.13 (`flutter --version`)
- Dart ≥ 3.1 (bundled with Flutter)
- Android Studio / Xcode CLI tools
- For web: Chrome or Edge 115+

### 2. Clone & Install

```bash
git clone https://github.com/<your-org>/zimlearn.git
cd zimlearn

# Get packages
flutter pub get
```

### 3. Configure Environment

Copy default env and adjust values:

```bash
cp assets/.env assets/.env.local   # or edit assets/.env directly
```

Key variables:

```
ENVIRONMENT=development
API_URL_DEVELOPMENT=https://dev-api.zimlearn.org
ENABLE_OFFLINE_MODE=true
```

### 4. Generate Code

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 5. Run

```bash
# Android / iOS
flutter run

# Web
flutter run -d chrome
```

---

## 🧪 Testing

```bash
# Unit & widget tests
flutter test

# Lint
flutter analyze
```

> **Tip**: Enable **coverage** with `flutter test --coverage` and view via `lcov`.

---

## 🔑 Development Guidelines

### Git Workflow

1. `main` – stable, auto-deployed.
2. `develop` – integration branch.
3. `feature/<ticket-id>-description` – PR into `develop`.
4. Use **Conventional Commits** (`feat:`, `fix:`…) & PR templates.

### Coding Standards

- **Dart 3** null-safety everywhere.
- `flutter_lints` rules enforced.
- Favor **composition over inheritance** for widgets.
- Keep widgets < 200 LOC; split builders/helpers.
- Write tests for all BLoCs, services, & critical widgets.

### Commit Hooks

```
pre-commit:  flutter format . && flutter analyze
pre-push:    flutter test
```

Install with `dart pub global activate git_hooks` or Husky for node-based projects.

---

## 🤝 Contributing

1. Fork the repo & create feature branch.  
2. Follow the Git workflow & guidelines above.  
3. Submit a pull request; the CI must pass.  
4. Maintainers will review within 48 hrs.

Need help? Open an issue or email **support@zimlearn.org**.

---

## 📜 License

ZimLearn is released under the **MIT License** – see [`LICENSE`](LICENSE) for details.

---

## ❤️ Acknowledgements

- Zimbabwean educators & curriculum experts  
- Flutter & Dart community  
- Open-source packages listed in `pubspec.yaml`

> **Empower young Zimbabweans to Learn • Grow • Lead** 🌍
