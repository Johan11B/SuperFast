// lib/presentation/screens/user/user_panel.dart - VERSIÓN CORREGIDA
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/catalog_viewmodel.dart';
import '../settings/ajustes_page.dart';
import '../business/business_registration_page.dart';

// Importar pantallas
import 'user_catalog_screen.dart';
import 'user_orders_screen.dart'; // Placeholder por ahora
import 'user_profile_screen.dart'; // Perfil del usuario

class UserPanel extends StatefulWidget {
  const UserPanel({super.key});

  @override
  State<UserPanel> createState() => _UserPanelState();
}

class _UserPanelState extends State<UserPanel> {
  final Color primaryColor = Colors.green;
  final Color scaffoldBackgroundColor = const Color(0xFFEFEFEF);

  int _selectedIndex = 0;
  int _previousIndex = 0;

  // Lista de pantallas
  final List<Widget> _widgetOptions = [];

  // ✅ CONTROLAR SI YA SE CARGÓ EL CATÁLOGO
  bool _catalogLoaded = false;

  @override
  void initState() {
    super.initState();

    // Inicializar las pantallas
    _widgetOptions.addAll([
      const UserCatalogScreen(),
      const UserOrdersScreen(), // Placeholder
      const UserProfileScreen(),
    ]);

    // ✅ CARGAR SOLO UNA VEZ AL INICIAR
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_catalogLoaded) {
        _loadCatalogData();
        _catalogLoaded = true;
      }
    });
  }

  void _loadCatalogData() {
    final catalogViewModel = context.read<CatalogViewModel>();
    catalogViewModel.loadCatalog();
  }

  void _handleTabChange(int index) {
    final currentIndex = _selectedIndex;

    setState(() {
      _selectedIndex = index;
    });

    // ✅ SOLO RECARGAR SI ES NECESARIO Y NO ESTÁ YA CARGANDO
    if (index == 0 && _previousIndex != 0) {
      final catalogViewModel = context.read<CatalogViewModel>();
      if (!catalogViewModel.isLoading) {
        print('🔄 Volviendo al catálogo - Recargando datos...');
        _loadCatalogData();
      }
    }

    // Actualizar el índice anterior
    _previousIndex = currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,

      // 1. AppBar Personalizado (similar al AdminPanel)
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
                  color: Colors.white,
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
                    "SuperFast Usuario",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
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
                  // Icono de Carrito (futuro)
                  IconButton(
                    icon: const Icon(Icons.shopping_cart, color: Colors.white, size: 22),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Carrito - Próximamente')),
                      );
                    },
                    tooltip: 'Carrito de compras',
                  ),
                  // Icono de Ajustes
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AjustesPage(
                            userRole: 'user',
                            primaryColor: primaryColor,
                          ),
                        ),
                      ).then((_) {
                        // ✅ RECARGAR DATOS AL VOLVER DE AJUSTES
                        _loadCatalogData();
                      });
                    },
                  )
                ],
              ),
            ],
          ),
        ),
      ),

      // Body con diferentes pantallas según el índice
      body: _widgetOptions.elementAt(_selectedIndex),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: primaryColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.7),
        currentIndex: _selectedIndex,
        onTap: _handleTabChange,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: "Catálogo",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: "Mis Pedidos",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Mi Cuenta",
          ),
        ],
      ),
    );
  }
}