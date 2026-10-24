import 'package:flutter_test/flutter_test.dart';
import 'package:wriport/data/repositories/challenge_repository.dart';
import 'package:wriport/data/services/gemini_evaluation_service.dart';
import 'package:wriport/domain/models/attempt.dart';
import 'package:wriport/domain/models/challenge.dart';

Attempt _dummyAttempt() => Attempt(
      id: 1,
      challengeId: 1,
      text: 'The quick brown fox writes a test.',
      attemptNumber: 1,
      createdAt: DateTime(2026),
      wordCount: 7,
    );

void main() {
  // Increment 3 requirement: "The prompt contains each category's criteria".
  //
  // buildPrompt is static and pure, so it needs no API key, no .env file,
  // and no network — this test exercises the exact prompt evaluate() sends.
  group('GeminiEvaluationService.buildPrompt', () {
    test('prompt contains every criterion id of every category', () {
      for (final category in Category.values) {
        final challenge =
            ChallengeRepository().getChallenges(category).first;
        final prompt =
            GeminiEvaluationService.buildPrompt(challenge, _dummyAttempt());

        for (final criterion in category.criteria) {
          expect(
            prompt,
            contains('"id": "${criterion.id}"'),
            reason: '${category.label} prompt is missing criterion '
                '"${criterion.id}"',
          );
        }
      }
    });

    test('prompt defines each criterion so Gemini is not judging blind', () {
      for (final category in Category.values) {
        final challenge =
            ChallengeRepository().getChallenges(category).first;
        final prompt =
            GeminiEvaluationService.buildPrompt(challenge, _dummyAttempt());

        for (final criterion in category.criteria) {
          expect(
            prompt,
            contains('${criterion.label}: ${criterion.description}'),
            reason: '${category.label} prompt is missing the definition of '
                '"${criterion.id}"',
          );
        }
      }
    });

    test('persona is built from the category, not a fixed proofreader', () {
      for (final category in Category.values) {
        final challenge =
            ChallengeRepository().getChallenges(category).first;
        final prompt =
            GeminiEvaluationService.buildPrompt(challenge, _dummyAttempt());

        expect(
          prompt,
          contains('specializing in ${category.label.toLowerCase()}'),
          reason: '${category.label} prompt should use a category-specific '
              'persona',
        );
        expect(
          prompt,
          isNot(contains('English Proofreader')),
          reason: 'The fixed proofreader persona should be gone',
        );
      }
    });

    test('prompt carries the challenge constraints and user text', () {
      for (final category in Category.values) {
        for (final challenge
            in ChallengeRepository().getChallenges(category)) {
          final attempt = _dummyAttempt();
          final prompt = GeminiEvaluationService.buildPrompt(challenge, attempt);

          expect(prompt, contains(challenge.tone),
              reason: '${challenge.title}: tone missing from prompt');
          expect(
            prompt,
            contains('${challenge.minWords}-${challenge.maxWords}'),
            reason: '${challenge.title}: word range missing from prompt',
          );
          expect(prompt, contains(attempt.text),
              reason: '${challenge.title}: user text missing from prompt');
        }
      }
    });
  });
}