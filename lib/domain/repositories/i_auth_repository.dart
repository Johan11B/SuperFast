import '../entities/user_entity.dart';

abstract class IAuthRepository {
  Future<UserEntity?> signInWithEmail(String email, String password);
  Future<UserEntity?> signUpWithEmail(String email, String password, String name);
  Future<UserEntity?> signInWithGoogle();
  Future<void> signOut();
  Stream<UserEntity?> get authStateChanges;
  Future<void> resetPassword(String email);
}