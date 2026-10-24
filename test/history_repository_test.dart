import 'package:flutter_test/flutter_test.dart';
import 'package:wriport/domain/models/session.dart';

import 'in_memory_history_repository.dart';
import 'test_helpers.dart';

void main() {
  group('Session model', () {
    test('copyWith updates bestScore while preserving other fields', () {
      final session = Session(
        id: 's1',
        challengeId: 10,
        categoryName: 'email',
        challengeTitle: 'Email Test',
        startedAt: DateTime(2026, 1, 1),
        bestScore: 70,
      );

      final updated = session.copyWith(bestScore: 85);
      expect(updated.id, 's1');
      expect(updated.challengeId, 10);
      expect(updated.categoryName, 'email');
      expect(updated.challengeTitle, 'Email Test');
      expect(updated.startedAt, DateTime(2026, 1, 1));
      expect(updated.bestScore, 85);
    });
  });

  group('HistoryRepository interface and persistence operations', () {
    late InMemoryHistoryRepository repo;

    setUp(() {
      repo = InMemoryHistoryRepository();
    });

    test('createSession stores new session with null bestScore', () async {
      final id = await repo.createSession(
        challengeId: 1,
        categoryName: 'email',
        challengeTitle: 'Welcome Email',
      );

      expect(id, isNotEmpty);
      final session = await repo.getSession(id);
      expect(session, isNotNull);
      expect(session!.challengeId, 1);
      expect(session.categoryName, 'email');
      expect(session.challengeTitle, 'Welcome Email');
      expect(session.bestScore, isNull);
    });

    test('saveAttempt persists attempt and embedded feedback', () async {
      final sessionId = await repo.createSession(
        challengeId: 1,
        categoryName: 'email',
        challengeTitle: 'Welcome Email',
      );

      final attempt = buildAttempt(id: 1, attemptNumber: 1, text: 'Hello there');
      final feedback = buildFeedback(attemptId: 1, overall: 85);

      await repo.saveAttempt(
        sessionId: sessionId,
        attempt: attempt,
        feedback: feedback,
      );

      final attempts = await repo.getAttempts(sessionId);
      expect(attempts.length, 1);
      expect(attempts.first.attempt.text, 'Hello there');
      expect(attempts.first.feedback.overallScore, 85);
      expect(attempts.first.feedback.strengths, feedback.strengths);
      expect(attempts.first.feedback.improvements, feedback.improvements);
    });

    test('updateBestScoreIfHigher updates best score only when higher', () async {
      final sessionId = await repo.createSession(
        challengeId: 1,
        categoryName: 'email',
        challengeTitle: 'Welcome Email',
      );

      // Initial update from null to 75
      await repo.updateBestScoreIfHigher(sessionId, 75);
      var session = await repo.getSession(sessionId);
      expect(session!.bestScore, 75);

      // Lower score should not overwrite
      await repo.updateBestScoreIfHigher(sessionId, 60);
      session = await repo.getSession(sessionId);
      expect(session!.bestScore, 75);

      // Higher score should overwrite
      await repo.updateBestScoreIfHigher(sessionId, 90);
      session = await repo.getSession(sessionId);
      expect(session!.bestScore, 90);
    });

    test('getSessions returns sessions ordered by startedAt descending', () async {
      await repo.createSession(
        challengeId: 1,
        categoryName: 'email',
        challengeTitle: 'First Session',
      );
      // Brief delay to ensure different timestamps
      await Future.delayed(const Duration(milliseconds: 10));
      await repo.createSession(
        challengeId: 2,
        categoryName: 'report',
        challengeTitle: 'Second Session',
      );

      final sessions = await repo.getSessions();
      expect(sessions.length, 2);
      expect(sessions.first.challengeTitle, 'Second Session');
      expect(sessions.last.challengeTitle, 'First Session');
    });

    test('deleteSession deletes session and its associated attempts', () async {
      final sessionId = await repo.createSession(
        challengeId: 1,
        categoryName: 'email',
        challengeTitle: 'To Delete',
      );

      await repo.saveAttempt(
        sessionId: sessionId,
        attempt: buildAttempt(),
        feedback: buildFeedback(),
      );

      expect((await repo.getAttempts(sessionId)).length, 1);

      await repo.deleteSession(sessionId);

      expect(await repo.getSession(sessionId), isNull);
      expect((await repo.getAttempts(sessionId)), isEmpty);
      expect((await repo.getSessions()), isEmpty);
    });
  });
}
