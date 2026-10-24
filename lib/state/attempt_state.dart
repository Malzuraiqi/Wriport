import 'package:wriport/core/app_constants.dart';

import '../domain/models/attempt.dart';
import '../domain/models/feedback.dart';

//AttemptState
//  + attempts: List<Attempt>
//  + feedbacks: List<Feedback>
//  + status: enum { idle, loading, error }
//  + errorMessage: String?
//  + sessionId: String?          – created on first successful evaluation
//  + saveStatus: enum { idle, saving, failed }

class AttemptState {
  // Constructor for AttemptState
  AttemptState({
    required this.attempts,
    required this.feedbacks,
    required this.status,
    this.errorMessage,
    this.sessionId,
    this.saveStatus = SaveStatus.idle,
  });

  // Define properties for each field
  final List<Attempt> attempts;
  final List<FeedBack> feedbacks;
  final AttemptStatus status;
  final String? errorMessage;
  final String? sessionId;
  final SaveStatus saveStatus;

  bool get canAttempt => attempts.length < AppConstants.maxAttempts;
  FeedBack get latestFeedback => feedbacks.last;
  FeedBack? get previousFeedback { 
    if (feedbacks.length < 2) return null; 
    return feedbacks[feedbacks.length - 2];
  }

  // Factory method to create an initial state
  factory AttemptState.initial() {
    return AttemptState(
      attempts: [],
      feedbacks: [],
      status: AttemptStatus.idle,
      errorMessage: null,
      sessionId: null,
      saveStatus: SaveStatus.idle,
    );
  }

  // Method to copy the current state with new values
  AttemptState copyWith({
    List<Attempt>? attempts,
    List<FeedBack>? feedbacks,
    AttemptStatus? status,
    String? errorMessage,
    String? sessionId,
    SaveStatus? saveStatus,
  }) {
    return AttemptState(
      attempts: attempts ?? this.attempts,
      feedbacks: feedbacks ?? this.feedbacks,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      sessionId: sessionId ?? this.sessionId,
      saveStatus: saveStatus ?? this.saveStatus,
    );
  }
}

enum AttemptStatus {
  // Define possible statuses for AttemptState
  idle,
  loading,
  error,
}

enum SaveStatus {
  idle,
  saving,
  failed,
}
