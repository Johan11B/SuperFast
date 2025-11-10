import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../settings/ajustes_page.dart';
import '../../viewmodels/auth_viewmodel.dart';

class BusinessPanel extends StatelessWidget {
  const BusinessPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.read<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Empresa - SuperFast'),
        backgroundColor: Colors.orange,
        actions: [
          // Botón de Ajustes
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AjustesPage(
                    userRole: 'business',
                    primaryColor: Colors.orange,
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
            Icon(Icons.business_center, size: 80, color: Colors.orange),
            SizedBox(height: 20),
            Text(
              'PANEL DE EMPRESA',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Gestiona tus productos y pedidos aquí'),
            SizedBox(height: 20),
            Text('🔧 En construcción...', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),

      // Botón flotante adicional para acceso rápido a ajustes
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AjustesPage(
                userRole: 'business',
                primaryColor: Colors.orange,
              ),
            ),
          );
        },
        backgroundColor: Colors.orange,
        child: const Icon(Icons.settings, color: Colors.white),
      ),
    );
  }
}