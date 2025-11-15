import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../models/user_model.dart';
import '../datasources/auth_remote_datasource.dart';
import '../../core/utils/performance_manager.dart';
import '../../core/services/role_service.dart';

class AuthRepository implements IAuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final RoleService roleService;
  final FirebaseFirestore _firestore;

  AuthRepository({
    required this.remoteDataSource,
    required this.roleService,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<UserEntity?> signInWithEmail(String email, String password) async {
    return await PerformanceManager.measure(
      'Firebase Email Login',
          () async {
        try {
          final user = await remoteDataSource.signInWithEmail(email, password);
          if (user != null) {
            final role = await roleService.getUserRole(user.uid);
            return UserModel(
              id: user.uid,
              email: user.email ?? '',
              name: user.displayName,
              photoUrl: user.photoURL,
              role: role,
            );
          }
          return null;
        } catch (e) {
          print("Error en repository login: $e");
          rethrow;
        }
      },
    );
  }

  @override
  Future<UserEntity?> signUpWithEmail(String email, String password, String name) async {
    return await PerformanceManager.measure(
      'Firebase Email Registration',
          () async {
        try {
          final user = await remoteDataSource.signUpWithEmail(email, password);
          if (user != null) {
            await user.updateDisplayName(name);

            // ✅ GUARDAR USUARIO EN FIRESTORE CON TODOS LOS DATOS
            await _saveUserToFirestore(
              uid: user.uid,
              email: email,
              name: name,
              photoUrl: user.photoURL,
              role: 'user',
            );

            return UserModel(
              id: user.uid,
              email: user.email ?? '',
              name: user.displayName,
              photoUrl: user.photoURL,
              role: 'user',
            );
          }
          return null;
        } catch (e) {
          print("Error en repository registro: $e");
          rethrow;
        }
      },
    );
  }

  @override
  Future<UserEntity?> signInWithGoogle() async {
    return await PerformanceManager.measure(
      'Google Sign-In Authentication',
          () async {
        try {
          final user = await remoteDataSource.signInWithGoogle();
          if (user != null) {
            print('✅ Usuario de Google autenticado: ${user.uid}');

            // ✅ VERIFICAR SI EL USUARIO YA EXISTE EN FIRESTORE
            final userDoc = await _firestore.collection('users').doc(user.uid).get();

            if (!userDoc.exists) {
              // ✅ CREAR USUARIO EN FIRESTORE SI NO EXISTE
              await _saveUserToFirestore(
                uid: user.uid,
                email: user.email!,
                name: user.displayName ?? user.email!.split('@')[0],
                photoUrl: user.photoURL,
                role: 'user',
              );
            }

            final role = await roleService.getUserRole(user.uid);
            print('✅ Rol obtenido: $role');

            return UserModel(
              id: user.uid,
              email: user.email ?? '',
              name: user.displayName,
              photoUrl: user.photoURL,
              role: role,
            );
          }
          return null;
        } catch (e) {
          print("Error en repository Google Sign-In: $e");
          rethrow;
        }
      },
    );
  }

  // ✅ MÉTODO AUXILIAR PARA GUARDAR USUARIO EN FIRESTORE
  Future<void> _saveUserToFirestore({
    required String uid,
    required String email,
    required String name,
    required String? photoUrl,
    required String role,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'name': name,
        'photoUrl': photoUrl,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Usuario guardado en Firestore: $email');
    } catch (e) {
      print('❌ Error guardando usuario en Firestore: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    return await PerformanceManager.measure(
      'User Logout Process',
          () async {
        try {
          await remoteDataSource.signOut();
        } catch (e) {
          print("Error en repository signOut: $e");
          rethrow;
        }
      },
    );
  }

  @override
  Future<void> resetPassword(String email) async {
    return await PerformanceManager.measure(
      'Password Reset Request',
          () async {
        try {
          await remoteDataSource.resetPassword(email);
        } catch (e) {
          print("Error en repository resetPassword: $e");
          rethrow;
        }
      },
    );
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return remoteDataSource.authStateChanges.asyncMap((user) async {
      if (user == null) {
        return null;
      }

      try {
        final role = await roleService.getUserRole(user.uid);
        print('🔄 AuthStateChanges - Rol obtenido: $role');
        return UserModel(
          id: user.uid,
          email: user.email ?? '',
          name: user.displayName,
          photoUrl: user.photoURL,
          role: role,
        );
      } catch (e) {
        print('❌ Error en authStateChanges: $e');
        return null;
      }
    });
  }
}