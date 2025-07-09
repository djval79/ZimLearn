# Changelog
All notable changes to **ZimLearn** will be documented in this file.  
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]
- Offline content download manager  
- Business/market simulation minigame  
- Social learning & discussion boards  
- Teacher dashboard & assignment tooling  
- Progressive Web App packaging & deployment  
- Real-time translation services and voice I/O for AI Tutor  

---

## [0.9.1] – 2025-07-09
### Added
- Comprehensive repository documentation: `README.md`, `CONTRIBUTING.md`, `LICENSE`, `.gitignore`, `assets/.env.example`.  
- Initial **MIT License** and community contribution guidelines.

### Changed
- Minor housekeeping of file headers and project metadata.

---

## [0.9.0] – 2025-07-09
### Added
- **Routing system** powered by **GoRouter** with >60 named routes and nested routes.  
- **Navigation middleware** stack (auth, subscription, onboarding, permission, offline, analytics, caching, error handling).  
- Splash screen with Zimbabwe-themed animation and connectivity/auth checks.  
- Universal error page with troubleshooting guidance.  
- Deep linking utilities, breadcrumb generator, route extensions.  
- Refactored `main.dart` to `MaterialApp.router` and multi-provider setup.

### Changed
- Integrated routing with all existing features (dashboard, lessons, quizzes, AI tutor, subscriptions).  

---

## [0.8.0] – 2025-07-08
### Added
- **AI Tutor MVP**  
  - `ai_tutor_service.dart` with intelligent chat, session management, personalization.  
  - `learning_style.dart` model.  
  - Chat UI (`ai_tutor_chat_page.dart`) with glassmorphic design & streaming messages.  
  - `AiTutorBloc` + events & states with offline queue.  
  - **Practice Question Card** and **Study Plan Card** interactive widgets.  

---

## [0.7.0] – 2025-07-06
### Added
- **Quiz engine**  
  - Multiple question types (MCQ, multiple answer, true/false, matching, fill-in-blank).  
  - Timer, hints, real-time scoring, detailed analytics page.  
  - `quiz_bloc.dart` for state management.  

---

## [0.6.0] – 2025-07-04
### Added
- **Lesson module**  
  - Lesson list & detail pages with video player, interactive activities, rich-text note-taking, progress tracking.  
  - `lesson_bloc.dart` for offline-first state, progress persistence.

---

## [0.5.0] – 2025-07-03
### Added
- **Subscription system**  
  - Three ultra-low monthly tiers ($1, $2, $3).  
  - Pricing page with animated cards.  
  - Subscription BLoC with offline persistence and pay-wall integration.

---

## [0.4.0] – 2025-07-02
### Added
- Secure **authentication** service with email/password, Google sign-in, and biometric unlock.  
- Token refresh & secure key storage via `flutter_secure_storage`.

---

## [0.3.0] – 2025-07-01
### Added
- Core **data models** (`User`, `Lesson`, `Quiz`, `Subscription`) annotated for Hive.  
- Encrypted **Hive storage** service with automatic box registration.  
- **Service Locator** using GetIt for dependency injection.

---

## [0.2.0] – 2025-06-29
### Added
- **Dashboard** with modern glassmorphic widgets, subject cards, subscription overview, progress indicators.  
- Global constants, theme colors (Zimbabwean flag palette), reusable glassmorphic & kids animation widgets.

---

## [0.1.0] – 2025-06-28
### Added
- Project bootstrap: Flutter 3.19 skeleton, directory structure (`lib/`, `assets/`, `test/`, `docs/`).  
- Initial `pubspec.yaml` with foundational dependencies and Zimbabwe-centric theming.

---
