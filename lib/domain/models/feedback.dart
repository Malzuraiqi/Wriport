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
  factory FeedBack.fromJson(Map<String, dynamic> json) {
    return FeedBack(
      attemptId: json['attemptId'],
      overallScore: json['overallScore'],
      criteria: (json['criteria'] as List)
          .map((item) => CriterionScore(
                name: item['name'],
                score: item['score'],
                comment: item['comment'],
              ))
          .toList(),
      strengths: List<String>.from(json['strengths']),
      improvements: List<String>.from(json['improvements']),
    );
  }
}