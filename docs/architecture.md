# ZimLearn Architecture Guide

_Last updated: **09 July 2025**_

## 1. High-Level Overview

```
 ┌───────────────────────────┐
 │       Presentation        │  Flutter widgets + Pages
 └────────────▲──────────────┘
              │ UI events
 ┌────────────┴──────────────┐
 │      State  Layer         │  BLoC / Cubit (Hydrated)
 └────────────▲──────────────┘
              │  intents / streams
 ┌────────────┴──────────────┐
 │     Service  Layer        │  Reusable business logic
 └────────────▲──────────────┘
              │  DTO / entities
 ┌────────────┴──────────────┐
 │     Data  Layer           │  Repositories
 └──────▲───────────▲────────┘
        │           │
  Local Sources   Remote Sources
  (Hive, Cache)   (REST, Firebase)
```

The system is **feature-first**: each folder under `lib/features/` contains its own UI, BLoC, repository interface, and tests. Cross-cutting services live under `lib/core/`.

---

## 2. Layer Responsibilities

| Layer | Responsibilities | Key Packages |
|-------|------------------|--------------|
| **Presentation** | Widgets, pages, themes, routing, accessibility, animations | `flutter`, `go_router`, custom glassmorphic widgets |
| **State** | Declarative business state, event → state mapping, offline hydration | `flutter_bloc`, `hydrated_bloc` |
| **Service** | Pure Dart logic: authentication, AI tutor, download manager, analytics, payment | Plain Dart + injected clients |
| **Data** | Repository interfaces & impls, caching, data transformation (DTO ↔ Entity) | `dio`, `firebase_*`, `hive` |
| **Local Source** | Offline persistence, encrypted boxes, file store | `hive_flutter`, `flutter_secure_storage` |
| **Remote Source** | REST/GraphQL, Firebase, 3rd-party APIs | `dio`, `firebase_auth`, `cloud_functions` |

---

## 3. Data Flow

1. **User Action** → Widget dispatches `BlocEvent`.
2. **BLoC** validates & emits loading state.
3. **Service** invoked via injected abstraction (e.g., `LessonService.getLessons()`).
4. **Repository** decides:  
   * return **cache** if fresh **OR**  
   * fetch from **remote source** then update cache.
5. **BLoC** receives data → emits success / error.
6. **HydratedBloc** serialises latest state to Hive for instant restoration on next launch.
7. **Widget** rebuilds using `BlocBuilder`.

_In offline mode steps 4-5 short-circuit to local cache or offline queue._

---

## 4. State Management

| Concern | Implementation |
|---------|----------------|
| Core flows (auth, lesson, quiz, tutor) | **BLoC** pattern (`Bloc`, `Event`, `State`) |
| Ephemeral UI state | `Cubit` (e.g., toggle, tab index) |
| Persistence | `hydrated_bloc` (serialise JSON to Hive box `_blocStorage`) |
| Connectivity | `ConnectivityCubit` broadcasts network changes |
| Global observers | Custom `AppBlocObserver` logs & sends metrics |

---

## 5. Dependency Injection

* **GetIt** service locator (`lib/core/services/service_locator.dart`)
* Registration happens once in `ServiceLocator.init()` during `main()`.
* Lifetimes  
  * _Singleton_ – configuration, logger, routers  
  * _LazySingleton_ – services (AuthService, AiTutorService)  
  * _Factory_ – repositories, BLoC factories
* BLoCs injected with `MultiBlocProvider` at app root, feature scope providers inside each page.

---

## 6. Offline-First Design

| Strategy | Detail |
|----------|--------|
| **Local DB** | Encrypted **Hive** boxes per model (`userBox`, `lessonBox`, …) |
| **Hydration** | UI state restored in <100 ms using HydratedBloc |
| **Download Manager** | Background isolates enqueue & write files to `getApplicationSupportDirectory()` |
| **Offline Queue** | AI Tutor & analytics events stored in `offline_queue_box` → flushed when connectivity returns |
| **Connectivity Guard** | Navigation middleware reroutes to offline-capable pages if no internet |
| **Conflict Resolution** | Last-write-wins with timestamp meta; future roadmap: CRDT for notes |

---

## 7. Security Considerations

1. **Encryption at Rest**  
   * AES-256 key stored in `flutter_secure_storage`.  
2. **Secure Auth**  
   * Firebase ID tokens + biometric unlock for quick resume.  
   * Token refresh handled by `AuthInterceptor` on every Dio call.  
3. **Parental Controls**  
   * Content restrictions evaluated in `PermissionMiddleware`.  
4. **Input Validation**  
   * Repository layer sanitises all user fields.  
5. **Secrets Management**  
   * Never committed; `.env.example` provided, real keys in CI secrets.  
6. **Secure Coding**  
   * `dart_audit` static analysis in CI, dependency scanning.  
7. **Network**  
   * TLS 1.2+, pinned certificates roadmap.  
   * Retry & exponential back-off to mitigate MITM timing vectors.  

---

## 8. Performance Optimisations

| Area | Optimisation |
|------|--------------|
| **Cold Start** | Pre-initialized ServiceLocator, deferred Firebase loading, splash animation min 2 s but work in parallel. |
| **Rendering** | Const constructors, `RepaintBoundary` for heavy widgets, image caching via `cached_network_image`. |
| **Routing** | **Route caching middleware** stores last 20 routes; pre-fetch lessons/quizzes in background isolate. |
| **I/O** | Batch Hive writes, compress downloaded media, lazy JSON decoding. |
| **Network** | `dio` interceptors add gzip headers, HTTP/2, and in-flight request coalescing. |
| **Memory** | Automatic image down-scaling based on device DPI, widget tear-down in `dispose()`. |
| **Observability** | Custom `PerformanceService` wraps `Timeline.startSync` during heavy operations, integrates with Firebase Performance. |

---

## 9. Future Enhancements

* **CRDT-based collaborative notes**  
* **GraphQL gateway** to reduce REST round-trips  
* **Edge caching** via Cloudflare Workers for low latency in rural Zimbabwe  
* **Predictive pre-fetch** using on-device ML of study habits  

> **TL;DR** – ZimLearn follows a pragmatic Clean-Architecture variant tailored for an offline-centric Flutter stack, emphasising maintainability, testability, and resilience in low-connectivity environments typical across Zimbabwe. 💚
