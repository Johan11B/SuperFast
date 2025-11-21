// business_statistics_screen.dart - VERSIÓN COMPLETA CORREGIDA
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/order_viewmodel.dart';
import '../../viewmodels/business_viewmodel.dart';
import '../../../domain/entities/order_entity.dart';

class BusinessStatisticsScreen extends StatefulWidget {
  const BusinessStatisticsScreen({super.key});

  @override
  State<BusinessStatisticsScreen> createState() => _BusinessStatisticsScreenState();
}

class _BusinessStatisticsScreenState extends State<BusinessStatisticsScreen> {
  String _selectedTimeRange = 'week'; // week, month, year

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final businessViewModel = context.read<BusinessViewModel>();
      final orderViewModel = context.read<OrderViewModel>();
      final business = businessViewModel.currentBusiness;

      if (business != null) {
        orderViewModel.loadBusinessOrders(business.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderViewModel = context.watch<OrderViewModel>();
    final businessViewModel = context.watch<BusinessViewModel>();
    final business = businessViewModel.currentBusiness;

    final stats = business != null
        ? orderViewModel.getBusinessOrderStats(business.id)
        : <String, dynamic>{}; // ✅ CORREGIDO: Especificar tipo Map<String, dynamic>

    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      appBar: AppBar(
        title: const Text('Estadísticas del Negocio'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (business != null) {
            await orderViewModel.refreshBusinessOrders(business.id);
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SELECTOR DE RANGO DE TIEMPO
              _buildTimeRangeSelector(),

              const SizedBox(height: 20),

              // ESTADÍSTICAS PRINCIPALES
              _buildMainStats(stats),

              const SizedBox(height: 20),

              // DISTRIBUCIÓN DE ESTADOS
              _buildStatusDistribution(stats),

              const SizedBox(height: 20),

              // INFORMACIÓN DETALLADA
              _buildDetailedInfo(orderViewModel, business?.id ?? ''),

              const SizedBox(height: 20),

              // PEDIDOS RECIENTES
              _buildRecentOrders(orderViewModel, business?.id ?? ''),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Período de Tiempo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimeRangeChip('Esta semana', 'week'),
                _buildTimeRangeChip('Este mes', 'month'),
                _buildTimeRangeChip('Este año', 'year'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedTimeRange == value,
      onSelected: (selected) {
        setState(() {
          _selectedTimeRange = value;
        });
      },
    );
  }

  Widget _buildMainStats(Map<String, dynamic> stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // ✅ CORREGIDO: Nombre correcto
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(
          'Pedidos Totales',
          stats['totalOrders']?.toString() ?? '0',
          Colors.blue,
          Icons.shopping_cart,
        ),
        _buildStatCard(
          'Ingresos Totales',
          '\$${stats['totalRevenue']?.toStringAsFixed(2) ?? '0'}',
          Colors.green,
          Icons.attach_money,
        ),
        _buildStatCard(
          'Tasa de Finalización',
          '${stats['completionRate']?.toStringAsFixed(1) ?? '0'}%',
          Colors.teal,
          Icons.check_circle,
        ),
        _buildStatCard(
          'Pedido Promedio',
          '\$${stats['averageOrderValue']?.toStringAsFixed(2) ?? '0'}',
          Colors.purple,
          Icons.trending_up,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDistribution(Map<String, dynamic> stats) {
    final Map<String, int> statusStats = _getStatusStats(stats); // ✅ CORREGIDO: Tipo explícito

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distribución de Pedidos por Estado',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatusBars(statusStats),
            const SizedBox(height: 16),
            _buildStatusLegend(statusStats),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBars(Map<String, int> statusStats) {
    final totalOrders = statusStats.values.fold(0, (sum, count) => sum + count);

    return Column(
      children: statusStats.entries.map((entry) {
        final percentage = totalOrders > 0 ? (entry.value / totalOrders) * 100 : 0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getStatusDisplayText(entry.key),
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: percentage / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getStatusColor(entry.key),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusLegend(Map<String, int> statusStats) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: statusStats.entries.map((entry) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getStatusColor(entry.key),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              _getStatusDisplayText(entry.key),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDetailedInfo(OrderViewModel orderViewModel, String businessId) {
    final Map<String, dynamic> stats = orderViewModel.getBusinessOrderStats(businessId); // ✅ CORREGIDO: Tipo explícito

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información Detallada',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Pedidos Pendientes', stats['pendingOrders']?.toString() ?? '0'),
            _buildInfoRow('Pedidos Confirmados', stats['confirmedOrders']?.toString() ?? '0'),
            _buildInfoRow('En Preparación', stats['preparingOrders']?.toString() ?? '0'),
            _buildInfoRow('Listos para Entrega', stats['readyOrders']?.toString() ?? '0'),
            _buildInfoRow('Pedidos Entregados', stats['deliveredOrders']?.toString() ?? '0'),
            _buildInfoRow('Pedidos Cancelados', stats['cancelledOrders']?.toString() ?? '0'),
            const Divider(),
            _buildInfoRow('Tasa de Cancelación', '${stats['cancellationRate']?.toStringAsFixed(1) ?? '0'}%', isHighlighted: true),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isHighlighted ? Colors.red : Colors.black,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isHighlighted ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrders(OrderViewModel orderViewModel, String businessId) {
    final List<OrderEntity> recentOrders = orderViewModel.getRecentOrders(limit: 5, businessId: businessId); // ✅ CORREGIDO: Tipo explícito

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pedidos Recientes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (recentOrders.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No hay pedidos recientes',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...recentOrders.map((order) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: order.statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(
                      'Pedido #${order.id.substring(order.id.length - 6)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      order.userName,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${order.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          order.statusDisplayText,
                          style: TextStyle(
                            fontSize: 12,
                            color: order.statusColor,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      _showOrderQuickView(order);
                    },
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }

  void _showOrderQuickView(OrderEntity order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vista Rápida del Pedido'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cliente: ${order.userName}'),
            Text('Estado: ${order.statusDisplayText}'),
            Text('Total: \$${order.totalAmount.toStringAsFixed(2)}'),
            Text('Fecha: ${order.formattedCreatedAt}'),
            if (order.userNote != null) Text('Nota: ${order.userNote}'),
          ],
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

  Map<String, int> _getStatusStats(Map<String, dynamic> stats) {
    return <String, int>{ // ✅ CORREGIDO: Tipo explícito
      'pending': stats['pendingOrders'] ?? 0,
      'confirmed': stats['confirmedOrders'] ?? 0,
      'preparing': stats['preparingOrders'] ?? 0,
      'ready': stats['readyOrders'] ?? 0,
      'delivered': stats['deliveredOrders'] ?? 0,
      'cancelled': stats['cancelledOrders'] ?? 0,
    };
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'preparing': return Colors.purple;
      case 'ready': return Colors.green;
      case 'delivered': return Colors.teal;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getStatusDisplayText(String status) {
    switch (status) {
      case 'pending': return 'Pendientes';
      case 'confirmed': return 'Confirmados';
      case 'preparing': return 'En preparación';
      case 'ready': return 'Listos';
      case 'delivered': return 'Entregados';
      case 'cancelled': return 'Cancelados';
      default: return status;
    }
  }
}