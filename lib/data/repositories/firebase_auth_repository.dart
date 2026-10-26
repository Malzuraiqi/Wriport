import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:wriport/domain/models/app_user.dart';
import 'package:wriport/domain/repositories/auth_repository.dart';
import 'package:wriport/domain/services/auth_exception.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  AppUser _mapUser(User user) => AppUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
      );

  @override
  Stream<AppUser?> get authStateChanges =>
       _auth.userChanges().map((user) => user == null ? null : _mapUser(user));

  @override
  AppUser? get currentUser =>
      _auth.currentUser == null ? null : _mapUser(_auth.currentUser!);

  @override
  Future<AppUser> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _mapUser(cred.user!);
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<AppUser> signUpWithEmail(String email, String password, String name) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user?.updateDisplayName(name);
      await cred.user?.reload();
      return _mapUser(_auth.currentUser!);
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      await _googleSignIn.initialize(
        serverClientId: '493789720301-4v0j6tjr28mjgden28a759fcu8s8tdiq.apps.googleusercontent.com'
      );
      
      final googleUser = await _googleSignIn.authenticate();
      
      final googleAuth = googleUser.authentication;

      final List<String> scopes = ['email', 'profile'];
      final clientAuth = await googleUser.authorizationClient.authorizeScopes(scopes);

      final credential = GoogleAuthProvider.credential(
        accessToken: clientAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final cred = await _auth.signInWithCredential(credential);
      return _mapUser(cred.user!);
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      throw AuthException('Google sign-in failed or was cancelled: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Google may not be initialized (email users); Firebase sign-out must still run.
    }
    await _auth.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  AuthException _mapAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return AuthException('No account found with that email.');
      case 'wrong-password':
        return AuthException('Incorrect password. Please try again.');
      case 'email-already-in-use':
        return AuthException('An account with that email already exists.');
      case 'weak-password':
        return AuthException('Password is too weak. Use at least 6 characters.');
      case 'invalid-email':
        return AuthException('Please enter a valid email address.');
      case 'network-request-failed':
        return AuthException('Check your internet connection and try again.');
      case 'too-many-requests':
        return AuthException('Too many attempts. Please try again later.');
      case 'invalid-credential':
        return AuthException('Incorrect email or password. Please try again.');
      default:
        return AuthException('Something went wrong. Please try again.');
    }
  }
}