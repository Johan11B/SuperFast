// lib/presentation/screens/user/user_catalog_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/business_entity.dart';
import '../../viewmodels/catalog_viewmodel.dart';
import 'business_products_screen.dart';

class UserCatalogScreen extends StatefulWidget {
  const UserCatalogScreen({super.key});

  @override
  State<UserCatalogScreen> createState() => _UserCatalogScreenState();
}

class _UserCatalogScreenState extends State<UserCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final catalogViewModel = context.read<CatalogViewModel>();
      catalogViewModel.forceRefresh();
    });
  }

  void _onSearchChanged() {
    context.read<CatalogViewModel>().updateSearchQuery(_searchController.text);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogViewModel = context.watch<CatalogViewModel>();

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 🔍 APP BAR CON BÚSQUEDA
          SliverAppBar(
            title: const Text('Catálogo de Empresas'),
            floating: true,
            snap: true,
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar empresas o categorías...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        catalogViewModel.updateSearchQuery('');
                      },
                    )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
            ),
          ),

          // 🏷️ FILTROS POR CATEGORÍA
          _buildCategoryFilters(catalogViewModel),

          // 📦 CONTENIDO PRINCIPAL
          if (catalogViewModel.isLoading) _buildLoadingState(),
          if (!catalogViewModel.isLoading && catalogViewModel.errorMessage.isNotEmpty)
            _buildErrorState(catalogViewModel),
          if (!catalogViewModel.isLoading && catalogViewModel.errorMessage.isEmpty)
            _buildBusinessesList(catalogViewModel),
        ],
      ),
    );
  }

  // 🏷️ FILTROS DE CATEGORÍA
  Widget _buildCategoryFilters(CatalogViewModel catalogViewModel) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 60,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            _buildFilterChip('Todas', 'Todas', catalogViewModel),
            const SizedBox(width: 8),
            ...catalogViewModel.businessCategories.where((cat) => cat != 'Todas').map(
                  (category) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: _buildFilterChip(category, category, catalogViewModel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, CatalogViewModel viewModel) {
    return FilterChip(
      label: Text(label),
      selected: viewModel.selectedCategory == value,
      onSelected: (selected) {
        viewModel.updateSelectedCategory(value);
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: Colors.green.shade100,
      checkmarkColor: Colors.green,
      labelStyle: TextStyle(
        color: viewModel.selectedCategory == value ? Colors.green : Colors.grey.shade700,
        fontWeight: viewModel.selectedCategory == value ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  // ⏳ ESTADO DE CARGA
  Widget _buildLoadingState() {
    return const SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando empresas...'),
          ],
        ),
      ),
    );
  }

  // ❌ ESTADO DE ERROR
  Widget _buildErrorState(CatalogViewModel catalogViewModel) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar empresas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                catalogViewModel.errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => catalogViewModel.forceRefresh(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  // 🏢 LISTA DE EMPRESAS (SOLO EMPRESAS, SIN PRODUCTOS)
  Widget _buildBusinessesList(CatalogViewModel catalogViewModel) {
    final filteredBusinesses = catalogViewModel.filteredBusinesses;

    if (filteredBusinesses.isEmpty) {
      return _buildEmptyState(catalogViewModel);
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final business = filteredBusinesses[index];
          return _buildBusinessCard(business, context, catalogViewModel);
        },
        childCount: filteredBusinesses.length,
      ),
    );
  }

  // 🏢 TARJETA DE EMPRESA
  Widget _buildBusinessCard(BusinessEntity business, BuildContext context, CatalogViewModel catalogViewModel) {
    final productCount = catalogViewModel.getProductsByBusiness(business.id).length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      child: Column(
        children: [
          // HEADER DE LA EMPRESA
          _buildBusinessHeader(business, context, productCount),
        ],
      ),
    );
  }

  // 🏢 HEADER DE LA EMPRESA
  Widget _buildBusinessHeader(BusinessEntity business, BuildContext context, int productCount) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              // LOGO DE LA EMPRESA
              _buildBusinessImage(business),
              const SizedBox(width: 16),

              // INFORMACIÓN DE LA EMPRESA
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            business.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        // ESTADO DE LA EMPRESA
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: business.statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: business.statusColor),
                          ),
                          child: Text(
                            business.statusDisplayText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: business.statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      business.category,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (business.description != null && business.description!.isNotEmpty)
                      Column(
                        children: [
                          Text(
                            business.description!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            business.address,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (business.phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            business.phone,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    // RATING Y CONTADOR DE PRODUCTOS
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (business.rating > 0) ...[
                          Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '${business.rating.toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Icon(Icons.inventory_2, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          '$productCount ${productCount == 1 ? 'producto' : 'productos'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // BOTÓN PARA VER PRODUCTOS
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _navigateToBusinessProducts(business, context);
              },
              icon: const Icon(Icons.shopping_bag, size: 20),
              label: const Text(
                'Ver Productos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🏢 IMAGEN DE LA EMPRESA
  Widget _buildBusinessImage(BusinessEntity business) {
    // ✅ VERIFICAR si la empresa tiene logoUrl
    final hasLogo = business.logoUrl != null && business.logoUrl!.isNotEmpty;

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: hasLogo ? Colors.transparent : Colors.green,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        // ✅ MOSTRAR LOGO SI EXISTE
        image: hasLogo
            ? DecorationImage(
          image: NetworkImage(business.logoUrl!),
          fit: BoxFit.cover,
        )
            : null,
      ),
      child: hasLogo
          ? null // No mostrar texto si hay logo
          : Center(
        child: Text(
          business.name[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // 🚀 NAVEGAR A PRODUCTOS DE LA EMPRESA
  void _navigateToBusinessProducts(BusinessEntity business, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusinessProductsScreen(business: business),
      ),
    );
  }

  // 👁️ DETALLES DE LA EMPRESA
  void _showBusinessDetails(BusinessEntity business, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Información del Negocio'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: _buildBusinessImage(business),
              ),
              const SizedBox(height: 16),
              _buildDetailItem('Negocio:', business.name),
              _buildDetailItem('Categoría:', business.category),
              _buildDetailItem('Estado:', business.statusDisplayText),
              _buildDetailItem('Dirección:', business.address),
              if (business.phone.isNotEmpty)
                _buildDetailItem('Teléfono:', business.phone),
              if (business.description != null && business.description!.isNotEmpty)
                _buildDetailItem('Descripción:', business.description!),
              if (business.rating > 0) ...[
                _buildDetailItem('Calificación:', '${business.rating} ⭐'),
                _buildDetailItem('Reseñas:', '${business.reviewCount} reseñas'),
              ],
              _buildDetailItem('Registrado:', _formatDate(business.createdAt)),
              if (business.approvedAt != null)
                _buildDetailItem('Aprobado:', _formatDate(business.approvedAt!)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToBusinessProducts(business, context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Ver Productos'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // 📭 ESTADO VACÍO
  Widget _buildEmptyState(CatalogViewModel catalogViewModel) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.business_center, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              catalogViewModel.searchQuery.isNotEmpty
                  ? 'No se encontraron empresas para "${catalogViewModel.searchQuery}"'
                  : 'No hay empresas disponibles',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (catalogViewModel.searchQuery.isNotEmpty)
              const Text(
                'Intenta con otros términos de búsqueda',
                style: TextStyle(color: Colors.grey),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                catalogViewModel.clearFilters();
                _searchController.clear();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Limpiar Filtros'),
            ),
          ],
        ),
      ),
    );
  }
}