// lib/presentation/viewmodels/business_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../../domain/entities/product_entity.dart';
import '../../core/services/product_service.dart';
import '../../core/services/business_registration_service.dart';
import '../../core/services/supabase_storage_service.dart';
import '../../../domain/entities/business_entity.dart';

class BusinessViewModel with ChangeNotifier {
  final ProductService _productService;
  final BusinessRegistrationService _businessRegistrationService;
  final SupabaseStorageService _storageService;

  BusinessViewModel({
    required ProductService productService,
    required BusinessRegistrationService businessRegistrationService,
    required SupabaseStorageService storageService,
  })  : _productService = productService,
        _businessRegistrationService = businessRegistrationService,
        _storageService = storageService;

  // ========== ESTADOS ==========
  bool _isLoading = false;
  bool _isLoadingProducts = false;
  String _errorMessage = '';
  String _successMessage = '';

  // Datos
  List<ProductEntity> _products = [];
  BusinessEntity? _currentBusiness;
  List<String> _categories = [];

  // Búsqueda y Filtros
  String _searchQuery = '';
  String _selectedCategory = 'Todas';

  // ========== GETTERS ==========
  bool get isLoading => _isLoading;
  bool get isLoadingProducts => _isLoadingProducts;
  String get errorMessage => _errorMessage;
  String get successMessage => _successMessage;

  List<ProductEntity> get products => _products;
  List<ProductEntity> get filteredProducts => _applyFilters(_products);
  BusinessEntity? get currentBusiness => _currentBusiness;
  List<String> get categories => _categories;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  // ========== MÉTODOS DE PRODUCTOS ==========

  // 🔹 Cargar productos de la empresa
  Future<void> loadBusinessProducts(String businessId) async {
    if (_isLoadingProducts) return;

    _isLoadingProducts = true;
    _errorMessage = '';
    notifyListeners();

    try {
      print('🔄 Cargando productos para empresa: $businessId');

      _products = await _productService.getBusinessProducts(businessId);
      _loadCategoriesFromProducts();

      print('✅ ${_products.length} productos cargados exitosamente');
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Error al cargar productos: ${e.toString()}';
      _products = [];
      print('❌ Error cargando productos: $e');
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  // 🔹 Cargar información de la empresa actual
  Future<void> loadCurrentBusiness(String userId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      print('🔄 Cargando información de empresa para usuario: $userId');

      final businessData = await _businessRegistrationService.getUserRegistrationStatus(userId);

      if (businessData != null) {
        _currentBusiness = _mapToBusinessEntity(businessData);
        print('✅ Empresa cargada: ${_currentBusiness!.name} (ID: ${_currentBusiness!.id})');

        // Cargar productos de la empresa
        await loadBusinessProducts(_currentBusiness!.id);
      } else {
        _errorMessage = 'No se encontró información de la empresa';
        print('⚠️ No se encontró empresa para usuario: $userId');
      }
    } catch (e) {
      _errorMessage = 'Error al cargar empresa: ${e.toString()}';
      print('❌ Error cargando empresa: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🔹 Agregar nuevo producto
  Future<bool> addProduct(ProductEntity product, {List<File>? imageFiles}) async {
    _isLoading = true;
    _errorMessage = '';
    _successMessage = '';
    notifyListeners();

    try {
      print('🔄 Agregando producto: ${product.name}');
      print('📋 Detalles del producto:');
      print('   - BusinessId: ${product.businessId}');
      print('   - Nombre: ${product.name}');
      print('   - Imágenes: ${imageFiles?.length ?? 0}');

      // ✅ VALIDACIÓN ADICIONAL del businessId
      if (product.businessId.isEmpty) {
        throw Exception('No se pudo obtener la información de la empresa. BusinessId vacío.');
      }

      await _productService.addProduct(product, imageFiles: imageFiles);

      // Forzar recarga completa de productos
      if (_currentBusiness != null) {
        await loadBusinessProducts(_currentBusiness!.id);
      }

      _successMessage = 'Producto agregado exitosamente';
      print('✅ Producto agregado: ${product.name}');
      return true;
    } catch (e) {
      _errorMessage = 'Error al agregar producto: ${e.toString()}';
      print('❌ Error agregando producto: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🔹 Actualizar producto existente
  Future<bool> updateProduct(
      ProductEntity product, {
        List<File>? newImageFiles,
        List<String>? deletedImageUrls,
      }) async {
    _isLoading = true;
    _errorMessage = '';
    _successMessage = '';
    notifyListeners();

    try {
      print('🔄 Actualizando producto: ${product.name}');
      print('📋 Detalles del producto:');
      print('   - ID: ${product.id}');
      print('   - BusinessId: ${product.businessId}');
      print('   - Nombre: ${product.name}');
      print('   - Nuevas imágenes: ${newImageFiles?.length ?? 0}');
      print('   - Imágenes a eliminar: ${deletedImageUrls?.length ?? 0}');

      // ✅ VALIDACIÓN ADICIONAL del ID
      if (product.id.isEmpty) {
        throw Exception('No se puede actualizar un producto sin ID. Por favor, recarga la lista de productos.');
      }

      // ✅ VALIDACIÓN ADICIONAL del businessId
      if (product.businessId.isEmpty) {
        throw Exception('BusinessId no válido. Por favor, verifica la información de la empresa.');
      }

      await _productService.updateProduct(
        product,
        newImageFiles: newImageFiles,
        deletedImageUrls: deletedImageUrls,
      );

      // Forzar recarga completa de productos
      if (_currentBusiness != null) {
        await loadBusinessProducts(_currentBusiness!.id);
      }

      _successMessage = 'Producto actualizado exitosamente';
      print('✅ Producto actualizado: ${product.name}');
      return true;
    } catch (e) {
      _errorMessage = 'Error al actualizar producto: ${e.toString()}';
      print('❌ Error actualizando producto: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🔹 Eliminar producto
  Future<bool> deleteProduct(String productId) async {
    _isLoading = true;
    _errorMessage = '';
    _successMessage = '';
    notifyListeners();

    try {
      print('🔄 Eliminando producto: $productId');

      // Buscar el producto para obtener sus imágenes
      final product = _products.firstWhere((p) => p.id == productId);
      final imageUrls = product.imageUrls;

      await _productService.deleteProduct(productId, imageUrls);

      // Forzar recarga completa de productos
      if (_currentBusiness != null) {
        await loadBusinessProducts(_currentBusiness!.id);
      }

      _successMessage = 'Producto eliminado exitosamente';
      print('✅ Producto eliminado: $productId');
      return true;
    } catch (e) {
      _errorMessage = 'Error al eliminar producto: ${e.toString()}';
      print('❌ Error eliminando producto: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🔹 Seleccionar imagen de galería CON VALIDACIÓN SIMPLE DE TAMAÑO
  Future<File?> pickImageFromGallery() async {
    try {
      final File? imageFile = await _storageService.pickImageFromGallery();

      if (imageFile != null) {
        // Validar tamaño inmediatamente
        final fileSize = await imageFile.length();
        final fileSizeMB = fileSize / (1024 * 1024);

        // Si es mayor a 10 MB, mostrar error y no permitir
        if (fileSizeMB > 10) {
          _errorMessage = '❌ Imagen demasiado pesada (${fileSizeMB.toStringAsFixed(1)} MB). '
              'Máximo permitido: 10 MB. '
              'Se recomienda usar una imagen de menos de 2 MB.';
          notifyListeners();
          return null;
        }

        // Si es mayor a 2 MB, mostrar advertencia pero permitir
        if (fileSizeMB > 2) {
          _errorMessage = '⚠️ Imagen pesada (${fileSizeMB.toStringAsFixed(1)} MB). '
              'Se recomienda usar una imagen de menos de 2 MB para mejor rendimiento.';
          notifyListeners();
        }

        return imageFile;
      }
      return null;
    } catch (e) {
      _errorMessage = 'Error al seleccionar imagen: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  // 🔹 Tomar foto con cámara CON VALIDACIÓN SIMPLE DE TAMAÑO
  Future<File?> takePhotoWithCamera() async {
    try {
      final File? imageFile = await _storageService.takePhotoWithCamera();

      if (imageFile != null) {
        // Validar tamaño inmediatamente
        final fileSize = await imageFile.length();
        final fileSizeMB = fileSize / (1024 * 1024);

        // Si es mayor a 10 MB, mostrar error y no permitir
        if (fileSizeMB > 10) {
          _errorMessage = '❌ Imagen demasiado pesada (${fileSizeMB.toStringAsFixed(1)} MB). '
              'Máximo permitido: 10 MB. '
              'Se recomienda usar una imagen de menos de 2 MB.';
          notifyListeners();
          return null;
        }

        // Si es mayor a 2 MB, mostrar advertencia pero permitir
        if (fileSizeMB > 2) {
          _errorMessage = '⚠️ Imagen pesada (${fileSizeMB.toStringAsFixed(1)} MB). '
              'Se recomienda usar una imagen de menos de 2 MB para mejor rendimiento.';
          notifyListeners();
        }

        return imageFile;
      }
      return null;
    } catch (e) {
      _errorMessage = 'Error al tomar foto: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  // 🔹 VALIDAR IMAGEN ANTES DE SUBIR (método público para usar en el formulario)
  Future<String?> validateImageBeforeUpload(File imageFile) async {
    try {
      final fileSize = await imageFile.length();
      final fileSizeMB = fileSize / (1024 * 1024);

      if (fileSizeMB > 10) {
        return '❌ Imagen demasiado pesada (${fileSizeMB.toStringAsFixed(1)} MB). '
            'Máximo permitido: 10 MB. '
            'Se recomienda usar una imagen de menos de 2 MB.';
      }

      if (fileSizeMB > 2) {
        return '⚠️ Imagen pesada (${fileSizeMB.toStringAsFixed(1)} MB). '
            'Se recomienda usar una imagen de menos de 2 MB para mejor rendimiento.';
      }

      return null; // No hay error
    } catch (e) {
      return 'Error validando imagen: ${e.toString()}';
    }
  }

  // ========== MÉTODOS EXISTENTES ==========

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void updateSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = 'Todas';
    notifyListeners();
  }

  List<ProductEntity> _applyFilters(List<ProductEntity> products) {
    List<ProductEntity> filtered = products;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) {
        final nameMatch = product.name.toLowerCase().contains(_searchQuery.toLowerCase());
        final categoryMatch = product.category.toLowerCase().contains(_searchQuery.toLowerCase());
        final descriptionMatch = product.description.toLowerCase().contains(_searchQuery.toLowerCase());
        return nameMatch || categoryMatch || descriptionMatch;
      }).toList();
    }

    if (_selectedCategory != 'Todas') {
      filtered = filtered.where((product) => product.category == _selectedCategory).toList();
    }

    return filtered;
  }

  void _loadCategoriesFromProducts() {
    final allCategories = _products.map((product) => product.category).toSet().toList();
    allCategories.sort();
    _categories = ['Todas', ...allCategories];
  }

  Map<String, dynamic> getBusinessStats() {
    final totalProducts = _products.length;
    final availableProducts = _products.where((p) => p.isAvailable).length;
    final outOfStockProducts = _products.where((p) => p.stock == 0).length;
    final lowStockProducts = _products.where((p) => p.stock > 0 && p.stock < 5).length;

    double totalInventoryValue = 0;
    for (var product in _products) {
      totalInventoryValue += product.price * product.stock;
    }

    return {
      'totalProducts': totalProducts,
      'availableProducts': availableProducts,
      'outOfStockProducts': outOfStockProducts,
      'lowStockProducts': lowStockProducts,
      'totalInventoryValue': totalInventoryValue,
      'categoriesCount': _categories.length - 1,
    };
  }

  // 🔹 Actualizar stock de producto
  Future<bool> updateProductStock(String productId, int newStock) async {
    try {
      print('🔄 Actualizando stock: $productId -> $newStock');

      await _productService.updateProductStock(productId, newStock);

      // Forzar recarga completa de productos
      if (_currentBusiness != null) {
        await loadBusinessProducts(_currentBusiness!.id);
      }

      return true;
    } catch (e) {
      _errorMessage = 'Error al actualizar stock: ${e.toString()}';
      print('❌ Error actualizando stock: $e');
      notifyListeners();
      return false;
    }
  }

  // 🔹 Cambiar disponibilidad de producto
  Future<bool> toggleProductAvailability(String productId, bool isAvailable) async {
    try {
      print('🔄 Cambiando disponibilidad: $productId -> $isAvailable');

      await _productService.toggleProductAvailability(productId, isAvailable);

      // Forzar recarga completa de productos
      if (_currentBusiness != null) {
        await loadBusinessProducts(_currentBusiness!.id);
      }

      return true;
    } catch (e) {
      _errorMessage = 'Error al cambiar disponibilidad: ${e.toString()}';
      print('❌ Error cambiando disponibilidad: $e');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  void clearSuccess() {
    _successMessage = '';
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = '';
    _successMessage = '';
    notifyListeners();
  }

  void refreshProducts(String businessId) {
    _products = [];
    _categories = ['Todas'];
    _searchQuery = '';
    _selectedCategory = 'Todas';
    loadBusinessProducts(businessId);
  }

  BusinessEntity _mapToBusinessEntity(Map<String, dynamic> data) {
    DateTime _parseDateTime(dynamic date) {
      if (date == null) return DateTime.now();
      if (date is Timestamp) {
        return date.toDate();
      } else if (date is int) {
        return DateTime.fromMillisecondsSinceEpoch(date);
      } else if (date is String) {
        return DateTime.parse(date);
      } else {
        return DateTime.now();
      }
    }

    return BusinessEntity(
      id: data['id'] ?? '',
      ownerId: data['userId'] ?? '',
      name: data['businessName'] ?? '',
      email: data['userEmail'] ?? '',
      category: data['category'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'pending',
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: (data['reviewCount'] ?? 0).toInt(),
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: data['updatedAt'] != null ? _parseDateTime(data['updatedAt']) : null,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}