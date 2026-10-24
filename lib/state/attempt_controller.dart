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

      // Auto-save to Firestore after a successful evaluation
      await _saveToHistory(challenge, attempt, feedback);
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

  /// Persists the attempt to Firestore. Creates the session on the first
  /// attempt, then saves each subsequent attempt under it.
  /// If saving fails, sets [SaveStatus.failed] so the UI can offer retry.
  Future<void> _saveToHistory(
    Challenge challenge,
    Attempt attempt,
    feedback,
  ) async {
    state = state.copyWith(saveStatus: SaveStatus.saving);

    try {
      final historyRepo = ref.read(Providers.historyRepositoryProvider);

      // Create session on first attempt
      var sessionId = state.sessionId;
      if (sessionId == null) {
        sessionId = await historyRepo.createSession(
          challengeId: challenge.id,
          categoryName: challenge.category.name,
          challengeTitle: challenge.title,
        );
        state = state.copyWith(sessionId: sessionId);
      }

      // Save the attempt
      await historyRepo.saveAttempt(
        sessionId: sessionId,
        attempt: attempt,
        feedback: feedback,
      );

      // Update best score
      await historyRepo.updateBestScoreIfHigher(
        sessionId,
        feedback.overallScore,
      );

      state = state.copyWith(saveStatus: SaveStatus.idle);
    } catch (e) {
      debugPrint('Failed to save attempt to history: $e');
      state = state.copyWith(saveStatus: SaveStatus.failed);
    }
  }

  /// Retries saving the latest attempt after a prior failure.
  /// Called from the UI when the user taps the retry action.
  Future<void> retrySave(Challenge challenge) async {
    if (state.saveStatus != SaveStatus.failed) return;
    if (state.attempts.isEmpty || state.feedbacks.isEmpty) return;

    final attempt = state.attempts.last;
    final feedback = state.feedbacks.last;
    await _saveToHistory(challenge, attempt, feedback);
  }

  // Method to reset the controller state
  void reset() {
    state = AttemptState.initial();
  }
}
