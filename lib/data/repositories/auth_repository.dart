import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../models/user_model.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepository implements IAuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepository({required this.remoteDataSource});

  @override
  Future<UserEntity?> signInWithEmail(String email, String password) async {
    try {
      final user = await remoteDataSource.signInWithEmail(email, password);
      return user != null ? UserModel.fromFirebaseUser(user) : null;
    } catch (e) {
      print("Error en repository login: $e");
      rethrow;
    }
  }

  @override
  Future<UserEntity?> signUpWithEmail(String email, String password, String name) async {
    try {
      final user = await remoteDataSource.signUpWithEmail(email, password);
      if (user != null) {
        // Actualizar display name si es necesario
        await user.updateDisplayName(name);
        return UserModel.fromFirebaseUser(user);
      }
      return null;
    } catch (e) {
      print("Error en repository registro: $e");
      rethrow;
    }
  }

  @override
  Future<UserEntity?> signInWithGoogle() async {
    try {
      final user = await remoteDataSource.signInWithGoogle();
      return user != null ? UserModel.fromFirebaseUser(user) : null;
    } catch (e) {
      print("Error en repository Google Sign-In: $e");
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await remoteDataSource.signOut();
    } catch (e) {
      print("Error en repository signOut: $e");
      rethrow;
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await remoteDataSource.resetPassword(email);
    } catch (e) {
      print("Error en repository resetPassword: $e");
      rethrow;
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return remoteDataSource.authStateChanges.map((user) {
      return user != null ? UserModel.fromFirebaseUser(user) : null;
    });
  }
}