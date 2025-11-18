// lib/core/services/catalog_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/business_entity.dart';
import '../../domain/entities/product_entity.dart';

class CatalogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 Obtener negocios aprobados
  Future<List<BusinessEntity>> getApprovedBusinesses() async {
    try {
      final querySnapshot = await _firestore
          .collection('business_registrations')
          .where('status', isEqualTo: 'approved')
          .get();

      return querySnapshot.docs.map((doc) {
        return BusinessEntity.fromMap({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    } catch (e) {
      print('❌ Error obteniendo negocios: $e');
      return [];
    }
  }

  // 🔹 Obtener productos de un negocio
  Future<List<ProductEntity>> getBusinessProducts(String businessId) async {
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('businessId', isEqualTo: businessId)
          .where('isAvailable', isEqualTo: true)
          .where('stock', isGreaterThan: 0)
          .orderBy('name')
          .get();

      return querySnapshot.docs.map((doc) {
        return ProductEntity.fromMap({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    } catch (e) {
      print('❌ Error obteniendo productos: $e');
      return [];
    }
  }

  // 🔹 Buscar productos por nombre/categoría
  Future<List<ProductEntity>> searchProducts(String query) async {
    try {
      // Primero obtener todos los negocios aprobados
      final businesses = await getApprovedBusinesses();
      if (businesses.isEmpty) return [];

      // Buscar en productos de todos los negocios
      List<ProductEntity> allProducts = [];
      for (final business in businesses) {
        final products = await getBusinessProducts(business.id);
        allProducts.addAll(products);
      }

      // Filtrar por búsqueda
      return allProducts.where((product) {
        final nameMatch = product.name.toLowerCase().contains(query.toLowerCase());
        final categoryMatch = product.category.toLowerCase().contains(query.toLowerCase());
        final businessMatch = businesses
            .firstWhere((b) => b.id == product.businessId)
            .name
            .toLowerCase()
            .contains(query.toLowerCase());

        return nameMatch || categoryMatch || businessMatch;
      }).toList();
    } catch (e) {
      print('❌ Error buscando productos: $e');
      return [];
    }
  }

  // 🔹 Obtener productos por categoría
  Future<List<ProductEntity>> getProductsByCategory(String category) async {
    try {
      final businesses = await getApprovedBusinesses();
      if (businesses.isEmpty) return [];

      List<ProductEntity> categoryProducts = [];
      for (final business in businesses) {
        final products = await getBusinessProducts(business.id);
        categoryProducts.addAll(
            products.where((p) => p.category.toLowerCase() == category.toLowerCase())
        );
      }

      return categoryProducts;
    } catch (e) {
      print('❌ Error obteniendo productos por categoría: $e');
      return [];
    }
  }
}