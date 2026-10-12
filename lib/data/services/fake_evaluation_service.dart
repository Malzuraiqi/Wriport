import '../../domain/models/challenge.dart';
import '../../domain/services/evaluation_service.dart';
import '../../domain/models/feedback.dart';
import '../../domain/models/attempt.dart';
import '../../domain/models/criterion_score.dart';

// FakeEvaluationService implements EvaluationService
class FakeEvaluationService implements EvaluationService {
  @override
  Future<FeedBack> evaluate(Challenge challenge, Attempt attempt) {
    //  waits 1-2 seconds, returns hardcoded feedback for now
    return Future.delayed(Duration(seconds: 2), () {
      return FeedBack(
        attemptId: attempt.id,
        overallScore: 95,
        criteria: [
          CriterionScore(name: 'Clarity', score: 50, comment: 'The writing is clear and easy to understand.'),
          CriterionScore(name: 'Grammar', score: 20, comment: 'There are a few grammar errors.'),
          CriterionScore(name: 'Tone', score: 100, comment: 'The tone is appropriate for the audience.'),
        ],
        strengths: ['Clear structure', 'Good tone'],
        improvements: ['Check grammar', 'Add more examples'],
      );
    });
  }
}