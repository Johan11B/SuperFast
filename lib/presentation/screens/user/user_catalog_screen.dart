// lib/presentation/screens/user/user_catalog_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../domain/entities/business_entity.dart';
import '../../viewmodels/catalog_viewmodel.dart';

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

    // Cargar datos después de que el widget esté en el árbol
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final catalogViewModel = context.read<CatalogViewModel>();
      catalogViewModel.loadCatalog();
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
            title: const Text('Catálogo de Productos'),
            floating: true,
            snap: true,
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Carrito - Próximamente')),
                  );
                },
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar productos, categorías o negocios...',
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
            _buildCatalogContent(catalogViewModel),
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
            ...catalogViewModel.categories.where((cat) => cat != 'Todas').map(
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
            Text('Cargando catálogo...'),
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
              'Error al cargar el catálogo',
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
              onPressed: () => catalogViewModel.loadCatalog(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  // 📦 CONTENIDO DEL CATÁLOGO
  Widget _buildCatalogContent(CatalogViewModel catalogViewModel) {
    if (catalogViewModel.products.isEmpty) {
      return _buildEmptyState(catalogViewModel);
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final product = catalogViewModel.products[index];
          final business = catalogViewModel.getBusinessById(product.businessId);

          return _buildProductCard(product, business, context);
        },
        childCount: catalogViewModel.products.length,
      ),
    );
  }

  // 🎯 TARJETA DE PRODUCTO
  Widget _buildProductCard(ProductEntity product, BusinessEntity? business, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: _buildProductImage(product),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              product.description.isNotEmpty
                  ? product.description
                  : 'Sin descripción',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            if (business != null)
              Text(
                business.name,
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                // PRECIO
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    product.formattedPrice,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // CATEGORÍA
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    product.category,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  ),
                ),
                // STOCK
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStockColor(product.stock),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    product.stockStatus,
                    style: TextStyle(
                      fontSize: 12,
                      color: product.stock > 0 ? Colors.white : Colors.red.shade100,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: product.canBeSold
            ? ElevatedButton(
          onPressed: () {
            _showAddToCartDialog(product, context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text('Agregar'),
        )
            : TextButton(
          onPressed: null,
          child: Text(
            'No disponible',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ),
        onTap: () {
          _showProductDetails(product, business, context);
        },
      ),
    );
  }

  // 🖼️ IMAGEN DEL PRODUCTO
  Widget _buildProductImage(ProductEntity product) {
    if (product.imageUrls.isNotEmpty) {
      return CircleAvatar(
        radius: 25,
        backgroundColor: Colors.transparent,
        backgroundImage: NetworkImage(product.imageUrls.first),
        onBackgroundImageError: (exception, stackTrace) {
          // Si hay error al cargar la imagen, mostrar placeholder
        },
      );
    } else {
      return CircleAvatar(
        radius: 25,
        backgroundColor: Colors.grey.shade300,
        child: Text(
          product.name[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  // 🎨 COLOR DEL STOCK
  Color _getStockColor(int stock) {
    if (stock == 0) return Colors.red;
    if (stock < 5) return Colors.orange;
    return Colors.green;
  }

  // 🛒 DIÁLOGO AGREGAR AL CARRITO
  void _showAddToCartDialog(ProductEntity product, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar al carrito'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Precio: ${product.formattedPrice}'),
            Text('Stock disponible: ${product.stock}'),
            const SizedBox(height: 16),
            const Text('¿Cuántas unidades deseas agregar?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implementar lógica del carrito
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product.name} agregado al carrito'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Agregar 1 unidad'),
          ),
        ],
      ),
    );
  }

  // 👁️ DETALLES DEL PRODUCTO
  void _showProductDetails(ProductEntity product, BusinessEntity? business, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles del Producto'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Imágenes
              if (product.imageUrls.isNotEmpty) ...[
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: product.imageUrls.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(product.imageUrls[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              _buildDetailItem('Producto:', product.name),
              _buildDetailItem('Descripción:',
                  product.description.isNotEmpty ? product.description : 'Sin descripción'),
              _buildDetailItem('Precio:', product.formattedPrice),
              _buildDetailItem('Categoría:', product.category),
              _buildDetailItem('Stock:', '${product.stock} unidades'),
              _buildDetailItem('Disponibilidad:',
                  product.canBeSold ? '🟢 Disponible' : '🔴 No disponible'),

              if (business != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Información del Negocio:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailItem('Negocio:', business.name),
                _buildDetailItem('Categoría:', business.category),
                _buildDetailItem('Dirección:', business.address),
                if (business.phone.isNotEmpty)
                  _buildDetailItem('Teléfono:', business.phone),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          if (product.canBeSold)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showAddToCartDialog(product, context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Agregar al Carrito'),
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

  // 📭 ESTADO VACÍO
  Widget _buildEmptyState(CatalogViewModel catalogViewModel) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              catalogViewModel.searchQuery.isNotEmpty
                  ? 'No se encontraron productos para "${catalogViewModel.searchQuery}"'
                  : 'No hay productos disponibles',
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