import 'package:flutter_test/flutter_test.dart';
import 'package:wriport/domain/models/criterion.dart';
import 'package:wriport/domain/models/feedback.dart';

// Builds the kind of JSON the AI returns. Tests pass different scores to
// check how fromJson reacts. (attemptId is deliberately not asserted here,
// because the service attaches the real id after parsing.)
Map<String, dynamic> _json(List<num> scores) {
  const criterions = ['grammar', 'tone', 'clarity'];
  return {
    'criteria': [
      for (var i = 0; i < scores.length; i++)
        {'criterion': criterions[i], 'score': scores[i], 'comment': 'comment $i'},
    ],
    'strengths': ['Clear structure'],
    'improvements': ['Shorten it'],
  };
}

void main() {
  group('FeedBack.fromJson', () {
    test('parses criteria, strengths and improvements', () {
      final feedback = FeedBack.fromJson(_json([90, 80, 70]), attemptId: 10, requiredCriterias: Criteria.core);

      expect(feedback.criteria.length, 3);
      expect(feedback.criteria.first.criterion, Criteria.grammar);
      expect(feedback.criteria.first.score, 90);
      expect(feedback.criteria.first.comment, 'comment 0');
      expect(feedback.strengths, ['Clear structure']);
      expect(feedback.improvements, ['Shorten it']);
    });

    test('overall score is the average of the criteria scores', () {
      expect(FeedBack.fromJson(_json([90, 80, 70]), attemptId: 8, requiredCriterias: Criteria.core).overallScore, 80);
    });

    test('rounded to the nearest whole number', () {
      // (50 + 20 + 100) / 3 = 56.67 -> 56
      expect(FeedBack.fromJson(_json([50, 20, 100]), attemptId: 7, requiredCriterias: Criteria.core).overallScore, 57);
    });

    test('accepts scores that arrive with decimals', () {
      final feedback = FeedBack.fromJson(_json([85.5, 84.5, 90.0]), attemptId: 6, requiredCriterias: Criteria.core);

      expect(feedback.criteria[0].score, 85);
      expect(feedback.overallScore, 86);
    });

    test('clamps an overall score above 100 down to 100', () {
      expect(FeedBack.fromJson(_json([150, 150, 150]), attemptId: 5, requiredCriterias: Criteria.core).overallScore, 100);
    });

    test('clamps an overall score below 0 up to 0', () {
      expect(FeedBack.fromJson(_json([-20, -20, -20]), attemptId: 4, requiredCriterias: Criteria.core).overallScore, 0);
    });

    test('overall score is 0 when there are no criteria', () {
      expect(FeedBack.fromJson(_json([]), attemptId: 3, requiredCriterias: []).overallScore, 0);
    });
  
    test('missing strengths and improvements become empty lists', () {
      final json = _json([80, 80, 80])
        ..remove('strengths')
        ..remove('improvements');
      final feedback = FeedBack.fromJson(json, attemptId: 1, requiredCriterias: Criteria.core);

      expect(feedback.strengths, isEmpty);
      expect(feedback.improvements, isEmpty);
    });

    test('throws when the criteria key is missing entirely', () {
      // A broken AI reply must fail loudly here. The Gemini service catches
      // it and converts it into an EvaluationException.
      expect(
        () => FeedBack.fromJson({'strengths': [], 'improvements': []}, attemptId: 2, requiredCriterias: Criteria.core),
        throwsA(anything),
      );
    });
  });
}