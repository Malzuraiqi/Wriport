class Session {
  const Session({
    required this.id,
    required this.challengeId,
    required this.categoryName,
    required this.challengeTitle,
    required this.startedAt,
    this.bestScore,
  });

  final String id;
  final int challengeId;
  final String categoryName; // Category.name — store the enum name, not the label
  final String challengeTitle; // human-readable title for the history list
  final DateTime startedAt;
  final int? bestScore; // null until first attempt is scored

  Session copyWith({int? bestScore}) => Session(
        id: id,
        challengeId: challengeId,
        categoryName: categoryName,
        challengeTitle: challengeTitle,
        startedAt: startedAt,
        bestScore: bestScore ?? this.bestScore,
      );
}
