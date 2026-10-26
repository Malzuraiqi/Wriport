import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wriport/core/app_constants.dart';
import 'package:wriport/domain/models/attempt.dart';
import 'package:wriport/domain/models/challenge.dart';
import 'package:wriport/domain/models/feedback.dart';
import 'package:wriport/domain/repositories/history_repository.dart';
import 'package:wriport/domain/services/evaluation_exception.dart';
import 'package:wriport/domain/services/evaluation_service.dart';
import 'package:wriport/providers.dart';
import 'package:wriport/state/attempt_controller.dart';
import 'package:wriport/state/attempt_state.dart';

import 'in_memory_history_repository.dart';
import 'test_helpers.dart';

// ---------------------------------------------------------------------------
// Test doubles: tiny fake services that replace Gemini during tests.
// They work because the controller only knows the EvaluationService interface.
// ---------------------------------------------------------------------------

/// Returns feedback instantly (or fails on demand) and counts its calls.
class _TestService implements EvaluationService {
  int calls = 0;
  bool shouldFail = false;
  int returnedScore = 80;

  @override
  Future<FeedBack> evaluate(Challenge challenge, Attempt attempt) async {
    calls++;
    if (shouldFail) throw EvaluationException('boom');
    return buildFeedback(attemptId: attempt.id, overall: returnedScore);
  }
}

/// Does not answer until the test calls complete(). Lets a test look at the
/// "loading" moment, which is otherwise too short to observe.
class _ManualService implements EvaluationService {
  final Completer<FeedBack> completer = Completer<FeedBack>();

  @override
  Future<FeedBack> evaluate(Challenge challenge, Attempt attempt) {
    return completer.future;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// A ProviderContainer is a standalone "state box" (like ProviderScope, but
/// without any widgets). The override swaps the real service for our double.
ProviderContainer _containerWith(
  EvaluationService service, {
  HistoryRepository? historyRepo,
}) {
  final repo = historyRepo ?? InMemoryHistoryRepository();
  final container = ProviderContainer(
    overrides: [
      Providers.evaluationServiceProvider.overrideWith((ref) => service),
      Providers.historyRepositoryProvider.overrideWith((ref) => repo),
    ],
  );
  addTearDown(container.dispose); // clean up automatically after each test
  return container;
}

AttemptController _controller(ProviderContainer c) =>
    c.read(Providers.attemptControllerProvider.notifier);

AttemptState _state(ProviderContainer c) =>
    c.read(Providers.attemptControllerProvider);

void main() {
  final challenge = buildChallenge();

  group('AttemptController.submit', () {
    test('success stores the attempt and feedback and returns to idle', () async {
      final container = _containerWith(_TestService());
      final String input = 'My first answer';
      await _controller(container).submit(challenge, input);

      final state = _state(container);
      expect(state.attempts.length, 1);
      expect(state.feedbacks.length, 1);
      expect(state.status, AttemptStatus.idle);
      expect(state.attempts.first.text, 'My first answer');
      expect(state.attempts.first.challengeId, challenge.id);
      expect(state.attempts.first.attemptNumber, 1);
    });

    test('status is loading while waiting for the service', () async {
      final service = _ManualService();
      final container = _containerWith(service);

      // Start the submit but do NOT await it yet.
      final String input = 'text';
      final future = _controller(container).submit(challenge, input);
      expect(_state(container).status, AttemptStatus.loading);

      // Let the "AI" answer, then wait for the submit to finish.
      service.completer.complete(buildFeedback());
      await future;

      expect(_state(container).status, AttemptStatus.idle);
    });

    test('a second submit becomes attempt number 2', () async {
      final container = _containerWith(_TestService());

      final String input = 'first';
      await _controller(container).submit(challenge, input);

      final String input2 = 'second';
      await _controller(container).submit(challenge, input2);

      final state = _state(container);
      expect(state.attempts.length, 2);
      expect(state.attempts.last.attemptNumber, 2);
      expect(state.feedbacks.length, 2);
    });

    test('a failing service sets the error status and stores nothing', () async {
      final service = _TestService()..shouldFail = true;
      final container = _containerWith(service);

      final String input = 'text';
      await _controller(container).submit(challenge, input);

      final state = _state(container);
      expect(state.status, AttemptStatus.error);
      expect(state.errorMessage, isNotNull);
      expect(state.attempts, isEmpty);
      expect(state.feedbacks, isEmpty);
    });

    test('a failed submit does not use up an attempt', () async {
      final service = _TestService()..shouldFail = true;
      final container = _containerWith(service);
      final String input = 'text';
      await _controller(container).submit(challenge, input);

      service.shouldFail = false; // the service recovers
      final String input2 = 'text again';
      await _controller(container).submit(challenge, input2);

      final state = _state(container);
      expect(state.status, AttemptStatus.idle);
      expect(state.attempts.length, 1);
      expect(state.attempts.first.attemptNumber, 1);
    });

    test('refuses to submit past the attempt limit', () async {
      final service = _TestService();
      final container = _containerWith(service);

      for (var i = 0; i < AppConstants.maxAttempts; i++) {
        final String input = 'attempt $i';
        await _controller(container).submit(challenge, input);
      }
      // One more than allowed.
      final String input = 'one too many';
      await _controller(container).submit(challenge, input);

      final state = _state(container);
      expect(state.attempts.length, AppConstants.maxAttempts);
      expect(state.status, AttemptStatus.error);
      expect(state.errorMessage, isNotNull);
      // The service must not even be called for the refused attempt.
      expect(service.calls, AppConstants.maxAttempts);
    });
  });

  group('AttemptController persistence (Section 4D)', () {
    test('auto-saves attempt and creates session on success', () async {
      final historyRepo = InMemoryHistoryRepository();
      final container = _containerWith(_TestService(), historyRepo: historyRepo);

      await _controller(container).submit(challenge, 'First answer');

      final state = _state(container);
      expect(state.saveStatus, SaveStatus.idle);
      expect(state.sessionId, isNotNull);

      // Verify the session was created in the repository
      final sessions = await historyRepo.getSessions();
      expect(sessions.length, 1);
      expect(sessions.first.id, state.sessionId);
      expect(sessions.first.challengeTitle, challenge.title);
      expect(sessions.first.bestScore, 80);

      // Verify the attempt was saved under the session
      final attempts = await historyRepo.getAttempts(state.sessionId!);
      expect(attempts.length, 1);
      expect(attempts.first.attempt.text, 'First answer');
      expect(attempts.first.feedback.overallScore, 80);
    });

    test('subsequent attempts reuse the same sessionId and update bestScore', () async {
      final historyRepo = InMemoryHistoryRepository();
      final service = _TestService()..returnedScore = 70;
      final container = _containerWith(service, historyRepo: historyRepo);

      await _controller(container).submit(challenge, 'Attempt 1');
      final firstSessionId = _state(container).sessionId;

      service.returnedScore = 90; // Higher score in attempt 2
      await _controller(container).submit(challenge, 'Attempt 2');
      final secondSessionId = _state(container).sessionId;

      expect(firstSessionId, equals(secondSessionId));

      final session = await historyRepo.getSession(firstSessionId!);
      expect(session?.bestScore, 90);

      final attempts = await historyRepo.getAttempts(firstSessionId);
      expect(attempts.length, 2);
    });

    test('save failure keeps feedback on screen and sets saveStatus to failed', () async {
      final historyRepo = InMemoryHistoryRepository()..shouldFail = true;
      final container = _containerWith(_TestService(), historyRepo: historyRepo);

      await _controller(container).submit(challenge, 'My text');

      final state = _state(container);
      // Evaluation succeeded and feedback is present
      expect(state.status, AttemptStatus.idle);
      expect(state.attempts.length, 1);
      expect(state.feedbacks.length, 1);
      // Save status indicates failure
      expect(state.saveStatus, SaveStatus.failed);
    });

    test('retrySave succeeds when repo recovers and updates saveStatus to idle', () async {
      final historyRepo = InMemoryHistoryRepository()..shouldFail = true;
      final container = _containerWith(_TestService(), historyRepo: historyRepo);

      await _controller(container).submit(challenge, 'My text');
      expect(_state(container).saveStatus, SaveStatus.failed);

      // Repo recovers
      historyRepo.shouldFail = false;
      await _controller(container).retrySave(challenge);

      final state = _state(container);
      expect(state.saveStatus, SaveStatus.idle);
      expect(state.sessionId, isNotNull);

      final sessions = await historyRepo.getSessions();
      expect(sessions.length, 1);
    });
  });

  group('AttemptController.reset', () {
    test('clears attempts, feedback, status, sessionId, and saveStatus', () async {
      final container = _containerWith(_TestService());
      final String input = 'text';
      await _controller(container).submit(challenge, input);

      _controller(container).reset();

      final state = _state(container);
      expect(state.attempts, isEmpty);
      expect(state.feedbacks, isEmpty);
      expect(state.status, AttemptStatus.idle);
      expect(state.sessionId, isNull);
      expect(state.saveStatus, SaveStatus.idle);
    });
  });
}