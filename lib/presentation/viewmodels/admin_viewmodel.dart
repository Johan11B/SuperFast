import 'package:flutter/material.dart';
import '../../core/utils/performance_manager.dart';

class AdminViewModel with ChangeNotifier {
  int _selectedIndex = 0;
  bool _isLoading = false;

  // Getters
  int get selectedIndex => _selectedIndex;
  bool get isLoading => _isLoading;

  // Methods
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void changeTab(int index) {
    // Para operaciones síncronas, usar Future.value
    PerformanceManager.measure(
      'Navigation Tab Change',
          () async {
        _selectedIndex = index;
        notifyListeners();
        return null; // Retornar un valor para Future<void>
      },
    );
  }

  // Simular carga de datos del dashboard
  Future<void> loadDashboardData() async {
    return await PerformanceManager.measure(
      'Load Dashboard Data',
          () async {
        setLoading(true);
        // Simular llamada a API
        await Future.delayed(const Duration(milliseconds: 800));
        setLoading(false);
      },
    );
  }

  // Datos de ejemplo para el dashboard
  Map<String, dynamic> getDashboardStats() {
    return {
      'activeOrders': 45,
      'pendingBusinesses': 9,
      'newUsers': 12,
      'pendingReports': 3,
    };
  }

  List<Map<String, dynamic>> getRecentActivity() {
    return [
      {'type': 'user', 'message': 'Nuevo usuario: Ana S'},
      {'type': 'business', 'message': 'Negocio "Café Express" en revisión'},
      {'type': 'order', 'message': 'Pedido #1234 completado'},
    ];
  }
}