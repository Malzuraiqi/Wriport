import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  // group() only labels related tests so the output is easy to read.
  group('Attempt.wordCount', () {
    test('counts words separated by single spaces', () {
      expect(buildAttempt(text: 'Dear Professor Luan').wordCount, 3);
    });

    test('ignores leading, trailing and repeated spaces', () {
      expect(buildAttempt(text: '  Dear   Professor  Luan  ').wordCount, 3);
    });

    test('treats newlines and tabs as separators', () {
      expect(buildAttempt(text: 'Dear\nProfessor\tLuan\n\nThanks').wordCount, 4);
    });

    test('returns 0 for empty text', () {
      expect(buildAttempt(text: '').wordCount, 0);
    });

    test('returns 0 for whitespace-only text', () {
      expect(buildAttempt(text: '   \n  ').wordCount, 0);
    });

    test('counts punctuation-attached words as one word each', () {
      expect(buildAttempt(text: 'Hello, world! Well-known.').wordCount, 3);
    });
  });
}