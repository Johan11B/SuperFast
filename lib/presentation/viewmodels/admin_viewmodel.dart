// lib/presentation/viewmodels/admin_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/business_entity.dart';
import '../../core/services/user_service.dart';
import '../../core/services/business_registration_service.dart';

class AdminViewModel extends ChangeNotifier {
  final UserService _userService;
  final BusinessRegistrationService _businessRegistrationService;

  // ========== ESTADOS ==========
  int _selectedIndex = 0;
  bool _isLoading = false;
  bool _isLoadingBusinesses = false;
  bool _isLoadingUsers = false;
  String _errorMessage = '';
  String _successMessage = '';

  // Control de carga
  bool _usersLoaded = false;
  bool _businessesLoaded = false;

  // ========== DATOS ==========
  List<UserEntity> _users = [];
  List<BusinessEntity> _businesses = [];

  // ========== BÚSQUEDA ==========
  String _userSearchQuery = '';
  String _businessSearchQuery = '';

  // ========== ESTADÍSTICAS ==========
  Map<String, int> _businessCounts = {
    'pending': 0,
    'approved': 0,
    'suspended': 0,
    'active': 0,
    'total': 0,
  };

  // ========== CONSTRUCTOR ==========
  AdminViewModel({
    required UserService userService,
    required BusinessRegistrationService businessRegistrationService,
  })  : _userService = userService,
        _businessRegistrationService = businessRegistrationService;

  // ========== GETTERS ==========
  int get selectedIndex => _selectedIndex;
  bool get isLoading => _isLoading;
  bool get isLoadingBusinesses => _isLoadingBusinesses;
  bool get isLoadingUsers => _isLoadingUsers;
  String get errorMessage => _errorMessage;
  String get successMessage => _successMessage;

  // ✅ CORREGIDO: Mantener ambos getters para compatibilidad
  List<UserEntity> get users => _users;
  List<UserEntity> get filteredUsers => _filterUsers(_users); // Para AdminUsersScreen

  List<BusinessEntity> get businesses => _businesses;
  List<BusinessEntity> get pendingBusinesses => _filterBusinesses(_businesses.where((b) => b.status == 'pending').toList());
  List<BusinessEntity> get approvedBusinesses => _filterBusinesses(_businesses.where((b) => b.status == 'approved').toList());
  List<BusinessEntity> get suspendedBusinesses => _filterBusinesses(_businesses.where((b) => b.status == 'suspended').toList());
  List<BusinessEntity> get rejectedBusinesses => _filterBusinesses(_businesses.where((b) => b.status == 'rejected').toList());

  Map<String, int> get businessCounts => _businessCounts;

  // ========== NAVEGACIÓN ==========
  void changeTab(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  // ========== BÚSQUEDA ==========
  void updateUserSearch(String query) {
    _userSearchQuery = query.toLowerCase();
    notifyListeners();
  }

  void updateBusinessSearch(String query) {
    _businessSearchQuery = query.toLowerCase();
    notifyListeners();
  }

  List<UserEntity> _filterUsers(List<UserEntity> list) {
    if (_userSearchQuery.isEmpty) return list;
    return list.where((user) =>
    user.email.toLowerCase().contains(_userSearchQuery) ||
        (user.name?.toLowerCase().contains(_userSearchQuery) ?? false) ||
        user.id.toLowerCase().contains(_userSearchQuery)
    ).toList();
  }

  List<BusinessEntity> _filterBusinesses(List<BusinessEntity> list) {
    if (_businessSearchQuery.isEmpty) return list;
    return list.where((business) =>
    business.name.toLowerCase().contains(_businessSearchQuery) ||
        business.email.toLowerCase().contains(_businessSearchQuery) ||
        business.category.toLowerCase().contains(_businessSearchQuery) ||
        business.address.toLowerCase().contains(_businessSearchQuery) ||
        business.id.toLowerCase().contains(_businessSearchQuery)
    ).toList();
  }

  // ========== CARGA DE DATOS DEL DASHBOARD ==========
  Future<void> loadDashboardData() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await Future.wait([
        loadBusinessCounts(),
        loadUsers(),
        loadBusinesses(),
      ]);
      print('✅ Dashboard data cargado exitosamente');
    } catch (e) {
      _errorMessage = 'Error cargando datos del dashboard: $e';
      print('❌ Error cargando dashboard data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== MÉTODOS DE USUARIOS ==========
  Future<void> loadUsers() async {
    if (_isLoadingUsers && _usersLoaded) return;

    try {
      _isLoadingUsers = true;
      _errorMessage = '';
      notifyListeners();

      _users = await _userService.getAllUsers();
      _usersLoaded = true;

      print('✅ Usuarios cargados: ${_users.length}');
    } catch (e) {
      _errorMessage = 'Error cargando usuarios: $e';
      _users = [];
      print('❌ Error cargando usuarios: $e');
    } finally {
      _isLoadingUsers = false;
      notifyListeners();
    }
  }

  Future<void> reloadUsers() async {
    _usersLoaded = false;
    await loadUsers();
  }

  Future<void> changeUserRole(String userId, String newRole) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _userService.updateUserRole(userId, newRole);
      await reloadUsers();
      _successMessage = 'Rol de usuario cambiado exitosamente';
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Error cambiando rol: $e';
      _successMessage = '';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteUser(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _userService.deleteUser(userId);
      await reloadUsers();
      _successMessage = 'Usuario eliminado exitosamente';
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Error eliminando usuario: $e';
      _successMessage = '';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== MÉTODOS DE NEGOCIOS ==========
  Future<void> loadBusinesses() async {
    if (_isLoadingBusinesses && _businessesLoaded) return;

    _isLoadingBusinesses = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Cargar negocios pendientes y activos por separado
      final pendingData = await _businessRegistrationService.getPendingRegistrations();
      final activeData = await _businessRegistrationService.getActiveBusinesses();

      // Combinar y convertir a BusinessEntity
      final allBusinessesData = [...pendingData, ...activeData];
      _businesses = allBusinessesData.map((businessMap) {
        return BusinessEntity.fromMap(businessMap);
      }).toList();

      _businessesLoaded = true;

      print('✅ Negocios cargados: ${_businesses.length}');
      print('📊 Pendientes: ${pendingBusinesses.length}');
      print('📊 Aprobados: ${approvedBusinesses.length}');
      print('📊 Suspendidos: ${suspendedBusinesses.length}');

      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Error cargando negocios: $e';
      _businesses = [];
      print('❌ Error cargando negocios: $e');
    } finally {
      _isLoadingBusinesses = false;
      notifyListeners();
    }
  }

  Future<void> reloadBusinesses() async {
    _businessesLoaded = false;
    await loadBusinesses();
  }

  Future<void> loadBusinessCounts() async {
    try {
      _businessCounts = await _businessRegistrationService.getBusinessCounts();
      print('✅ Conteos de negocios cargados: $_businessCounts');
    } catch (e) {
      print('❌ Error cargando conteos de negocios: $e');
      _businessCounts = {
        'pending': 0,
        'approved': 0,
        'suspended': 0,
        'active': 0,
        'total': 0,
      };
    }
  }

  // ========== OPERACIONES DE NEGOCIOS ==========
  Future<void> approveBusiness(String businessId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _businessRegistrationService.approveBusinessRegistration(businessId);
      await reloadBusinesses();
      await reloadUsers(); // Para actualizar roles si es necesario
      _successMessage = 'Negocio aprobado exitosamente';
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Error aprobando negocio: $e';
      _successMessage = '';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> rejectBusiness(String businessId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _businessRegistrationService.rejectBusinessRegistration(businessId);
      await reloadBusinesses();
      _successMessage = 'Negocio rechazado exitosamente';
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Error rechazando negocio: $e';
      _successMessage = '';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> suspendBusiness(String businessId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _businessRegistrationService.suspendBusiness(businessId);
      await reloadBusinesses();
      _successMessage = 'Negocio suspendido exitosamente';
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Error suspendiendo negocio: $e';
      _successMessage = '';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> activateBusiness(String businessId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _businessRegistrationService.activateBusiness(businessId);
      await reloadBusinesses();
      _successMessage = 'Negocio activado exitosamente';
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Error activando negocio: $e';
      _successMessage = '';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteBusiness(String businessId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _businessRegistrationService.deleteBusiness(businessId);
      await reloadBusinesses();
      await reloadUsers(); // Para actualizar roles si es necesario
      _successMessage = 'Negocio eliminado exitosamente';
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Error eliminando negocio: $e';
      _successMessage = '';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== MÉTODOS DEL DASHBOARD ==========
  Map<String, dynamic> getDashboardStats() {
    final userStats = _calculateUserStats();

    return {
      'pendingBusinesses': _businessCounts['pending'] ?? 0,
      'approvedBusinesses': _businessCounts['approved'] ?? 0,
      'suspendedBusinesses': _businessCounts['suspended'] ?? 0,
      'activeBusinesses': _businessCounts['active'] ?? 0,
      'totalBusinesses': _businessCounts['total'] ?? 0,
      'totalUsers': userStats['total'],
      'activeUsers': userStats['user'],
      'businessUsers': userStats['business'],
      'adminUsers': userStats['admin'],
      'activeOrders': 0,
      'totalRevenue': 0.0,
      'pendingReports': 0,
    };
  }

  Map<String, int> _calculateUserStats() {
    return {
      'total': _users.length,
      'admin': _users.where((user) => user.role == 'admin').length,
      'business': _users.where((user) => user.role == 'business').length,
      'user': _users.where((user) => user.role == 'user').length,
    };
  }

  List<Map<String, dynamic>> getRecentActivity() {
    final activities = <Map<String, dynamic>>[];

    // Agregar solicitudes recientes de negocios
    for (final business in pendingBusinesses.take(3)) {
      activities.add({
        'type': 'business',
        'message': 'Nueva solicitud: ${business.name}',
        'time': business.createdAt ?? DateTime.now(),
        'businessName': business.name,
      });
    }

    // Agregar usuarios recientes
    for (final user in _users.take(2)) {
      activities.add({
        'type': 'user',
        'message': 'Nuevo usuario: ${user.email}',
        'time': DateTime.now(),
        'userEmail': user.email,
      });
    }

    // Ordenar por tiempo (más reciente primero)
    activities.sort((a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime));

    return activities.take(5).toList();
  }

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

  // ========== MÉTODOS DE ESTADÍSTICAS ==========
  int get totalUsersCount => _users.length;
  int get businessUsersCount => _users.where((user) => user.role == 'business').length;
  int get adminUsersCount => _users.where((user) => user.role == 'admin').length;
  int get regularUsersCount => _users.where((user) => user.role == 'user').length;

  bool get hasUsers => _users.isNotEmpty;
  bool get hasBusinesses => _businesses.isNotEmpty;
  bool get hasPendingBusinesses => pendingBusinesses.isNotEmpty;
  bool get hasApprovedBusinesses => approvedBusinesses.isNotEmpty;
  bool get hasSuspendedBusinesses => suspendedBusinesses.isNotEmpty;

  // ========== MÉTODOS DE ACTUALIZACIÓN EN TIEMPO REAL ==========
  Future<void> refreshData() async {
    _usersLoaded = false;
    _businessesLoaded = false;
    await loadDashboardData();
  }

  Future<void> refreshUsers() async {
    _usersLoaded = false;
    await loadUsers();
  }

  Future<void> refreshBusinesses() async {
    _businessesLoaded = false;
    await loadBusinesses();
  }

  // ========== MÉTODOS DE LIMPIEZA ==========
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  void clearSuccess() {
    _successMessage = '';
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = '';
    _successMessage = '';
    notifyListeners();
  }

  void clearSearch() {
    _userSearchQuery = '';
    _businessSearchQuery = '';
    notifyListeners();
  }

  void reset() {
    _selectedIndex = 0;
    _isLoading = false;
    _isLoadingBusinesses = false;
    _isLoadingUsers = false;
    _errorMessage = '';
    _successMessage = '';
    _users = [];
    _businesses = [];
    _userSearchQuery = '';
    _businessSearchQuery = '';
    _usersLoaded = false;
    _businessesLoaded = false;
    _businessCounts = {
      'pending': 0,
      'approved': 0,
      'suspended': 0,
      'active': 0,
      'total': 0,
    };
    notifyListeners();
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

  // ========== VALIDACIONES ==========
  bool isValidRole(String role) {
    return ['admin', 'business', 'user'].contains(role);
  }

  bool canChangeRole(UserEntity user, String newRole) {
    // No permitir cambiar el rol del usuario actual si es el único admin
    if (user.role == 'admin' && newRole != 'admin') {
      final adminCount = _users.where((u) => u.role == 'admin').length;
      return adminCount > 1;
    }
    return true;
  }
}