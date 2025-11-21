// admin_orders_screen.dart - VERSIÓN CORREGIDA
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/order_viewmodel.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../../domain/entities/order_entity.dart';
import '../../../domain/entities/business_entity.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedView = 'all'; // all, by_business, pending, active, completed
  String _selectedBusiness = 'all';
  bool _initialLoadCompleted = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadInitialData();
  }

  void _loadInitialData() {
    if (!_initialLoadCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final orderViewModel = context.read<OrderViewModel>();
        final adminViewModel = context.read<AdminViewModel>();

        orderViewModel.loadAllOrders();
        adminViewModel.loadBusinesses();

        _initialLoadCompleted = true;
      });
    }
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
    final orderViewModel = context.watch<OrderViewModel>();
    final adminViewModel = context.watch<AdminViewModel>();

    final orders = _filterAndGroupOrders(orderViewModel.allOrders, adminViewModel.businesses);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      floatingActionButton: FloatingActionButton(
        onPressed: orderViewModel.isLoadingAllOrders
            ? null
            : () {
          orderViewModel.loadAllOrders();
          adminViewModel.loadBusinesses();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Datos actualizados')),
          );
        },
        tooltip: 'Actualizar',
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        mini: true,
        child: const Icon(Icons.refresh),
      ),
      body: Column(
        children: [
          // FILTROS Y BÚSQUEDA
          _buildFiltersSection(adminViewModel.businesses),

          // ESTADÍSTICAS RÁPIDAS
          _buildQuickStats(orderViewModel),

          // CONTENIDO PRINCIPAL
          Expanded(
            child: _buildContent(orderViewModel, adminViewModel, orders),
          ),
        ],
      ),
    );
  }


  void _handleViewChange(String value) {
    setState(() {
      _selectedView = value;
    });
  }

  Widget _buildFiltersSection(List<BusinessEntity> businesses) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // BARRA DE BÚSQUEDA
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por ID, cliente, empresa...',
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

          // FILTROS DE VISTA
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildViewChip('Todos', 'all', Icons.list),
                const SizedBox(width: 8),
                _buildViewChip('Por Empresa', 'by_business', Icons.business),
                const SizedBox(width: 8),
                _buildViewChip('Pendientes', 'pending', Icons.pending),
                const SizedBox(width: 8),
                _buildViewChip('En Curso', 'active', Icons.timer),
                const SizedBox(width: 8),
                _buildViewChip('Completados', 'completed', Icons.check_circle),
              ],
            ),
          ),

          // FILTRO POR EMPRESA (solo cuando se selecciona vista por empresa)
          if (_selectedView == 'by_business') ...[
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Filtrar por empresa:',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildBusinessChip('Todas', 'all', Icons.business_center),
                  const SizedBox(width: 8),
                  ...businesses.take(5).map((business) =>
                      _buildBusinessChip(
                          business.name.length > 15 ? '${business.name.substring(0, 15)}...' : business.name,
                          business.id,
                          Icons.store
                      )
                  ),
                  if (businesses.length > 5)
                    _buildBusinessChip('+${businesses.length - 5} más', 'more', Icons.more_horiz),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildViewChip(String label, String value, IconData icon) {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: _selectedView == value,
      onSelected: (selected) {
        setState(() {
          _selectedView = value;
        });
      },
    );
  }

  Widget _buildBusinessChip(String label, String value, IconData icon) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: _selectedBusiness == value,
      onSelected: (selected) {
        if (value == 'more') {
          _showAllBusinessesDialog();
        } else {
          setState(() {
            _selectedBusiness = value;
          });
        }
      },
    );
  }

  void _showAllBusinessesDialog() {
    final adminViewModel = context.read<AdminViewModel>();
    final businesses = adminViewModel.businesses;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Empresa'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: businesses.length,
            itemBuilder: (context, index) {
              final business = businesses[index];
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: business.logoUrl != null && business.logoUrl!.isNotEmpty
                        ? DecorationImage(
                      image: NetworkImage(business.logoUrl!),
                      fit: BoxFit.cover,
                    )
                        : null,
                    color: business.logoUrl == null ? Colors.blue.shade100 : null,
                  ),
                  child: business.logoUrl == null
                      ? Center(
                    child: Text(
                      business.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                      : null,
                ),
                title: Text(business.name),
                subtitle: Text(business.category),
                trailing: _selectedBusiness == business.id
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedBusiness = business.id;
                  });
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(OrderViewModel orderViewModel) {
    final stats = orderViewModel.getAdminOrderStats();
    final statusStats = stats['statusStats'] ?? {};

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.withOpacity(0.05),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickStatItem('Total', stats['totalOrders'].toString(), Icons.shopping_cart, Colors.blue),
              _buildQuickStatItem('Pendientes', statusStats['pending']?.toString() ?? '0', Icons.pending, Colors.orange),
              _buildQuickStatItem('En Curso', '${(statusStats['confirmed'] ?? 0) + (statusStats['preparing'] ?? 0)}', Icons.timer, Colors.purple),
              _buildQuickStatItem('Completados', statusStats['delivered']?.toString() ?? '0', Icons.check_circle, Colors.green),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildContent(OrderViewModel orderViewModel, AdminViewModel adminViewModel, Map<String, List<OrderEntity>> groupedOrders) {
    if (orderViewModel.isLoadingAllOrders && orderViewModel.allOrders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando pedidos...'),
          ],
        ),
      );
    }

    if (orderViewModel.errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                orderViewModel.errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => orderViewModel.loadAllOrders(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (orderViewModel.allOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No hay pedidos en el sistema',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Los pedidos aparecerán aquí cuando los clientes realicen compras',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await orderViewModel.refreshAllOrders();
        await adminViewModel.loadBusinesses();
      },
      child: _selectedView == 'by_business'
          ? _buildBusinessGroupedView(groupedOrders, adminViewModel.businesses)
          : _buildAllOrdersView(orderViewModel.allOrders),
    );
  }

  Widget _buildBusinessGroupedView(Map<String, List<OrderEntity>> groupedOrders, List<BusinessEntity> businesses) {
    final entries = groupedOrders.entries.where((entry) => entry.value.isNotEmpty).toList();

    if (entries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_list, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No hay pedidos que coincidan con los filtros',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final businessId = entries[index].key;
        final businessOrders = entries[index].value;
        final business = businesses.firstWhere((b) => b.id == businessId, orElse: () => BusinessEntity(
            id: '', ownerId: '', name: 'Empresa no encontrada', email: '',
            category: '', address: '', phone: '', status: 'approved',
            rating: 0, reviewCount: 0, createdAt: DateTime.now()
        ));

        return _buildBusinessOrderGroup(business, businessOrders);
      },
    );
  }

  Widget _buildBusinessOrderGroup(BusinessEntity business, List<OrderEntity> orders) {
    final pendingOrders = orders.where((o) => o.isPending).toList();
    final activeOrders = orders.where((o) => o.isActive && !o.isPending).toList();
    final completedOrders = orders.where((o) => o.isDelivered).toList();
    final cancelledOrders = orders.where((o) => o.isCancelled).toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER DE LA EMPRESA
            Row(
              children: [
                // Logo de la empresa
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: business.logoUrl != null && business.logoUrl!.isNotEmpty
                        ? DecorationImage(
                      image: NetworkImage(business.logoUrl!),
                      fit: BoxFit.cover,
                    )
                        : null,
                    color: business.logoUrl == null ? Colors.blue.shade100 : null,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: business.logoUrl == null
                      ? Center(
                    child: Text(
                      business.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        business.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        business.category,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        business.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getBusinessStatusColor(business.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _getBusinessStatusColor(business.status)),
                      ),
                      child: Text(
                        _getBusinessStatusText(business.status),
                        style: TextStyle(
                          fontSize: 10,
                          color: _getBusinessStatusColor(business.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${orders.length} pedidos',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$${_calculateBusinessTotal(orders).toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ESTADÍSTICAS DE LA EMPRESA
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBusinessStatItem('Pendientes', pendingOrders.length, Colors.orange, Icons.pending),
                  _buildBusinessStatItem('En Curso', activeOrders.length, Colors.purple, Icons.timer),
                  _buildBusinessStatItem('Completados', completedOrders.length, Colors.green, Icons.check_circle),
                  _buildBusinessStatItem('Cancelados', cancelledOrders.length, Colors.red, Icons.cancel),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // PEDIDOS RECIENTES (máximo 3)
            if (orders.isNotEmpty) ...[
              const Text(
                'Pedidos Recientes:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ...orders.take(3).map((order) => _buildCompactOrderItem(order)),
              if (orders.length > 3)
                Center(
                  child: TextButton(
                    onPressed: () {
                      _showAllBusinessOrders(business, orders);
                    },
                    child: Text('Ver todos los ${orders.length} pedidos →'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessStatItem(String label, int count, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildCompactOrderItem(OrderEntity order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: order.statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Pedido #${order.id.substring(order.id.length - 6)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Text(
                      '\$${order.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  order.userName,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 10, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      order.formattedCreatedAt,
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: order.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        order.statusDisplayText,
                        style: TextStyle(
                          fontSize: 10,
                          color: order.statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.visibility, size: 16),
            onPressed: () => _showOrderDetails(order),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildAllOrdersView(List<OrderEntity> orders) {
    final filteredOrders = _filterOrders(orders);

    if (filteredOrders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_list, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No hay pedidos que coincidan con los filtros',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(OrderEntity order) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pedido #${order.id.substring(order.id.length - 6)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cliente: ${order.userName}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        'Empresa: ${order.businessName}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: order.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: order.statusColor),
                      ),
                      child: Text(
                        order.statusDisplayText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: order.statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${order.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // PRODUCTOS
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${order.items.length} ${order.items.length == 1 ? 'producto' : 'productos'}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                ...order.items.take(2).map((item) => Text(
                  '• ${item.productName} x${item.quantity}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                )),
                if (order.items.length > 2)
                  Text(
                    '... y ${order.items.length - 2} más',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // INFORMACIÓN ADICIONAL
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  order.formattedCreatedAt,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const Spacer(),
                if (order.paymentMethod != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Pago: ${order.paymentMethod}',
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
              ],
            ),

            if (order.userNote != null && order.userNote!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.orange.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.userNote!,
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // BOTONES DE ACCIÓN
            _buildAdminActions(order),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminActions(OrderEntity order) {
    final availableTransitions = _getAvailableTransitions(order.status);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton(
          onPressed: () => _showOrderDetails(order),
          child: const Text('Ver Detalles'),
        ),
        ...availableTransitions.map((transition) => ElevatedButton(
          onPressed: () => _updateOrderStatus(order, transition['value'] as String),
          style: ElevatedButton.styleFrom(
            backgroundColor: transition['color'] as Color,
            foregroundColor: Colors.white,
          ),
          child: Text(transition['label'] as String),
        )),
        if (order.isActive)
          ElevatedButton(
            onPressed: () => _cancelOrder(order),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancelar'),
          ),
      ],
    );
  }

  List<Map<String, Object>> _getAvailableTransitions(String currentStatus) {
    const transitions = {
      'pending': [
        {'value': 'confirmed', 'label': 'Confirmar', 'color': Colors.blue},
      ],
      'confirmed': [
        {'value': 'preparing', 'label': 'Preparar', 'color': Colors.purple},
      ],
      'preparing': [
        {'value': 'ready', 'label': 'Marcar Listo', 'color': Colors.green},
      ],
      'ready': [
        {'value': 'delivered', 'label': 'Entregado', 'color': Colors.teal},
      ],
    };

    return transitions[currentStatus] ?? [];
  }

  Map<String, List<OrderEntity>> _filterAndGroupOrders(List<OrderEntity> orders, List<BusinessEntity> businesses) {
    List<OrderEntity> filtered = orders;

    // Aplicar filtros de búsqueda
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((order) {
        return order.id.toLowerCase().contains(query) ||
            order.userName.toLowerCase().contains(query) ||
            order.businessName.toLowerCase().contains(query) ||
            (order.userNote?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Aplicar filtros de vista
    switch (_selectedView) {
      case 'pending':
        filtered = filtered.where((order) => order.isPending).toList();
        break;
      case 'active':
        filtered = filtered.where((order) => order.isActive && !order.isPending).toList();
        break;
      case 'completed':
        filtered = filtered.where((order) => order.isDelivered).toList();
        break;
    }

    // Agrupar por empresa
    final Map<String, List<OrderEntity>> grouped = {};
    for (final order in filtered) {
      if (!grouped.containsKey(order.businessId)) {
        grouped[order.businessId] = [];
      }
      grouped[order.businessId]!.add(order);
    }

    // Filtrar por empresa específica si está seleccionada
    if (_selectedBusiness != 'all') {
      final filteredGroup = <String, List<OrderEntity>>{};
      if (grouped.containsKey(_selectedBusiness)) {
        filteredGroup[_selectedBusiness] = grouped[_selectedBusiness]!;
      }
      return filteredGroup;
    }

    return grouped;
  }

  List<OrderEntity> _filterOrders(List<OrderEntity> orders) {
    List<OrderEntity> filtered = orders;

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((order) {
        return order.id.toLowerCase().contains(query) ||
            order.userName.toLowerCase().contains(query) ||
            order.businessName.toLowerCase().contains(query) ||
            (order.userNote?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    switch (_selectedView) {
      case 'pending':
        filtered = filtered.where((order) => order.isPending).toList();
        break;
      case 'active':
        filtered = filtered.where((order) => order.isActive && !order.isPending).toList();
        break;
      case 'completed':
        filtered = filtered.where((order) => order.isDelivered).toList();
        break;
    }

    return filtered;
  }

  double _calculateBusinessTotal(List<OrderEntity> orders) {
    return orders.fold(0.0, (sum, order) => sum + order.totalAmount);
  }

  Color _getBusinessStatusColor(String status) {
    switch (status) {
      case 'approved': return Colors.green;
      case 'pending': return Colors.orange;
      case 'suspended': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getBusinessStatusText(String status) {
    switch (status) {
      case 'approved': return 'Aprobada';
      case 'pending': return 'Pendiente';
      case 'suspended': return 'Suspendida';
      default: return status;
    }
  }

  void _showAllBusinessOrders(BusinessEntity business, List<OrderEntity> orders) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Todos los pedidos - ${business.name}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _buildCompactOrderItem(order);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(OrderEntity order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles del Pedido'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('ID del Pedido:', order.id),
              _buildDetailItem('Cliente:', order.userName),
              _buildDetailItem('Empresa:', order.businessName),
              _buildDetailItem('Estado:', order.statusDisplayText),
              _buildDetailItem('Fecha:', order.formattedCreatedAt),
              _buildDetailItem('Dirección:', order.deliveryAddress ?? 'No especificada'),
              _buildDetailItem('Método de Pago:', order.paymentMethod ?? 'No especificado'),
              _buildDetailItem('Estado de Pago:', order.paymentStatus ?? 'Pendiente'),
              if (order.userNote != null) _buildDetailItem('Nota del Cliente:', order.userNote!),

              const SizedBox(height: 16),
              const Text(
                'Productos:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.productName,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text('x${item.quantity}'),
                        ],
                      ),
                      Text('Precio unitario: \$${item.price.toStringAsFixed(2)}'),
                      Text('Total: \$${item.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (item.notes != null && item.notes!.isNotEmpty)
                        Text('Nota: ${item.notes!}', style: TextStyle(color: Colors.blue.shade600)),
                    ],
                  ),
                ),
              )),

              const SizedBox(height: 16),
              const Divider(),
              _buildDetailItem('Subtotal:', '\$${order.subtotal.toStringAsFixed(2)}'),
              _buildDetailItem('Envío:', '\$${order.deliveryFee.toStringAsFixed(2)}'),
              _buildDetailItem('Impuestos:', '\$${order.tax.toStringAsFixed(2)}'),
              _buildDetailItem('TOTAL:', '\$${order.totalAmount.toStringAsFixed(2)}', isTotal: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? Colors.green : Colors.black,
                fontSize: isTotal ? 16 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateOrderStatus(OrderEntity order, String newStatus) async {
    final orderViewModel = context.read<OrderViewModel>();
    final success = await orderViewModel.updateOrderStatus(order.id, newStatus);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pedido ${_getStatusText(newStatus)}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al actualizar el pedido'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _cancelOrder(OrderEntity order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Pedido'),
        content: const Text('¿Estás seguro de que quieres cancelar este pedido?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final orderViewModel = context.read<OrderViewModel>();
              final success = await orderViewModel.updateOrderStatus(order.id, 'cancelled');

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pedido cancelado'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'confirmed': return 'confirmado';
      case 'preparing': return 'en preparación';
      case 'ready': return 'marcado como listo';
      case 'delivered': return 'marcado como entregado';
      case 'cancelled': return 'cancelado';
      default: return 'actualizado';
    }
  }
}