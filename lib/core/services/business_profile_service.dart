// lib/core/services/business_profile_service.dart - VERSIÓN CORREGIDA
import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 ACTUALIZAR información de la empresa EN business_registrations
  Future<void> updateBusinessProfile({
    required String businessId,
    String? name,
    String? description,
    String? category,
    String? address,
    String? phone,
    String? logoUrl,
  }) async {
    try {
      print('🔄 Actualizando perfil de empresa en business_registrations: $businessId');

      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // ✅ USAR LOS NOMBRES DE CAMPO CORRECTOS para business_registrations
      if (name != null) updates['businessName'] = name;
      if (description != null) updates['description'] = description;
      if (category != null) updates['category'] = category;
      if (address != null) updates['address'] = address;
      if (phone != null) updates['phone'] = phone;
      if (logoUrl != null) updates['logoUrl'] = logoUrl;

      // ✅ USAR business_registrations EN LUGAR DE businesses
      await _firestore.collection('business_registrations').doc(businessId).update(updates);

      print('✅ Perfil de empresa actualizado exitosamente en business_registrations');
    } catch (e) {
      print('❌ Error actualizando perfil de empresa en business_registrations: $e');
      rethrow;
    }
  }

  // 🔹 OBTENER información de la empresa DESDE business_registrations
  Future<Map<String, dynamic>?> getBusinessByUserId(String userId) async {
    try {
      print('🔄 Buscando empresa para usuario: $userId');

      final query = await _firestore
          .collection('business_registrations') // ✅ COLECCIÓN CORRECTA
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final businessData = {
          'id': query.docs.first.id,
          ...query.docs.first.data(),
        };

        print('✅ Empresa encontrada: ${businessData['businessName']}');
        return businessData;
      }

      print('⚠️ No se encontró empresa para el usuario: $userId');
      return null;
    } catch (e) {
      print('❌ Error obteniendo empresa desde business_registrations: $e');
      return null;
    }
  }

  // 🔹 OBTENER empresa por ID desde business_registrations
  Future<Map<String, dynamic>?> getBusinessById(String businessId) async {
    try {
      final doc = await _firestore.collection('business_registrations').doc(businessId).get(); // ✅ COLECCIÓN CORRECTA

      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data()!,
        };
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo empresa por ID: $e');
      return null;
    }
  }
}