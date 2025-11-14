// lib/presentation/viewmodels/admin_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../../core/services/business_registration_service.dart';
import '../../core/services/user_service.dart';
import '../../domain/entities/user_entity.dart';

class AdminViewModel extends ChangeNotifier {
  final BusinessRegistrationService _businessService = BusinessRegistrationService();
  final UserService _userService = UserService();

  // Estados
  int _selectedIndex = 0;
  bool _isLoading = false;
  bool _isLoadingBusinesses = false;
  String _errorMessage = '';
  List<Map<String, dynamic>> _pendingBusinesses = [];
  List<Map<String, dynamic>> _activeBusinesses = [];
  List<Map<String, dynamic>> _approvedBusinesses = [];
  List<Map<String, dynamic>> _suspendedBusinesses = [];
  List<UserEntity> _users = [];
  String _businessSearch = '';
  String _userSearch = '';

  // Estadísticas
  Map<String, int> _businessCounts = {
    'pending': 0,
    'approved': 0,
    'suspended': 0,
    'active': 0,
    'total': 0,
  };

  // Getters
  int get selectedIndex => _selectedIndex;
  bool get isLoading => _isLoading;
  bool get isLoadingBusinesses => _isLoadingBusinesses;
  String get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get pendingBusinesses => _filterBusinesses(_pendingBusinesses);
  List<Map<String, dynamic>> get activeBusinesses => _filterBusinesses(_activeBusinesses);
  List<Map<String, dynamic>> get approvedBusinesses => _filterBusinesses(_approvedBusinesses);
  List<Map<String, dynamic>> get suspendedBusinesses => _filterBusinesses(_suspendedBusinesses);
  List<UserEntity> get users => _filterUsers(_users);
  Map<String, int> get businessCounts => _businessCounts;

  void changeTab(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  void updateBusinessSearch(String query) {
    _businessSearch = query.toLowerCase();
    notifyListeners();
  }

  void updateUserSearch(String query) {
    _userSearch = query.toLowerCase();
    notifyListeners();
  }

  List<Map<String, dynamic>> _filterBusinesses(List<Map<String, dynamic>> list) {
    if (_businessSearch.isEmpty) return list;
    return list.where((business) =>
    business['businessName']?.toString().toLowerCase().contains(_businessSearch) == true ||
        business['userEmail']?.toString().toLowerCase().contains(_businessSearch) == true ||
        business['category']?.toString().toLowerCase().contains(_businessSearch) == true
    ).toList();
  }

  List<UserEntity> _filterUsers(List<UserEntity> list) {
    if (_userSearch.isEmpty) return list;
    return list.where((user) =>
    user.email.toLowerCase().contains(_userSearch) ||
        (user.name?.toLowerCase().contains(_userSearch) ?? false)
    ).toList();
  }

  // Cargar datos del dashboard
  Future<void> loadDashboardData() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await Future.wait([
        loadBusinessCounts(),
        loadPendingBusinesses(),
        loadActiveBusinesses(),
        loadUsers(),
      ]);
      print('✅ Dashboard data cargado exitosamente');
    } catch (e) {
      _errorMessage = 'Error cargando datos: $e';
      print('❌ Error cargando dashboard data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cargar conteos de negocios
  Future<void> loadBusinessCounts() async {
    try {
      _businessCounts = await _businessService.getBusinessCounts();
      print('✅ Conteos de negocios cargados: $_businessCounts');
    } catch (e) {
      print('❌ Error cargando conteos de negocios: $e');
    }
  }

  // Cargar negocios pendientes
  Future<void> loadPendingBusinesses() async {
    try {
      _pendingBusinesses = await _businessService.getPendingRegistrations();
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Error cargando negocios pendientes: $e';
      _pendingBusinesses = [];
    }
    notifyListeners();
  }

  // Cargar negocios activos (aprobados + suspendidos)
  Future<void> loadActiveBusinesses() async {
    try {
      _activeBusinesses = await _businessService.getActiveBusinesses();
      // Separar en listas individuales
      _approvedBusinesses = _activeBusinesses.where((b) => b['status'] == 'approved').toList();
      _suspendedBusinesses = _activeBusinesses.where((b) => b['status'] == 'suspended').toList();
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Error cargando negocios activos: $e';
      _activeBusinesses = [];
      _approvedBusinesses = [];
      _suspendedBusinesses = [];
    }
    notifyListeners();
  }

  // Cargar usuarios
  Future<void> loadUsers() async {
    try {
      _users = await _userService.getAllUsers();
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Error cargando usuarios: $e';
      _users = [];
    }
    notifyListeners();
  }

  // Método para cargar todos los negocios
  Future<void> loadBusinesses() async {
    if (_isLoadingBusinesses) return;

    _isLoadingBusinesses = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await Future.wait([
        loadBusinessCounts(),
        loadPendingBusinesses(),
        loadActiveBusinesses(),
      ]);
      print('✅ Todos los negocios cargados exitosamente');
    } catch (e) {
      _errorMessage = 'Error cargando negocios: $e';
      print('❌ Error cargando negocios: $e');
    } finally {
      _isLoadingBusinesses = false;
      notifyListeners();
    }
  }

  // Aprobar negocio
  Future<void> approveBusiness(String businessId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _businessService.approveBusinessRegistration(businessId);
      await loadBusinesses(); // Recargar todos los datos
      await loadUsers(); // Para actualizar roles si es necesario
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Error aprobando negocio: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Rechazar negocio
  Future<void> rejectBusiness(String businessId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _businessService.rejectBusinessRegistration(businessId);
      await loadBusinesses(); // Recargar todos los datos
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Error rechazando negocio: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Suspender negocio
  Future<void> suspendBusiness(String businessId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _businessService.suspendBusiness(businessId);
      await loadBusinesses(); // Recargar todos los datos
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Error suspendiendo negocio: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Activar negocio
  Future<void> activateBusiness(String businessId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _businessService.activateBusiness(businessId);
      await loadBusinesses(); // Recargar todos los datos
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Error activando negocio: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Eliminar negocio permanentemente
  Future<void> deleteBusiness(String businessId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _businessService.deleteBusiness(businessId);
      await loadBusinesses(); // Recargar todos los datos
      await loadUsers(); // Para actualizar roles si es necesario
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Error eliminando negocio: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cambiar rol de usuario
  Future<void> changeUserRole(String userId, String newRole) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _userService.updateUserRole(userId, newRole);
      await loadUsers();
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Error cambiando rol: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Eliminar usuario
  Future<void> deleteUser(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _userService.deleteUser(userId);
      await loadUsers();
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Error eliminando usuario: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Métodos para el dashboard
  Map<String, dynamic> getDashboardStats() {
    return {
      'pendingBusinesses': _businessCounts['pending'] ?? 0,
      'approvedBusinesses': _businessCounts['approved'] ?? 0,
      'suspendedBusinesses': _businessCounts['suspended'] ?? 0,
      'activeBusinesses': _businessCounts['active'] ?? 0,
      'totalBusinesses': _businessCounts['total'] ?? 0,
      'totalUsers': _users.length,
      'activeUsers': _users.where((user) => user.role == 'user').length,
      'businessUsers': _users.where((user) => user.role == 'business').length,
      'adminUsers': _users.where((user) => user.role == 'admin').length,
      'activeOrders': 0,
      'totalRevenue': 0.0,
      'pendingReports': 0,
    };
  }

  List<Map<String, dynamic>> getRecentActivity() {
    final activities = <Map<String, dynamic>>[];

    // Agregar solicitudes recientes
    for (final business in _pendingBusinesses.take(3)) {
      activities.add({
        'type': 'business',
        'message': 'Nueva solicitud: ${business['businessName']}',
        'time': DateTime.now(),
      });
    }

    // Agregar usuarios recientes
    for (final user in _users.take(2)) {
      activities.add({
        'type': 'user',
        'message': 'Nuevo usuario: ${user.email}',
        'time': DateTime.now(),
      });
    }

    return activities;
  }

  // Limpiar errores
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}