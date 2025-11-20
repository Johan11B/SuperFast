// lib/presentation/viewmodels/catalog_viewmodel.dart - VERSIÓN CON MUTEX
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

  // ========== CONTROL DE EJECUCIÓN CONCURRENTE ==========
  bool _isExecuting = false;

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
    List<BusinessEntity> filtered = List.from(_businesses); // ✅ COPIA SEGURA

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

  // ========== MÉTODO PRINCIPAL CORREGIDO ==========
  Future<void> loadCatalog({bool forceRefresh = false}) async {
    // ✅ PREVENIR EJECUCIÓN CONCURRENTE
    if (_isExecuting) {
      print('⏳ Carga en progreso, ignorando llamada concurrente...');
      return;
    }

    // Evitar cargas múltiples simultáneas
    if (_isLoading && !forceRefresh) return;

    // Si ya se cargó y no es un refresh forzado, no hacer nada
    if (_hasLoaded && !forceRefresh) return;

    _isExecuting = true;
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
      final loadedBusinesses = await _catalogService.getApprovedBusinesses();
      _businesses = loadedBusinesses; // ✅ ASIGNACIÓN DIRECTA
      print('✅ ${_businesses.length} negocios cargados');

      // Cargar productos de todos los negocios - ✅ EVITAR MODIFICACIÓN DURANTE ITERACIÓN
      final allProductsList = <ProductEntity>[];

      for (final business in loadedBusinesses) { // ✅ ITERAR SOBRE LA LISTA LOCAL
        final products = await _catalogService.getBusinessProducts(business.id);

        // FILTRAR PRODUCTOS DUPLICADOS POR ID
        final uniqueProducts = _removeDuplicateProducts(products);
        allProductsList.addAll(uniqueProducts); // ✅ AGREGAR A LISTA TEMPORAL

        print('📦 Negocio "${business.name}": ${uniqueProducts.length} productos únicos');
      }

      // ✅ ASIGNACIÓN FINAL - SIN MODIFICACIÓN DURANTE ITERACIÓN
      _allProducts = _removeDuplicateProducts(allProductsList);
      _filteredProducts = List.from(_allProducts);

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
      _isExecuting = false;
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
    // ✅ CREAR LISTA TEMPORAL PARA FILTRAR
    List<ProductEntity> filteredProducts = List.from(_allProducts);

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
    _filteredProducts = List.from(_allProducts); // ✅ COPIA SEGURA
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

  // ========== FORZAR RECARGA ==========
  Future<void> forceRefresh() async {
    await loadCatalog(forceRefresh: true);
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

  @override
  void dispose() {
    super.dispose();
  }
}