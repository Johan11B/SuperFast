// user_orders_screen.dart - VERSIÓN CORREGIDA
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/order_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../domain/entities/order_entity.dart';

class UserOrdersScreen extends StatefulWidget {
  const UserOrdersScreen({super.key});

  @override
  State<UserOrdersScreen> createState() => _UserOrdersScreenState();
}

class _UserOrdersScreenState extends State<UserOrdersScreen> {
  String _selectedFilter = 'all'; // all, pending, delivered, cancelled

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = context.read<AuthViewModel>();
      final orderViewModel = context.read<OrderViewModel>();
      final user = authViewModel.currentUser;

      if (user != null) {
        orderViewModel.loadUserOrders(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderViewModel = context.watch<OrderViewModel>();
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.currentUser;

    final filteredOrders = _filterOrders(orderViewModel.userOrders);

    return Scaffold(
      body: Column(
        children: [
          // FILTROS
          _buildFilterChips(),

          // CONTENIDO
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                if (user != null) {
                  await orderViewModel.loadUserOrders(user.id);
                }
              },
              child: _buildContent(orderViewModel, filteredOrders),
            ),
          ),
        ],
      ),
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

  Widget _buildContent(OrderViewModel orderViewModel, List<OrderEntity> orders) {
    if (orderViewModel.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando tus pedidos...'),
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
            const Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _selectedFilter == 'all'
                  ? 'No tienes pedidos'
                  : 'No hay pedidos ${_getFilterText(_selectedFilter)}',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Realiza tu primer pedido desde el catálogo',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // SOLUCIÓN CORREGIDA: Usar Navigator para volver atrás
                // Esto asume que el catálogo es la primera pestaña (índice 0)
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Ir al Catálogo'),
            ),
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
                        order.businessName,
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

            const SizedBox(height: 8),

            // BOTONES DE ACCIÓN
            if (order.isActive) _buildOrderActions(order),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderActions(OrderEntity order) {
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
        if (order.isPending)
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                _cancelOrder(order);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancelar'),
            ),
          ),
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
              _buildDetailItem('Negocio:', order.businessName),
              _buildDetailItem('Estado:', order.statusDisplayText),
              _buildDetailItem('Fecha:', order.formattedCreatedAt),
              _buildDetailItem('Dirección:', order.deliveryAddress ?? 'No especificada'),
              if (order.userNote != null) _buildDetailItem('Notas:', order.userNote!),

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
                      child: Text('${item.productName} x${item.quantity}'),
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
            width: 80,
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
                    content: Text('Pedido cancelado exitosamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sí, cancelar'),
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
}