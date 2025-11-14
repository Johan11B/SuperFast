// lib/core/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<UserEntity>> getAllUsers() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return UserEntity(
          id: doc.id,
          email: data['email'] ?? '',
          name: data['name'],
          photoUrl: data['photoUrl'],
          role: data['role'] ?? 'user',
        );
      }).toList();
    } catch (e) {
      print('❌ Error obteniendo usuarios: $e');
      return [];
    }
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      if (!['admin', 'business', 'user'].contains(newRole)) {
        throw ArgumentError('Rol inválido: $newRole');
      }

      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Rol del usuario $userId cambiado a: $newRole');
    } catch (e) {
      print('❌ Error actualizando rol: $e');
      rethrow;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
      print('✅ Usuario eliminado: $userId');
    } catch (e) {
      print('❌ Error eliminando usuario: $e');
      rethrow;
    }
  }

  // Obtener usuario por ID
  Future<UserEntity?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        return UserEntity(
          id: doc.id,
          email: data['email'] ?? '',
          name: data['name'],
          photoUrl: data['photoUrl'],
          role: data['role'] ?? 'user',
        );
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo usuario: $e');
      return null;
    }
  }

  // Buscar usuarios por email o nombre
  Future<List<UserEntity>> searchUsers(String query) async {
    try {
      // Esta es una implementación básica, en una app real necesitarías índices
      final allUsers = await getAllUsers();
      return allUsers.where((user) {
        final emailMatch = user.email.toLowerCase().contains(query.toLowerCase());
        final nameMatch = user.name?.toLowerCase().contains(query.toLowerCase()) ?? false;
        return emailMatch || nameMatch;
      }).toList();
    } catch (e) {
      print('❌ Error buscando usuarios: $e');
      return [];
    }
  }
}