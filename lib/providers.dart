//Providers (providers.dart)
//  evaluationServiceProvider  -> Fake or Gemini (the only swap point)
//  challengesProvider         -> list of challenges per category
//  challengeProvider          -> single challenge looked up by id (for URL routes)
//  attemptControllerProvider  -> AttemptController
//  themeModeProvider          -> ThemeMode (system / light / dark)
//  historyRepositoryProvider  -> HistoryRepository (Firestore)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wriport/data/repositories/challenge_repository.dart';
import 'package:wriport/data/repositories/firebase_auth_repository.dart';
import 'package:wriport/data/repositories/firestore_history_repository.dart';
import 'package:wriport/data/services/firebase_ai_evaluation_service.dart';
import 'package:wriport/domain/models/app_user.dart';
import 'package:wriport/domain/repositories/auth_repository.dart';
import 'package:wriport/domain/repositories/history_repository.dart';
import 'package:wriport/ui/theme/theme_mode_notifier.dart';
import 'domain/services/evaluation_service.dart';
import 'domain/models/challenge.dart';
import 'state/attempt_controller.dart';
import 'state/attempt_state.dart';

// learning: providors is read-only, but to manage state that changes over time and
// triggers UI rebuilds, convert it to extend Notifier.

class Providers {
  // Provider for the evaluation service
  static final evaluationServiceProvider = Provider<EvaluationService>((ref) {
    return FirebaseAiEvaluationService();
  });

  // Provider for the list of challenges
  static final challengesProvider = Provider.family<List<Challenge>, Category>((ref, category) {
    return ChallengeRepository().getChallenges(category);
  });

  // Provider for looking up a single challenge by id.
  // Routes carry ids in the URL (e.g. /writing/7), never whole objects.
  static final challengeProvider = Provider.family<Challenge?, int>((ref, id) {
    return ChallengeRepository().getChallengeById(id);
  });

  // Provider for the AttemptController
  static final attemptControllerProvider = 
    NotifierProvider<AttemptController, AttemptState>(AttemptController.new);

  // Provider for the current theme mode (system / light / dark).
  static final themeModeProvider = 
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

  static final authRepositoryProvider = Provider<AuthRepository>((ref) {
    return FirebaseAuthRepository();
  });

  // Exposes the auth state stream. Watch this to rebuild when user logs in/out.
  static final authStateProvider = StreamProvider<AppUser?>((ref) {
    return ref.watch(authRepositoryProvider).authStateChanges;
  });

  // Convenience provider for the current user (nullable)
  static final currentUserProvider = Provider<AppUser?>((ref) {
    return ref.watch(authStateProvider).value;
  });

  // Provider for the history repository (Firestore persistence)
  static final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
    return FirestoreHistoryRepository();
  });
}
