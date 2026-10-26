import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wriport/domain/models/challenge.dart';
import 'package:wriport/providers.dart';
import 'package:wriport/ui/screens/challenge_screen.dart';
import 'package:wriport/ui/screens/feedback_screen.dart';
import 'package:wriport/ui/screens/history_screen.dart';
import 'package:wriport/ui/screens/home_screen.dart';
import 'package:wriport/ui/screens/login_screen.dart';
import 'package:wriport/ui/screens/session_detail_screen.dart';
import 'package:wriport/ui/screens/sign_up_screen.dart';
import 'package:wriport/ui/screens/writing_screen.dart';

class AuthChangeNotifier extends ChangeNotifier {
    AuthChangeNotifier(Ref ref) {
        ref.listen(Providers.authStateProvider, (_, _) => notifyListeners());
    }
}

/// App navigation, declarative via go_router.
///
/// URLs carry ids only — never whole objects:
/// - `/home` — category picker
/// - `/challenges/:category` — challenge list (enum name, e.g. /challenges/email)
/// - `/writing/:id` — writing screen for the challenge with that id
/// - `/feedback` — feedback for the latest attempt (guarded, see below)
/// - `/history` — session history (from Firestore)
/// - `/history/:sessionId` — read-only detail of a past session's attempts
///
/// The feedback route is *pushed* (never `go`) so the writing screen stays
/// underneath it and keeps the user's typed text when they pop back.
final routerProvider = Provider<GoRouter>((ref) {
    final router = GoRouter(
        initialLocation: AppRouter.home,
        refreshListenable: AuthChangeNotifier(ref),
        redirect: (context, state) {
            final authState = ref.read(Providers.authStateProvider);
            if (authState.isLoading) return null;
            final isLoggedIn = authState.value != null;
            final isAuthRoute = state.matchedLocation == AppRouter.login ||
                state.matchedLocation == AppRouter.signup;

             // Not logged in and not on auth screen -> force login
            if (!isLoggedIn && !isAuthRoute) {
                return AppRouter.login;
            }

            // Logged in but stuck on auth screen -> send home
            if (isLoggedIn && isAuthRoute) {
                return AppRouter.home;
            }

            return null; // No redirect needed
        },
        errorBuilder: (context, state) => const HomeScreen(),
        routes: [
            GoRoute(
                path: AppRouter.login,
                builder: (context, state) => const LoginScreen(),
            ),
            GoRoute(
                path: AppRouter.signup,
                builder: (context, state) => const SignUpScreen(),
            ),
        GoRoute(
            path: AppRouter.home,
            builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
            path: '/challenges/:category',
            // Unknown category name -> home, instead of a byName crash.
            redirect: (context, state) {
            final name = state.pathParameters['category'];
            final isKnown = Category.values.any((c) => c.name == name);
            return isKnown ? null : AppRouter.home;
            },
            builder: (context, state) {
            final category = Category.values.byName(state.pathParameters['category']!);
            return ChallengeScreen(category: category);
            },
        ),
        GoRoute(
            path: '/writing/:id',
            // Unknown / malformed challenge id -> home.
            redirect: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            if (id == null) return AppRouter.home;

            final challenge = ref.read(Providers.challengeProvider(id));
            return challenge == null ? AppRouter.home : null;
            },
            builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return WritingScreen(challengeId: id);
            },
        ),
        GoRoute(
            path: AppRouter.feedback,
            // Guard: feedback only exists right after an evaluation. With no
            // feedback in state, redirect home instead of showing a dead-end
            // empty-state screen.
            redirect: (context, state) {
            final hasFeedback = ref.read(Providers.attemptControllerProvider)
                .feedbacks
                .isNotEmpty;
            return hasFeedback ? null : AppRouter.home;
            },
            builder: (context, state) => const FeedbackScreen(),
        ),
        GoRoute(
            path: AppRouter.history,
            builder: (context, state) => const HistoryScreen(),
        ),
        GoRoute(
            path: '/history/:sessionId',
            builder: (context, state) {
            final sessionId = state.pathParameters['sessionId']!;
            return SessionDetailScreen(sessionId: sessionId);
            },
        ),
        ],
    );

    ref.onDispose(router.dispose);
    return router;
});


class AppRouter {
  AppRouter._();
  
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String feedback = '/feedback';
  static const String history = '/history';

  static String challengeList(Category category) => '/challenges/${category.name}';
  static String writing(int challengeId) => '/writing/$challengeId';
  static String sessionDetail(String sessionId) => '/history/$sessionId';
}
