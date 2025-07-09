# Contributing to **ZimLearn**

🎉 **Maita basa!** We’re excited that you want to help improve ZimLearn, the open-source learning platform for Zimbabwean students. This guide explains the rules, processes and best-practices for contributing code, documentation, designs, translations, or ideas.

---

## 1. Code of Conduct

We follow the **[Contributor Covenant v2.1](https://www.contributor-covenant.org/version/2/1/code_of_conduct/)**.  
In short:

* Be **respectful** and inclusive.
* No harassment, discrimination, or hate speech.
* Assume good intentions and keep criticism constructive.
* Report unacceptable behaviour to **conduct@zimlearn.co.zw**.

Violations may result in warnings or removal from the community.

---

## 2. Ways to Contribute

| Type | How |
|------|-----|
| 🐛 **Bug Fix** | File an Issue ➜ fork ➜ fix ➜ PR |
| ✨ **New Feature** | Open feature proposal Issue ➜ discuss ➜ PR |
| 📝 **Docs / Tutorials** | Edit `.md` files or add new ones |
| 🌐 **Translation** | See `docs/i18n/README.md` |
| 🎨 **UI/UX / Assets** | Attach mock-ups in Issues or PRs |
| 🔍 **Testing & QA** | Add unit / widget tests or run test matrix |
| 💡 **Ideas / Feedback** | Start a Discussion or comment on Issues |

---

## 3. Development Setup

1. **Clone**

```bash
git clone https://github.com/djval79/ZimLearn.git
cd ZimLearn
```

2. **Prerequisites**

| Tool | Min Version |
|------|-------------|
| Flutter | 3.13 |
| Dart | 3.1 |
| Android Studio / Xcode | Latest |
| Node (for hooks/scripts) | 18 + |

3. **Dependencies**

```bash
flutter pub get
```

4. **Environment**

```bash
cp assets/.env.example assets/.env
# Edit API keys & feature flags
```

5. **Generate code**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

6. **Run**

```bash
flutter run -d <device>
```

---

## 4. Coding Standards

| Area | Rule |
|------|------|
| **Style** | Follow `flutter_lints` + `dart format` |
| **Null-safety** | Mandatory |
| **File Size** | \< 400 LOC per file where possible |
| **Widgets** | Prefer composition over inheritance, split builders |
| **Architectural** | Feature-first folders; Clean Architecture layers |
| **Commit Messages** | **Conventional Commits** (e.g. `feat(ai_tutor): add voice input`) |
| **Secrets** | **Never** commit credentials or `.env` |

---

## 5. Pull Request Process

1. **Fork** the repo and create a branch:  
   `git checkout -b feat/<ticket-id>-short-description`
2. **Sync** with `main` regularly:  
   `git pull upstream main --rebase`
3. **Format & Lint**

```bash
dart format .
flutter analyze
```

4. **Tests**

```bash
flutter test --coverage
```

5. **Commit** using Conventional Commits.
6. **Push** and open a **Draft PR** early for visibility.
7. Fill in the **PR template**:
   * What / Why
   * Screenshots / recordings
   * Checklist (tests, docs, lint)
8. At least **one approval** and **green CI** required to merge.
9. Squash-merge via GitHub; the title becomes the release note entry.

---

## 6. Issue Reporting

* **Search first** – avoid duplicates.
* Use the **Bug Report** or **Feature Request** template.
* Include:
  * Flutter / OS version (`flutter doctor -v`)
  * Steps to reproduce
  * Expected vs. actual behaviour
  * Logs / screenshots / videos if available
* Set appropriate labels (`bug`, `good first issue`, `question`, etc.).
* Security vulnerabilities → **security@zimlearn.co.zw** (do not file public Issue).

---

## 7. Community Guidelines

* Discussions happen in **GitHub Discussions** or `#zimlearn-dev` on Slack.
* Use inclusive language (English, Shona, Ndebele all welcome).
* Keep threads on topic; start a new thread for new topics.
* Advertisements, politics, or unrelated content are not allowed.
* Mentorship: tag issues with **`good first issue`** for newcomers.

---

## 8. Testing Requirements

| Layer | Required Tests |
|-------|----------------|
| **Models & Utils** | 100 % line coverage |
| **BLoC / Cubit** | Logic branches, hydrated persistence |
| **Widget** | Golden tests for critical UI, interaction tests with `flutter_test` |
| **Integration** | At least one happy-path e2e for each major flow (login → lesson → quiz) |

* CI will fail if **coverage \< 80 %** or any tests fail.
* Use **Mockito / mocktail** for stubs.
* Large integration tests should use `flutter_driver` (or `integration_test`).

---

## Thank You! 💚

Your contribution helps Zimbabwean learners **Learn • Grow • Lead**.  
For questions ping **@djval79** or open a Discussion topic.

