// lib/core/services/business_registration_service.dart - VERSIÓN COMPLETA
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BusinessRegistrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Método para verificar si el usuario ya tiene un negocio
  Future<bool> userHasBusiness(String userId) async {
    try {
      final query = await _firestore
          .collection('business_registrations')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Error verificando negocio del usuario: $e');
    }
  }

  // Método para obtener el estado del negocio del usuario
  Future<String?> getUserBusinessStatus(String userId) async {
    try {
      final query = await _firestore
          .collection('business_registrations')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first['status'] as String?;
      }
      return null;
    } catch (e) {
      throw Exception('Error obteniendo estado del negocio: $e');
    }
  }

  // Método para registrar un nuevo negocio
  Future<void> registerBusiness({
    required String userId,
    required String userEmail,
    required String businessName,
    required String category,
    required String address,
    required String phone,
    String? description,
  }) async {
    try {
      // Verificar si el usuario ya tiene un negocio pendiente o aprobado
      final existingBusiness = await userHasBusiness(userId);
      if (existingBusiness) {
        throw Exception('Ya tienes una solicitud de negocio en proceso');
      }

      // Crear el documento de registro de negocio
      await _firestore.collection('business_registrations').add({
        'userId': userId,
        'userEmail': userEmail,
        'businessName': businessName,
        'category': category,
        'address': address,
        'phone': phone,
        'description': description,
        'status': 'pending', // pending, approved, rejected
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      throw Exception('Error registrando negocio: $e');
    }
  }

  // Método para obtener registros pendientes (para admin)
  Future<List<Map<String, dynamic>>> getPendingRegistrations() async {
    try {
      final query = await _firestore
          .collection('business_registrations')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();
    } catch (e) {
      throw Exception('Error obteniendo registros pendientes: $e');
    }
  }

  // MÉTODO NUEVO: Obtener negocios aprobados
  Future<List<Map<String, dynamic>>> getApprovedBusinesses() async {
    try {
      final query = await _firestore
          .collection('business_registrations')
          .where('status', isEqualTo: 'approved')
          .orderBy('approvedAt', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'approvedAt': (data['approvedAt'] as Timestamp?)?.toDate(),
        };
      }).toList();
    } catch (e) {
      throw Exception('Error obteniendo negocios aprobados: $e');
    }
  }

  // Método para aprobar un negocio
  Future<void> approveBusinessRegistration(String registrationId) async {
    try {
      final docRef = _firestore.collection('business_registrations').doc(registrationId);
      final doc = await docRef.get();

      if (!doc.exists) {
        throw Exception('Registro no encontrado');
      }

      final data = doc.data()!;
      final userId = data['userId'] as String;

      // Actualizar el estado a aprobado
      await docRef.update({
        'status': 'approved',
        'updatedAt': FieldValue.serverTimestamp(),
        'approvedAt': FieldValue.serverTimestamp(),
      });

      // Actualizar el rol del usuario a 'business'
      await _updateUserRole(userId, 'business');

    } catch (e) {
      throw Exception('Error aprobando negocio: $e');
    }
  }

  // Método para rechazar un negocio
  Future<void> rejectBusinessRegistration(String registrationId) async {
    try {
      await _firestore.collection('business_registrations').doc(registrationId).update({
        'status': 'rejected',
        'updatedAt': FieldValue.serverTimestamp(),
        'rejectedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error rechazando negocio: $e');
    }
  }

  // MÉTODO NUEVO: Suspender negocio
  Future<void> suspendBusiness(String businessId) async {
    try {
      await _firestore.collection('business_registrations').doc(businessId).update({
        'status': 'suspended',
        'updatedAt': FieldValue.serverTimestamp(),
        'suspendedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error suspendiendo negocio: $e');
    }
  }

  // MÉTODO NUEVO: Activar negocio
  Future<void> activateBusiness(String businessId) async {
    try {
      await _firestore.collection('business_registrations').doc(businessId).update({
        'status': 'approved',
        'updatedAt': FieldValue.serverTimestamp(),
        'activatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error activando negocio: $e');
    }
  }

  // MÉTODO NUEVO: Eliminar negocio
  Future<void> deleteBusiness(String businessId) async {
    try {
      await _firestore.collection('business_registrations').doc(businessId).delete();
    } catch (e) {
      throw Exception('Error eliminando negocio: $e');
    }
  }

  // Método para actualizar el rol del usuario
  Future<void> _updateUserRole(String userId, String newRole) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error actualizando rol del usuario: $e');
    }
  }

  // Método para obtener el estado de registro del usuario
  Future<Map<String, dynamic>?> getUserRegistrationStatus(String userId) async {
    try {
      final query = await _firestore
          .collection('business_registrations')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }
      return null;
    } catch (e) {
      throw Exception('Error obteniendo estado de registro: $e');
    }
  }

  // MÉTODO NUEVO: Obtener todos los negocios (para admin)
  Future<List<Map<String, dynamic>>> getAllBusinesses() async {
    try {
      final query = await _firestore
          .collection('business_registrations')
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();
    } catch (e) {
      throw Exception('Error obteniendo todos los negocios: $e');
    }
  }
}