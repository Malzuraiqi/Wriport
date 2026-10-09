class CriterionScore {
  // name (e.g "Clarity"), score (0-100), comment
  CriterionScore({
    required this.name,
    required this.score,
    required this.comment,
  });

  final String name;
  final int score;
  final String comment;
}