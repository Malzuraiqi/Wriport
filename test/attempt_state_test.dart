import 'package:flutter_test/flutter_test.dart';
import 'package:wriport/core/app_constants.dart';
import 'package:wriport/state/attempt_state.dart';

import 'test_helpers.dart';

void main() {
  group('AttemptState', () {
    test('initial state is empty and idle', () {
      final state = AttemptState.initial();

      expect(state.attempts, isEmpty);
      expect(state.feedbacks, isEmpty);
      expect(state.status, AttemptStatus.idle);
      expect(state.errorMessage, isNull);
    });

    test('canAttempt is true until the maximum is reached', () {
      var state = AttemptState.initial();
      expect(state.canAttempt, isTrue);

      // Add attempts one by one, up to the limit.
      for (var i = 1; i <= AppConstants.maxAttempts; i++) {
        state = state.copyWith(
          attempts: [...state.attempts, buildAttempt(id: i, attemptNumber: i)],
        );
      }

      expect(state.attempts.length, AppConstants.maxAttempts);
      expect(state.canAttempt, isFalse);
    });

    test('latestFeedback returns the most recent feedback', () {
      final state = AttemptState.initial().copyWith(
        feedbacks: [
          buildFeedback(attemptId: 1, overall: 50),
          buildFeedback(attemptId: 2, overall: 70),
        ],
      );

      expect(state.latestFeedback.overallScore, 70);
    });

    test('latestFeedback throws when there is no feedback yet', () {
      // Documents current behavior: screens must check feedbacks.isEmpty first.
      expect(() => AttemptState.initial().latestFeedback, throwsStateError);
    });

    test('previousFeedback is null with fewer than two feedbacks', () {
      final state = AttemptState.initial().copyWith(
        feedbacks: [buildFeedback()],
      );

      expect(state.previousFeedback, isNull);
    });

    test('previousFeedback is the one before the latest', () {
      final state = AttemptState.initial().copyWith(
        feedbacks: [
          buildFeedback(attemptId: 1, overall: 50),
          buildFeedback(attemptId: 2, overall: 70),
        ],
      );

      expect(state.previousFeedback?.overallScore, 50);
    });

    test('copyWith keeps every field that is not replaced', () {
      final original = AttemptState.initial().copyWith(
        attempts: [buildAttempt()],
        feedbacks: [buildFeedback()],
      );
      final updated = original.copyWith(status: AttemptStatus.loading);

      expect(updated.status, AttemptStatus.loading);
      expect(updated.attempts, original.attempts);
      expect(updated.feedbacks, original.feedbacks);
    });
  });
}