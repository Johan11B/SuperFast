import 'package:flutter/material.dart';

class AdminViewModel with ChangeNotifier {
  int _selectedIndex = 0;
  bool _isLoading = false;

  // Getters
  int get selectedIndex => _selectedIndex;
  bool get isLoading => _isLoading;

  // Methods
  void changeTab(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Simular carga de datos del dashboard
  Future<void> loadDashboardData() async {
    setLoading(true);
    // Simular llamada a API
    await Future.delayed(const Duration(seconds: 2));
    setLoading(false);
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