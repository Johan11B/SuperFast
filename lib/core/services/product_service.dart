// lib/core/services/product_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/product_entity.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 Obtener todos los productos de una empresa
  Future<List<ProductEntity>> getBusinessProducts(String businessId) async {
    try {
      print('🔄 Obteniendo productos para empresa: $businessId');

      final querySnapshot = await _firestore
          .collection('products')
          .where('businessId', isEqualTo: businessId)
          .orderBy('createdAt', descending: true)
          .get();

      final products = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return ProductEntity.fromMap({
          'id': doc.id,
          ...data,
        });
      }).toList();

      print('✅ ${products.length} productos cargados para empresa: $businessId');
      return products;
    } catch (e) {
      print('❌ Error obteniendo productos: $e');
      throw Exception('Error al cargar productos: $e');
    }
  }

  // 🔹 Agregar nuevo producto
  Future<void> addProduct(ProductEntity product) async {
    try {
      print('🔄 Agregando producto: ${product.name}');

      // Validaciones básicas
      if (product.name.isEmpty) {
        throw Exception('El nombre del producto es requerido');
      }
      if (product.price <= 0) {
        throw Exception('El precio debe ser mayor a 0');
      }

      final productData = product.toMap();

      await _firestore.collection('products').add({
        ...productData,
        'description': product.description.isNotEmpty ? product.description : 'Sin descripción',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Producto agregado exitosamente: ${product.name}');
    } catch (e) {
      print('❌ Error agregando producto: $e');
      throw Exception('Error al agregar producto: $e');
    }
  }

  // 🔹 Actualizar producto existente
  Future<void> updateProduct(ProductEntity product) async {
    try {
      print('🔄 Actualizando producto: ${product.name} (${product.id})');

      if (product.id.isEmpty) {
        throw Exception('ID de producto inválido');
      }

      final productData = product.toMap();

      await _firestore.collection('products').doc(product.id).update({
        ...productData,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Producto actualizado exitosamente: ${product.name}');
    } catch (e) {
      print('❌ Error actualizando producto: $e');
      throw Exception('Error al actualizar producto: $e');
    }
  }

  // 🔹 Eliminar producto
  Future<void> deleteProduct(String productId) async {
    try {
      print('🔄 Eliminando producto: $productId');

      if (productId.isEmpty) {
        throw Exception('ID de producto inválido');
      }

      await _firestore.collection('products').doc(productId).delete();

      print('✅ Producto eliminado exitosamente: $productId');
    } catch (e) {
      print('❌ Error eliminando producto: $e');
      throw Exception('Error al eliminar producto: $e');
    }
  }

  // 🔹 Obtener producto por ID
  Future<ProductEntity?> getProductById(String productId) async {
    try {
      print('🔄 Obteniendo producto: $productId');

      final doc = await _firestore.collection('products').doc(productId).get();

      if (doc.exists) {
        final product = ProductEntity.fromMap({
          'id': doc.id,
          ...doc.data()!,
        });
        print('✅ Producto encontrado: ${product.name}');
        return product;
      }

      print('⚠️ Producto no encontrado: $productId');
      return null;
    } catch (e) {
      print('❌ Error obteniendo producto: $e');
      throw Exception('Error al obtener producto: $e');
    }
  }

  // 🔹 Buscar productos por nombre o categoría
  Future<List<ProductEntity>> searchProducts({
    required String businessId,
    required String query,
  }) async {
    try {
      print('🔍 Buscando productos: "$query" en empresa: $businessId');

      final allProducts = await getBusinessProducts(businessId);

      final filteredProducts = allProducts.where((product) {
        final nameMatch = product.name.toLowerCase().contains(query.toLowerCase());
        final categoryMatch = product.category.toLowerCase().contains(query.toLowerCase());
        final descriptionMatch = product.description.toLowerCase().contains(query.toLowerCase());

        return nameMatch || categoryMatch || descriptionMatch;
      }).toList();

      print('✅ ${filteredProducts.length} productos encontrados para búsqueda: "$query"');
      return filteredProducts;
    } catch (e) {
      print('❌ Error buscando productos: $e');
      throw Exception('Error al buscar productos: $e');
    }
  }

  // 🔹 Obtener productos por categoría
  Future<List<ProductEntity>> getProductsByCategory({
    required String businessId,
    required String category,
  }) async {
    try {
      print('🔄 Obteniendo productos por categoría: $category');

      final querySnapshot = await _firestore
          .collection('products')
          .where('businessId', isEqualTo: businessId)
          .where('category', isEqualTo: category)
          .orderBy('name')
          .get();

      final products = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return ProductEntity.fromMap({
          'id': doc.id,
          ...data,
        });
      }).toList();

      print('✅ ${products.length} productos encontrados en categoría: $category');
      return products;
    } catch (e) {
      print('❌ Error obteniendo productos por categoría: $e');
      throw Exception('Error al obtener productos por categoría: $e');
    }
  }

  // 🔹 Actualizar stock de producto
  Future<void> updateProductStock(String productId, int newStock) async {
    try {
      print('🔄 Actualizando stock del producto: $productId -> $newStock');

      await _firestore.collection('products').doc(productId).update({
        'stock': newStock,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Stock actualizado exitosamente');
    } catch (e) {
      print('❌ Error actualizando stock: $e');
      throw Exception('Error al actualizar stock: $e');
    }
  }

  // 🔹 Cambiar disponibilidad de producto
  Future<void> toggleProductAvailability(String productId, bool isAvailable) async {
    try {
      print('🔄 Cambiando disponibilidad del producto: $productId -> $isAvailable');

      await _firestore.collection('products').doc(productId).update({
        'isAvailable': isAvailable,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Disponibilidad actualizada exitosamente');
    } catch (e) {
      print('❌ Error cambiando disponibilidad: $e');
      throw Exception('Error al cambiar disponibilidad: $e');
    }
  }

  // 🔹 Obtener categorías únicas de una empresa
  Future<List<String>> getBusinessCategories(String businessId) async {
    try {
      print('🔄 Obteniendo categorías para empresa: $businessId');

      final products = await getBusinessProducts(businessId);
      final categories = products.map((product) => product.category).toSet().toList();
      categories.sort();

      print('✅ ${categories.length} categorías encontradas');
      return categories;
    } catch (e) {
      print('❌ Error obteniendo categorías: $e');
      throw Exception('Error al obtener categorías: $e');
    }
  }
}