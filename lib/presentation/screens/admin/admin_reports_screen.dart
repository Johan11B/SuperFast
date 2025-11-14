// lib/presentation/screens/admin/admin_reports_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/admin_viewmodel.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bar_chart, size: 64, color: Colors.purple),
            const SizedBox(height: 16),
            const Text(
              'Reportes y Métricas',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Aquí podrás ver reportes y métricas del sistema'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final stats = context.read<AdminViewModel>().getDashboardStats();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ingresos totales: \$${stats['totalRevenue']}')),
                );
              },
              child: const Text('Ver Métricas'),
            ),
          ],
        ),
      ),
    );
  }
}