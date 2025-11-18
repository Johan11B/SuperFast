// lib/core/services/business_profile_service.dart
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
      if (logoUrl != null) {
        print('🖼️ Logo URL actualizada: $logoUrl');
      }
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
          .collection('business_registrations')
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
      final doc = await _firestore.collection('business_registrations').doc(businessId).get();

      if (doc.exists) {
        final data = {
          'id': doc.id,
          ...doc.data()!,
        };
        print('✅ Empresa obtenida por ID: ${data['businessName']}');
        return data;
      }
      print('⚠️ No se encontró empresa con ID: $businessId');
      return null;
    } catch (e) {
      print('❌ Error obteniendo empresa por ID: $e');
      return null;
    }
  }

  // 🔹 CREAR NUEVA EMPRESA si no existe
  Future<void> createBusinessIfNotExists({
    required String businessId,
    required String userId,
    required String userEmail,
    required String businessName,
    required String category,
    required String address,
    required String phone,
    String? description,
    String? logoUrl,
  }) async {
    try {
      final docRef = _firestore.collection('business_registrations').doc(businessId);
      final doc = await docRef.get();

      if (!doc.exists) {
        print('🆕 Creando nueva empresa: $businessName');

        await docRef.set({
          'id': businessId,
          'userId': userId,
          'userEmail': userEmail,
          'businessName': businessName,
          'category': category,
          'address': address,
          'phone': phone,
          'description': description,
          'logoUrl': logoUrl,
          'status': 'approved',
          'rating': 0.0,
          'reviewCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'approvedAt': FieldValue.serverTimestamp(),
        });

        print('✅ Nueva empresa creada: $businessName');
      } else {
        print('✅ Empresa ya existe: $businessName');
      }
    } catch (e) {
      print('❌ Error creando empresa: $e');
      rethrow;
    }
  }

  // 🔹 OBTENER URL del logo de la empresa
  Future<String?> getBusinessLogoUrl(String businessId) async {
    try {
      final doc = await _firestore.collection('business_registrations').doc(businessId).get();

      if (doc.exists) {
        final data = doc.data()!;
        final logoUrl = data['logoUrl'] as String?;
        print('🖼️ Logo URL obtenida: $logoUrl');
        return logoUrl;
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo logo URL: $e');
      return null;
    }
  }
}