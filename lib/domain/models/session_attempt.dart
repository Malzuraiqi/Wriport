import 'attempt.dart';
import 'feedback.dart';

class SessionAttempt {
  const SessionAttempt({
    required this.attempt,
    required this.feedback,
  });

  final Attempt attempt;
  final FeedBack feedback;
}