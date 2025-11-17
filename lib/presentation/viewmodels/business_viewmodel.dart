// lib/presentation/viewmodels/business_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/product_entity.dart';
import '../../core/services/product_service.dart';
import '../../core/services/business_registration_service.dart';
import '../../../domain/entities/business_entity.dart';

class BusinessViewModel with ChangeNotifier {
  final ProductService _productService;
  final BusinessRegistrationService _businessRegistrationService;

  BusinessViewModel({
    required ProductService productService,
    required BusinessRegistrationService businessRegistrationService,
  })  : _productService = productService,
        _businessRegistrationService = businessRegistrationService;

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
      _errorMessage = 'Error al cargar productos: $e';
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
    notifyListeners();

    try {
      print('🔄 Cargando información de empresa para usuario: $userId');

      final businessData = await _businessRegistrationService.getUserRegistrationStatus(userId);

      if (businessData != null) {
        _currentBusiness = _mapToBusinessEntity(businessData);
        print('✅ Empresa cargada: ${_currentBusiness!.name}');

        // Cargar productos de la empresa
        await loadBusinessProducts(_currentBusiness!.id);
      } else {
        _errorMessage = 'No se encontró información de la empresa';
        print('⚠️ No se encontró empresa para usuario: $userId');
      }
    } catch (e) {
      _errorMessage = 'Error al cargar empresa: $e';
      print('❌ Error cargando empresa: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🔹 Agregar nuevo producto
  Future<bool> addProduct(ProductEntity product) async {
    _isLoading = true;
    _errorMessage = '';
    _successMessage = '';
    notifyListeners();

    try {
      print('🔄 Agregando producto: ${product.name}');

      await _productService.addProduct(product);

      // Recargar productos para incluir el nuevo
      if (_currentBusiness != null) {
        await loadBusinessProducts(_currentBusiness!.id);
      }

      _successMessage = 'Producto agregado exitosamente';
      print('✅ Producto agregado: ${product.name}');
      return true;
    } catch (e) {
      _errorMessage = 'Error al agregar producto: $e';
      print('❌ Error agregando producto: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🔹 Actualizar producto existente
  Future<bool> updateProduct(ProductEntity product) async {
    _isLoading = true;
    _errorMessage = '';
    _successMessage = '';
    notifyListeners();

    try {
      print('🔄 Actualizando producto: ${product.name}');

      await _productService.updateProduct(product);

      // Actualizar en la lista local
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product;
      }

      _successMessage = 'Producto actualizado exitosamente';
      print('✅ Producto actualizado: ${product.name}');
      return true;
    } catch (e) {
      _errorMessage = 'Error al actualizar producto: $e';
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

      await _productService.deleteProduct(productId);

      // Remover de la lista local
      _products.removeWhere((product) => product.id == productId);
      _loadCategoriesFromProducts();

      _successMessage = 'Producto eliminado exitosamente';
      print('✅ Producto eliminado: $productId');
      return true;
    } catch (e) {
      _errorMessage = 'Error al eliminar producto: $e';
      print('❌ Error eliminando producto: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🔹 Actualizar stock de producto
  Future<bool> updateProductStock(String productId, int newStock) async {
    try {
      print('🔄 Actualizando stock: $productId -> $newStock');

      await _productService.updateProductStock(productId, newStock);

      // Actualizar en la lista local
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = _products[index].copyWith(stock: newStock);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al actualizar stock: $e';
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

      // Actualizar en la lista local
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = _products[index].copyWith(isAvailable: isAvailable);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al cambiar disponibilidad: $e';
      print('❌ Error cambiando disponibilidad: $e');
      notifyListeners();
      return false;
    }
  }

  // ========== BÚSQUEDA Y FILTROS ==========

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

    // Aplicar filtro de búsqueda
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) {
        final nameMatch = product.name.toLowerCase().contains(_searchQuery.toLowerCase());
        final categoryMatch = product.category.toLowerCase().contains(_searchQuery.toLowerCase());
        final descriptionMatch = product.description.toLowerCase().contains(_searchQuery.toLowerCase());
        return nameMatch || categoryMatch || descriptionMatch;
      }).toList();
    }

    // Aplicar filtro de categoría
    if (_selectedCategory != 'Todas') {
      filtered = filtered.where((product) => product.category == _selectedCategory).toList();
    }

    return filtered;
  }

  // ========== MÉTODOS DE CATEGORÍAS ==========

  void _loadCategoriesFromProducts() {
    final allCategories = _products.map((product) => product.category).toSet().toList();
    allCategories.sort();
    _categories = ['Todas', ...allCategories];
  }

  Future<List<String>> loadBusinessCategories(String businessId) async {
    try {
      _categories = await _productService.getBusinessCategories(businessId);
      _categories.insert(0, 'Todas');
      notifyListeners();
      return _categories;
    } catch (e) {
      _errorMessage = 'Error al cargar categorías: $e';
      notifyListeners();
      return [];
    }
  }

  // ========== ESTADÍSTICAS Y MÉTRICAS ==========

  Map<String, dynamic> getBusinessStats() {
    final totalProducts = _products.length;
    final availableProducts = _products.where((p) => p.isAvailable).length;
    final outOfStockProducts = _products.where((p) => p.stock == 0).length;
    final lowStockProducts = _products.where((p) => p.stock > 0 && p.stock < 5).length;

    // Calcular valor total del inventario
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
      'categoriesCount': _categories.length - 1, // Excluir "Todas"
    };
  }

  List<ProductEntity> getLowStockProducts() {
    return _products.where((product) => product.stock > 0 && product.stock < 5).toList();
  }

  List<ProductEntity> getOutOfStockProducts() {
    return _products.where((product) => product.stock == 0).toList();
  }

  // ========== MÉTODOS DE VALIDACIÓN ==========

  bool isProductNameUnique(String name, {String? excludeProductId}) {
    return !_products.any((product) =>
    product.name.toLowerCase() == name.toLowerCase() &&
        product.id != excludeProductId);
  }

  // ========== MÉTODOS DE LIMPIEZA ==========

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

  // ========== MÉTODOS DE BÚSQUEDA AVANZADA ==========

  List<ProductEntity> searchProductsByName(String name) {
    return _products.where((product) =>
        product.name.toLowerCase().contains(name.toLowerCase())).toList();
  }

  List<ProductEntity> getProductsByAvailability(bool isAvailable) {
    return _products.where((product) => product.isAvailable == isAvailable).toList();
  }

  List<ProductEntity> getProductsByPriceRange(double minPrice, double maxPrice) {
    return _products.where((product) =>
    product.price >= minPrice && product.price <= maxPrice).toList();
  }

  // ========== MÉTODOS DE OBTENCIÓN DE DATOS ESPECÍFICOS ==========

  ProductEntity? getProductById(String productId) {
    try {
      return _products.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }

  List<ProductEntity> getProductsByCategory(String category) {
    return _products.where((product) => product.category == category).toList();
  }

  bool get hasProducts => _products.isNotEmpty;
  bool get hasCategories => _categories.length > 1; // Más de "Todas"
  bool get hasLowStockProducts => getLowStockProducts().isNotEmpty;
  bool get hasOutOfStockProducts => getOutOfStockProducts().isNotEmpty;

  // ========== MÉTODO DE MAPEO PARA BUSINESS ENTITY ==========

  BusinessEntity _mapToBusinessEntity(Map<String, dynamic> data) {
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
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.parse(data['createdAt'].toString()))
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(data['updatedAt'].toString()))
          : null,
    );
  }

  @override
  void dispose() {
    // Limpiar cualquier suscripción si es necesario
    super.dispose();
  }
}