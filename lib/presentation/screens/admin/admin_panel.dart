import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../settings/ajustes_page.dart';
import '../performance/performance_results_page.dart';

// Importar las nuevas pantallas
import 'admin_users_screen.dart';
import 'admin_businesses_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_reports_screen.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final Color primaryColor = const Color(0xFF008C9E);
  final Color scaffoldBackgroundColor = const Color(0xFFEFEFEF);

  @override
  void initState() {
    super.initState();
    // Cargar datos del dashboard al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminViewModel = context.watch<AdminViewModel>();

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,

      // 1. AppBar Personalizado
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80.0),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 40, 16, 10),
          color: primaryColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo (Lado Izquierdo)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  image: const DecorationImage(
                    image: AssetImage('assets/logo_panel.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Título Centrado
              const Expanded(
                child: Center(
                  child: Text(
                    "Panel\nAdministrativo",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                ),
              ),

              // Iconos (Lado Derecho) - CORREGIDO
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icono de Analytics (Performance) - MÁS PEQUEÑO
                  IconButton(
                    icon: const Icon(Icons.analytics, color: Colors.white, size: 22),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PerformanceResultsPage()),
                      );
                    },
                    tooltip: 'Rendimiento', // Texto al mantener presionado
                  ),
                  // Icono de Ajustes
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AjustesPage(
                            userRole: 'admin',
                            primaryColor: const Color(0xFF008C9E),
                          ),
                        ),
                      );
                    },
                  )
                ],
              ),
            ],
          ),
        ),
      ),

      // Body con diferentes pantallas según el índice
      body: adminViewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _widgetOptions.elementAt(adminViewModel.selectedIndex),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: primaryColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.7),
        currentIndex: adminViewModel.selectedIndex,
        onTap: (index) => adminViewModel.changeTab(index),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Usuarios"),
          BottomNavigationBarItem(icon: Icon(Icons.business_center), label: "Negocios"),
          BottomNavigationBarItem(icon: Icon(Icons.file_copy), label: "Pedidos"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Reportes"),
        ],
      ),
    );
  }

  // Widgets para las diferentes pantallas - ACTUALIZADO
  final List<Widget> _widgetOptions = <Widget>[
    const _AdminDashboardContent(),
    const AdminUsersScreen(),
    const AdminBusinessesScreen(),
    const AdminOrdersScreen(),
    const AdminReportsScreen(),
  ];
}

// CONTENIDO DEL DASHBOARD - MEJORADO
class _AdminDashboardContent extends StatelessWidget {
  const _AdminDashboardContent();

  final Color primaryColor = const Color(0xFF008C9E);

  @override
  Widget build(BuildContext context) {
    final adminViewModel = context.watch<AdminViewModel>();
    final stats = adminViewModel.getDashboardStats();
    final activities = adminViewModel.getRecentActivity();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sección de Estadísticas - MEJORADA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _StatBox(
                  title: "Pedidos Activos",
                  value: stats['activeOrders'].toString(),
                  icon: Icons.shopping_cart,
                  color: Colors.blue,
                  primaryColor: primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatBox(
                  title: "Negocios Pendientes",
                  value: stats['pendingBusinesses'].toString(),
                  icon: Icons.business,
                  color: Colors.orange,
                  primaryColor: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _StatBox(
                  title: "Total Usuarios",
                  value: stats['totalUsers'].toString(),
                  icon: Icons.people,
                  color: Colors.green,
                  primaryColor: primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatBox(
                  title: "Ingresos Totales",
                  value: "\$${stats['totalRevenue'].toStringAsFixed(2)}",
                  icon: Icons.attach_money,
                  color: Colors.purple,
                  primaryColor: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Tarjeta de Actividad Reciente - MEJORADA
          _buildCard(
            context,
            title: "Actividad reciente",
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: activities.map((activity) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        _getActivityIcon(activity['type']),
                        color: _getActivityColor(activity['type']),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          activity['message'],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Tarjeta de Alertas - MEJORADA
          _buildCard(
            context,
            title: "Alertas del Sistema",
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAlertItem(
                  Icons.warning,
                  Colors.orange,
                  "${stats['pendingBusinesses']} negocios pendientes de aprobación",
                ),
                _buildAlertItem(
                  Icons.assignment,
                  Colors.blue,
                  "${stats['pendingReports']} reportes pendientes de revisión",
                ),
                _buildAlertItem(
                  Icons.trending_up,
                  Colors.green,
                  "Crecimiento del 15% en pedidos este mes",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'user': return Icons.person;
      case 'business': return Icons.business;
      case 'order': return Icons.shopping_cart;
      default: return Icons.notifications;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'user': return Colors.blue;
      case 'business': return Colors.orange;
      case 'order': return Colors.green;
      default: return Colors.grey;
    }
  }

  Widget _buildAlertItem(IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required String title, required Widget content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          content,
        ],
      ),
    );
  }
}

// CAJA DE ESTADÍSTICAS - MANTENIDO
class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color primaryColor;

  const _StatBox({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  value,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  )
              ),
              Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(50),
                ),
                padding: const EdgeInsets.all(4),
                child: Icon(icon, color: Colors.white, size: 20),
              ),

            ],
          ),
        ],
      ),
    );
  }
}