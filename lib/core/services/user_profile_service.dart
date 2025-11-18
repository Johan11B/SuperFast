// lib/core/services/user_profile_service.dart - VERSIÓN CORREGIDA
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔹 ACTUALIZAR perfil de usuario EN FIRESTORE
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? email,
    String? photoUrl,
  }) async {
    try {
      print('🔄 Actualizando perfil de usuario en Firestore: $userId');

      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updates['name'] = name;
      if (email != null) updates['email'] = email;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      // ✅ USAR FIRESTORE - NO Supabase tables
      await _firestore.collection('users').doc(userId).update(updates);

      // Si se cambió el email, actualizar en Firebase Auth también
      if (email != null && _auth.currentUser != null) {
        await _auth.currentUser!.updateEmail(email);
        print('✅ Email actualizado en Firebase Auth');
      }

      print('✅ Perfil de usuario actualizado exitosamente en Firestore');
    } catch (e) {
      print('❌ Error actualizando perfil de usuario: $e');
      rethrow;
    }
  }

  // 🔹 CAMBIAR CONTRASEÑA (solo Firebase Auth)
  Future<void> changePassword(String newPassword) async {
    try {
      if (_auth.currentUser != null) {
        await _auth.currentUser!.updatePassword(newPassword);
        print('✅ Contraseña cambiada exitosamente');
      } else {
        throw Exception('Usuario no autenticado');
      }
    } catch (e) {
      print('❌ Error cambiando contraseña: $e');
      rethrow;
    }
  }

  // 🔹 OBTENER datos de usuario desde Firestore
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data()!,
        };
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo datos de usuario: $e');
      return null;
    }
  }
}