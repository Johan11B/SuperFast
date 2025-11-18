// lib/presentation/screens/user/business_products_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/business_entity.dart';
import '../../../domain/entities/product_entity.dart';
import '../../viewmodels/catalog_viewmodel.dart';

class BusinessProductsScreen extends StatefulWidget {
  final BusinessEntity business;

  const BusinessProductsScreen({super.key, required this.business});

  @override
  State<BusinessProductsScreen> createState() => _BusinessProductsScreenState();
}

class _BusinessProductsScreenState extends State<BusinessProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Todas';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogViewModel = context.watch<CatalogViewModel>();
    final businessProducts = catalogViewModel.getProductsByBusiness(widget.business.id);

    // Aplicar filtros locales
    final filteredProducts = _applyFilters(businessProducts);

    return Scaffold(
      appBar: AppBar(
        title: Text('Productos - ${widget.business.name}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // HEADER DE LA EMPRESA
          _buildBusinessHeader(),

          // BARRA DE BÚSQUEDA Y FILTROS
          _buildSearchAndFilters(),

          // LISTA DE PRODUCTOS
          Expanded(
            child: _buildProductsList(filteredProducts, catalogViewModel),
          ),
        ],
      ),
    );
  }

  // 🏢 HEADER DE LA EMPRESA
  Widget _buildBusinessHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          _buildBusinessImage(widget.business),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.business.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  widget.business.category,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔍 BÚSQUEDA Y FILTROS
  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar productos...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildCategoryFilter(),
        ],
      ),
    );
  }

  // 🏷️ FILTRO POR CATEGORÍA
  Widget _buildCategoryFilter() {
    final catalogViewModel = context.read<CatalogViewModel>();
    final businessProducts = catalogViewModel.getProductsByBusiness(widget.business.id);
    final categories = _getBusinessCategories(businessProducts);

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildCategoryChip('Todas'),
          const SizedBox(width: 8),
          ...categories.where((cat) => cat != 'Todas').map(
                (category) => Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: _buildCategoryChip(category),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    return ChoiceChip(
      label: Text(category),
      selected: _selectedCategory == category,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = category;
        });
      },
    );
  }

  List<String> _getBusinessCategories(List<ProductEntity> products) {
    final categories = products.map((p) => p.category).toSet().toList();
    categories.sort();
    return ['Todas', ...categories];
  }

  // 📦 LISTA DE PRODUCTOS
  Widget _buildProductsList(List<ProductEntity> products, CatalogViewModel catalogViewModel) {
    if (products.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductCard(product, catalogViewModel);
      },
    );
  }

  // 🎯 TARJETA DE PRODUCTO
  Widget _buildProductCard(ProductEntity product, CatalogViewModel catalogViewModel) {
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
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                // PRECIO
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    product.formattedPrice,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // CATEGORÍA
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    product.category,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.blue,
                    ),
                  ),
                ),
                // STOCK
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStockColor(product.stock),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    product.stockStatus,
                    style: TextStyle(
                      fontSize: 11,
                      color: product.stock > 0 ? Colors.white : Colors.red.shade100,
                      fontWeight: FontWeight.bold,
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          _showProductDetails(product, catalogViewModel);
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

  // 🏢 IMAGEN DE LA EMPRESA
  Widget _buildBusinessImage(BusinessEntity business) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          business.name[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // 🎨 COLOR DEL STOCK
  Color _getStockColor(int stock) {
    if (stock == 0) return Colors.red;
    if (stock < 5) return Colors.orange;
    return Colors.green;
  }

  // 🔍 APLICAR FILTROS
  List<ProductEntity> _applyFilters(List<ProductEntity> products) {
    List<ProductEntity> filtered = products;

    // Filtrar por categoría
    if (_selectedCategory != 'Todas') {
      filtered = filtered.where((p) => p.category == _selectedCategory).toList();
    }

    // Filtrar por búsqueda
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((product) {
        final nameMatch = product.name.toLowerCase().contains(_searchController.text.toLowerCase());
        final categoryMatch = product.category.toLowerCase().contains(_searchController.text.toLowerCase());
        final descriptionMatch = product.description.toLowerCase().contains(_searchController.text.toLowerCase());
        return nameMatch || categoryMatch || descriptionMatch;
      }).toList();
    }

    return filtered;
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
  void _showProductDetails(ProductEntity product, CatalogViewModel catalogViewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles del Producto'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
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
              _buildDetailItem('Descripción:', product.description.isNotEmpty ? product.description : 'Sin descripción'),
              _buildDetailItem('Precio:', product.formattedPrice),
              _buildDetailItem('Categoría:', product.category),
              _buildDetailItem('Stock:', '${product.stock} unidades'),
              _buildDetailItem('Disponibilidad:', product.canBeSold ? '🟢 Disponible' : '🔴 No disponible'),
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
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty
                ? 'No se encontraron productos para "${_searchController.text}"'
                : 'Esta empresa no tiene productos disponibles',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}