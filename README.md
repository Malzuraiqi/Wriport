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
6. [Navigation](#navigation)
7. [Security & Privacy](#security--privacy)
8. [Project structure](#project-structure)
9. [Getting started](#getting-started)
10. [Testing](#testing)
11. [Development approach](#development-approach)
12. [Roadmap](#roadmap)
13. [Known limitations](#known-limitations)
14. [Author and license](#author-and-license)

---

## Core idea

Most AI writing tools write *for* you. Wriport does the opposite: you write, and the AI evaluates. Every challenge gives you instructions, a required tone, and a word range. After you submit, you get:

- an overall score (0-100)
- a score and comment for each criterion (Grammar, Tone, Clarity, plus category-specific ones like Structure, Conciseness, or Completeness)
- a list of strengths
- a list of concrete improvements

Then you rewrite and try again, and the app shows whether you actually improved.

---

## Features

**Implemented**

- **Category & Challenge Library (v0.1 & v0.3):**
  - 8 categories: Email, Blog Post, Prompt, Report, Social Media Post, Essay, Product Description, and Technical Documentation
  - 4 challenges per category with tailored personas and criteria definitions
  - Instructions, tone chips, target word range chips, and a live word counter
- **Real AI Evaluation:**
  - Fast, structured evaluation powered by Google Gemini (`gemini-3.1-flash-lite`)
  - Animated overall score, per-criterion score bars, strengths, and actionable improvements
  - 30-second timeout and user-friendly error messages (technical details are only logged)
- **Revision Loop (v0.2):**
  - Up to 3 attempts per session
  - Retains previous text for quick editing and compares current vs. previous scores
  - Feedback screen shows improvement suggestions while revising
- **Accounts & Authentication (v0.4):**
  - User registration and sign-in with Email & Password
  - Google Sign-In
  - Password reset by email
  - Declarative authentication routing with `go_router` redirect guards
  - Greeting uses the signed-in user's name
- **Cloud Firestore Persistence (v0.4):**
  - Automatic saving of sessions and individual attempts after successful AI evaluation
  - Resilient save handling: if saving fails, feedback remains on-screen with an immediate retry option
  - Cross-device sync: practice on one device, log in on another, and see past history
  - Dedicated History screen displaying past sessions sorted by date, with best scores and challenge titles
  - Read-only session detail view showing each attempt's written text and feedback breakdown
  - Session deletion (long-press or delete button) that removes the session and all its attempts
- **Robust Security (v0.4):**
  - No API keys in client-side code; AI requests go through Firebase AI Logic
  - Firestore security rules restrict data access to the authenticated owner

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
| Framework | Flutter (Dart `^3.13.5`) | Reactive UI; configured for Android and Web |
| State management | Riverpod (`flutter_riverpod`) | Pure Dart testability, decoupled from UI, easy service overriding |
| AI | Google Gemini (`gemini-3.1-flash-lite`) via Firebase AI Logic (`firebase_ai`) | No client-side API keys, JSON output mode |
| Authentication | Firebase Auth (`firebase_auth`, `google_sign_in`) | Secure user sessions, email/password & Google OAuth |
| Database | Cloud Firestore (`cloud_firestore`) | Cloud sync, document/subcollection hierarchy, offline cache |
| Navigation | `go_router` | Declarative URL routes, authentication redirect guards |

---

## Architecture

The app is split into four layers following clean architecture principles. Each layer only depends on the ones below it.

```
        UI  (screens, widgets, theme)
         |
        State  (Riverpod controllers)
         |
        Domain  (models, interfaces, exceptions: pure Dart)
         ^
         |  implements
        Data  (Firebase services, Firestore & in-memory repositories)
```

### Key classes

| Class | Layer | Responsibility |
|-------|-------|----------------|
| `Challenge` / `Category` | Domain | Writing task constraints, tones, and category-specific evaluation criteria |
| `Criterion` / `Criteria` | Domain | Criterion id, label, and description used in prompts and scoring |
| `Attempt` / `FeedBack` / `CriterionScore` | Domain | Submission text, word counts, and AI evaluation output |
| `Session` / `SessionAttempt` | Domain | Persistence models linking a challenge run to its best score and attempts |
| `AppUser` | Domain | Authenticated user entity |
| `EvaluationService` | Domain | Interface: `evaluate(Challenge, Attempt) -> Future<FeedBack>` |
| `AuthRepository` | Domain | Interface: auth state stream, sign-in, sign-up, sign-out, password reset |
| `HistoryRepository` | Domain | Interface: create session, save attempt, update best score, read and delete sessions |
| `FirebaseAiEvaluationService` | Data | Calls Gemini via Firebase AI Logic without exposing API keys |
| `FakeEvaluationService` | Data | Simulated evaluator for offline development |
| `FirestoreHistoryRepository` | Data | Firestore persistence under `/users/{uid}/sessions/...` |
| `FirebaseAuthRepository` | Data | Firebase Authentication and Google Sign-In integration |
| `InMemoryHistoryRepository` / `InMemoryAuthRepository` | Data | In-memory repositories used for tests and offline development |
| `AttemptController` / `AttemptState` | State | Manages the writing workflow, auto-saves attempts, handles save retry |

---

## Navigation

Routes carry ids only, never whole objects.

| Route | Screen | Notes |
|-------|--------|-------|
| `/login`, `/signup` | Auth screens | Signed-in users are redirected to `/home` |
| `/home` | Category picker | Default after sign-in |
| `/challenges/:category` | Challenge list | Unknown category redirects home |
| `/writing/:id` | Writing screen | Unknown id redirects home |
| `/feedback` | Feedback for the latest attempt | Guarded: redirects home if there is no feedback in state |
| `/history` | Session history | Loaded from Firestore |
| `/history/:sessionId` | Session detail | Read-only |

Signed-out users are redirected to `/login` from every other route.

---

## Security & Privacy

Starting with **v0.4**, Wriport follows these practices:

1. **No API keys in the app:**
   - Earlier versions used a client-side `.env` file. From `v0.4`, the client talks to Gemini through **Firebase AI Logic (`firebase_ai`)**, and the Gemini key stays on the Google side.
   - The values in `lib/firebase_options.dart` are Firebase client identifiers, not secrets. Access is controlled by Auth and Firestore rules.
2. **Strict Firestore Security Rules (`firestore.rules`):**
   - User data lives under `/users/{uid}`.
   - Every read and write requires authentication and ownership; everything else is denied by default:
     ```javascript
     rules_version = '2';
     service cloud.firestore {
       match /databases/{database}/documents {
         match /users/{uid} {
           allow read, write: if request.auth != null && request.auth.uid == uid;

           match /sessions/{sessionId} {
             allow read, write: if request.auth != null && request.auth.uid == uid;

             match /attempts/{attemptId} {
               allow read, write: if request.auth != null && request.auth.uid == uid;
             }
           }
         }

         match /{document=**} {
           allow read, write: if false;
         }
       }
     }
     ```
3. **Prompt-injection hardening:**
   - User text is wrapped in `<user_text>` tags, labelled as data, and any tag-like text the user types is stripped before it reaches the prompt.
4. **Data isolation:**
   - Users can only view, change, or delete their own sessions and attempts.
5. **App Check Protection:** 
   - Firebase App Check is integrated into the client (`firebase_app_check`) to protect backend services from unauthorized access. It is currently configured to use a debug provider for local testing and should be switched to `PlayIntegrity` before production enforcement.

---

## Project structure

```
lib/
├── main.dart / app.dart / providers.dart / router.dart / firebase_options.dart
├── core/                  App constants
├── domain/
│   ├── models/            Challenge, Criterion, Attempt, FeedBack, CriterionScore, Session, SessionAttempt, AppUser
│   ├── repositories/      AuthRepository, HistoryRepository (interfaces)
│   └── services/          EvaluationService, evaluation prompt builder, AuthException, EvaluationException
├── data/
│   ├── repositories/      ChallengeRepository, FirestoreHistoryRepository, FirebaseAuthRepository, in-memory repositories
│   └── services/          FirebaseAiEvaluationService, FakeEvaluationService
├── state/                 AttemptController, AttemptState
└── ui/
    ├── category_icons.dart    Category -> icon mapping (keeps the domain free of Flutter)
    ├── theme/                 AppTheme, ThemeModeNotifier
    ├── screens/               Login, SignUp, Home, Challenge, Writing, Feedback, History, SessionDetail
    └── widgets/               AttemptsPill, FeedbackListCard, InfoSectionCard, ScoreCard, WordCounter

test/
├── attempt_controller_test.dart          Full submission flow, auto-save, failure retention, retry save, reset
├── attempt_state_test.dart               State transitions, attempt limits, feedback comparisons
├── attempt_test.dart                     Word counting logic and whitespace handling
├── auth_repository_test.dart             In-memory auth lifecycle, validation, and stream events
├── challenge_repository_test.dart        Category completeness, sanity checks, unique challenge IDs
├── feedback_test.dart                    JSON parsing, score averaging, boundary clamping
├── gemini_evaluation_service_test.dart   Category-specific prompt generation and criteria validation
├── history_repository_test.dart          Session model copyWith, attempt storage, best-score updates, deletion
├── in_memory_history_repository.dart     Re-export of the in-memory repository for tests
└── test_helpers.dart                     Shared builders

firebase.json / firestore.rules           Firebase project config and security rules
```

---

## Getting started

### Prerequisites

- Flutter SDK (Dart SDK `^3.13.5`, see `pubspec.yaml`)
- A Firebase project with:
  - Authentication enabled (Email/Password and Google)
  - Cloud Firestore enabled
  - Firebase AI Logic enabled with the Gemini Developer API
- An Android emulator, physical device, or Google Chrome

### Setup

1. **Clone the repository**

   ```bash
   git clone https://github.com/Malzuraiqi/Wriport.git
   cd Wriport
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Configure Firebase**

   ```bash
   flutterfire configure
   ```

   This generates `lib/firebase_options.dart`. Then deploy the security rules:

   ```bash
   firebase deploy --only firestore:rules
   ```

4. **Google Sign-In (Android)**

   Add your debug and release SHA-1 fingerprints to the Firebase Android app, and use your project's web client ID as the `serverClientId` in `FirebaseAuthRepository`.

5. **App Check (Local Development)**
   
   App Check is set up in `main.dart` using a debug provider. When you first run the app, look for a debug token printed in your terminal. If you enforce App Check in the Firebase Console, you must add this token to the App Check dashboard to allow local reads/writes.

6. **Run the app**

   ```bash
   flutter run
   ```

### Running with simulated services (Offline/Dev Mode)

To run or test without calling live Firebase backends, swap the providers in `lib/providers.dart`:
- `evaluationServiceProvider` -> `FakeEvaluationService()`
- `authRepositoryProvider` -> `InMemoryAuthRepository()`
- `historyRepositoryProvider` -> `InMemoryHistoryRepository()`

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
| `auth_repository_test.dart` | In-memory authentication: sign up, sign in, Google sign in, sign out, password length validation, duplicate email handling |
| `history_repository_test.dart` | Session `copyWith`, session creation, attempt storage with embedded feedback, conditional best-score updates, reverse-chronological ordering, and session deletion |
| `attempt_test.dart` | Word counting across normal text, extra spaces, tabs, newlines, empty strings, and punctuation |
| `feedback_test.dart` | `FeedBack.fromJson` parsing, score rounding, decimal tolerance, 0-100 clamping, missing list defaults, and invalid JSON handling |
| `attempt_state_test.dart` | Initial state, `canAttempt` against max attempts, `latestFeedback` / `previousFeedback`, and `copyWith` |
| `challenge_repository_test.dart` | Challenges exist for all categories, at least 3 per category, sane word limits, and unique IDs |
| `gemini_evaluation_service_test.dart` | The prompt builder includes every criterion ID, definition, and persona per category |

---

## Development approach

- **Agile as the philosophy:** Build the most valuable feature first, verify with tests, learn, and iterate.
- **Incremental delivery:** Every increment delivers a complete, runnable slice of functionality.
- **Vertical slices:** Increments connect UI, state, domain logic, and backend storage end-to-end.
- **Replaceable technologies:** AI, authentication, and persistence sit behind domain interfaces so backends can be swapped without UI changes.
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

- Challenges are defined in a local repository; remote challenge management is a future increment.
- Feedback nuance depends on Gemini's inference and may vary between runs.
- English writing evaluation only.
- Firebase is configured for Android and Web only (iOS and desktop are not set up).
- The history list loads all sessions at once (no pagination yet).

---

## Author and license

**Author:** Mohammed Hesham\
**Context:** Built as a learning project alongside a Software Architecture course\
**License:** Copyright (c) 2026 Mohammed Hesham. All rights reserved.