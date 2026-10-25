class EvaluationException implements Exception {
  /// User-friendly message — safe to show in the UI (snackbar / error state).
  final String message;

  /// Technical detail for debugging only. Services attach the raw error
  /// here and log it with debugPrint.
  final String? detail;

  EvaluationException(this.message, {this.detail});

  @override
  String toString() => detail == null ? message : '$message (detail: $detail)';
}