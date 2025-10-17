import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'ajustes_page.dart';
import 'login_page.dart'; // Asegúrate de tener este import si se necesita en otros lugares

// -------------------------------------------------------------------------
// CLASE PRINCIPAL: ADMIN PANEL
// -------------------------------------------------------------------------

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  // Estado para la barra de navegación: 0 = "Inicio"
  int _selectedIndex = 0;

  // Lista de widgets de destino (Pestañas de la barra inferior)
  static const List<Widget> _widgetOptions = <Widget>[
    _AdminDashboardContent(), // 0: Contenido del Dashboard (Inicio)
    Center(child: Text('Pantalla de Usuarios', style: TextStyle(fontSize: 30))),
    Center(child: Text('Pantalla de Negocios', style: TextStyle(fontSize: 30))),
    Center(child: Text('Pantalla de Pedidos', style: TextStyle(fontSize: 30))),
    Center(child: Text('Pantalla de Reportes', style: TextStyle(fontSize: 30))),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Colores del diseño
  final Color primaryColor = const Color(0xFF008C9E);
  final Color scaffoldBackgroundColor = const Color(0xFFEFEFEF);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,

      // 1. AppBar Personalizado (Encabezado)
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80.0),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 40, 16, 10),
          color: primaryColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Lado Izquierdo (Logo)
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

              // 2. Título Centrado
              SizedBox(
                width: screenWidth - 140,
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

              // 3. Icono de Ajustes (Navega a AjustesPage)
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white, size: 30),
                onPressed: () {
                  // *** CORRECCIÓN CLAVE: Usamos PUSH para mantener AdminPanel en la pila ***
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

      // Muestra el widget de contenido seleccionado
      body: _widgetOptions.elementAt(_selectedIndex),

      // 4. Barra de Navegación Inferior (Funcional)
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: primaryColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.7),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
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
}

// -------------------------------------------------------------------------
// CLASE AUXILIAR 1: CONTENIDO DEL DASHBOARD (_AdminDashboardContent)
// -------------------------------------------------------------------------

class _AdminDashboardContent extends StatelessWidget {
  const _AdminDashboardContent();

  final Color primaryColor = const Color(0xFF008C9E);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sección de Estadísticas (Tarjetas Simétricas)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Usamos Expanded para asegurar la simetría
              Expanded(
                child: _StatBox(
                  title: "Pedidos Activos",
                  value: "45",
                  icon: Icons.arrow_upward,
                  color: Colors.green,
                  primaryColor: primaryColor,
                ),
              ),
              const SizedBox(width: 16), // Espacio entre tarjetas
              Expanded(
                child: _StatBox(
                  title: "Negocios Pendientes",
                  value: "9",
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
              children: const [
                Text("Nuevo usuario: Ana S", style: TextStyle(fontSize: 16)),
                SizedBox(height: 5),
                Text("Negocio “Café Express” en revisión", style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tarjeta de Alertas
          _buildCard(
            context,
            title: "Alertas",
            content: const Text(
              "3 nuevos reportes pendientes",
              style: TextStyle(fontSize: 16)
            ),
          ),
        ],
      ),
    );
  }

  // Helper para construir las tarjetas de Actividad y Alertas
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
// -------------------------------------------------------------------------
// CLASE AUXILIAR 2: CAJA DE ESTADÍSTICAS (_StatBox)
// -------------------------------------------------------------------------

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
    // El ancho es manejado por Expanded en la clase padre
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