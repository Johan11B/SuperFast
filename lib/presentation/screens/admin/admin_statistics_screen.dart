// admin_statistics_screen.dart - VERSIÓN COMPLETA CORREGIDA
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../viewmodels/order_viewmodel.dart';
import '../../../domain/entities/business_entity.dart';

class AdminStatisticsScreen extends StatefulWidget {
  const AdminStatisticsScreen({super.key});

  @override
  State<AdminStatisticsScreen> createState() => _AdminStatisticsScreenState();
}

class _AdminStatisticsScreenState extends State<AdminStatisticsScreen> {
  String _selectedTimeRange = 'today';
  String _selectedView = 'general';
  bool _initialLoadCompleted = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print('🔄 AdminStatisticsScreen - initState llamado');

    // Usar un delay más largo para asegurar que el widget esté completamente montado
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _loadInitialData();
      }
    });
  }

  void _loadInitialData() {
    if (_initialLoadCompleted || _isLoading || !mounted) {
      print('⏳ AdminStatisticsScreen - Carga ignorada (ya completada/en progreso/no montado)');
      return;
    }

    _isLoading = true;
    if (mounted) {
      setState(() {});
    }

    print('🚀 AdminStatisticsScreen - INICIANDO CARGA INICIAL');
    _executeInitialLoad();
  }

  void _executeInitialLoad() async {
    try {
      final adminViewModel = context.read<AdminViewModel>();
      final orderViewModel = context.read<OrderViewModel>();

      print('📊 Ejecutando carga de dashboard...');
      await adminViewModel.loadDashboardData();

      // VERIFICAR SI EL WIDGET SIGUE MONTADO
      if (!mounted) {
        print('❌ Widget disposed durante carga de dashboard');
        return;
      }

      print('📦 Ejecutando carga de pedidos...');
      await orderViewModel.loadAllOrders();

      // VERIFICAR NUEVAMENTE
      if (!mounted) {
        print('❌ Widget disposed durante carga de pedidos');
        return;
      }

      _initialLoadCompleted = true;
      _isLoading = false;
      print('🎉 AdminStatisticsScreen - CARGA INICIAL COMPLETADA EXITOSAMENTE');

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;

      _isLoading = false;
      print('💥 AdminStatisticsScreen - Error en carga inicial: $e');

      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _refreshData() async {
    if (_isLoading || !mounted) {
      print('⏳ AdminStatisticsScreen - Refresh ignorado (en progreso/no montado)');
      return;
    }

    _isLoading = true;
    if (mounted) {
      setState(() {});
    }

    print('🔄 AdminStatisticsScreen - INICIANDO REFRESH MANUAL');

    try {
      final adminViewModel = context.read<AdminViewModel>();
      final orderViewModel = context.read<OrderViewModel>();

      await Future.wait([
        adminViewModel.refreshData(),
        orderViewModel.refreshAllOrders(),
      ]);

      if (!mounted) return;

      print('✅ AdminStatisticsScreen - REFRESH COMPLETADO');
    } catch (e) {
      if (!mounted) return;
      print('❌ AdminStatisticsScreen - Error en refresh: $e');
    } finally {
      _isLoading = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderViewModel = context.watch<OrderViewModel>();
    final adminViewModel = context.watch<AdminViewModel>();

    // DEBUG limitado para evitar spam
    if (_isLoading && !_initialLoadCompleted) {
      print('🏗️ AdminStatisticsScreen - build() | CARGANDO...');
    }

    final dashboardStats = adminViewModel.getDashboardStats();
    final orderStats = orderViewModel.getAdminOrderStats();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Estadísticas Administrativas'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshData,
            tooltip: 'Actualizar datos',
          ),
        ],
      ),
      body: _isLoading && !_initialLoadCompleted
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando estadísticas...'),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _refreshData,
        child: _buildContent(dashboardStats, orderStats, adminViewModel, orderViewModel),
      ),
    );
  }

  Widget _buildContent(
      Map<String, dynamic> dashboardStats,
      Map<String, dynamic> orderStats,
      AdminViewModel adminViewModel,
      OrderViewModel orderViewModel
      ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildViewSelectors(),
          const SizedBox(height: 20),

          if (_selectedView == 'general') ...[
            _buildGeneralStats(dashboardStats, orderStats),
            const SizedBox(height: 20),
            _buildBusinessStats(adminViewModel),
            const SizedBox(height: 20),
            _buildOrderStats(orderStats),
          ],

          if (_selectedView == 'by_business') ...[
            _buildBusinessPerformance(adminViewModel, orderViewModel),
          ],

          const SizedBox(height: 20),
          _buildRecentActivity(adminViewModel),
        ],
      ),
    );
  }

  Widget _buildViewSelectors() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vista de Estadísticas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildViewChip('General', 'general'),
                  const SizedBox(width: 8),
                  _buildViewChip('Por Empresa', 'by_business'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildTimeChip('Hoy', 'today'),
                  const SizedBox(width: 8),
                  _buildTimeChip('Esta semana', 'week'),
                  const SizedBox(width: 8),
                  _buildTimeChip('Este mes', 'month'),
                  const SizedBox(width: 8),
                  _buildTimeChip('Este año', 'year'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedView == value,
      onSelected: (selected) {
        setState(() {
          _selectedView = value;
        });
      },
    );
  }

  Widget _buildTimeChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _selectedTimeRange == value,
      onSelected: (selected) {
        setState(() {
          _selectedTimeRange = value;
        });
      },
    );
  }

  Widget _buildGeneralStats(Map<String, dynamic> dashboardStats, Map<String, dynamic> orderStats) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen General',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildStatCard('Usuarios Totales', dashboardStats['totalUsers']?.toString() ?? '0', Icons.people, Colors.blue),
                _buildStatCard('Empresas Activas', dashboardStats['activeBusinesses']?.toString() ?? '0', Icons.business, Colors.green),
                _buildStatCard('Pedidos Totales', orderStats['totalOrders']?.toString() ?? '0', Icons.shopping_cart, Colors.orange),
                _buildStatCard('Ingresos Totales', '\$${orderStats['totalRevenue']?.toStringAsFixed(0) ?? '0'}', Icons.attach_money, Colors.purple),
                _buildStatCard('Tasa Finalización', '${orderStats['completionRate']?.toStringAsFixed(1) ?? '0'}%', Icons.check_circle, Colors.teal),
                _buildStatCard('Empresas Pendientes', dashboardStats['pendingBusinesses']?.toString() ?? '0', Icons.pending, Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
              child: Icon(icon, color: color, size: 20),
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

  Widget _buildBusinessStats(AdminViewModel adminViewModel) {
    final stats = adminViewModel.getDashboardStats();
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estadísticas de Empresas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStatItem('Aprobadas', stats['approvedBusinesses']?.toString() ?? '0', Colors.green),
                _buildMiniStatItem('Pendientes', stats['pendingBusinesses']?.toString() ?? '0', Colors.orange),
                _buildMiniStatItem('Suspendidas', stats['suspendedBusinesses']?.toString() ?? '0', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
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

  Widget _buildOrderStats(Map<String, dynamic> orderStats) {
    final statusStats = orderStats['statusStats'] ?? {};
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distribución de Pedidos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                _buildOrderStatusItem('Pendientes', statusStats['pending']?.toString() ?? '0', Icons.pending, Colors.orange),
                _buildOrderStatusItem('Confirmados', statusStats['confirmed']?.toString() ?? '0', Icons.check_circle_outline, Colors.blue),
                _buildOrderStatusItem('Preparando', statusStats['preparing']?.toString() ?? '0', Icons.restaurant, Colors.purple),
                _buildOrderStatusItem('Listos', statusStats['ready']?.toString() ?? '0', Icons.done_all, Colors.green),
                _buildOrderStatusItem('Entregados', statusStats['delivered']?.toString() ?? '0', Icons.local_shipping, Colors.teal),
                _buildOrderStatusItem('Cancelados', statusStats['cancelled']?.toString() ?? '0', Icons.cancel, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatusItem(String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessPerformance(AdminViewModel adminViewModel, OrderViewModel orderViewModel) {
    final businesses = adminViewModel.businesses;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rendimiento por Empresa',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (businesses.isEmpty)
              const Center(child: Text('No hay empresas registradas'))
            else
              ...businesses.take(5).map((business) {
                final stats = orderViewModel.getBusinessOrderStats(business.id);
                return _buildBusinessPerformanceItem(business, stats);
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessPerformanceItem(BusinessEntity business, Map<String, dynamic> stats) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  business.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  business.category,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${stats['totalOrders'] ?? 0} pedidos',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '\$${stats['totalRevenue']?.toStringAsFixed(0) ?? '0'}',
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(AdminViewModel adminViewModel) {
    final recentActivity = adminViewModel.getRecentActivity();
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actividad Reciente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (recentActivity.isEmpty)
              const Center(
                child: Text(
                  'No hay actividad reciente',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...recentActivity.map((activity) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: activity['type'] == 'business' ? Colors.orange : Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['message'] as String,
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            _formatTime(activity['time'] as DateTime),
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )).toList(),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inMinutes < 1) return 'Ahora mismo';
    if (difference.inMinutes < 60) return 'Hace ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'Hace ${difference.inHours} h';
    if (difference.inDays < 7) return 'Hace ${difference.inDays} días';
    return '${time.day}/${time.month}/${time.year}';
  }
}