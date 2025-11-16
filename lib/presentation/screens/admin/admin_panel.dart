// lib/presentation/screens/admin/admin_panel.dart
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

  // ✅ AGREGADO: Controlador para manejar el índice anterior
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    // Cargar datos del dashboard al iniciar - MEJORADO
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🚀 AdminPanel iniciado - Cargando datos...');
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

              // Iconos (Lado Derecho)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icono de Analytics (Performance)
                  IconButton(
                    icon: const Icon(Icons.analytics, color: Colors.white, size: 22),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PerformanceResultsPage()),
                      );
                    },
                    tooltip: 'Rendimiento',
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
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando datos del panel...'),
          ],
        ),
      )
          : _widgetOptions.elementAt(adminViewModel.selectedIndex),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: primaryColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.7),
        currentIndex: adminViewModel.selectedIndex,
        onTap: (index) {
          // ✅ CORREGIDO: Manejo mejorado del cambio de pestañas
          _handleTabChange(index, adminViewModel);
        },
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

  // ✅ NUEVO MÉTODO: Manejar cambio de pestañas
  void _handleTabChange(int index, AdminViewModel adminViewModel) {
    final currentIndex = adminViewModel.selectedIndex;

    // Cambiar la pestaña primero
    adminViewModel.changeTab(index);

    // Si se cambia a una pestaña diferente y luego se vuelve al dashboard, recargar datos
    if (index == 0 && _previousIndex != 0) {
      print('🔄 Volviendo al dashboard - Recargando datos...');
      adminViewModel.refreshData();
    }

    // Actualizar el índice anterior
    _previousIndex = currentIndex;
  }

  // Widgets para las diferentes pantallas
  final List<Widget> _widgetOptions = <Widget>[
    const _AdminDashboardContent(),
    const AdminUsersScreen(),
    const AdminBusinessesScreen(),
    const AdminOrdersScreen(),
    const AdminReportsScreen(),
  ];
}

// CONTENIDO DEL DASHBOARD
class _AdminDashboardContent extends StatelessWidget {
  const _AdminDashboardContent();

  final Color primaryColor = const Color(0xFF008C9E);

  @override
  Widget build(BuildContext context) {
    final adminViewModel = context.watch<AdminViewModel>();
    final stats = adminViewModel.getDashboardStats();
    final activities = adminViewModel.getRecentActivity();

    return RefreshIndicator(
      // ✅ AGREGADO: Permitir recargar arrastrando hacia abajo
      onRefresh: () async {
        await adminViewModel.refreshData();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título con botón de recarga
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dashboard Administrativo',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                // ✅ AGREGADO: Botón de recarga manual
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF008C9E)),
                  onPressed: () {
                    adminViewModel.refreshData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Actualizando datos...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  tooltip: 'Recargar datos',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Mostrar mensajes de éxito o error
            if (adminViewModel.successMessage.isNotEmpty) ...[
              _buildMessageBanner(adminViewModel.successMessage, Colors.green),
              const SizedBox(height: 16),
            ],
            if (adminViewModel.errorMessage.isNotEmpty) ...[
              _buildMessageBanner(adminViewModel.errorMessage, Colors.red),
              const SizedBox(height: 16),
            ],

            // NUEVA SECCIÓN DE ESTADÍSTICAS - EMPRESAS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _StatBox(
                    title: "Solicitudes Pendientes",
                    value: stats['pendingBusinesses'].toString(),
                    icon: Icons.pending_actions,
                    color: Colors.orange,
                    primaryColor: primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatBox(
                    title: "Empresas Activas",
                    value: stats['activeBusinesses'].toString(),
                    icon: Icons.business,
                    color: Colors.green,
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
                    title: "Empresas Aprobadas",
                    value: stats['approvedBusinesses'].toString(),
                    icon: Icons.check_circle,
                    color: Colors.blue,
                    primaryColor: primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatBox(
                    title: "Empresas Suspendidas",
                    value: stats['suspendedBusinesses'].toString(),
                    icon: Icons.pause_circle,
                    color: Colors.grey,
                    primaryColor: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Sección de Estadísticas Adicionales (Usuarios y Empresas)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _StatBox(
                    title: "Total Usuarios",
                    value: stats['totalUsers'].toString(),
                    icon: Icons.people,
                    color: Colors.purple,
                    primaryColor: primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatBox(
                    title: "Empresas Registradas",
                    value: stats['businessUsers'].toString(),
                    icon: Icons.store,
                    color: Colors.teal,
                    primaryColor: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tarjeta de Actividad Reciente
            _buildCard(
              context,
              title: "Actividad Reciente",
              content: activities.isEmpty
                  ? const Center(
                child: Text(
                  'No hay actividad reciente',
                  style: TextStyle(color: Colors.grey),
                ),
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: activities.map((activity) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        Icon(
                          _getActivityIcon(activity['type']),
                          color: _getActivityColor(activity['type']),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity['message'],
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(activity['time']),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NUEVO MÉTODO: Banner para mensajes
  Widget _buildMessageBanner(String message, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(
            color == Colors.green ? Icons.check_circle : Icons.error,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NUEVO MÉTODO: Formatear tiempo
  String _formatTime(dynamic time) {
    if (time is DateTime) {
      final now = DateTime.now();
      final difference = now.difference(time);

      if (difference.inMinutes < 1) return 'Hace unos segundos';
      if (difference.inMinutes < 60) return 'Hace ${difference.inMinutes} min';
      if (difference.inHours < 24) return 'Hace ${difference.inHours} h';
      return 'Hace ${difference.inDays} días';
    }
    return 'Hace unos momentos';
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'user': return Icons.person_add;
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
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }
}

// CAJA DE ESTADÍSTICAS
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
              fontSize: 14,
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
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(50),
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }
}