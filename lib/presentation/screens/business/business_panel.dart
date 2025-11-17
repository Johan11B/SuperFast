// lib/presentation/screens/business/business_panel.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/business_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../settings/ajustes_page.dart';
import '../performance/performance_results_page.dart';

// Importar las pantallas especializadas
import 'business_products_screen.dart';
import 'business_orders_screen.dart'; // Asumimos que existe
import 'business_statistics_screen.dart'; // Asumimos que existe
import 'business_dashboard_screen.dart'; // Asumimos que existe

class BusinessPanel extends StatefulWidget {
  const BusinessPanel({super.key});

  @override
  State<BusinessPanel> createState() => _BusinessPanelState();
}

class _BusinessPanelState extends State<BusinessPanel> {
  final Color primaryColor = Colors.orange;
  final Color scaffoldBackgroundColor = const Color(0xFFEFEFEF);

  int _selectedIndex = 0;
  int _previousIndex = 0;

  // Lista de pantallas
  final List<Widget> _widgetOptions = [];

  @override
  void initState() {
    super.initState();

    // Inicializar las pantallas
    _widgetOptions.addAll([
      const BusinessDashboardScreen(),
      const BusinessProductsScreen(),
      const BusinessOrdersScreen(),
      const BusinessStatisticsScreen(),
    ]);

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

  void _handleTabChange(int index, BusinessViewModel businessViewModel) {
    final currentIndex = _selectedIndex;

    setState(() {
      _selectedIndex = index;
    });

    // Si se cambia a una pestaña diferente y luego se vuelve al dashboard, recargar datos
    if (index == 0 && _previousIndex != 0) {
      print('🔄 Volviendo al dashboard - Recargando datos...');
      _loadBusinessData();
    }

    // Actualizar el índice anterior
    _previousIndex = currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    final businessViewModel = context.watch<BusinessViewModel>();

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,

      // 1. AppBar Personalizado (igual que AdminPanel)
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
                    "Panel de Empresa",
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
                  // Icono de Ajustes
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
                  )
                ],
              ),
            ],
          ),
        ),
      ),

      // Body con diferentes pantallas según el índice
      body: businessViewModel.isLoading
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
          : _widgetOptions.elementAt(_selectedIndex),

      // Bottom Navigation Bar (navegación entre pantallas)
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: primaryColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.7),
        currentIndex: _selectedIndex,
        onTap: (index) {
          final businessViewModel = context.read<BusinessViewModel>();
          _handleTabChange(index, businessViewModel);
        },
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: "Productos"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Pedidos"),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: "Estadísticas"),
        ],
      ),
    );
  }
}