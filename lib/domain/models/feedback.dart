import 'package:wriport/domain/models/criterion.dart';
import 'package:wriport/domain/services/evaluation_exception.dart';

import 'criterion_score.dart';

class FeedBack {
  // attemptId, overallScore, criteria (List<CriterionScore>), strengths (List<String>), improvements (List<String>), fromJson (to build feedback from AI Json) 
  FeedBack({
    required this.attemptId,
    required this.overallScore,
    required this.criteria,
    required this.strengths,
    required this.improvements,
  });

  // Define properties for each field
  final int attemptId;
  final int overallScore;
  final List<CriterionScore> criteria;
  final List<String> strengths;
  final List<String> improvements;

  // Factory method to create Feedback from JSON
  factory FeedBack.fromJson(Map<String, dynamic> json, {required int attemptId, required List<Criterion> requiredCriterias}) {
    final rawCriteriaList = json['criteria'] as List? ?? [];   
    
    final returnedCriteriaMap = <String, Map<String, dynamic>>{};
    for (final item in rawCriteriaList) {
      final id = (item['id'] ?? item['criterion'] as String?);
      if (id != null) {
        returnedCriteriaMap[id] = item as Map<String, dynamic>;
      }
    }

    final List<CriterionScore> parsedCriteria = [];
    int sum = 0;

    for (final req in requiredCriterias) {
      final returnedItem = returnedCriteriaMap[req.id];

      if (returnedItem == null) {
        throw EvaluationException('Evaluation incomplete: Missing required criterion "${req.id}"');
      }
      
      final score = ((returnedItem['score'] as num?)?.toInt() ?? 0).clamp(0, 100);
      sum += score;

      parsedCriteria.add(
        CriterionScore(
          criterion: req, 
          score: score, 
          comment: returnedItem['comment'] as String? ?? '',
        )
      );
    }

    int avg = requiredCriterias.isNotEmpty
      ? (sum / requiredCriterias.length).toInt()
      : 0;

    int finalScore = avg.clamp(0, 100);

    return FeedBack(
      attemptId: attemptId,
      overallScore: finalScore,
      criteria: parsedCriteria,
      strengths: List<String>.from(json['strengths'] ?? []),
      improvements: List<String>.from(json['improvements'] ?? []),
    );
  }
}