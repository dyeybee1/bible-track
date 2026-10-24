import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

enum SignInResult { success, cancelled, failed }

/// Google login through Firebase Authentication.
///
/// On **web** (`kIsWeb == true`): uses `signInWithPopup` (the only approach
/// that works in a browser — GoogleSignIn native SDK is unavailable).
/// On **mobile**: uses the GoogleSignIn 7.x `initialize + authenticate` flow.
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Must be called once at startup. No-op on web.
  Future<void> init() async {
    if (kIsWeb) return;
    await GoogleSignIn.instance.initialize();
  }

  Stream<User?> get authChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<SignInResult> signInWithGoogle() async {
    if (kIsWeb) return _signInWithPopup();
    return _signInWithGoogleSignIn();
  }

  // ── Web ──────────────────────────────────────────────────────────────────────

  Future<SignInResult> _signInWithPopup() async {
    try {
      final result =
          await _auth.signInWithPopup(GoogleAuthProvider());
      if (result.credential == null) return SignInResult.failed;
      return SignInResult.success;
    } on FirebaseAuthException catch (e) {
      // popup-closed-by-user or cancelled-popup-request
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        return SignInResult.cancelled;
      }
      return SignInResult.failed;
    } catch (_) {
      return SignInResult.failed;
    }
  }

  // ── Mobile ───────────────────────────────────────────────────────────────────

  Future<SignInResult> _signInWithGoogleSignIn() async {
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) return SignInResult.failed;
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await _auth.signInWithCredential(credential);
      return SignInResult.success;
    } on GoogleSignInException catch (e) {
      return e.code == GoogleSignInExceptionCode.canceled
          ? SignInResult.cancelled
          : SignInResult.failed;
    } on FirebaseAuthException {
      return SignInResult.failed;
    } catch (_) {
      return SignInResult.failed;
    }
  }

  /// Shows the account chooser again so another Google account can be picked.
  Future<SignInResult> switchAccount() async {
    if (!kIsWeb) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    return signInWithGoogle();
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    await _auth.signOut();
  }
}
