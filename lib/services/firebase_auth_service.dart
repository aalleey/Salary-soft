import 'package:firebase_auth/firebase_auth.dart' as auth;

class FirebaseAuthService {
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;

  /// Exposes the current Firebase Auth user
  auth.User? get currentFirebaseUser => _firebaseAuth.currentUser;

  /// Signs in a user using email and password
  Future<auth.UserCredential> signIn(String email, String password) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Registers a user in Firebase Auth using email and password
  Future<auth.UserCredential> signUp(String email, String password) async {
    return await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Signs out of Firebase Authentication
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  /// Sends a password-reset email to the specified address
  Future<void> sendPasswordReset(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }
}
