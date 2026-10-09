import '../models/attempt.dart';
import '../models/challenge.dart';
import '../models/feedback.dart';

// this class is an interface for the evaluation services
abstract class EvaluationService {
  // EvaluationService(interface): evaluate(Challenge, Attempt) -> Future<Feedback>, Fails with: EvaluationException (message)
  Future<FeedBack> evaluate(Challenge challenge, Attempt attempt);
}