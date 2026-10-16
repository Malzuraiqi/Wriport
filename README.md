# Wriport

> Practice writing. Get coached, not corrected.

Wriport is a Flutter app where you complete real-world writing challenges (emails, blog posts) and receive AI feedback on your work. The AI acts as a **coach, not a ghostwriter**: it scores your writing and explains how to improve it, but it never rewrites the text for you.

**Current version:** `v0.3` (Increment 3: more categories)

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
- a score and comment for each criterion (Grammar, Tone, Clarity, plus category-specific ones like Structure or Conciseness)
- a list of strengths
- a list of concrete improvements

Then you rewrite and try again, and the app shows whether you actually improved.

## Features

**Implemented**

- Challenge lists for eight categories: Email, Blog Post, Prompt, Report, Social Media Post, Essay, Product Description, and Technical Documentation
- Writing screen with instructions, tone and word-range chips, and a live word counter
- Real AI evaluation through Google Gemini
- Feedback screen with an animated overall score, per-criterion scores, strengths and improvements
- **Revision loop (v0.2):**
  - up to 3 attempts per challenge
  - your previous text stays in the editor so you revise instead of starting over
  - previous improvements are shown while you rewrite
  - current vs previous score comparison, with the difference per attempt
  - attempt history with expandable details
- **More categories (v0.3):**
  - 8 categories with 3-4 challenges each
  - each category defines its own icon, description, and evaluation criteria
  - the Gemini prompt and the fake service build their criteria list from the category, instead of a fixed set
  - adding a new category means editing only the category definition and the challenge data — no UI or service changes
- Responsive layout 
- Loading and error handling, including a safe fallback when the AI call fails
- Basic protection against prompt injection 

**Not yet implemented:** see the [Roadmap](#roadmap).

## Screenshots

| Home | Writing | Feedback | History |
|------|---------|----------|---------|
| ![Home Screen](/docs/screenshots/HomeScreen.png) | ![Writing Screen](/docs/screenshots/WritingScreen.png) | ![Feedback Screen](/docs/screenshots/FeedbackScreen.png) | ![Histor Overlay](/docs/screenshots/HistoryOverlay.png) |

## Tech stack

| Area | Choice | Why |
|------|--------|-----|
| Framework | Flutter (Dart) | One codebase, Android first, other platforms possible later |
| State management | Riverpod (`flutter_riverpod`) | Testable, no dependency on widgets, easy to swap services |
| AI | Google Gemini (`gemini-3.1-flash-lite`) via `google_generative_ai` | Fast, low cost, supports JSON output |
| Config | `flutter_dotenv` | Keeps the API key out of source code |
| Navigation | `Navigator` (go_router is installed and planned) | Enough for the current number of screens |

> **Note:** the `google_generative_ai` package is deprecated by Google. It still works for development. See [Known limitations](#known-limitations).

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
| `Category` | Domain | Enum: label, description, icon, and the criteria used to evaluate it |
| `Attempt` | Domain | One submission by the user, including a computed word count |
| `FeedBack` / `CriterionScore` | Domain | The evaluation result |
| `EvaluationService` | Domain | Interface: `evaluate(Challenge, Attempt) -> Future<FeedBack>` |
| `EvaluationException` | Domain | The single error type services throw |
| `GeminiEvaluationService` | Data | Builds the prompt (via `buildPrompt`), calls Gemini, parses the JSON reply |
| `FakeEvaluationService` | Data | Returns simulated feedback for UI work |
| `ChallengeRepository` | Data | Provides challenges per category (hardcoded for now) |
| `AttemptController` / `AttemptState` | State | Holds attempts, feedback, attempt limit and loading/error status |
| `AppConstants` | Core | App-wide constants (maximum attempts) |

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
├── main.dart / app.dart / providers.dart   Entry point, MaterialApp, all providers (the service swap point)
├── core/        App-wide constants
├── domain/      Models + the EvaluationService interface (pure Dart, no Flutter)
├── data/        Gemini & fake services, challenge repository
├── state/       AttemptController + AttemptState
└── ui/          Screens, widgets, theme

test/
├── attempt_test.dart
├── attempt_state_test.dart
├── attempt_controller_test.dart
├── feedback_test.dart
├── challenge_repository_test.dart        Every category has challenges; data is sane
└── gemini_evaluation_service_test.dart   The prompt contains each category's criteria
```

> Adding a category touches exactly two files: the `Category` enum in
> `domain/models/challenge.dart` and `ChallengeRepository`. Everything else —
> home screen, challenge screen, prompts, fake service — derives from the enum.

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

To work on the UI without using API calls, open `lib/providers.dart` and make `evaluationServiceProvider` return `FakeEvaluationService()` instead of `GeminiEvaluationService()`. It waits two seconds and returns simulated feedback built from the challenge's own criteria list.

## Testing

Run all tests:

```bash
flutter test
```

Run one file:

```bash
flutter test test/attempt_controller_test.dart
```

### What is covered

| Test file | What it verifies |
|-----------|------------------|
| `attempt_test.dart` | `Attempt.wordCount` for normal text, extra spaces, newlines and tabs, empty and whitespace-only text, punctuation |
| `feedback_test.dart` | `FeedBack.fromJson` parses valid JSON; overall score is the rounded-down average; decimal scores are accepted; overall score is clamped to 0-100; missing lists default to empty; missing criteria throws |
| `attempt_state_test.dart` | Initial state; `canAttempt` against the attempt limit; `latestFeedback` and `previousFeedback`; `copyWith` keeps untouched fields |
| `attempt_controller_test.dart` | Successful submit stores attempt and feedback; loading status while waiting; attempt numbers increase; a failing service sets the error status and stores nothing; a failed submit does not use up an attempt; submitting past the limit is refused without calling the service; `reset()` clears everything |
| `challenge_repository_test.dart` | Every category has at least one challenge (the loop fails if a category is added with no data); every category has 3-5 challenges; word ranges are sane; ids are unique |
| `gemini_evaluation_service_test.dart` | The evaluation prompt contains every criterion of every category, plus the tone, word range, and user text |

>36 tests passing as of 2026-10-16: 00:27 +36: All tests passed!

### Not tested yet

- Widget (UI) tests
- The Gemini network call itself (prompt generation is covered; an integration test is planned)

## Development approach

- **Agile as the philosophy:** build the most valuable thing, test it, learn, adjust.
- **Incremental delivery:** every increment ends with a complete, working app.
- **Vertical slices:** each increment builds one full path through the system (UI to AI to feedback) instead of one layer at a time.
- **Replaceable technologies:** AI provider, storage and navigation sit behind boundaries so they can change without rewrites.
- **Git workflow:** one branch per increment, merged when it is working, and tagged (`v0.1`, `v0.2`, ...).
- **UI workflow:** screens are designed in Figma, and the widget code is generated from the designs and then reviewed. State, logic and tests are written by hand.

## Roadmap

- [x] **Increment 0:** Foundation (project, layers, interface, fake service)
- [x] **Increment 1:** Core loop (one writing evaluation from start to finish) `v0.1`
- [x] **Increment 2:** Revision loop (attempt limit, previous attempts, comparing feedback) `v0.2`
- [x] **Increment 3:** More categories (a category is data, not new code) `v0.3`
- [ ] **Increment 4:** Backend, accounts and persistence (secure AI calls, replace deprecated SDK, go_router, saved history)
- [ ] **Increment 5:** Progress tracking (averages, improvement over time, common weaknesses)

**Out of scope for now:** social features, custom-trained models, multi-platform polish.

## Known limitations

- The Gemini SDK in use is deprecated and will be replaced in Increment 4.
- The API key ships with the app (development only, see the security note).
- Challenges are hardcoded; there is no storage, so attempts are lost when the app closes.
- Feedback quality depends on the model and can vary between runs.
- The AI is not told about previous attempts, so it does not judge whether earlier feedback was addressed.
- English writing only. [FILL IN: confirm or change]

## Author and license

**Author:** Mohammed Hesham\
**Context:** Built as a learning project alongside a Software Architecture course\
**License:** Copyright (c) 2026 Mohammed Hesham. All rights reserved.
