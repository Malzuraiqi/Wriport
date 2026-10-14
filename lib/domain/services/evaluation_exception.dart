// and exception class for the evaluation services
class EvaluationException implements Exception {
  final String message;
  EvaluationException(this.message);

  @override
  String toString() => message;
}