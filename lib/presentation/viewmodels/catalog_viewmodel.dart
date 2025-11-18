// lib/presentation/viewmodels/catalog_viewmodel.dart
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
  Future<void> loadCatalog() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      print('🔄 Cargando catálogo...');

      // Cargar negocios aprobados
      _businesses = await _catalogService.getApprovedBusinesses();
      print('✅ ${_businesses.length} negocios cargados');

      // Cargar productos de todos los negocios
      _allProducts = [];
      for (final business in _businesses) {
        final products = await _catalogService.getBusinessProducts(business.id);
        _allProducts.addAll(products);
      }

      _filteredProducts = _allProducts;
      print('✅ ${_allProducts.length} productos cargados');

    } catch (e) {
      _errorMessage = 'Error cargando catálogo: $e';
      print('❌ Error cargando catálogo: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
}