import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../settings/ajustes_page.dart';
import '../../viewmodels/auth_viewmodel.dart';

class UserDashboard extends StatelessWidget {
  const UserDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SuperFast - Usuario'),
        backgroundColor: Colors.green,
        actions: [
          // Botón de Ajustes
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AjustesPage(
                    userRole: 'user',
                    primaryColor: Colors.green,
                  ),
                ),
              );
            },
            tooltip: 'Ajustes',
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag, size: 80, color: Colors.green),
            SizedBox(height: 20),
            Text(
              'DASHBOARD DE USUARIO',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Realiza tus pedidos y sigue tu historial'),
            SizedBox(height: 20),
            Text('🔧 En construcción...', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),

      // Botón flotante para información del usuario
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AjustesPage(
                    userRole: 'user',
                    primaryColor: Colors.green,
                  ),
                ),
              );
            },
            backgroundColor: Colors.green,
            mini: true,
            child: const Icon(Icons.settings, color: Colors.white),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () {
              _showUserInfo(context);
            },
            backgroundColor: Colors.blue,
            child: const Icon(Icons.info, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _showUserInfo(BuildContext context) {
    final authViewModel = context.read<AuthViewModel>();
    final user = authViewModel.currentUser;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Información del Usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📧 Email: ${user?.email ?? 'N/A'}'),
            Text('👤 Nombre: ${user?.name ?? 'N/A'}'),
            Text('🎯 Rol: ${user?.role ?? 'N/A'}'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getRoleColor(user?.role),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                'ROL: ${user?.role?.toUpperCase() ?? 'N/A'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'admin': return Colors.red;
      case 'business': return Colors.orange;
      case 'user': return Colors.green;
      default: return Colors.grey;
    }
  }
}