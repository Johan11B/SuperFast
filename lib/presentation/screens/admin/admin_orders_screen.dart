// lib/presentation/screens/admin/admin_orders_screen.dart
import 'package:flutter/material.dart';

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'Gestión de Pedidos',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Módulo en desarrollo'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Función futura para cargar pedidos
              },
              child: const Text('Cargar Pedidos'),
            ),
          ],
        ),
      ),
    );
  }
}