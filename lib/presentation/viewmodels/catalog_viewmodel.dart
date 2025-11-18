// lib/presentation/viewmodels/catalog_viewmodel.dart - VERSIÓN COMPLETA ACTUALIZADA
import 'package:flutter/material.dart';
import '../../domain/entities/business_entity.dart';
import '../../domain/entities/product_entity.dart';
import '../../core/services/catalog_service.dart';

class CatalogViewModel extends ChangeNotifier {
  final CatalogService _catalogService;

  CatalogViewModel({required CatalogService catalogService})
      : _catalogService = catalogService;

  // ========== ESTADOS ==========
  bool _isLoading = false;
  bool _isLoadingProducts = false;
  String _errorMessage = '';
  String _searchQuery = '';
  String _selectedCategory = 'Todas';

  // ========== DATOS ==========
  List<BusinessEntity> _businesses = [];
  List<ProductEntity> _allProducts = [];
  List<ProductEntity> _filteredProducts = [];

  // ========== CONTROL DE CARGA ==========
  bool _hasLoaded = false;

  // ========== GETTERS ==========
  bool get isLoading => _isLoading;
  bool get isLoadingProducts => _isLoadingProducts;
  String get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  List<BusinessEntity> get businesses => _businesses;
  List<ProductEntity> get products => _filteredProducts;
  List<ProductEntity> get allProducts => _allProducts;

  // ========== NUEVOS GETTERS PARA EMPRESAS ==========
  List<String> get businessCategories {
    final allCategories = _businesses.map((b) => b.category).toSet().toList();
    allCategories.sort();
    return ['Todas', ...allCategories];
  }

  List<BusinessEntity> get filteredBusinesses {
    List<BusinessEntity> filtered = _businesses;

    // Filtrar por categoría
    if (_selectedCategory != 'Todas') {
      filtered = filtered.where((b) => b.category == _selectedCategory).toList();
    }

    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((business) {
        final nameMatch = business.name.toLowerCase().contains(_searchQuery.toLowerCase());
        final categoryMatch = business.category.toLowerCase().contains(_searchQuery.toLowerCase());
        final addressMatch = business.address.toLowerCase().contains(_searchQuery.toLowerCase());
        final descriptionMatch = business.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;

        return nameMatch || categoryMatch || addressMatch || descriptionMatch;
      }).toList();
    }

    return filtered;
  }

  // ========== CATEGORÍAS ÚNICAS DE PRODUCTOS ==========
  List<String> get categories {
    final allCategories = _allProducts.map((p) => p.category).toSet().toList();
    allCategories.sort();
    return ['Todas', ...allCategories];
  }

  // ========== MÉTODOS PRINCIPALES ==========
  Future<void> loadCatalog({bool forceRefresh = false}) async {
    // Evitar cargas múltiples simultáneas
    if (_isLoading && !forceRefresh) return;

    // Si ya se cargó y no es un refresh forzado, no hacer nada
    if (_hasLoaded && !forceRefresh) return;

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      print('🔄 Cargando catálogo... (forceRefresh: $forceRefresh)');

      // LIMPIAR DATOS ANTES DE CARGAR
      if (forceRefresh) {
        _businesses.clear();
        _allProducts.clear();
        _filteredProducts.clear();
        _hasLoaded = false;
      }

      // Cargar negocios aprobados
      _businesses = await _catalogService.getApprovedBusinesses();
      print('✅ ${_businesses.length} negocios cargados');

      // Cargar productos de todos los negocios
      _allProducts = [];
      for (final business in _businesses) {
        final products = await _catalogService.getBusinessProducts(business.id);

        // FILTRAR PRODUCTOS DUPLICADOS POR ID
        final uniqueProducts = _removeDuplicateProducts(products);
        _allProducts.addAll(uniqueProducts);

        print('📦 Negocio "${business.name}": ${uniqueProducts.length} productos únicos');
      }

      // ELIMINAR DUPLICADOS FINALES
      _allProducts = _removeDuplicateProducts(_allProducts);
      _filteredProducts = _allProducts;

      _hasLoaded = true;

      print('🎯 TOTAL: ${_allProducts.length} productos únicos después de eliminar duplicados');
      print('🏢 TOTAL: ${_businesses.length} negocios aprobados');

      // DEBUG: Mostrar estadísticas por empresa
      _debugBusinessStats();

    } catch (e) {
      _errorMessage = 'Error cargando catálogo: $e';
      print('❌ Error cargando catálogo: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== ELIMINAR PRODUCTOS DUPLICADOS ==========
  List<ProductEntity> _removeDuplicateProducts(List<ProductEntity> products) {
    final uniqueProducts = <String, ProductEntity>{};

    for (final product in products) {
      if (product.id.isNotEmpty && !uniqueProducts.containsKey(product.id)) {
        uniqueProducts[product.id] = product;
      }
    }

    return uniqueProducts.values.toList();
  }

  // ========== BÚSQUEDA Y FILTROS ==========
  void updateSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void updateSelectedCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    // Aplicar filtros a productos
    List<ProductEntity> filteredProducts = _allProducts;

    // Filtrar por categoría
    if (_selectedCategory != 'Todas') {
      filteredProducts = filteredProducts.where((p) => p.category == _selectedCategory).toList();
    }

    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      filteredProducts = filteredProducts.where((product) {
        final nameMatch = product.name.toLowerCase().contains(_searchQuery.toLowerCase());
        final categoryMatch = product.category.toLowerCase().contains(_searchQuery.toLowerCase());

        // Buscar también en el nombre del negocio
        final business = _businesses.firstWhere(
                (b) => b.id == product.businessId,
            orElse: () => BusinessEntity(
                id: '', ownerId: '', name: '', email: '',
                category: '', address: '', phone: '',
                status: 'approved', rating: 0, reviewCount: 0,
                createdAt: DateTime.now()
            )
        );
        final businessMatch = business.name.toLowerCase().contains(_searchQuery.toLowerCase());

        return nameMatch || categoryMatch || businessMatch;
      }).toList();
    }

    _filteredProducts = filteredProducts;
    print('🔍 Filtros aplicados: ${_filteredProducts.length} productos mostrados');
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = 'Todas';
    _filteredProducts = _allProducts;
    notifyListeners();
  }

  // ========== MÉTODOS AUXILIARES ==========
  BusinessEntity? getBusinessById(String businessId) {
    try {
      return _businesses.firstWhere((b) => b.id == businessId);
    } catch (e) {
      return null;
    }
  }

  List<ProductEntity> getProductsByBusiness(String businessId) {
    return _allProducts.where((p) => p.businessId == businessId && p.canBeSold).toList();
  }

  // ========== ESTADÍSTICAS DE EMPRESAS ==========
  Map<String, dynamic> getBusinessStats(String businessId) {
    final businessProducts = getProductsByBusiness(businessId);
    final totalProducts = businessProducts.length;
    final availableProducts = businessProducts.where((p) => p.isAvailable).length;
    final outOfStockProducts = businessProducts.where((p) => p.stock == 0).length;
    final lowStockProducts = businessProducts.where((p) => p.stock > 0 && p.stock < 5).length;

    double totalInventoryValue = 0;
    for (var product in businessProducts) {
      totalInventoryValue += product.price * product.stock;
    }

    return {
      'totalProducts': totalProducts,
      'availableProducts': availableProducts,
      'outOfStockProducts': outOfStockProducts,
      'lowStockProducts': lowStockProducts,
      'totalInventoryValue': totalInventoryValue,
    };
  }

  // ========== BÚSQUEDA ESPECÍFICA ==========
  List<BusinessEntity> searchBusinesses(String query) {
    if (query.isEmpty) return _businesses;

    return _businesses.where((business) {
      final nameMatch = business.name.toLowerCase().contains(query.toLowerCase());
      final categoryMatch = business.category.toLowerCase().contains(query.toLowerCase());
      final addressMatch = business.address.toLowerCase().contains(query.toLowerCase());
      final descriptionMatch = business.description?.toLowerCase().contains(query.toLowerCase()) ?? false;

      return nameMatch || categoryMatch || addressMatch || descriptionMatch;
    }).toList();
  }

  List<ProductEntity> searchProducts(String query) {
    if (query.isEmpty) return _allProducts;

    return _allProducts.where((product) {
      final nameMatch = product.name.toLowerCase().contains(query.toLowerCase());
      final categoryMatch = product.category.toLowerCase().contains(query.toLowerCase());
      final descriptionMatch = product.description.toLowerCase().contains(query.toLowerCase());

      return nameMatch || categoryMatch || descriptionMatch;
    }).toList();
  }

  // ========== FILTRADO POR CATEGORÍA ESPECÍFICA ==========
  List<BusinessEntity> getBusinessesByCategory(String category) {
    if (category == 'Todas') return _businesses;
    return _businesses.where((business) => business.category == category).toList();
  }

  List<ProductEntity> getProductsByCategory(String category) {
    if (category == 'Todas') return _allProducts;
    return _allProducts.where((product) => product.category == category).toList();
  }

  // ========== MÉTODOS DE LIMPIEZA ==========
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  void clearAllData() {
    _businesses.clear();
    _allProducts.clear();
    _filteredProducts.clear();
    _searchQuery = '';
    _selectedCategory = 'Todas';
    _hasLoaded = false;
    _errorMessage = '';
    notifyListeners();
  }

  // ========== FORZAR RECARGA ==========
  Future<void> forceRefresh() async {
    await loadCatalog(forceRefresh: true);
  }

  // ========== VERIFICACIÓN DE DATOS ==========
  void _debugBusinessStats() {
    print('=== ESTADÍSTICAS DE EMPRESAS ===');
    for (final business in _businesses) {
      final stats = getBusinessStats(business.id);
      print('🏢 ${business.name}');
      print('   📦 Productos totales: ${stats['totalProducts']}');
      print('   ✅ Disponibles: ${stats['availableProducts']}');
      print('   ❌ Sin stock: ${stats['outOfStockProducts']}');
      print('   ⚠️ Stock bajo: ${stats['lowStockProducts']}');
      print('   💰 Valor inventario: \$${stats['totalInventoryValue'].toStringAsFixed(2)}');
    }
    print('================================');
  }

  void debugData() {
    print('=== DEBUG CATALOG DATA ===');
    print('Negocios: ${_businesses.length}');
    print('Productos totales: ${_allProducts.length}');
    print('Productos filtrados: ${_filteredProducts.length}');
    print('Búsqueda actual: "$_searchQuery"');
    print('Categoría seleccionada: "$_selectedCategory"');

    for (final business in _businesses) {
      final businessProducts = _allProducts.where((p) => p.businessId == business.id).toList();
      print('🏢 ${business.name} (${business.category}): ${businessProducts.length} productos');
      for (final product in businessProducts) {
        print('   📦 ${product.name} - \$${product.price} (Stock: ${product.stock})');
      }
    }
    print('==========================');
  }

  // ========== VALIDACIONES ==========
  bool hasBusinessProducts(String businessId) {
    return _allProducts.any((p) => p.businessId == businessId && p.canBeSold);
  }

  int getBusinessProductCount(String businessId) {
    return _allProducts.where((p) => p.businessId == businessId && p.canBeSold).length;
  }

  bool isBusinessEmpty(String businessId) {
    return !hasBusinessProducts(businessId);
  }

  // ========== ESTADO DE CARGA ESPECÍFICO ==========
  Future<void> loadBusinessProducts(String businessId) async {
    if (_isLoadingProducts) return;

    _isLoadingProducts = true;
    notifyListeners();

    try {
      // Recargar productos específicos del negocio
      final products = await _catalogService.getBusinessProducts(businessId);

      // Actualizar la lista de productos
      _allProducts.removeWhere((p) => p.businessId == businessId);
      _allProducts.addAll(products);

      // Reaplicar filtros
      _applyFilters();

      print('✅ Productos del negocio $businessId actualizados: ${products.length} productos');
    } catch (e) {
      print('❌ Error cargando productos del negocio $businessId: $e');
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  // ========== ACTUALIZACIÓN SELECTIVA ==========
  void updateBusiness(BusinessEntity updatedBusiness) {
    final index = _businesses.indexWhere((b) => b.id == updatedBusiness.id);
    if (index != -1) {
      _businesses[index] = updatedBusiness;
      notifyListeners();
    }
  }

  void updateProduct(ProductEntity updatedProduct) {
    final index = _allProducts.indexWhere((p) => p.id == updatedProduct.id);
    if (index != -1) {
      _allProducts[index] = updatedProduct;
      _applyFilters();
      notifyListeners();
    }
  }

  // ========== DISPOSE ==========
  @override
  void dispose() {
    // Limpiar recursos si es necesario
    super.dispose();
  }
}