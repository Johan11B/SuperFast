// lib/presentation/screens/business/business_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/business_viewmodel.dart';

class BusinessDashboardScreen extends StatelessWidget {
  const BusinessDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final businessViewModel = context.watch<BusinessViewModel>();
    final stats = businessViewModel.getBusinessStats();

    return RefreshIndicator(
      onRefresh: () async {
        if (businessViewModel.currentBusiness != null) {
          await businessViewModel.loadBusinessProducts(
              businessViewModel.currentBusiness!.id
          );
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título con botón de recarga
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dashboard Empresarial',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.orange),
                  onPressed: () {
                    if (businessViewModel.currentBusiness != null) {
                      businessViewModel.loadBusinessProducts(
                          businessViewModel.currentBusiness!.id
                      );
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Actualizando datos...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  tooltip: 'Recargar datos',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Estadísticas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _StatBox(
                    title: "Total Productos",
                    value: stats['totalProducts'].toString(),
                    icon: Icons.inventory,
                    color: Colors.blue,
                    primaryColor: Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatBox(
                    title: "Productos Activos",
                    value: stats['availableProducts'].toString(),
                    icon: Icons.check_circle,
                    color: Colors.green,
                    primaryColor: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _StatBox(
                    title: "Sin Stock",
                    value: stats['outOfStockProducts'].toString(),
                    icon: Icons.error,
                    color: Colors.red,
                    primaryColor: Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatBox(
                    title: "Stock Bajo",
                    value: stats['lowStockProducts'].toString(),
                    icon: Icons.warning,
                    color: Colors.orange,
                    primaryColor: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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
              fontSize: 14,
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
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(50),
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }
}