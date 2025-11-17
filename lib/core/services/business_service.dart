// lib/core/services/business_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/business_entity.dart';

class BusinessService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Crear un nuevo negocio
  Future<void> createBusiness({
    required String businessId,
    required String name,
    required String email,
    required String ownerId,
    required String category,
    required String address,
    String? phone,
    String? description,
    String? imageUrl,
  }) async {
    try {
      print('🏪 Creando negocio: $name');

      await _firestore.collection('businesses').doc(businessId).set({
        'name': name,
        'email': email,
        'ownerId': ownerId,
        'category': category,
        'address': address,
        'phone': phone,
        'description': description,
        'imageUrl': imageUrl,
        'status': 'pending', // Por defecto pendiente
        'rating': 0.0,
        'reviewCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Negocio creado exitosamente: $businessId');
    } catch (e) {
      print('❌ Error creando negocio: $e');
      rethrow;
    }
  }

  // Obtener todos los negocios
  Future<List<BusinessEntity>> getAllBusinesses() async {
    try {
      final querySnapshot = await _firestore.collection('businesses').get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return BusinessEntity(
          id: doc.id,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          ownerId: data['ownerId'] ?? '',
          status: data['status'] ?? 'pending',
          category: data['category'] ?? 'General',
          address: data['address'] ?? '',
          phone: data['phone'],
          description: data['description'],
          rating: (data['rating'] ?? 0.0).toDouble(),
          reviewCount: (data['reviewCount'] ?? 0).toInt(),
          createdAt: data['createdAt']?.toDate(),
          updatedAt: data['updatedAt']?.toDate(),
        );
      }).toList();
    } catch (e) {
      print('❌ Error obteniendo negocios: $e');
      return [];
    }
  }

  // Obtener negocios por estado
  Future<List<BusinessEntity>> getBusinessesByStatus(String status) async {
    try {
      final querySnapshot = await _firestore
          .collection('businesses')
          .where('status', isEqualTo: status)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return BusinessEntity(
          id: doc.id,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          ownerId: data['ownerId'] ?? '',
          status: data['status'] ?? 'pending',
          category: data['category'] ?? 'General',
          address: data['address'] ?? '',
          phone: data['phone'],
          description: data['description'],
          rating: (data['rating'] ?? 0.0).toDouble(),
          reviewCount: (data['reviewCount'] ?? 0).toInt(),
          createdAt: data['createdAt']?.toDate(),
          updatedAt: data['updatedAt']?.toDate(),
        );
      }).toList();
    } catch (e) {
      print('❌ Error obteniendo negocios por estado: $e');
      return [];
    }
  }

  // Actualizar estado de un negocio
  Future<void> updateBusinessStatus(String businessId, String status) async {
    try {
      if (!['pending', 'approved', 'rejected', 'suspended'].contains(status)) {
        throw ArgumentError('Estado inválido: $status');
      }

      await _firestore.collection('businesses').doc(businessId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Estado del negocio $businessId actualizado a: $status');
    } catch (e) {
      print('❌ Error actualizando estado del negocio: $e');
      rethrow;
    }
  }

  // Eliminar negocio
  Future<void> deleteBusiness(String businessId) async {
    try {
      await _firestore.collection('businesses').doc(businessId).delete();
      print('✅ Negocio eliminado: $businessId');
    } catch (e) {
      print('❌ Error eliminando negocio: $e');
      rethrow;
    }
  }
}