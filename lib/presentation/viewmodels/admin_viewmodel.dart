// lib/presentation/viewmodels/admin_viewmodel.dart - VERSIÓN CORREGIDA
import 'package:flutter/foundation.dart';
import '../../core/services/business_registration_service.dart';
import '../../core/services/user_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/business_entity.dart'; // AÑADIR ESTO

class AdminViewModel extends ChangeNotifier {
  final BusinessRegistrationService _businessService = BusinessRegistrationService();
  final UserService _userService = UserService();

  // Estados
  int _selectedIndex = 0;
  bool _isLoading = false;
  String _errorMessage = '';
  List<BusinessEntity> _pendingBusinesses = []; // CAMBIADO A BusinessEntity
  List<BusinessEntity> _approvedBusinesses = []; // CAMBIADO A BusinessEntity
  List<UserEntity> _users = []; // CAMBIADO A UserEntity
  String _businessSearch = '';
  String _userSearch = '';

  // Getters CORREGIDOS
  int get selectedIndex => _selectedIndex;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<BusinessEntity> get pendingBusinesses => _filterBusinesses(_pendingBusinesses); // CAMBIADO
  List<BusinessEntity> get businesses => _filterBusinesses(_approvedBusinesses); // CAMBIADO
  List<UserEntity> get users => _filterUsers(_users); // CAMBIADO

  // Métodos para cambiar pestaña
  void changeTab(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  // Métodos de búsqueda
  void updateBusinessSearch(String query) {
    _businessSearch = query.toLowerCase();
    notifyListeners();
  }

  void updateUserSearch(String query) {
    _userSearch = query.toLowerCase();
    notifyListeners();
  }

  // Filtros CORREGIDOS
  List<BusinessEntity> _filterBusinesses(List<BusinessEntity> list) {
    if (_businessSearch.isEmpty) return list;
    return list.where((business) =>
    business.name.toLowerCase().contains(_businessSearch) ||
        business.email.toLowerCase().contains(_businessSearch) ||
        business.category.toLowerCase().contains(_businessSearch)
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
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        loadPendingBusinesses(), // CAMBIADO
        loadApprovedBusinesses(),
        loadUsers(),
      ]);
    } catch (e) {
      _errorMessage = 'Error cargando datos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cargar negocios pendientes - NUEVO MÉTODO
  Future<void> loadPendingBusinesses() async {
    try {
      final registrations = await _businessService.getPendingRegistrations();
      _pendingBusinesses = registrations.map((map) => BusinessEntity.fromMap(map)).toList();
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Error cargando negocios pendientes: $e';
    }
    notifyListeners();
  }

  // Cargar negocios aprobados - CORREGIDO
  Future<void> loadApprovedBusinesses() async {
    try {
      final businesses = await _businessService.getApprovedBusinesses();
      _approvedBusinesses = businesses.map((map) => BusinessEntity.fromMap(map)).toList();
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Error cargando negocios aprobados: $e';
    }
    notifyListeners();
  }

  // Cargar usuarios - CORREGIDO
  Future<void> loadUsers() async {
    try {
      _users = await _userService.getAllUsers();
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Error cargando usuarios: $e';
    }
    notifyListeners();
  }

  // Método para cargar todos los negocios (usado en businesses screen)
  Future<void> loadBusinesses() async {
    await Future.wait([
      loadPendingBusinesses(),
      loadApprovedBusinesses(),
    ]);
  }

  // Aprobar negocio - CORREGIDO
  Future<void> approveBusiness(String businessId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _businessService.approveBusinessRegistration(businessId);
      await loadPendingBusinesses();
      await loadApprovedBusinesses();
      await loadUsers(); // Para actualizar roles si es necesario
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Error aprobando negocio: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Rechazar negocio - CORREGIDO
  Future<void> rejectBusiness(String businessId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _businessService.rejectBusinessRegistration(businessId);
      await loadPendingBusinesses();
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Error rechazando negocio: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Suspender negocio - CORREGIDO
  Future<void> suspendBusiness(String businessId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _businessService.suspendBusiness(businessId);
      await loadApprovedBusinesses();
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Error suspendiendo negocio: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Activar negocio - CORREGIDO
  Future<void> activateBusiness(String businessId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _businessService.activateBusiness(businessId);
      await loadApprovedBusinesses();
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Error activando negocio: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Eliminar negocio - CORREGIDO
  Future<void> deleteBusiness(String businessId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _businessService.deleteBusiness(businessId);
      await loadApprovedBusinesses();
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Error eliminando negocio: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cambiar rol de usuario - CORREGIDO
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

  // Eliminar usuario - CORREGIDO
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

  // Métodos para el dashboard - CORREGIDOS
  Map<String, dynamic> getDashboardStats() {
    return {
      'pendingBusinesses': _pendingBusinesses.length,
      'approvedBusinesses': _approvedBusinesses.length,
      'totalUsers': _users.length,
      'activeUsers': _users.where((user) => user.role == 'user').length,
      'businessUsers': _users.where((user) => user.role == 'business').length,
      'adminUsers': _users.where((user) => user.role == 'admin').length,
      'activeOrders': 0, // Placeholder
      'totalRevenue': 0.0, // Placeholder
      'pendingReports': 0, // Placeholder
    };
  }

  List<Map<String, dynamic>> getRecentActivity() {
    final activities = <Map<String, dynamic>>[];

    // Agregar solicitudes recientes
    for (final business in _pendingBusinesses.take(3)) {
      activities.add({
        'type': 'business',
        'message': 'Nueva solicitud: ${business.name}',
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
}