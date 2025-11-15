import 'package:flutter/foundation.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/business_entity.dart';
import '../../core/services/user_service.dart';
import '../../core/services/business_service.dart';

class AdminViewModel extends ChangeNotifier {
  final UserService _userService;
  final BusinessService _businessService;

  String? _lastError;
  String? get lastError => _lastError;

  String? _lastSuccess;
  String? get lastSuccess => _lastSuccess;

  AdminViewModel({
    required UserService userService,
    required BusinessService businessService,
  })  : _userService = userService,
        _businessService = businessService;

  // ========== ESTADOS DE CARGA ==========
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingBusinesses = false;
  bool get isLoadingBusinesses => _isLoadingBusinesses;

  // ========== DATOS ==========
  List<UserEntity> _users = [];
  List<UserEntity> get users => _users;

  List<BusinessEntity> _businesses = [];
  List<BusinessEntity> get businesses => _businesses;

  // ========== BÚSQUEDA Y FILTROS ==========
  String _userSearchQuery = '';
  String _businessSearchQuery = '';

  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  // ========== GETTERS PARA USUARIOS FILTRADOS ==========
  List<UserEntity> get filteredUsers {
    if (_userSearchQuery.isEmpty) return _users;

    return _users.where((user) {
      final emailMatch = user.email.toLowerCase().contains(_userSearchQuery.toLowerCase());
      final nameMatch = user.name?.toLowerCase().contains(_userSearchQuery.toLowerCase()) ?? false;
      return emailMatch || nameMatch;
    }).toList();
  }

  // ========== GETTERS PARA NEGOCIOS FILTRADOS ==========
  List<BusinessEntity> get filteredBusinesses {
    if (_businessSearchQuery.isEmpty) return _businesses;

    return _businesses.where((business) {
      final name = business.name.toLowerCase();
      final email = business.email.toLowerCase();
      final category = business.category.toLowerCase();
      final address = business.address.toLowerCase();

      return name.contains(_businessSearchQuery.toLowerCase()) ||
          email.contains(_businessSearchQuery.toLowerCase()) ||
          category.contains(_businessSearchQuery.toLowerCase()) ||
          address.contains(_businessSearchQuery.toLowerCase());
    }).toList();
  }

  // ========== GETTERS PARA NEGOCIOS POR ESTADO ==========
  List<BusinessEntity> get pendingBusinesses {
    return filteredBusinesses.where((b) => b.status == 'pending').toList();
  }

  List<BusinessEntity> get approvedBusinesses {
    return filteredBusinesses.where((b) => b.status == 'approved').toList();
  }

  List<BusinessEntity> get suspendedBusinesses {
    return filteredBusinesses.where((b) => b.status == 'suspended').toList();
  }

  List<BusinessEntity> get rejectedBusinesses {
    return filteredBusinesses.where((b) => b.status == 'rejected').toList();
  }

  // ========== MÉTODOS DE NAVEGACIÓN ==========
  void changeTab(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  // ========== MÉTODOS DE USUARIOS ==========
  Future<void> loadUsers() async {
    try {
      _isLoading = true;
      _lastError = null;
      notifyListeners();

      _users = await _userService.getAllUsers();

      print('✅ Usuarios cargados: ${_users.length}');
      for (var user in _users) {
        print('👤 Usuario: ${user.name ?? "Sin nombre"} - ${user.email} - Rol: ${user.role}');
      }
    } catch (e) {
      _lastError = 'Error cargando usuarios: $e';
      print('❌ Error cargando usuarios: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateUserSearch(String query) {
    _userSearchQuery = query;
    notifyListeners();
  }

  Future<bool> changeUserRole(String userId, String newRole) async {
    try {
      await _userService.updateUserRole(userId, newRole);
      await loadUsers();

      _lastSuccess = 'Rol cambiado a ${_getRoleDisplayName(newRole)}';
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = 'Error cambiando rol: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      await _userService.deleteUser(userId);
      await loadUsers();

      _lastSuccess = 'Usuario eliminado correctamente';
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = 'Error eliminando usuario: $e';
      notifyListeners();
      return false;
    }
  }

  // ========== MÉTODOS DE NEGOCIOS ==========
  Future<void> loadBusinesses() async {
    try {
      _isLoadingBusinesses = true;
      _lastError = null;
      notifyListeners();

      _businesses = await _businessService.getAllBusinesses();
      print('✅ Negocios cargados: ${_businesses.length}');

      // Log de negocios para debugging
      for (var business in _businesses.take(3)) {
        print('🏪 Negocio: ${business.name} - ${business.status} - ${business.category}');
      }
    } catch (e) {
      _lastError = 'Error cargando negocios: $e';
      print('❌ Error cargando negocios: $e');
    } finally {
      _isLoadingBusinesses = false;
      notifyListeners();
    }
  }

  void updateBusinessSearch(String query) {
    _businessSearchQuery = query;
    notifyListeners();
  }

  Future<bool> approveBusiness(String businessId) async {
    try {
      await _businessService.updateBusinessStatus(businessId, 'approved');
      await loadBusinesses();

      _lastSuccess = 'Negocio aprobado correctamente';
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = 'Error aprobando negocio: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectBusiness(String businessId) async {
    try {
      await _businessService.updateBusinessStatus(businessId, 'rejected');
      await loadBusinesses();

      _lastSuccess = 'Negocio rechazado correctamente';
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = 'Error rechazando negocio: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> suspendBusiness(String businessId) async {
    try {
      await _businessService.updateBusinessStatus(businessId, 'suspended');
      await loadBusinesses();

      _lastSuccess = 'Negocio suspendido correctamente';
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = 'Error suspendiendo negocio: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> activateBusiness(String businessId) async {
    try {
      await _businessService.updateBusinessStatus(businessId, 'approved');
      await loadBusinesses();

      _lastSuccess = 'Negocio activado correctamente';
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = 'Error activando negocio: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBusiness(String businessId) async {
    try {
      await _businessService.deleteBusiness(businessId);
      await loadBusinesses();

      _lastSuccess = 'Negocio eliminado correctamente';
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = 'Error eliminando negocio: $e';
      notifyListeners();
      return false;
    }
  }

  // ========== MÉTODOS DEL DASHBOARD ==========
  Future<void> loadDashboardData() async {
    try {
      _isLoading = true;
      _lastError = null;
      notifyListeners();

      // Cargar usuarios y negocios en paralelo
      await Future.wait([
        loadUsers(),
        loadBusinesses(),
      ]);

      print('✅ Dashboard cargado: ${_users.length} usuarios, ${_businesses.length} negocios');
    } catch (e) {
      _lastError = 'Error cargando dashboard: $e';
      print('❌ Error cargando dashboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> getDashboardStats() {
    final totalUsers = _users.length;
    final businessUsers = _users.where((user) => user.role == 'business').length;
    final adminUsers = _users.where((user) => user.role == 'admin').length;
    final regularUsers = _users.where((user) => user.role == 'user').length;

    final pendingBusinessesCount = _businesses.where((b) => b.status == 'pending').length;
    final approvedBusinessesCount = _businesses.where((b) => b.status == 'approved').length;
    final suspendedBusinessesCount = _businesses.where((b) => b.status == 'suspended').length;
    final rejectedBusinessesCount = _businesses.where((b) => b.status == 'rejected').length;
    final activeBusinessesCount = approvedBusinessesCount;

    // Calcular métricas adicionales
    final totalRevenue = _calculateTotalRevenue();
    final averageRating = _calculateAverageRating();

    return {
      'totalUsers': totalUsers,
      'businessUsers': businessUsers,
      'adminUsers': adminUsers,
      'regularUsers': regularUsers,
      'pendingBusinesses': pendingBusinessesCount,
      'approvedBusinesses': approvedBusinessesCount,
      'suspendedBusinesses': suspendedBusinessesCount,
      'rejectedBusinesses': rejectedBusinessesCount,
      'activeBusinesses': activeBusinessesCount,
      'totalRevenue': totalRevenue,
      'averageRating': averageRating,
    };
  }

  double _calculateTotalRevenue() {
    // Placeholder para cálculo de ingresos
    return 0.0;
  }

  double _calculateAverageRating() {
    if (_businesses.isEmpty) return 0.0;

    final ratedBusinesses = _businesses.where((b) => b.rating != null && b.rating! > 0).toList();
    if (ratedBusinesses.isEmpty) return 0.0;

    final totalRating = ratedBusinesses.map((b) => b.rating!).reduce((a, b) => a + b);
    return totalRating / ratedBusinesses.length;
  }

  List<Map<String, dynamic>> getRecentActivity() {
    final activities = <Map<String, dynamic>>[];

    // Agregar actividad de usuarios recientes
    final recentUsers = _users.take(3).toList();
    for (var user in recentUsers) {
      activities.add({
        'type': 'user',
        'message': 'Nuevo usuario registrado: ${user.email}',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
        'userEmail': user.email,
      });
    }

    // Agregar actividad de negocios pendientes
    final pendingBusinesses = _businesses.where((b) => b.status == 'pending').take(2).toList();
    for (var business in pendingBusinesses) {
      activities.add({
        'type': 'business',
        'message': 'Solicitud pendiente: ${business.name}',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 15)),
        'businessName': business.name,
      });
    }

    // Ordenar por timestamp (más reciente primero)
    activities.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

    return activities.take(5).toList();
  }

  // ========== MÉTODOS ADICIONALES PARA ESTADÍSTICAS ==========
  int get totalUsersCount => _users.length;
  int get businessUsersCount => _users.where((user) => user.role == 'business').length;
  int get adminUsersCount => _users.where((user) => user.role == 'admin').length;
  int get regularUsersCount => _users.where((user) => user.role == 'user').length;

  // ========== MÉTODOS DE BÚSQUEDA AVANZADA ==========
  List<UserEntity> searchUsersByRole(String role) {
    return _users.where((user) => user.role == role).toList();
  }

  List<UserEntity> searchUsersByName(String name) {
    return _users.where((user) =>
    user.name?.toLowerCase().contains(name.toLowerCase()) ?? false
    ).toList();
  }

  List<UserEntity> searchUsersByEmail(String email) {
    return _users.where((user) =>
        user.email.toLowerCase().contains(email.toLowerCase())
    ).toList();
  }

  List<BusinessEntity> searchBusinessesByCategory(String category) {
    return _businesses.where((business) =>
        business.category.toLowerCase().contains(category.toLowerCase())
    ).toList();
  }

  List<BusinessEntity> searchBusinessesByStatus(String status) {
    return _businesses.where((business) => business.status == status).toList();
  }

  // ========== MÉTODOS AUXILIARES ==========
  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'admin': return 'Administrador';
      case 'business': return 'Empresa';
      case 'user': return 'Usuario';
      default: return role;
    }
  }

  // ========== MÉTODOS DE RESET Y LIMPIEZA ==========
  void clearMessages() {
    _lastError = null;
    _lastSuccess = null;
    notifyListeners();
  }

  void clearSearch() {
    _userSearchQuery = '';
    _businessSearchQuery = '';
    notifyListeners();
  }

  void reset() {
    _users = [];
    _businesses = [];
    _userSearchQuery = '';
    _businessSearchQuery = '';
    _selectedIndex = 0;
    _isLoading = false;
    _isLoadingBusinesses = false;
    _lastError = null;
    _lastSuccess = null;
    notifyListeners();
  }

  // ========== MÉTODOS DE VALIDACIÓN ==========
  bool get hasUsers => _users.isNotEmpty;
  bool get hasBusinesses => _businesses.isNotEmpty;
  bool get hasPendingBusinesses => pendingBusinesses.isNotEmpty;
  bool get hasApprovedBusinesses => approvedBusinesses.isNotEmpty;

  // ========== MÉTODOS DE OBTENCIÓN DE DATOS ESPECÍFICOS ==========
  UserEntity? getUserById(String userId) {
    try {
      return _users.firstWhere((user) => user.id == userId);
    } catch (e) {
      return null;
    }
  }

  BusinessEntity? getBusinessById(String businessId) {
    try {
      return _businesses.firstWhere((business) => business.id == businessId);
    } catch (e) {
      return null;
    }
  }

  List<BusinessEntity> getBusinessesByOwner(String ownerId) {
    return _businesses.where((business) => business.ownerId == ownerId).toList();
  }

  // ========== MÉTODOS DE ACTUALIZACIÓN EN TIEMPO REAL ==========
  void refreshData() {
    loadDashboardData();
  }

  void refreshUsers() {
    loadUsers();
  }

  void refreshBusinesses() {
    loadBusinesses();
  }
}