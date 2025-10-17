import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel Administrativo"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const LoginPage()));
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                _StatBox(title: "Pedidos Activos", value: "45", icon: Icons.arrow_upward, color: Colors.green),
                _StatBox(title: "Negocios Pendientes", value: "9", icon: Icons.arrow_downward, color: Colors.red),
              ],
            ),
            const SizedBox(height: 20),
            const ListTile(
              title: Text("Actividad reciente"),
              subtitle: Text("Nuevo usuario: Ana S\nNegocio 'Café Express' en revisión"),
            ),
            const ListTile(
              title: Text("Alertas"),
              subtitle: Text("3 nuevos reportes pendientes"),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Usuarios"),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: "Negocios"),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: "Pedidos"),
          BottomNavigationBarItem(icon: Icon(Icons.report), label: "Reportes"),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              Text(value, style: TextStyle(fontSize: 20, color: color)),
            ],
          ),
        ],
      ),
    );
  }
}
