// lib/presentation/screens/business/business_panel.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/business_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../settings/ajustes_page.dart';
import '../performance/performance_results_page.dart';

// Importar las pantallas especializadas
import 'business_products_screen.dart';
import 'business_orders_screen.dart';
import 'business_statistics_screen.dart';
import 'business_dashboard_screen.dart';
import 'business_edit_profile_screen.dart';

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

  // ✅ CORREGIDO: Método para mostrar información de la empresa
  void _showBusinessInfo() {
    final businessViewModel = context.read<BusinessViewModel>();
    final business = businessViewModel.currentBusiness;

    if (business == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.business, color: Colors.orange),
            SizedBox(width: 8),
            Text('Información General'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo de la empresa
              if (business.logoUrl != null && business.logoUrl!.isNotEmpty)
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(business.logoUrl!),
                            fit: BoxFit.cover,
                          ),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                      ),
                      const Text(
                        'Logo de la Empresa',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              _buildInfoItem('🏢 Nombre:', business.name),
              _buildInfoItem('📁 Categoría:', business.category),
              _buildInfoItem('📍 Dirección:', business.address),
              _buildInfoItem('📞 Teléfono:', business.phone),
              if (business.description != null && business.description!.isNotEmpty)
                _buildInfoItem('📝 Descripción:', business.description!),
              _buildInfoItem('📊 Estado:', business.statusDisplayText),
              _buildInfoItem('⭐ Rating:', '${business.rating} (${business.reviewCount} reseñas)'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, size: 16, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Para cambiar el logo de la empresa, ve a "Editar Perfil"',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BusinessEditProfileScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Editar Perfil'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final businessViewModel = context.watch<BusinessViewModel>();
    final business = businessViewModel.currentBusiness;

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,

      // 1. AppBar Personalizado - CORREGIDO
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80.0),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 40, 16, 10),
          color: primaryColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ✅ LOGO DE SUPERFAST (Lado Izquierdo) - SIEMPRE FIJO
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

              // ✅ TÍTULO CENTRADO con información de la empresa
              Expanded(
                child: GestureDetector(
                  onTap: _showBusinessInfo,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        business?.name ?? "Panel de Empresa",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 40,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),

              // ✅ ICONOS (Lado Derecho)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icono de Información de Empresa - SOLO si hay empresa
                  if (business != null)
                    IconButton(
                      icon: const Icon(Icons.business, color: Colors.white),
                      onPressed: _showBusinessInfo,
                      tooltip: 'Información de la empresa',
                    ),
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
                    tooltip: 'Configuración',
                  ),
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

      // ✅ BOTÓN FLOTANTE para ver información de la empresa
      floatingActionButton: business != null
          ? FloatingActionButton(
        onPressed: _showBusinessInfo,
        backgroundColor: Colors.orange,
        mini: true,
        child: const Icon(Icons.business, color: Colors.white),
        tooltip: 'Ver información de la empresa',
      )
          : null,
    );
  }
}