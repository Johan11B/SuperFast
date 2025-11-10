import 'package:cloud_firestore/cloud_firestore.dart';

class RoleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> getUserRole(String userId) async {
    try {
      print('🔍 Buscando rol para usuario: $userId');
      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        final role = doc.data()?['role'];
        print('✅ Documento encontrado. Rol: $role');
        return role ?? 'user';
      }

      print('⚠️  No se encontró documento, creando con rol "user"');
      await _firestore.collection('users').doc(userId).set({
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return 'user';
    } catch (e) {
      print('❌ Error obteniendo rol: $e');
      return 'user';
    }
  }

  Future<void> setUserRole(String userId, String role) async {
    try {
      print('💾 Intentando guardar rol: $role para usuario: $userId');

      if (!['admin', 'business', 'user'].contains(role)) {
        throw ArgumentError('Rol inválido: $role');
      }

      await _firestore.collection('users').doc(userId).set({
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ Rol guardado exitosamente en Firestore');

      // Verificar que se guardó correctamente
      final doc = await _firestore.collection('users').doc(userId).get();
      final savedRole = doc.data()?['role'];
      print('✅ Rol verificado después de guardar: $savedRole');

    } catch (e) {
      print('❌ Error guardando rol: $e');
      rethrow;
    }
  }

  bool hasPermission(String userRole, List<String> allowedRoles) {
    return allowedRoles.contains(userRole);
  }
}