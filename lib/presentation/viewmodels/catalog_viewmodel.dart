// lib/presentation/viewmodels/catalog_viewmodel.dart - VERSIÓN CORREGIDA
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

  // ========== CATEGORÍAS ÚNICAS ==========
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
    List<ProductEntity> filtered = _allProducts;

    // Filtrar por categoría
    if (_selectedCategory != 'Todas') {
      filtered = filtered.where((p) => p.category == _selectedCategory).toList();
    }

    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) {
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

    _filteredProducts = filtered;
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
    return _allProducts.where((p) => p.businessId == businessId).toList();
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  // ========== FORZAR RECARGA ==========
  Future<void> forceRefresh() async {
    await loadCatalog(forceRefresh: true);
  }

  // ========== VERIFICAR DATOS ==========
  void debugData() {
    print('=== DEBUG CATALOG DATA ===');
    print('Negocios: ${_businesses.length}');
    print('Productos totales: ${_allProducts.length}');
    print('Productos filtrados: ${_filteredProducts.length}');

    for (final business in _businesses) {
      final businessProducts = _allProducts.where((p) => p.businessId == business.id).toList();
      print('🏢 ${business.name}: ${businessProducts.length} productos');
      for (final product in businessProducts) {
        print('   📦 ${product.name} (ID: ${product.id})');
      }
    }
    print('==========================');
  }
}