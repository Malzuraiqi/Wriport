# Wriport

> Practice writing. Get coached, not corrected.

Wriport is a Flutter app where you complete real-world writing challenges (emails, blog posts) and receive AI feedback on your work. The AI acts as a **coach, not a ghostwriter**: it scores your writing and explains how to improve it, but it never rewrites the text for you.

**Current version:** `v0.1` (Increment 1: core writing loop)

---

## Table of contents

1. [Core idea](#core-idea)
2. [Features](#features)
3. [Screenshots](#screenshots)
4. [Tech stack](#tech-stack)
5. [Architecture](#architecture)
6. [Project structure](#project-structure)
7. [Getting started](#getting-started)
8. [Testing](#testing)
9. [Development approach](#development-approach)
10. [Roadmap](#roadmap)
11. [Known limitations](#known-limitations)
12. [Author and license](#author-and-license)

---

## Core idea

Most AI writing tools write *for* you. Wriport does the opposite: you write, and the AI evaluates. Every challenge gives you instructions, a required tone, and a word range. After you submit, you get:

- an overall score (0-100)
- a score and comment for each criterion (Grammar, Tone Alignment, Clarity)
- a list of strengths
- a list of concrete improvements

Then you rewrite and try again.

## Features

**Implemented (v0.1)**

- Challenge lists for two categories: Email and Blog Post
- Real AI evaluation through Google Gemini
- Responsive layout
- Loading and error handling, including a safe fallback when the AI call fails
- Basic protection against prompt injection

**Not yet implemented:** see the [Roadmap](#roadmap).

## Screenshots

| Home | Writing | Feedback |
|------|---------|----------|
| ![Home Screen](/docs/screenshots/HomeScreen.png) | ![Writing Screen](/docs/screenshots/WritingScreen.png) | ![Feedback Screen](/docs/screenshots/FeedbackScreen.png) |

## Tech stack

| Area | Choice | Why |
|------|--------|-----|
| Framework | Flutter (Dart) | One codebase, Android first, other platforms possible later |
| State management | Riverpod (`flutter_riverpod`) | Testable, no dependency on widgets, easy to swap services |
| AI | Google Gemini (`gemini-3.1-flash-lite`) via `google_generative_ai` | Fast, low cost, supports JSON output |
| Config | `flutter_dotenv` | Keeps the API key out of source code |
| Navigation | `Navigator` (go_router is installed and planned) | Enough for the current number of screens |

> **Note:** the `google_generative_ai` package is deprecated by Google. It still works for development, and it is isolated behind an interface so it can be replaced by editing a single file. See [Known limitations](#known-limitations).

## Architecture

The app is split into four layers. Each layer only depends on the ones below it.

```
        UI  (screens, widgets)
         |
        State  (Riverpod controllers)
         |
        Domain  (models + EvaluationService interface)
         ^
         |  implements
        Data  (Gemini service, Fake service, repositories)
```

### Key classes

| Class | Layer | Responsibility |
|-------|-------|----------------|
| `Challenge` | Domain | Describes a writing task (instructions, tone, word range) |
| `Attempt` | Domain | One submission by the user, including a computed word count |
| `FeedBack` / `CriterionScore` | Domain | The evaluation result |
| `EvaluationService` | Domain | Interface: `evaluate(Challenge, Attempt) -> Future<FeedBack>` |
| `EvaluationException` | Domain | The single error type services throw |
| `GeminiEvaluationService` | Data | Builds the prompt, calls Gemini, parses the JSON reply |
| `FakeEvaluationService` | Data | Returns hardcoded feedback for UI work and tests |
| `ChallengeRepository` | Data | Provides challenges per category (hardcoded for now) |
| `AttemptController` / `AttemptState` | State | Holds attempts, feedback and loading/error status |

### Data flow (one submission)

```
WritingScreen --submit--> AttemptController --evaluate--> EvaluationService
                                   |                              |
                                   |<--------- FeedBack ----------|
                                   v
                             AttemptState --watch--> FeedbackScreen
```

## Project structure

```
lib/
├── main.dart                         App entry point, loads .env
├── app.dart                          MaterialApp and theme wiring
├── router.dart                       Reserved for go_router (planned)
├── providers.dart                    All Riverpod providers (service swap point)
├── domain/
│   ├── models/
│   │   ├── challenge.dart
│   │   ├── attempt.dart
│   │   ├── criterion_score.dart
│   │   └── feedback.dart
│   └── services/
│       ├── evaluation_service.dart   Interface
│       └── evaluation_exception.dart
├── data/
│   ├── repositories/
│   │   └── challenge_repository.dart
│   └── services/
│       ├── fake_evaluation_service.dart
│       └── gemini_evaluation_service.dart
├── state/
│   ├── attempt_state.dart
│   └── attempt_controller.dart
└── ui/
    ├── screens/
    │   ├── home_screen.dart
    │   ├── challenge_screen.dart
    │   ├── writing_screen.dart
    │   └── feedback_screen.dart
    ├── widgets/
    │   ├── score_card.dart
    │   └── word_counter.dart
    └── theme/
        └── app_theme.dart
```

## Getting started

### Prerequisites

- Flutter SDK (Dart SDK `^3.13.5`, see `pubspec.yaml`)
- A Gemini API key from [Google AI Studio](https://aistudio.google.com/)
- An Android emulator, a physical device, or Chrome for web

### Setup

1. Clone the repository

   ```bash
   git clone https://github.com/Malzuraiqi/Wriport.git
   cd wriport
   ```

2. Install dependencies

   ```bash
   flutter pub get
   ```

3. Create your environment file. In the project root, create a file named `.env`:

   ```
   GEMINI_API_KEY=your_key_here
   ```

   The file is listed as an asset in `pubspec.yaml`, so it must exist or the app will not build.

4. Run the app

   ```bash
   flutter run
   ```

### Running without the real AI

To work on the UI without using API calls, open `lib/providers.dart` and make `evaluationServiceProvider` return `FakeEvaluationService()` instead of `GeminiEvaluationService()`. It waits two seconds and returns fixed feedback.

## Development approach

- **Agile as the philosophy:** build the most valuable thing, test it, learn, adjust.
- **Incremental delivery:** every increment ends with a complete, working app.
- **Vertical slices:** each increment builds one full path through the system (UI to AI to feedback) instead of one layer at a time.
- **Replaceable technologies:** AI provider, storage and navigation sit behind boundaries so they can change without rewrites.
- **Git workflow:** one branch per increment, merged when it is working, and tagged (`v0.1`, `v0.2`, ...).

## Known limitations

- The Gemini SDK in use is deprecated and will be replaced in v0.4.
- The API key ships with the app (development only).
- Challenges are hardcoded; there is no storage, so attempts are lost when the app closes.
- Feedback quality depends on the model and can vary between runs.
- English writing only.

## Author and license

**Author:** Mohammed Hesham
**Context:** Built as a learning project alongside a Software Architecture course
**License:** Copyright (c) 2026 Mohammed Hesham. All rights reserved.