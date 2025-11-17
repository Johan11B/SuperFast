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
          // ✅ AGREGAR: Campos de empresa si existen
          businessName: data['businessName'],
          businessEmail: data['businessEmail'],
          businessCategory: data['businessCategory'],
          businessAddress: data['businessAddress'],
          businessPhone: data['businessPhone'],
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

  // 🔹 Eliminar usuario - ✅ CORREGIDO
  Future<void> deleteUser(String userId) async {
    try {
      // ✅ PRIMERO: Verificar si el usuario tiene negocios
      final businessQuery = await _firestore
          .collection('business_registrations')
          .where('userId', isEqualTo: userId)
          .get();

      // ✅ SEGUNDO: Eliminar todos los negocios asociados al usuario
      for (final doc in businessQuery.docs) {
        await doc.reference.delete();
        print('✅ Negocio eliminado: ${doc.id}');
      }

      // ✅ TERCERO: Eliminar el usuario
      await _firestore.collection('users').doc(userId).delete();

      print('✅ Usuario y sus negocios eliminados: $userId');
    } catch (e) {
      print('❌ Error eliminando usuario: $e');
      rethrow;
    }
  }

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
          // ✅ AGREGAR: Campos de empresa si existen
          businessName: data['businessName'],
          businessEmail: data['businessEmail'],
          businessCategory: data['businessCategory'],
          businessAddress: data['businessAddress'],
          businessPhone: data['businessPhone'],
        );
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo usuario: $e');
      return null;
    }
  }

  Future<List<UserEntity>> searchUsers(String query) async {
    try {
      final allUsers = await getAllUsers();
      return allUsers.where((user) {
        final emailMatch = user.email.toLowerCase().contains(query.toLowerCase());
        final nameMatch = user.name?.toLowerCase().contains(query.toLowerCase()) ?? false;
        final businessNameMatch = user.businessName?.toLowerCase().contains(query.toLowerCase()) ?? false;
        return emailMatch || nameMatch || businessNameMatch;
      }).toList();
    } catch (e) {
      print('❌ Error buscando usuarios: $e');
      return [];
    }
  }

  // ✅ NUEVO MÉTODO: Obtener estadísticas de usuarios
  Future<Map<String, int>> getUserStatistics() async {
    try {
      final allUsers = await getAllUsers();
      return {
        'total': allUsers.length,
        'admin': allUsers.where((user) => user.role == 'admin').length,
        'business': allUsers.where((user) => user.role == 'business').length,
        'user': allUsers.where((user) => user.role == 'user').length,
      };
    } catch (e) {
      print('❌ Error obteniendo estadísticas: $e');
      return {'total': 0, 'admin': 0, 'business': 0, 'user': 0};
    }
  }
}