import 'package:wriport/domain/models/attempt.dart';
import 'package:wriport/domain/models/feedback.dart';
import 'package:wriport/domain/models/session.dart';
import 'package:wriport/domain/models/session_attempt.dart';
import 'package:wriport/domain/repositories/history_repository.dart';

/// In-memory implementation of [HistoryRepository] for testing and offline development.
class InMemoryHistoryRepository implements HistoryRepository {
  final Map<String, Session> _sessions = {};
  final Map<String, List<SessionAttempt>> _attempts = {};
  int _idCounter = 1;
  bool shouldFail = false;

  @override
  Future<String> createSession({
    required int challengeId,
    required String categoryName,
    required String challengeTitle,
  }) async {
    if (shouldFail) throw Exception('Simulated createSession failure');
    final id = 'session_${_idCounter++}';
    final session = Session(
      id: id,
      challengeId: challengeId,
      categoryName: categoryName,
      challengeTitle: challengeTitle,
      startedAt: DateTime.now(),
      bestScore: null,
    );
    _sessions[id] = session;
    _attempts[id] = [];
    return id;
  }

  @override
  Future<void> saveAttempt({
    required String sessionId,
    required Attempt attempt,
    required FeedBack feedback,
  }) async {
    if (shouldFail) throw Exception('Simulated saveAttempt failure');
    _attempts[sessionId] ??= [];
    _attempts[sessionId]!.add(SessionAttempt(attempt: attempt, feedback: feedback));
  }

  @override
  Future<void> updateBestScoreIfHigher(String sessionId, int score) async {
    if (shouldFail) throw Exception('Simulated updateBestScore failure');
    final session = _sessions[sessionId];
    if (session == null) return;
    final current = session.bestScore;
    if (current == null || score > current) {
      _sessions[sessionId] = session.copyWith(bestScore: score);
    }
  }

  @override
  Future<List<Session>> getSessions() async {
    if (shouldFail) throw Exception('Simulated getSessions failure');
    final list = _sessions.values.toList();
    list.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return list;
  }

  @override
  Future<Session?> getSession(String sessionId) async {
    if (shouldFail) throw Exception('Simulated getSession failure');
    return _sessions[sessionId];
  }

  @override
  Future<List<SessionAttempt>> getAttempts(String sessionId) async {
    if (shouldFail) throw Exception('Simulated getAttempts failure');
    return List.unmodifiable(_attempts[sessionId] ?? []);
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    if (shouldFail) throw Exception('Simulated deleteSession failure');
    _sessions.remove(sessionId);
    _attempts.remove(sessionId);
  }
}
