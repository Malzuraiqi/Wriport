import 'package:flutter/foundation.dart';
import 'package:wriport/core/app_constants.dart';
import 'package:wriport/domain/services/evaluation_exception.dart';

import '../domain/models/attempt.dart';
import 'attempt_state.dart';
import '../domain/models/challenge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';


class AttemptController extends Notifier<AttemptState> {
  @override
  AttemptState build() { 
    return AttemptState.initial();
  }

  Future<void> submit(Challenge challenge, String text) async {
    if (!state.canAttempt) {
      state = state.copyWith(
        status: AttemptStatus.error,
        errorMessage: "You have reached the maximum of ${AppConstants.maxAttempts} attempts.",
      );
      return;
    }

    final attempt = Attempt(
      id: state.attempts.length + 1,
      challengeId: challenge.id,
      text: text,
      createdAt: DateTime.now(),
      attemptNumber: state.attempts.length + 1,
      wordCount: countWords(text),
    );

    // Update state to loading
    state = state.copyWith(status: AttemptStatus.loading);
    final evaluationService = ref.read(Providers.evaluationServiceProvider);

    try {
      // Call the evaluation service to get feedback
      final feedback = await evaluationService.evaluate(challenge, attempt);

      // Update state with the new attempt and feedback
      state = state.copyWith(
        attempts: [...state.attempts, attempt],
        feedbacks: [...state.feedbacks, feedback],
        status: AttemptStatus.idle,
      );
    } on EvaluationException catch (e) {
      // e.message is user-friendly; the technical detail was already logged
      // by the service that threw it.
      state = state.copyWith(
        status: AttemptStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      debugPrint('Unexpected error during submit: $e');
      // Update state to error if evaluation fails
      state = state.copyWith(
        status: AttemptStatus.error,
        errorMessage: 'Something went wrong. Please try again later.',
      );
    }
  }

  // Method to reset the controller state
  void reset() {
    state = AttemptState.initial();
  }
}