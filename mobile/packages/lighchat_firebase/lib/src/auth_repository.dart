import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthRepository {
  AuthRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Сначала отдаём [currentUser], затем [authStateChanges].
  /// Иначе [StreamProvider] в приложении может долго оставаться в loading: первое событие Firebase иногда приходит с заметной задержкой.
  Stream<User?> watchUser() async* {
    yield _auth.currentUser;
    yield* _auth.authStateChanges();
  }

  User? get currentUser => _auth.currentUser;

  Future<void> signInAnonymously() async {
    await _auth.signInAnonymously();
  }

  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> registerWithEmailPassword({
    required String email,
    required String password,
  }) async {
    await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign in with Apple — native flow через `sign_in_with_apple` package.
  ///
  /// На iOS/macOS использует SDK Apple напрямую, обходя
  /// `_auth.signInWithProvider`, который не реализован в `firebase_auth_macos`.
  /// Полученный identityToken конвертируется в Firebase `OAuthCredential`
  /// и подаётся в `_auth.signInWithCredential`.
  ///
  /// На Android / web fallback к OAuth provider flow — там работает.
  ///
  /// Требования:
  ///   - Apple Sign-In Service ID в Firebase Console → Authentication.
  ///   - Capability "Sign In with Apple" в Xcode (iOS/macOS).
  ///   - На macOS Debug с paid Apple Developer Program — keychain entitlement
  ///     для persistence; на free ID `signInWithCredential` упрётся в
  ///     keychain ошибку, но самим Apple Sign-In dialog откроется и
  ///     credential будет получен (можно использовать для верификации UI).
  Future<void> signInWithApple() async {
    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        if (!kIsWeb &&
            (Platform.isIOS || Platform.isMacOS) &&
            await SignInWithApple.isAvailable()) {
          // Native Apple Sign-In: получаем identityToken + nonce.
          final rawNonce = _generateNonce();
          final nonce = _sha256(rawNonce);
          final credential = await SignInWithApple.getAppleIDCredential(
            scopes: const [
              AppleIDAuthorizationScopes.email,
              AppleIDAuthorizationScopes.fullName,
            ],
            nonce: nonce,
          );
          final identityToken = credential.identityToken;
          if (identityToken == null || identityToken.isEmpty) {
            throw FirebaseAuthException(
              code: 'apple-no-identity-token',
              message: 'Apple Sign-In didn’t return identityToken',
            );
          }
          final oauthCredential = OAuthProvider('apple.com').credential(
            idToken: identityToken,
            rawNonce: rawNonce,
          );
          await _auth.signInWithCredential(oauthCredential);
          return;
        }
        // Android / web / fallback — OAuthProvider flow.
        final provider = OAuthProvider('apple.com');
        provider.addScope('email');
        provider.addScope('name');
        await _auth.signInWithProvider(provider);
        return;
      } on FirebaseAuthException catch (e) {
        final raw = e.code;
        final code = raw.startsWith('auth/') ? raw : 'auth/$raw';
        final isNetwork = code == 'auth/network-request-failed';
        if (!isNetwork || attempt == maxAttempts) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 250 * attempt));
      }
    }
  }

  static String _generateNonce([int length = 32]) {
    const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = math.Random.secure();
    return List.generate(
      length,
      (_) => charset[rnd.nextInt(charset.length)],
    ).join();
  }

  static String _sha256(String input) =>
      sha256.convert(utf8.encode(input)).toString();

  Future<void> signInWithGoogle() async {
    // Matches web parity (Google Auth provider) without pulling the iOS GoogleSignIn pod,
    // which currently conflicts with Firebase iOS SDK's GTMSessionFetcher version.
    //
    // On iOS/macOS this uses native OAuth flow via FirebaseAuth.
    debugPrint('[AUTH] Google Sign-In: Starting...');

    final provider = GoogleAuthProvider();
    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        debugPrint('[AUTH] Google Sign-In: Attempt $attempt/$maxAttempts - calling signInWithProvider');
        await _auth.signInWithProvider(provider);
        debugPrint('[AUTH] Google Sign-In: SUCCESS - User signed in');
        return;
      } on FirebaseAuthException catch (e) {
        final raw = e.code;
        final code = raw.startsWith('auth/') ? raw : 'auth/$raw';
        final isNetwork = code == 'auth/network-request-failed';

        debugPrint('[AUTH] Google Sign-In: ERROR (attempt $attempt/$maxAttempts)');
        debugPrint('[AUTH]   Code: $code');
        debugPrint('[AUTH]   Message: ${e.message}');
        debugPrint('[AUTH]   PluginCode: ${e.plugin}');
        debugPrint('[AUTH]   IsNetworkError: $isNetwork');

        if (!isNetwork || attempt == maxAttempts) {
          debugPrint('[AUTH] Google Sign-In: Throwing error (not retryable or max attempts reached)');
          rethrow;
        }

        final delay = Duration(milliseconds: 250 * attempt);
        debugPrint('[AUTH] Google Sign-In: Retrying after ${delay.inMilliseconds}ms');
        await Future<void>.delayed(delay);
      } catch (e) {
        debugPrint('[AUTH] Google Sign-In: UNEXPECTED ERROR: $e');
        debugPrint('[AUTH]   Type: ${e.runtimeType}');
        rethrow;
      }
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// После callable `signInWithTelegram` (WebView-мост или другой клиент).
  Future<void> signInWithCustomToken(String customToken) async {
    try {
      debugPrint('[AUTH] Custom Token Sign-In: Starting...');
      debugPrint('[AUTH]   Token length: ${customToken.length}');

      await _auth.signInWithCustomToken(customToken.trim());

      debugPrint('[AUTH] Custom Token Sign-In: SUCCESS');
    } on FirebaseAuthException catch (e) {
      debugPrint('[AUTH] Custom Token Sign-In: FIREBASE ERROR');
      debugPrint('[AUTH]   Code: ${e.code}');
      debugPrint('[AUTH]   Message: ${e.message}');
      debugPrint('[AUTH]   Plugin: ${e.plugin}');
      rethrow;
    } catch (e) {
      debugPrint('[AUTH] Custom Token Sign-In: UNEXPECTED ERROR');
      debugPrint('[AUTH]   Error: $e');
      debugPrint('[AUTH]   Type: ${e.runtimeType}');
      rethrow;
    }
  }
}

