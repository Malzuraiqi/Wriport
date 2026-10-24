import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wriport/domain/models/attempt.dart';
import 'package:wriport/domain/models/challenge.dart';
import 'package:wriport/domain/models/criterion.dart';
import 'package:wriport/domain/models/criterion_score.dart';
import 'package:wriport/domain/models/feedback.dart';
import 'package:wriport/domain/models/session.dart';
import 'package:wriport/domain/models/session_attempt.dart';
import 'package:wriport/domain/repositories/history_repository.dart';
import 'package:wriport/domain/services/evaluation_exception.dart';

class FirestoreHistoryRepository implements HistoryRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw EvaluationException('You must be signed in to save your history.');
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _db.collection('users').doc(_uid).collection('sessions');

  CollectionReference<Map<String, dynamic>> _attempts(String sessionId) =>
      _sessions.doc(sessionId).collection('attempts');

  @override
  Future<String> createSession({
    required int challengeId,
    required String categoryName,
    required String challengeTitle,
  }) async {
    final ref = await _sessions.add({
      'challengeId': challengeId,
      'categoryName': categoryName,
      'challengeTitle': challengeTitle,
      'startedAt': FieldValue.serverTimestamp(),
      'bestScore': null,
    });
    return ref.id;
  }

  @override
  Future<void> saveAttempt({
    required String sessionId,
    required Attempt attempt,
    required FeedBack feedback,
  }) async {
    await _attempts(sessionId).doc('${attempt.attemptNumber}').set({
      'text': attempt.text,
      'wordCount': attempt.wordCount,
      'createdAt': Timestamp.fromDate(attempt.createdAt),
      'feedback': {
        'overallScore': feedback.overallScore,
        'criteria': feedback.criteria
            .map((c) => {
                  'criterionId': c.criterion.id, // id, not label
                  'score': c.score,
                  'comment': c.comment,
                })
            .toList(),
        'strengths': feedback.strengths,
        'improvements': feedback.improvements,
      },
    });
  }

  @override
  Future<void> updateBestScoreIfHigher(String sessionId, int score) async {
    final docRef = _sessions.doc(sessionId);
    await _db.runTransaction((tx) async {
      final snapshot = await tx.get(docRef);
      final current = snapshot.data()?['bestScore'] as int?;
      if (current == null || score > current) {
        tx.update(docRef, {'bestScore': score});
      }
    });
  }

  @override
  Future<List<Session>> getSessions() async {
    final snapshot = await _sessions.orderBy('startedAt', descending: true).get();
    return snapshot.docs.map(_sessionFromDoc).toList();
  }

  @override
  Future<Session?> getSession(String sessionId) async {
    final doc = await _sessions.doc(sessionId).get();
    if (!doc.exists) return null;
    return _sessionFromDoc(doc);
  }

  @override
  Future<List<SessionAttempt>> getAttempts(String sessionId) async {
    // Fetch the session to know which category's criteria to use.
    final sessionDoc = await _sessions.doc(sessionId).get();
    final sessionData = sessionDoc.data();
    final categoryName = sessionData?['categoryName'] as String? ?? '';

    // Look up the Category enum by name to get its criteria list.
    final category = Category.values
        .where((c) => c.name == categoryName)
        .firstOrNull;
    final criteria = category?.criteria ?? Criteria.core;

    final snapshot =
        await _attempts(sessionId).orderBy(FieldPath.documentId).get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return SessionAttempt(
        attempt: _attemptFromData(doc.id, data),
        feedback: _feedbackFromData(
          data['feedback'] as Map<String, dynamic>,
          criteria,
        ),
      );
    }).toList();
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    // Delete subcollection first, then the session doc.
    final attempts = await _attempts(sessionId).get();
    final batch = _db.batch();
    for (final doc in attempts.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_sessions.doc(sessionId));
    await batch.commit();
  }

  // -- Mapping helpers ------------------------------------------------------

  Session _sessionFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Session(
      id: doc.id,
      challengeId: data['challengeId'] as int,
      categoryName: data['categoryName'] as String,
      challengeTitle: data['challengeTitle'] as String? ?? 'Untitled',
      startedAt: (data['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      bestScore: data['bestScore'] as int?,
    );
  }

  Attempt _attemptFromData(String docId, Map<String, dynamic> data) {
    return Attempt(
      id: int.tryParse(docId) ?? 0,
      challengeId: 0, // not stored per-attempt; comes from session
      text: data['text'] as String? ?? '',
      attemptNumber: int.tryParse(docId) ?? 1,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      wordCount: data['wordCount'] as int? ?? 0,
    );
  }

  /// Reconstructs a [FeedBack] from Firestore data by matching stored
  /// `criterionId` values back to the category's [Criterion] objects.
  FeedBack _feedbackFromData(
    Map<String, dynamic> data,
    List<Criterion> categoryCriteria,
  ) {
    final rawList = data['criteria'] as List<dynamic>? ?? [];

    // Build a quick lookup: criterionId -> Criterion
    final criterionById = {
      for (final c in categoryCriteria) c.id: c,
    };

    final List<CriterionScore> scores = [];
    for (final raw in rawList) {
      final map = raw as Map<String, dynamic>;
      final id = map['criterionId'] as String? ?? '';
      // Look up the Criterion; if unknown, create a minimal placeholder so
      // history still renders even after a category redesign.
      final criterion = criterionById[id] ??
          Criterion(id: id, label: id, description: '');
      scores.add(CriterionScore(
        criterion: criterion,
        score: (map['score'] as num?)?.toInt() ?? 0,
        comment: map['comment'] as String? ?? '',
      ));
    }

    return FeedBack(
      attemptId: 0, // not stored; irrelevant for history display
      overallScore: (data['overallScore'] as num?)?.toInt() ?? 0,
      criteria: scores,
      strengths: List<String>.from(data['strengths'] ?? []),
      improvements: List<String>.from(data['improvements'] ?? []),
    );
  }
}
