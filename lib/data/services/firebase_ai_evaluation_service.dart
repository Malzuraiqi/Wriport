import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:wriport/domain/models/attempt.dart';
import 'package:wriport/domain/models/challenge.dart';
import 'package:wriport/domain/models/criterion.dart';
import 'package:wriport/domain/models/feedback.dart';
import 'package:wriport/domain/services/evaluation_exception.dart';
import 'package:wriport/domain/services/evaluation_prompt.dart';
import 'package:wriport/domain/services/evaluation_service.dart';

class FirebaseAiEvaluationService implements EvaluationService {
  static const Duration evaluationTimeout = Duration(seconds: 30);

  // no apiKey — Firebase AI Logic holds the key server-side.
  final GenerativeModel _model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-3.1-flash-lite',
    generationConfig: GenerationConfig(
      responseMimeType: 'application/json',
    ),
  );

  Future<FeedBack?> _generateEvaluation(
    String prompt,
    int attemptId,
    List<Criterion> requiredCriterias,
  ) async {
    try {
      final response = await _model
          .generateContent([Content.text(prompt)])
          .timeout(evaluationTimeout);

      final jsonText = response.text;
      if (jsonText == null) return null;

      final Map<String, dynamic> decodedJson = jsonDecode(jsonText);
      return FeedBack.fromJson(
        decodedJson,
        attemptId: attemptId,
        requiredCriterias: requiredCriterias,
      );
    } on TimeoutException catch (e) {
      throw EvaluationException(
        'The evaluation is taking too long. Check your connection and try again.',
        detail: 'Firebase AI request timed out after ${evaluationTimeout.inSeconds}s: $e',
      );
    } on FirebaseException catch (e) {
      if (e.code != 'network-request-failed') {
        throw EvaluationException(
          'Something went wrong while evaluating your writing. Please try again.',
          detail: 'Firebase error ${e.code}: $e',
        );
      }
      if (e.code == 'network-request-failed') {
        throw EvaluationException(
          'Check your internet connection and try again.',
          detail: 'Firebase network error: $e',
        );
      }
      rethrow;
    } on SocketException catch (e) {
      throw EvaluationException(
        'Check your internet connection and try again.',
        detail: 'Socket error: $e',
      );
    } on EvaluationException {
      rethrow; // already user-friendly
    } catch (e) {
      debugPrint('Firebase AI evaluation failed: $e');
      throw EvaluationException(
        'Something went wrong while evaluating your writing. Please try again.',
        detail: e.toString(),
      );
    }
  }

  @override
  Future<FeedBack> evaluate(Challenge challenge, Attempt attempt) async {
    final prompt = buildPrompt(challenge, attempt);

    final feedback = await _generateEvaluation(
      prompt,
      attempt.id,
      challenge.category.criteria,
    );

    if (feedback == null) {
      throw EvaluationException(
        'The AI returned an empty response. Please try again.',
      );
    }

    return feedback;
  }
}