// business_orders_screen.dart - VERSIÓN COMPLETA CORREGIDA
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/order_viewmodel.dart';
import '../../viewmodels/business_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../domain/entities/order_entity.dart';
import '../../../domain/entities/business_entity.dart';


class BusinessOrdersScreen extends StatefulWidget {
  const BusinessOrdersScreen({super.key});

  @override
  State<BusinessOrdersScreen> createState() => _BusinessOrdersScreenState();
}

class _BusinessOrdersScreenState extends State<BusinessOrdersScreen> {
  String _selectedFilter = 'all'; // all, pending, confirmed, preparing, ready, delivered, cancelled

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final businessViewModel = context.read<BusinessViewModel>();
      final orderViewModel = context.read<OrderViewModel>();
      final business = businessViewModel.currentBusiness;

      if (business != null) {
        print('🔄 Cargando pedidos para negocio: ${business.id} - ${business.name}');
        orderViewModel.loadBusinessOrders(business.id);
      } else {
        print('❌ No se encontró información del negocio actual');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderViewModel = context.watch<OrderViewModel>();
    final businessViewModel = context.watch<BusinessViewModel>();
    final business = businessViewModel.currentBusiness;

    // DEBUG: Verificar datos
    print('🏢 Negocio actual: ${business?.name}');
    print('📦 Pedidos cargados: ${orderViewModel.businessOrders.length}');
    orderViewModel.businessOrders.forEach((order) {
      print('   - Pedido: ${order.id} | Negocio: ${order.businessId} | Estado: ${order.status}');
    });

    final filteredOrders = _filterOrders(orderViewModel.businessOrders);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Pedidos'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ESTADÍSTICAS RÁPIDAS
          _buildQuickStats(orderViewModel, business?.id ?? ''),

          // FILTROS
          _buildFilterChips(),

          // CONTENIDO
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                if (business != null) {
                  await orderViewModel.refreshBusinessOrders(business.id);
                }
              },
              child: _buildContent(orderViewModel, filteredOrders, business),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(OrderViewModel orderViewModel, String businessId) {
    final stats = orderViewModel.getBusinessOrderStats(businessId);

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.orange.withOpacity(0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', stats['totalOrders'].toString(), Colors.blue),
          _buildStatItem('Pendientes', stats['pendingOrders'].toString(), Colors.orange),
          _buildStatItem('En curso', '${stats['confirmedOrders']! + stats['preparingOrders']!}', Colors.purple),
          _buildStatItem('Entregados', stats['deliveredOrders'].toString(), Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
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

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Todos', 'all'),
            const SizedBox(width: 8),
            _buildFilterChip('Pendientes', 'pending'),
            const SizedBox(width: 8),
            _buildFilterChip('Confirmados', 'confirmed'),
            const SizedBox(width: 8),
            _buildFilterChip('En preparación', 'preparing'),
            const SizedBox(width: 8),
            _buildFilterChip('Listos', 'ready'),
            const SizedBox(width: 8),
            _buildFilterChip('Entregados', 'delivered'),
            const SizedBox(width: 8),
            _buildFilterChip('Cancelados', 'cancelled'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedFilter == value,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
    );
  }

  Widget _buildContent(OrderViewModel orderViewModel, List<OrderEntity> orders, BusinessEntity? business) {
    if (orderViewModel.isLoadingBusinessOrders) {
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
            const Text(
              'Error al cargar pedidos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              orderViewModel.errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOrders,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _selectedFilter == 'all'
                  ? 'No hay pedidos'
                  : 'No hay pedidos ${_getFilterText(_selectedFilter)}',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Los pedidos de tus clientes aparecerán aquí',
              style: TextStyle(color: Colors.grey),
            ),
            if (business == null) ...[
              const SizedBox(height: 16),
              const Text(
                '⚠️ No se detectó información del negocio',
                style: TextStyle(color: Colors.orange),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
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
                        order.userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pedido #${order.id.substring(order.id.length - 6)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
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

            if (order.userNote != null && order.userNote!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.userNote!,
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // BOTONES DE ACCIÓN PARA EL NEGOCIO
            _buildBusinessActions(order),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessActions(OrderEntity order) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              _showOrderDetails(order);
            },
            child: const Text('Ver Detalles'),
          ),
        ),
        const SizedBox(width: 8),
        if (order.isPending) ...[
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                _updateOrderStatus(order, 'confirmed');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Aceptar'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                _rejectOrder(order);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Rechazar'),
            ),
          ),
        ],
        if (order.isConfirmed) ...[
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                _updateOrderStatus(order, 'preparing');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Preparar'),
            ),
          ),
        ],
        if (order.isPreparing) ...[
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                _updateOrderStatus(order, 'ready');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Listo'),
            ),
          ),
        ],
        if (order.isReady) ...[
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                _updateOrderStatus(order, 'delivered');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: const Text('Entregado'),
            ),
          ),
        ],
      ],
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
              _buildDetailItem('Cliente:', order.userName),
              _buildDetailItem('Estado:', order.statusDisplayText),
              _buildDetailItem('Fecha:', order.formattedCreatedAt),
              _buildDetailItem('Dirección:', order.deliveryAddress ?? 'No especificada'),
              if (order.userNote != null) _buildDetailItem('Notas del cliente:', order.userNote!),

              const SizedBox(height: 16),
              const Text(
                'Productos:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${item.productName} x${item.quantity}'),
                          if (item.notes != null && item.notes!.isNotEmpty)
                            Text(
                              'Nota: ${item.notes!}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                        ],
                      ),
                    ),
                    Text('\$${(item.totalPrice).toStringAsFixed(2)}'),
                  ],
                ),
              )),

              const SizedBox(height: 16),
              const Divider(),
              _buildDetailItem('Subtotal:', '\$${order.subtotal.toStringAsFixed(2)}'),
              _buildDetailItem('Envío:', '\$${order.deliveryFee.toStringAsFixed(2)}'),
              _buildDetailItem('Impuestos:', '\$${order.tax.toStringAsFixed(2)}'),
              _buildDetailItem(
                'TOTAL:',
                '\$${order.totalAmount.toStringAsFixed(2)}',
                isTotal: true,
              ),
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
    }
  }

  void _rejectOrder(OrderEntity order) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Pedido'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Estás seguro de que quieres rechazar este pedido?'),
            const SizedBox(height: 16),
            const Text('Motivo (opcional):'),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Ej: Producto no disponible, horario cerrado...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final orderViewModel = context.read<OrderViewModel>();
              final success = await orderViewModel.updateOrderStatus(order.id, 'cancelled');

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pedido rechazado'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  List<OrderEntity> _filterOrders(List<OrderEntity> orders) {
    switch (_selectedFilter) {
      case 'pending':
        return orders.where((order) => order.isPending).toList();
      case 'confirmed':
        return orders.where((order) => order.isConfirmed).toList();
      case 'preparing':
        return orders.where((order) => order.isPreparing).toList();
      case 'ready':
        return orders.where((order) => order.isReady).toList();
      case 'delivered':
        return orders.where((order) => order.isDelivered).toList();
      case 'cancelled':
        return orders.where((order) => order.isCancelled).toList();
      default:
        return orders;
    }
  }

  String _getFilterText(String filter) {
    switch (filter) {
      case 'pending': return 'pendientes';
      case 'confirmed': return 'confirmados';
      case 'preparing': return 'en preparación';
      case 'ready': return 'listos';
      case 'delivered': return 'entregados';
      case 'cancelled': return 'cancelados';
      default: return '';
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'confirmed': return 'confirmado';
      case 'preparing': return 'en preparación';
      case 'ready': return 'marcado como listo';
      case 'delivered': return 'marcado como entregado';
      default: return 'actualizado';
    }
  }
}