import '../domain/models/attempt.dart';
import '../domain/models/feedback.dart';

//AttemptState
//  + attempts: List<Attempt>
//  + feedbacks: List<Feedback>
//  + status: enum { idle, loading, error }
//  + errorMessage: String?

class AttemptState {
  // Constructor for AttemptState
  AttemptState({
    required this.attempts,
    required this.feedbacks,
    required this.status,
    this.errorMessage,
  });

  // Define properties for each field
  final List<Attempt> attempts;
  final List<FeedBack> feedbacks;
  final AttemptStatus status;
  final String? errorMessage;

  // Factory method to create an initial state
  factory AttemptState.initial() {
    return AttemptState(
      attempts: [],
      feedbacks: [],
      status: AttemptStatus.idle,
      errorMessage: null,
    );
  }

  // Method to copy the current state with new values
  AttemptState copyWith({
    List<Attempt>? attempts,
    List<FeedBack>? feedbacks,
    AttemptStatus? status,
    String? errorMessage,
  }) {
    return AttemptState(
      attempts: attempts ?? this.attempts,
      feedbacks: feedbacks ?? this.feedbacks,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

enum AttemptStatus {
  // Define possible statuses for AttemptState
  idle,
  loading,
  error,
}