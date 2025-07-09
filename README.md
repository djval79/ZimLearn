# ZimLearn

Empowering the next generation of Zimbabwean scholars and entrepreneurs through an engaging, offline-first learning experience.

---

## 1. Project Overview & Mission

ZimLearn is a mobile-first educational platform built **by Zimbabweans for Zimbabweans**.  
Our mission is to make high-quality, culturally relevant learning resources accessible to every learner in Zimbabwe— from urban Harare to the most remote parts of Binga— while nurturing 21-st-century skills such as critical thinking, digital literacy, and entrepreneurship.

---

## 2. Features & Capabilities

| Area | Highlights |
|------|------------|
| 🇿🇼 Curriculum | Full ZIMSEC-aligned lessons, quizzes, and revision notes across Grades 3-7 & Form 1-6 |
| 📚 Interactive Lessons | Videos, simulations, drag-and-drop activities, note-taking, offline downloads |
| 📝 Adaptive Quizzes | Multiple choice, matching, fill-in-the-blank, analytics & progress tracking |
| 🤖 AI Tutor | Shona / Ndebele / English chat tutor with practice questions & personalized study plans |
| 💎 Glassmorphic UI | Modern, kid-friendly interface with animations & celebration effects |
| 📡 Offline-First | Encrypted local storage (Hive) & smart sync for low-bandwidth regions |
| 🔐 Secure Auth | Email / Google / biometrics; parental controls & age-gating |
| 💳 Subscriptions | Ultra-low monthly tiers ($1 / $2 / $3) with in-app purchases |
| 👩‍🏫 Admin CMS | Content management, analytics dashboard, push updates (in progress) |
| 💼 Business Sim | Entrepreneurship & market simulation minigames (roadmap) |

---

## 3. Screenshots / Demo

| Dashboard | Lesson Player | AI Tutor |
|-----------|---------------|----------|
| ![Dashboard](docs/screenshots/dashboard.png) | ![Lesson](docs/screenshots/lesson.png) | ![Tutor](docs/screenshots/tutor.png) |

> A short demo video is available on YouTube: https://youtu.be/zimlearn-demo

---

## 4. Technology Stack

- **Flutter 3.19** – multi-platform UI
- **Dart 3** – language
- **BLoC + HydratedBloc** – reactive state management
- **GoRouter** – declarative navigation
- **Hive + AES encryption** – offline data store
- **Firebase** – auth, analytics, crashlytics
- **Dio / HTTP** – networking
- **TFLite / OpenAI API** – AI integrations
- **CI/CD** – GitHub Actions → Firebase App Distribution

---

## 5. Architecture Overview

```
layers: presentation → blocs → services → data (repositories & models) → local / remote sources
```

- **Feature-based folder structure** (`features/lessons`, `features/quiz`, `features/ai_tutor`, …)  
- **Service Locator (GetIt)** for dependency injection  
- **Clean Architecture** boundaries; unit-testable core logic  
- **Navigation Middleware** (auth, subscription, offline) built around GoRouter  
- **Offline-Download Manager** queues files & syncs when online  

_For a full diagram see `docs/architecture/overview.png`._

---

## 6. Installation & Setup

```bash
# 1. Prerequisites
git clone https://github.com/djval79/ZimLearn.git
cd ZimLearn
flutter --version   # ⬅ requires Flutter ≥3.13
dart --version

# 2. Environment
cp assets/.env.example assets/.env
# ▶ edit API keys & feature flags

# 3. Bootstrap
flutter pub get
flutter run           # android | ios | web | windows | macos | linux
```

Optional:

```bash
# Generate Hive adapters & JSON serializables
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 7. Usage Guidelines

| Action | Command / Gesture |
|--------|-------------------|
| Select grade & subjects | First-run onboarding wizard |
| Switch language | Settings → Language |
| Download lessons for offline | Lesson card → ⋮ → “Download” |
| Summon AI tutor | Dashboard → AI Tutor icon |
| View analytics | Dashboard → Profile avatar → “Progress” |
| Admin login | `/admin` route (role = `admin`) |

---

## 8. Contributing

We love PRs! 🥳

1. Fork & clone the repo  
2. Create a feature branch `git checkout -b feature/awesome`  
3. Run `flutter analyze && flutter test`  
4. Commit using [Conventional Commits](https://www.conventionalcommits.org/)  
5. Open a pull request describing **why** and **what** you changed  

Please read `CONTRIBUTING.md` for our coding style, branch strategy, and CLA.

---

## 9. Roadmap

- [x] Core lessons & quizzes
- [x] AI tutor MVP with Shona/Ndebele support
- [x] Three-tier subscriptions
- [ ] Full offline content download manager
- [ ] Entrepreneurship business simulation game
- [ ] Social learning & discussion boards
- [ ] Teacher dashboard & assignment tool
- [ ] Progressive Web App deployment
- [ ] Open-source content translation pipeline

---

## 10. License

This project is licensed under the **MIT License** – see the `LICENSE` file for details.

---

## 11. Contact

| Role | Contact |
|------|---------|
| Lead Maintainer | **Valentine M.** – val@zimlearn.co.zw |
| Twitter | [@ZimLearn](https://twitter.com/ZimLearn) |
| Website | https://www.zimlearn.co.zw |
| Issues | <https://github.com/djval79/ZimLearn/issues> |

---

## 12. Acknowledgments

- **Ministry of Primary & Secondary Education (Zimbabwe)** – curriculum guidelines  
- **Zimbabwe Open University** – educational research partnership  
- **Flutter & Dart communities** – amazing OSS tooling  
- Icons by [Phosphor](https://phosphoricons.com) • Illustrations by [Storyset](https://storyset.com)  
- Special thanks to teachers, students, and parents across Harare, Bulawayo, Mutare, and Gweru who beta-tested early builds. Mabonga zvikuru! 💚
