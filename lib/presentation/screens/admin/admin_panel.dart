import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../settings/ajustes_page.dart';

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
              // Logo
              Row(
                children: [
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
                  const SizedBox(width: 10),
                ],
              ),

              // Título Centrado
              SizedBox(
                width: MediaQuery.of(context).size.width - 140,
                child: const Center(
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

              // Icono de Ajustes
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white, size: 30),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AjustesPage()),
                  );
                },
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

  // Widgets para las diferentes pantallas
  final List<Widget> _widgetOptions = <Widget>[
    const _AdminDashboardContent(),
    const Center(child: Text('Pantalla de Usuarios', style: TextStyle(fontSize: 30))),
    const Center(child: Text('Pantalla de Negocios', style: TextStyle(fontSize: 30))),
    const Center(child: Text('Pantalla de Pedidos', style: TextStyle(fontSize: 30))),
    const Center(child: Text('Pantalla de Reportes', style: TextStyle(fontSize: 30))),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sección de Estadísticas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _StatBox(
                  title: "Pedidos Activos",
                  value: stats['activeOrders'].toString(),
                  icon: Icons.arrow_upward,
                  color: Colors.green,
                  primaryColor: primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatBox(
                  title: "Negocios Pendientes",
                  value: stats['pendingBusinesses'].toString(),
                  icon: Icons.arrow_downward,
                  color: Colors.red,
                  primaryColor: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Tarjeta de Actividad Reciente
          _buildCard(
            context,
            title: "Actividad reciente",
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: activities.map((activity) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    activity['message'],
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Tarjeta de Alertas
          _buildCard(
            context,
            title: "Alertas",
            content: Text(
                "${stats['pendingReports']} nuevos reportes pendientes",
                style: const TextStyle(fontSize: 16)
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