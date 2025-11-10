import 'package:flutter/material.dart';
import '../../../core/utils/performance_manager.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../admin/admin_panel.dart';

class PerformanceResultsPage extends StatelessWidget {
  const PerformanceResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = PerformanceManager.stats;
    final metrics = PerformanceManager.metrics;
    final results = PerformanceManager.results;

    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF008C9E),
        title: const Text(
          'Resultados de Rendimiento',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              PerformanceManager.clear();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Métricas reiniciadas')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta de Resumen General
            _buildSummaryCard(stats),
            const SizedBox(height: 20),

            // Estadísticas Detalladas
            _buildStatsGrid(stats),
            const SizedBox(height: 20),

            // Lista de Métricas Individuales
            _buildMetricsList(metrics),
            const SizedBox(height: 20),

            // Botones de Acción
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(PerformanceStats stats) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'RESUMEN DE RENDIMIENTO',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF008C9E),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total Operaciones',
                  '${stats.totalOperations}',
                  Icons.functions,
                ),
                _buildStatItem(
                  'Tiempo Promedio',
                  '${stats.averageTime}ms',
                  Icons.timer,
                ),
                _buildStatItem(
                  'Éxito',
                  '${stats.successRate.toStringAsFixed(1)}%',
                  Icons.check_circle,
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, {Color color = Colors.blue}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatsGrid(PerformanceStats stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          'Tiempo Total',
          '${stats.totalTime}ms',
          Icons.access_time,
          Colors.orange,
        ),
        _buildMetricCard(
          'Operaciones Exitosas',
          '${stats.successfulOperations}',
          Icons.check,
          Colors.green,
        ),
        _buildMetricCard(
          'Operaciones Fallidas',
          '${stats.failedOperations}',
          Icons.close,
          Colors.red,
        ),
        _buildMetricCard(
          'Tiempo Máximo',
          '${stats.maxTime}ms',
          Icons.trending_up,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsList(List<PerformanceMetric> metrics) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MÉTRICAS DETALLADAS',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF008C9E),
              ),
            ),
            const SizedBox(height: 12),
            if (metrics.isEmpty)
              const Center(
                child: Text(
                  'No hay métricas registradas',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...metrics.map((metric) => _buildMetricItem(metric)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(PerformanceMetric metric) {
    Color getColorByDuration(int duration) {
      if (duration < 100) return Colors.green;
      if (duration < 500) return Colors.orange;
      return Colors.red;
    }

    IconData getIconByType(PerformanceType type) {
      switch (type) {
        case PerformanceType.auth: return Icons.security;
        case PerformanceType.navigation: return Icons.navigation;
        case PerformanceType.data: return Icons.storage;
        case PerformanceType.ui: return Icons.dashboard;
        case PerformanceType.other: return Icons.more_horiz;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: getColorByDuration(metric.duration).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              getIconByType(metric.type),
              color: getColorByDuration(metric.duration),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${metric.typeName} • ${metric.formattedDuration}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: getColorByDuration(metric.duration),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              metric.formattedDuration,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.analytics),
            label: const Text('Ejecutar Pruebas'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008C9E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            onPressed: () => _runPerformanceTests(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.dashboard),
            label: const Text('Volver al Panel'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AdminPanel()),
              );
            },
          ),
        ),
      ],
    );
  }

  void _runPerformanceTests(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Ejecutando pruebas de rendimiento...')),
      );

      // Simular diferentes operaciones para medir
      await PerformanceManager.measure('Login de Usuario', () async {
        await Future.delayed(const Duration(milliseconds: 150));
      });

      await PerformanceManager.measure('Carga de Dashboard', () async {
        await Future.delayed(const Duration(milliseconds: 200));
      });

      await PerformanceManager.measure('Navegación a Ajustes', () async {
        await Future.delayed(const Duration(milliseconds: 100));
      });

      await PerformanceManager.measure('Carga de Datos de Usuario', () async {
        await Future.delayed(const Duration(milliseconds: 300));
      });

      // Forzar rebuild para mostrar nuevos resultados
      // En un StatefulWidget usarías setState, aquí mostramos mensaje
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Pruebas completadas ✅')),
      );

    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error en pruebas: $e')),
      );
    }
  }
}