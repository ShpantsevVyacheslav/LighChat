import 'package:firebase_auth/firebase_auth.dart';

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

  Future<void> signInWithGoogle() async {
    // Matches web parity (Google Auth provider) without pulling the iOS GoogleSignIn pod,
    // which currently conflicts with Firebase iOS SDK's GTMSessionFetcher version.
    //
    // On iOS/macOS this uses native OAuth flow via FirebaseAuth.
    final provider = GoogleAuthProvider();
    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
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

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

