import 'package:wriport/domain/models/attempt.dart';
import 'package:wriport/domain/models/feedback.dart';
import 'package:wriport/domain/models/session.dart';
import 'package:wriport/domain/models/session_attempt.dart';

abstract class HistoryRepository {
  /// Creates a new session and returns its id.
  Future<String> createSession({
    required int challengeId,
    required String categoryName,
    required String challengeTitle,
  });

  /// Writes one attempt (with embedded feedback) under the session.
  Future<void> saveAttempt({
    required String sessionId,
    required Attempt attempt,
    required FeedBack feedback,
  });

  /// Updates the session's bestScore if [score] is higher than the current one.
  Future<void> updateBestScoreIfHigher(String sessionId, int score);

  Future<List<Session>> getSessions();
  Future<Session?> getSession(String sessionId);
  Future<List<SessionAttempt>> getAttempts(String sessionId);
  Future<void> deleteSession(String sessionId);
}
