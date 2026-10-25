import 'dart:async';
import 'package:wriport/domain/models/app_user.dart';
import 'package:wriport/domain/repositories/auth_repository.dart';
import 'package:wriport/domain/services/auth_exception.dart';

/// In-memory implementation of [AuthRepository] for testing and offline development.
class InMemoryAuthRepository implements AuthRepository {
  InMemoryAuthRepository({AppUser? initialUser}) {
    if (initialUser != null) {
      _currentUser = initialUser;
      _users[initialUser.email] = (initialUser, 'password123');
      _controller.add(initialUser);
    }
  }

  final StreamController<AppUser?> _controller =
      StreamController<AppUser?>.broadcast();
  final Map<String, (AppUser user, String password)> _users = {};
  AppUser? _currentUser;
  bool shouldFail = false;

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Future<AppUser> signInWithEmail(String email, String password) async {
    if (shouldFail) throw AuthException('Simulated auth error.');
    final entry = _users[email];
    if (entry == null) {
      throw AuthException('No account found with that email.');
    }
    if (entry.$2 != password) {
      throw AuthException('Incorrect password. Please try again.');
    }
    _currentUser = entry.$1;
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<AppUser> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    if (shouldFail) throw AuthException('Simulated auth error.');
    if (_users.containsKey(email)) {
      throw AuthException('An account with that email already exists.');
    }
    if (password.length < 6) {
      throw AuthException('Password is too weak. Use at least 6 characters.');
    }
    final user = AppUser(
      uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: name,
    );
    _users[email] = (user, password);
    _currentUser = user;
    _controller.add(_currentUser);
    return user;
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    if (shouldFail) throw AuthException('Google sign-in failed.');
    final user = AppUser(
      uid: 'google_user_${DateTime.now().millisecondsSinceEpoch}',
      email: 'google_user@example.com',
      displayName: 'Google User',
    );
    _currentUser = user;
    _controller.add(_currentUser);
    return user;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    if (shouldFail) throw AuthException('Could not send reset email.');
    if (!_users.containsKey(email)) {
      throw AuthException('No account found with that email.');
    }
  }

  void dispose() {
    _controller.close();
  }
}
