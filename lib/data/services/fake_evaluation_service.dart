import '../../domain/models/challenge.dart';
import '../../domain/services/evaluation_service.dart';
import '../../domain/models/feedback.dart';
import '../../domain/models/attempt.dart';

class FakeEvaluationService implements EvaluationService {
  @override
  Future<FeedBack> evaluate(Challenge challenge, Attempt attempt) async {
    // Simulate a 1-2 second network delay for the AI response
    await Future.delayed(const Duration(seconds: 2));

    // 1. Build a fake JSON array for the criteria requested by the challenge.
    final List<Map<String, dynamic>> fakeCriteriaJson = challenge.category.criteria.map((criterion) {
      return {
        'id': criterion.id, 
        'score': 75 + (attempt.id * 5) % 25, // Generates a slightly different score per attempt
        'comment': 'Simulated feedback for ${criterion.label}.',
      };
    }).toList();

    // 2. Construct the full fake JSON response exactly as the AI would return it
    final Map<String, dynamic> simulatedAiResponse = {
      'criteria': fakeCriteriaJson,
      'strengths': [
        'Clear structure in the simulated attempt.', 
        'Appropriate tone overall.'
      ],
      'improvements': [
        'Review the notes on conciseness.', 
        'Add a sharper closing sentence.'
      ],
    };

    // 3. Process it through your factory just like the real AI service will
    return FeedBack.fromJson(
      simulatedAiResponse,
      attemptId: attempt.id,
      requiredCriterias: challenge.category.criteria,
    );
  }
}