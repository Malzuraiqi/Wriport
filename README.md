# Wriport

> Practice writing. Get coached, not corrected.

Wriport is a Flutter app where you complete real-world writing challenges (emails, blog posts, essays, reports, and more) and receive AI feedback on your work. The AI acts as a **coach, not a ghostwriter**: it scores your writing and explains how to improve it, but it never rewrites the text for you.

**Current version:** `v0.4` (Increment 4: Backend, accounts, and persistence)

---

## Table of contents

1. [Core idea](#core-idea)
2. [Features](#features)
3. [Screenshots](#screenshots)
4. [Tech stack](#tech-stack)
5. [Architecture](#architecture)
6. [Security & Privacy](#security--privacy)
7. [Project structure](#project-structure)
8. [Getting started](#getting-started)
9. [Testing](#testing)
10. [Development approach](#development-approach)
11. [Roadmap](#roadmap)
12. [Known limitations](#known-limitations)
13. [Author and license](#author-and-license)

---

## Core idea

Most AI writing tools write *for* you. Wriport does the opposite: you write, and the AI evaluates. Every challenge gives you instructions, a required tone, and a word range. After you submit, you get:

- an overall score (0-100)
- a score and comment for each criterion (Grammar, Tone, Clarity, plus category-specific ones like Structure or Conciseness)
- a list of strengths
- a list of concrete improvements

Then you rewrite and try again, and the app shows whether you actually improved.

---

## Features

**Implemented**

- **Category & Challenge Library (v0.1 & v0.3):**
  - 8 categories: Email, Blog Post, Prompt, Report, Social Media Post, Essay, Product Description, and Technical Documentation
  - 3-4 challenges per category with tailored personas and criteria definitions
  - Instructions, tone chips, target word range chips, and a live word counter
- **Real AI Evaluation:**
  - Fast, structured evaluation powered by Google Gemini (`gemini-3.1-flash-lite`)
  - Animated overall score, per-criterion score bars, strengths, and actionable improvements
- **Revision Loop (v0.2):**
  - Up to 3 attempts per session
  - Retains previous text for quick editing and compares current vs. previous scores
  - Feedback screen shows improvement suggestions while revising
- **Accounts & Authentication (v0.4):**
  - User registration and sign-in with Email & Password
  - Google Sign-In support
  - Declarative authentication state routing with `go_router` redirect guards
- **Cloud Firestore Persistence (v0.4):**
  - Automatic saving of sessions and individual attempts after successful AI evaluation
  - Resilient save handling: if saving fails, feedback remains on-screen with an immediate retry option
  - Cross-device sync: user practices on one device, closes the app, logs in on another device, and sees past history
  - Dedicated History screen displaying past sessions sorted by date, with best scores and challenge titles
  - Read-only session detail view inspecting previous attempts, written drafts, and feedback breakdown
  - Session deletion with clean batch removal of session data and subcollections
- **Robust Security (v0.4):**
  - Zero API keys in client-side code; requests proxy through Firebase AI Logic
  - Fine-grained Firestore security rules restricting data access strictly to authenticated document owners

**Not yet implemented:** see the [Roadmap](#roadmap).

---

## Screenshots

| Home | Writing | Feedback | History |
|------|---------|----------|---------|
| ![Home Screen](/docs/screenshots/HomeScreen.png) | ![Writing Screen](/docs/screenshots/WritingScreen.png) | ![Feedback Screen](/docs/screenshots/FeedbackScreen.png) | ![History Screen](/docs/screenshots/HistoryOverlay.png) |

---

## Tech stack

| Area | Choice | Why |
|------|--------|-----|
| Framework | Flutter (Dart `^3.13.5`) | Cross-platform (Android, Web, iOS), reactive UI |
| State management | Riverpod (`flutter_riverpod`) | Pure Dart testability, decoupled from UI, seamless service overriding |
| AI | Google Gemini (`gemini-3.1-flash-lite`) via Firebase AI Logic (`firebase_ai`) | Zero client-side API keys, server-side credential enforcement, JSON mode |
| Authentication | Firebase Auth (`firebase_auth`, `google_sign_in`) | Secure user sessions, email/password & Google OAuth |
| Database | Cloud Firestore (`cloud_firestore`) | Real-time cloud sync, structured document/subcollection hierarchy, offline cache |
| Navigation | go_router | Declarative URL routes, deep linking, authentication redirect guards |

---

## Architecture

The app is split into four layers following clean architecture principles. Each layer only depends on the ones below it.

```
        UI  (screens, widgets)
         |
        State  (Riverpod controllers)
         |
        Domain  (models, interfaces, exceptions)
         ^
         |  implements
        Data  (Firebase services, Firestore & In-memory repositories)
```

### Key classes

| Class | Layer | Responsibility |
|-------|-------|----------------|
| `Challenge` / `Category` | Domain | Writing task constraints, tones, and category-specific evaluation criteria |
| `Attempt` / `FeedBack` / `CriterionScore` | Domain | Models for submission text, word counts, and AI evaluation output |
| `Session` / `SessionAttempt` | Domain | Persistence models linking challenges, best scores, and successive attempts |
| `AppUser` | Domain | Authenticated user profile entity |
| `EvaluationService` | Domain | Interface: `evaluate(Challenge, Attempt) -> Future<FeedBack>` |
| `AuthRepository` | Domain | Interface: authentication stream, sign-in, sign-up, sign-out |
| `HistoryRepository` | Domain | Interface: session lifecycle, saving attempts, score updates, deletion |
| `FirebaseAiEvaluationService` | Data | Calls Gemini via Firebase AI Logic without exposing API keys |
| `FirestoreHistoryRepository` | Data | Cloud Firestore persistence under `/users/{uid}/sessions/...` |
| `FirebaseAuthRepository` | Data | Firebase Authentication integration |
| `InMemoryHistoryRepository` | Data | Fast, isolated in-memory repository used for unit and controller testing |
| `InMemoryAuthRepository` | Data | In-memory authentication repository used for testing |
| `AttemptController` / `AttemptState` | State | Manages writing workflow, auto-saves attempts, manages retry state |

---

## Security & Privacy

Starting with **v0.4**, Wriport incorporates production-grade security practices:

1. **No API Keys in Client Binaries:**
   - Previous versions used client-side `.env` configuration. In `v0.4`, the client communicates through **Firebase AI Logic (`firebase_ai`)**.
   - Gemini API keys are held server-side by Firebase and Google Cloud, preventing extraction via reverse engineering, decompilation, or network inspection.
2. **Strict Firestore Security Rules (`firestore.rules`):**
   - User data is compartmentalized under `/users/{userId}`.
   - All read and write operations require valid Firebase Authentication and enforce ownership:
     ```javascript
     rules_version = '2';
     service cloud.firestore {
       match /databases/{database}/documents {
         match /users/{userId} {
           allow read, write: if request.auth != null && request.auth.uid == userId;

           match /sessions/{sessionId} {
             allow read, write: if request.auth != null && request.auth.uid == userId;

             match /attempts/{attemptId} {
               allow read, write: if request.auth != null && request.auth.uid == userId;
             }
           }
         }
       }
     }
     ```
3. **Data Isolation:**
   - Users can only view, mutate, or delete their own sessions and attempts.

---

## Project structure

```
lib/
├── main.dart / app.dart / providers.dart / router.dart   Entry point, MaterialApp, Riverpod providers, Route table + auth guards
├── core/                  App constants
├── domain/
│   ├── models/            Challenge, Attempt, FeedBack, Session, AppUser
│   ├── repositories/      AuthRepository, HistoryRepository
│   └── services/          EvaluationService, EvaluationPrompt, Exceptions
├── data/
│   ├── repositories/      FirestoreHistoryRepository, FirebaseAuthRepository, InMemory repositories
│   └── services/          FirebaseAiEvaluationService, FakeEvaluationService
├── state/                 AttemptController, AttemptState, AuthState
└── ui/
    ├── screens/           Auth, Home, Challenge, Writing, Feedback, History, SessionDetail
    └── widgets/           Score cards, chips, dialogs, criterion bars, app bars

test/
├── attempt_controller_test.dart          Full submission flow, auto-save, failure retention, retry save, reset
├── attempt_state_test.dart               State transitions, attempt limits, feedback comparisons
├── attempt_test.dart                     Word counting logic and whitespace handling
├── auth_repository_test.dart             In-memory auth lifecycle, validation, and stream events
├── challenge_repository_test.dart        Category completeness, sanity checks, unique challenge IDs
├── feedback_test.dart                    JSON parsing, score averaging, boundary clamping
├── gemini_evaluation_service_test.dart   Category-specific prompt generation and criteria validation
├── history_repository_test.dart          Session model copyWith, attempt storage, best-score updates, deletion
└── test_helpers.dart                     Shared mock builders
```

---

## Getting started

### Prerequisites

- Flutter SDK (Dart SDK `^3.13.5`, see `pubspec.yaml`)
- A Firebase project with Authentication (Email/Password & Google) and Cloud Firestore enabled
- An Android emulator, physical device, or Google Chrome

### Setup

1. **Clone the repository**

   ```bash
   git clone https://github.com/Malzuraiqi/Wriport.git
   cd wriport
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Configure Firebase**

   Configure your Firebase project using the FlutterFire CLI:

   ```bash
   flutterfire configure
   ```

   This generates `lib/firebase_options.dart` with your client configurations. Deploy the security rules using the Firebase CLI:

   ```bash
   firebase deploy --only firestore:rules
   ```

4. **Run the app**

   ```bash
   flutter run
   ```

### Running with simulated services (Offline/Dev Mode)

To run or test without calling live Firebase backends:
- In `lib/providers.dart`, `evaluationServiceProvider` can be pointed to `FakeEvaluationService()`.
- Repository providers (`authRepositoryProvider`, `historyRepositoryProvider`) can be swapped with `InMemoryAuthRepository()` and `InMemoryHistoryRepository()`.

---

## Testing

Run all unit and state tests:

```bash
flutter test
```

Run an individual test file:

```bash
flutter test test/attempt_controller_test.dart
```

### What is covered

| Test file | What it verifies |
|-----------|------------------|
| `attempt_controller_test.dart` | Evaluation submission, attempt counting, limit enforcement, error handling, auto-saving attempts to history, session ID reuse, best-score updates, save-failure feedback retention, manual retry save, and state reset |
| `auth_repository_test.dart` | In-memory authentication repository: sign up, sign in, Google sign in, sign out, password length validation, duplicate email handling, and auth stream broadcasts |
| `history_repository_test.dart` | Session model `copyWith`, session creation, attempt storage with embedded feedback, conditional best-score updates, reverse-chronological ordering, and session deletion |
| `attempt_test.dart` | Shared `countWords()` logic across normal text, extra spaces, tabs, newlines, empty strings, and punctuation |
| `feedback_test.dart` | `FeedBack.fromJson` parser, score rounding, decimal tolerance, 0-100 clamping, missing list defaults, and invalid JSON error handling |
| `attempt_state_test.dart` | Initial state, `canAttempt` calculation against max attempts, `latestFeedback` / `previousFeedback` diffing, and `copyWith` |
| `challenge_repository_test.dart` | Challenges exist for all categories, minimum challenge counts, sane word limits, and unique IDs |
| `gemini_evaluation_service_test.dart` | Dynamic prompt builder includes every criterion ID, definition, and persona per category |

---

## Development approach

- **Agile as the philosophy:** Build the most valuable feature first, verify with tests, learn, and iterate.
- **Incremental delivery:** Every increment delivers a complete, runnable slice of functionality.
- **Vertical slices:** Increments connect UI, state, domain logic, and backend storage end-to-end.
- **Replaceable technologies:** AI services, authentication, and persistence sit behind clean domain repository interfaces to allow swapping backends without UI changes.
- **Git workflow:** Feature branches merged when stable and tagged (`v0.1`, `v0.2`, `v0.3`, `v0.4`).

---

## Roadmap

- [x] **Increment 0:** Foundation (project, layers, interface, fake service)
- [x] **Increment 1:** Core loop (one writing evaluation from start to finish) `v0.1`
- [x] **Increment 2:** Revision loop (attempt limit, previous attempts, comparing feedback) `v0.2`
- [x] **Increment 3:** More categories (a category is data, not new code) `v0.3`
- [x] **Increment 4:** Backend, accounts and persistence (Firebase Auth, Cloud Firestore, secure AI calls via Firebase AI Logic, saved history, session details, deletion) `v0.4`
- [ ] **Increment 5:** Progress tracking (averages, improvement over time, common weaknesses)

**Out of scope for now:** social features, custom-trained models, multi-platform desktop polish.

---

## Known limitations

- Challenges are currently defined in local challenge repository datasets; remote challenge management will come in future increments.
- Feedback nuance depends on Gemini's inference and may vary between runs.
- English writing evaluation only.

---

## Author and license

**Author:** Mohammed Hesham\
**Context:** Built as a learning project alongside a Software Architecture course\
**License:** Copyright (c) 2026 Mohammed Hesham. All rights reserved.
