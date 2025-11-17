// lib/presentation/screens/business/business_panel.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../settings/ajustes_page.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/business_viewmodel.dart';
import '../../../domain/entities/product_entity.dart';

class BusinessPanel extends StatefulWidget {
  const BusinessPanel({super.key});

  @override
  State<BusinessPanel> createState() => _BusinessPanelState();
}

class _BusinessPanelState extends State<BusinessPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color primaryColor = Colors.orange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Cargar datos de la empresa al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBusinessData();
    });
  }

  void _loadBusinessData() {
    final authViewModel = context.read<AuthViewModel>();
    final businessViewModel = context.read<BusinessViewModel>();

    final user = authViewModel.currentUser;
    if (user != null) {
      print('🔄 Cargando datos de empresa para usuario: ${user.id}');
      businessViewModel.loadCurrentBusiness(user.id);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.read<AuthViewModel>();
    final businessViewModel = context.watch<BusinessViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: _buildAppBarTitle(businessViewModel),
        backgroundColor: primaryColor,
        actions: [
          // Botón de Ajustes
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AjustesPage(
                    userRole: 'business',
                    primaryColor: primaryColor,
                  ),
                ),
              );
            },
            tooltip: 'Ajustes',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          indicatorColor: Colors.white,
          tabs: const [
            Tab(
              icon: Icon(Icons.dashboard),
              text: 'Dashboard',
            ),
            Tab(
              icon: Icon(Icons.inventory),
              text: 'Productos',
            ),
            Tab(
              icon: Icon(Icons.shopping_cart),
              text: 'Pedidos',
            ),
            Tab(
              icon: Icon(Icons.analytics),
              text: 'Estadísticas',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pestaña 1: Dashboard
          _buildDashboardTab(businessViewModel),

          // Pestaña 2: Productos
          _buildProductsTab(businessViewModel),

          // Pestaña 3: Pedidos (Próximamente)
          _buildOrdersTab(),

          // Pestaña 4: Estadísticas (Próximamente)
          _buildStatisticsTab(),
        ],
      ),

      // Botón flotante para agregar productos (solo en pestaña de productos)
      floatingActionButton: _buildFloatingActionButton(),

      // Indicador de carga global
      persistentFooterButtons: businessViewModel.isLoading
          ? [
        const LinearProgressIndicator(),
      ]
          : null,
    );
  }

  Widget _buildAppBarTitle(BusinessViewModel businessViewModel) {
    if (businessViewModel.currentBusiness != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Panel de Empresa',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            businessViewModel.currentBusiness!.name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          ),
        ],
      );
    }

    return const Text('Panel de Empresa - SuperFast');
  }

  Widget _buildDashboardTab(BusinessViewModel businessViewModel) {
    final stats = businessViewModel.getBusinessStats();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta de bienvenida
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '¡Bienvenido a tu Panel!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    businessViewModel.currentBusiness?.name ?? 'Tu Empresa',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  // Estadísticas rápidas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Productos', '${stats['totalProducts']}'),
                      _buildStatItem('Disponibles', '${stats['availableProducts']}'),
                      _buildStatItem('Categorías', '${stats['categoriesCount']}'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Alertas importantes
          if (businessViewModel.hasLowStockProducts)
            _buildAlertCard(
              'Productos con stock bajo',
              'Tienes ${stats['lowStockProducts']} productos con stock bajo',
              Colors.orange,
            ),

          if (businessViewModel.hasOutOfStockProducts)
            _buildAlertCard(
              'Productos sin stock',
              'Tienes ${stats['outOfStockProducts']} productos sin stock',
              Colors.red,
            ),

          // Acciones rápidas
          const SizedBox(height: 16),
          const Text(
            'Acciones Rápidas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildActionChip('Agregar Producto', Icons.add, () {
                _tabController.animateTo(1); // Ir a pestaña de productos
              }),
              _buildActionChip('Ver Pedidos', Icons.shopping_cart, () {
                _tabController.animateTo(2); // Ir a pestaña de pedidos
              }),
              _buildActionChip('Actualizar Stock', Icons.inventory, () {
                _tabController.animateTo(1); // Ir a pestaña de productos
              }),
            ],
          ),

          // Espacio expandible
          const Expanded(child: SizedBox()),

          // Información del negocio
          if (businessViewModel.currentBusiness != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Información de tu Negocio',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('📍 ${businessViewModel.currentBusiness!.address}'),
                    Text('📞 ${businessViewModel.currentBusiness!.phone}'),
                    Text('📧 ${businessViewModel.currentBusiness!.email}'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductsTab(BusinessViewModel businessViewModel) {
    if (businessViewModel.isLoadingProducts) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando productos...'),
          ],
        ),
      );
    }

    if (businessViewModel.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No hay productos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Agrega tu primer producto para comenzar'),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                _showAddProductDialog(context, businessViewModel);
              },
              icon: const Icon(Icons.add),
              label: const Text('Agregar Primer Producto'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar productos...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: businessViewModel.updateSearchQuery,
          ),
          const SizedBox(height: 16),

          // Filtros
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('Todos', 'Todas', businessViewModel),
                const SizedBox(width: 8),
                ...businessViewModel.categories.where((cat) => cat != 'Todas').map(
                      (category) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: _buildFilterChip(category, category, businessViewModel),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Lista de productos
          Expanded(
            child: ListView.builder(
              itemCount: businessViewModel.filteredProducts.length,
              itemBuilder: (context, index) {
                final product = businessViewModel.filteredProducts[index];
                return _buildProductCard(product, businessViewModel);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductEntity product, BusinessViewModel businessViewModel) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: product.isAvailable ? Colors.green : Colors.grey,
          child: Text(
            product.name[0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          product.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: product.isAvailable ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.description.isNotEmpty ? product.description : product.category),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStockColor(product.stock),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Stock: ${product.stock}',
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              product.isAvailable ? '🟢 Disponible' : '🔴 No disponible',
              style: TextStyle(
                fontSize: 12,
                color: product.isAvailable ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleProductAction(value, product, businessViewModel),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            PopupMenuItem(
              value: product.isAvailable ? 'disable' : 'enable',
              child: Row(
                children: [
                  Icon(
                    product.isAvailable ? Icons.pause : Icons.play_arrow,
                    size: 20,
                    color: product.isAvailable ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(product.isAvailable ? 'Desactivar' : 'Activar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Gestión de Pedidos',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Próximamente...'),
          SizedBox(height: 16),
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Estamos trabajando en esta funcionalidad'),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Estadísticas y Reportes',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Próximamente...'),
          SizedBox(height: 16),
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Estamos trabajando en esta funcionalidad'),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Consumer<BusinessViewModel>(
      builder: (context, businessViewModel, child) {
        // Mostrar FAB solo en la pestaña de productos
        if (_tabController.index != 1) {
          return const SizedBox.shrink();
        }

        return FloatingActionButton(
          heroTag: 'business_products_fab',
          onPressed: () {
            _showAddProductDialog(context, businessViewModel);
          },
          backgroundColor: primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        );
      },
    );
  }

  void _showAddProductDialog(BuildContext context, BusinessViewModel businessViewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Producto'),
        content: const Text('Esta funcionalidad estará disponible en la próxima actualización.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleProductAction(String action, ProductEntity product, BusinessViewModel businessViewModel) {
    switch (action) {
      case 'edit':
        _showEditProductDialog(context, product, businessViewModel);
        break;
      case 'enable':
        businessViewModel.toggleProductAvailability(product.id, true);
        break;
      case 'disable':
        businessViewModel.toggleProductAvailability(product.id, false);
        break;
      case 'delete':
        _showDeleteProductDialog(context, product, businessViewModel);
        break;
    }
  }

  void _showEditProductDialog(BuildContext context, ProductEntity product, BusinessViewModel businessViewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Producto'),
        content: const Text('Esta funcionalidad estará disponible en la próxima actualización.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDeleteProductDialog(BuildContext context, ProductEntity product, BusinessViewModel businessViewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text('¿Estás seguro de que quieres eliminar "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              businessViewModel.deleteProduct(product.id);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // ========== WIDGETS AUXILIARES ==========

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildAlertCard(String title, String message, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(Icons.warning, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    message,
                    style: TextStyle(color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip(String label, IconData icon, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: primaryColor.withOpacity(0.1),
    );
  }

  Widget _buildFilterChip(String label, String value, BusinessViewModel viewModel) {
    return FilterChip(
      label: Text(label),
      selected: viewModel.selectedCategory == value,
      onSelected: (selected) {
        viewModel.updateSelectedCategory(value);
      },
    );
  }

  Color _getStockColor(int stock) {
    if (stock == 0) return Colors.red;
    if (stock < 5) return Colors.orange;
    return Colors.green;
  }
}