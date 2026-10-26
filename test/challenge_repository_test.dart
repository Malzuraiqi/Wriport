import 'package:flutter_test/flutter_test.dart';
import 'package:wriport/data/repositories/challenge_repository.dart';
import 'package:wriport/domain/models/challenge.dart';

void main() {
  final repository = ChallengeRepository();

  // Increment 3 requirement: "Every category has at least one challenge
  // (loop over all categories, so adding one without challenges fails)".
  //
  // The loop over Category.values is the point: a new enum value with no
  // repository data fails here instead of shipping an empty list.
  group('ChallengeRepository', () {
    test('every category has at least one challenge', () {
      for (final category in Category.values) {
        final challenges = repository.getChallenges(category);
        expect(
          challenges,
          isNotEmpty,
          reason: '${category.label} must have at least one challenge',
        );
      }
    });

    // Increment 3 requirement: the two new categories must ship with 3-5
    // challenges each.
    test('every category has at least 3 challenges', () {
      for (final category in Category.values) {
        final challenges = repository.getChallenges(category);
        expect(
          challenges.length,
          greaterThanOrEqualTo(3),
          reason: '${category.label} should have 3-5 challenges, '
              'found ${challenges.length}',
        );
      }
    });

    test('every returned challenge belongs to the requested category', () {
      for (final category in Category.values) {
        for (final challenge in repository.getChallenges(category)) {
          expect(
            challenge.category,
            category,
            reason: '"${challenge.title}" is filed under '
                '${challenge.category.label} but returned for ${category.label}',
          );
        }
      }
    });

    test('every challenge has a sane word range', () {
      for (final category in Category.values) {
        for (final challenge in repository.getChallenges(category)) {
          expect(challenge.minWords, greaterThan(0),
              reason: '${challenge.title}: minWords must be positive');
          expect(
            challenge.maxWords,
            greaterThanOrEqualTo(challenge.minWords),
            reason: '${challenge.title}: maxWords (${challenge.maxWords}) '
                'must be >= minWords (${challenge.minWords})',
          );
        }
      }
    });

    test('challenge ids are unique across all categories', () {
      final ids = Category.values
          .expand(repository.getChallenges)
          .map((c) => c.id)
          .toList();
      expect(ids.toSet().length, ids.length,
          reason: 'Duplicate challenge ids detected: $ids');
    });
  });
}