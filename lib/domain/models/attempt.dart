int countWords(String text) {
  return text
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .length;
}

class Attempt {
  // id, challengeId, text, attemptNumber, createdAt, wordCount
  Attempt({
    required this.id,
    required this.challengeId,
    required this.text,
    required this.attemptNumber,
    required this.createdAt,
    required this.wordCount,
  });

  // Define properties for each field
  final int id;
  final int challengeId;
  final String text;
  final int attemptNumber;
  final DateTime createdAt;
  final int wordCount;

}