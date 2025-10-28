import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    signInOption: SignInOption.standard,
  );

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password
      );
      return userCredential.user;
    } catch (e) {
      print("Error en datasource login: $e");
      return null;
    }
  }

  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password
      );
      return userCredential.user;
    } catch (e) {
      print("Error en datasource registro: $e");
      return null;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      // Cerrar sesión previa forzosamente
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
        await Future.delayed(const Duration(milliseconds: 500));
      }

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print("Usuario canceló el inicio de sesión");
        return null;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print("Error Google Sign-In en datasource: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
      print("Sesión cerrada exitosamente desde datasource");
    } catch (e) {
      print("Error al cerrar sesión en datasource: $e");
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print("Error al resetear password: $e");
      rethrow;
    }
  }

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
}