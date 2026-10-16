import 'package:wriport/domain/models/criterion.dart';

class CriterionScore {
  CriterionScore({
    required this.criterion,
    required this.score,
    required this.comment
  });

  final Criterion criterion;
  final int score;
  final String comment;
}