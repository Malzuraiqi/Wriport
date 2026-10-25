import 'package:flutter_test/flutter_test.dart';
import 'package:wriport/data/repositories/in_memory_auth_repository.dart';
import 'package:wriport/domain/models/app_user.dart';
import 'package:wriport/domain/services/auth_exception.dart';

void main() {
  group('InMemoryAuthRepository', () {
    late InMemoryAuthRepository repo;

    setUp(() {
      repo = InMemoryAuthRepository();
    });

    tearDown(() {
      repo.dispose();
    });

    test('starts with null current user', () {
      expect(repo.currentUser, isNull);
    });

    test('initialUser constructor sets the current user', () {
      final initial = AppUser(uid: 'u1', email: 'test@example.com', displayName: 'Test');
      final customRepo = InMemoryAuthRepository(initialUser: initial);
      expect(customRepo.currentUser, initial);
      customRepo.dispose();
    });

    test('signUpWithEmail registers user, emits state change, and enforces password length', () async {
      expect(
        () => repo.signUpWithEmail('test@example.com', '123', 'Test'),
        throwsA(isA<AuthException>()),
      );

      final user = await repo.signUpWithEmail('test@example.com', 'password123', 'Test User');
      expect(user.email, 'test@example.com');
      expect(user.displayName, 'Test User');
      expect(repo.currentUser, user);

      // Duplicate email throws
      expect(
        () => repo.signUpWithEmail('test@example.com', 'password123', 'Test User'),
        throwsA(isA<AuthException>()),
      );
    });

    test('signInWithEmail validates password and updates currentUser', () async {
      await repo.signUpWithEmail('user@test.com', 'pass1234', 'User');
      await repo.signOut();
      expect(repo.currentUser, isNull);

      // Wrong password
      expect(
        () => repo.signInWithEmail('user@test.com', 'wrongpass'),
        throwsA(isA<AuthException>()),
      );

      // Non-existent user
      expect(
        () => repo.signInWithEmail('other@test.com', 'pass1234'),
        throwsA(isA<AuthException>()),
      );

      // Successful sign in
      final signedIn = await repo.signInWithEmail('user@test.com', 'pass1234');
      expect(signedIn.email, 'user@test.com');
      expect(repo.currentUser, signedIn);
    });

    test('signInWithGoogle signs in and sets currentUser', () async {
      final user = await repo.signInWithGoogle();
      expect(user.email, 'google_user@example.com');
      expect(repo.currentUser, user);
    });

    test('signOut clears currentUser and emits null', () async {
      await repo.signInWithGoogle();
      expect(repo.currentUser, isNotNull);

      await repo.signOut();
      expect(repo.currentUser, isNull);
    });
  });
}
