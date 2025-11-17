// lib/core/services/product_service.dart - ACTUALIZADO
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../../domain/entities/product_entity.dart';
import 'supabase_storage_service.dart'; // Cambiar por Supabase

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseStorageService _storageService; // Cambiar a Supabase

  ProductService({required SupabaseStorageService storageService})
      : _storageService = storageService;

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
        final product = ProductEntity.fromMap({
          'id': doc.id,
          ...data,
        });

        print('📦 Producto cargado: ${product.name} (ID: ${product.id}, Imágenes: ${product.imageUrls.length})');

        return product;
      }).toList();

      print('✅ ${products.length} productos cargados para empresa: $businessId');
      return products;
    } catch (e) {
      print('❌ Error obteniendo productos: $e');
      throw Exception('Error al cargar productos: $e');
    }
  }

  // 🔹 Agregar nuevo producto CON IMÁGENES (Supabase)
  Future<void> addProduct(ProductEntity product, {List<File>? imageFiles}) async {
    try {
      print('🔄 Agregando producto: ${product.name}');

      // Validaciones básicas
      if (product.name.isEmpty) {
        throw Exception('El nombre del producto es requerido');
      }
      if (product.price <= 0) {
        throw Exception('El precio debe ser mayor a 0');
      }
      if (product.businessId.isEmpty) {
        throw Exception('BusinessId es requerido');
      }

      final productData = product.toMap();

      // Remover campos que serán manejados por Firestore
      productData.remove('createdAt');
      productData.remove('updatedAt');
      productData.remove('id');

      print('📝 Datos a agregar:');
      print('   - BusinessId: ${product.businessId}');
      print('   - Nombre: ${product.name}');
      print('   - Precio: ${product.price}');
      print('   - Stock: ${product.stock}');
      print('   - Imágenes a subir: ${imageFiles?.length ?? 0}');

      // Agregar producto a Firestore
      final docRef = await _firestore.collection('products').add({
        ...productData,
        'description': product.description.isNotEmpty ? product.description : 'Sin descripción',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final String productId = docRef.id;
      print('✅ Producto agregado con ID: $productId');

      // Subir imágenes a Supabase si hay
      List<String> imageUrls = [];
      if (imageFiles != null && imageFiles.isNotEmpty) {
        print('🔄 Subiendo ${imageFiles.length} imágenes a Supabase...');
        imageUrls = await _storageService.uploadMultipleImages(
            imageFiles,
            product.businessId,
            productId
        );

        // Actualizar producto con las URLs de las imágenes
        if (imageUrls.isNotEmpty) {
          await docRef.update({
            'imageUrls': imageUrls,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        print('✅ ${imageUrls.length} imágenes subidas exitosamente a Supabase');
      }

      print('✅ Producto agregado exitosamente: ${product.name}');
    } catch (e) {
      print('❌ Error agregando producto: $e');
      throw Exception('Error al agregar producto: $e');
    }
  }

  // 🔹 Actualizar producto existente CON IMÁGENES (Supabase)
  Future<void> updateProduct(
      ProductEntity product, {
        List<File>? newImageFiles,
        List<String>? deletedImageUrls,
      }) async {
    try {
      print('🔄 Actualizando producto: ${product.name} (${product.id})');

      // ✅ VALIDACIÓN del ID
      if (product.id.isEmpty) {
        throw Exception('ID de producto inválido');
      }

      // ✅ VALIDACIÓN del businessId
      if (product.businessId.isEmpty) {
        throw Exception('BusinessId inválido');
      }

      final productData = product.toMap();

      // Remover campos que serán manejados por Firestore
      productData.remove('createdAt');
      productData.remove('updatedAt');

      print('📝 Datos a actualizar:');
      print('   - ID: ${product.id}');
      print('   - BusinessId: ${product.businessId}');
      print('   - Nombre: ${product.name}');
      print('   - Nuevas imágenes: ${newImageFiles?.length ?? 0}');
      print('   - URLs a eliminar: ${deletedImageUrls?.length ?? 0}');

      // Eliminar imágenes de Supabase si hay
      if (deletedImageUrls != null && deletedImageUrls.isNotEmpty) {
        print('🔄 Eliminando ${deletedImageUrls.length} imágenes de Supabase...');
        await _storageService.deleteMultipleImages(deletedImageUrls);
      }

      List<String> updatedImageUrls = List.from(product.imageUrls);

      // Subir nuevas imágenes a Supabase si hay
      if (newImageFiles != null && newImageFiles.isNotEmpty) {
        print('🔄 Subiendo ${newImageFiles.length} nuevas imágenes a Supabase...');
        final List<String> newImageUrls = await _storageService.uploadMultipleImages(
            newImageFiles,
            product.businessId,
            product.id
        );
        updatedImageUrls.addAll(newImageUrls);
      }

      // Actualizar producto en Firestore
      await _firestore.collection('products').doc(product.id).update({
        ...productData,
        'imageUrls': updatedImageUrls,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Producto actualizado exitosamente: ${product.name} (${product.id})');
    } catch (e) {
      print('❌ Error actualizando producto: $e');
      throw Exception('Error al actualizar producto: $e');
    }
  }

  // 🔹 Eliminar producto CON SUS IMÁGENES (Supabase)
  Future<void> deleteProduct(String productId, List<String> imageUrls) async {
    try {
      print('🔄 Eliminando producto: $productId');

      if (productId.isEmpty) {
        throw Exception('ID de producto inválido');
      }

      // Eliminar imágenes de Supabase
      if (imageUrls.isNotEmpty) {
        print('🔄 Eliminando ${imageUrls.length} imágenes del producto de Supabase...');
        await _storageService.deleteMultipleImages(imageUrls);
      }

      // Eliminar producto de Firestore
      await _firestore.collection('products').doc(productId).delete();

      print('✅ Producto e imágenes eliminados exitosamente: $productId');
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