// Shared "builder" functions for tests.
//
// Creating a Challenge / Attempt / FeedBack needs many required fields.
// Writing them out in every test would be noisy, so each builder fills in
// sensible defaults and lets a test override only what it cares about.

import 'package:wriport/domain/models/attempt.dart';
import 'package:wriport/domain/models/challenge.dart';
import 'package:wriport/domain/models/criterion.dart';
import 'package:wriport/domain/models/criterion_score.dart';
import 'package:wriport/domain/models/feedback.dart';

Challenge buildChallenge({int id = 1}) {
  return Challenge(
    id: id,
    category: Category.email,
    title: 'Test challenge',
    instructions: 'Write a short test email.',
    tone: 'Professional',
    minWords: 5,
    maxWords: 100,
  );
}

Attempt buildAttempt({
  int id = 1,
  int attemptNumber = 1,
  String text = 'Dear Professor Luan',
}) {
  int wordCount = text.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  return Attempt(
    id: id,
    challengeId: 1,
    text: text,
    attemptNumber: attemptNumber,
    createdAt: DateTime(2026, 1, 1), // fixed date: tests must be repeatable
    wordCount: wordCount, 
  );
}

FeedBack buildFeedback({int attemptId = 1, int overall = 80}) {
  return FeedBack(
    attemptId: attemptId,
    overallScore: overall,
    criteria: [
      CriterionScore(criterion: Criteria.grammar, score: 80, comment: 'ok'),
      CriterionScore(criterion: Criteria.tone, score: 80, comment: 'ok'),
      CriterionScore(criterion: Criteria.clarity, score: 80, comment: 'ok'),
    ],
    strengths: ['Clear structure'],
    improvements: ['Shorten the last paragraph'],
  );
}