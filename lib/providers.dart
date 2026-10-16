//Providers (providers.dart)
//  evaluationServiceProvider  -> Fake or Gemini (the only swap point)
//  challengesProvider         -> list of challenges
//  attemptControllerProvider  -> AttemptController
//  themeModeProvider          -> ThemeMode (system / light / dark)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wriport/data/services/gemini_evaluation_service.dart';
import 'package:wriport/ui/theme/app_theme.dart';
import 'domain/services/evaluation_service.dart';
import 'data/repositories/challenge_repository.dart';
import 'domain/models/challenge.dart';
import 'state/attempt_controller.dart';
import 'state/attempt_state.dart';

// learning: providors is read-only, but to manage state that changes over time and
// triggers UI rebuilds, convert it to extend Notifier.

class Providers {
  // Provider for the evaluation service
  static final evaluationServiceProvider = Provider<EvaluationService>((ref) {
    return GeminiEvaluationService();
  });

  // Provider for the list of challenges
  static final challengesProvider = Provider.family<List<Challenge>, Category>((ref, category) {
    return ChallengeRepository().getChallenges(category);
  });

  // Provider for the AttemptController
  static final attemptControllerProvider = 
    NotifierProvider<AttemptController, AttemptState>(AttemptController.new);

  // Provider for the current theme mode (system / light / dark).
  // ADDITIVE ONLY: none of the providers above were modified.
  static final themeModeProvider = 
    NotifierProvider<AppTheme, ThemeMode>(AppTheme.new);
}