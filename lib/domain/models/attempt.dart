class Attempt {
  // id, challengeId, text, attemptNumber, createdAt, wordCount (from text)
  Attempt({
    required this.id,
    required this.challengeId,
    required this.text,
    required this.attemptNumber,
    required this.createdAt,
  }) : wordCount = _calculateWordCount(text);

  // Define properties for each field
  final int id;
  final int challengeId;
  final String text;
  final int attemptNumber;
  final DateTime createdAt;
  final int wordCount;

  // Private method to calculate word count from text
  static int _calculateWordCount(String text) {
    // Split the text by whitespace and filter out empty strings
    final words = text.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    return words.length;
  }
}