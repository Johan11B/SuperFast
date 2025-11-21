// order_viewmodel.dart - VERSIÓN COMPLETA CORREGIDA
import 'package:flutter/material.dart';
import '../../domain/entities/order_entity.dart';
import '../../core/services/order_service.dart';

class OrderViewModel with ChangeNotifier {
  final OrderService _orderService;

  OrderViewModel({required OrderService orderService})
      : _orderService = orderService;

  // ========== ESTADOS ==========
  bool _isLoading = false;
  bool _isLoadingUserOrders = false;
  bool _isLoadingBusinessOrders = false;
  bool _isLoadingAllOrders = false;
  String _errorMessage = '';
  String _successMessage = '';

  // ========== CONTROL DE CARGA ==========
  bool _userOrdersLoaded = false;
  bool _businessOrdersLoaded = false;
  bool _allOrdersLoaded = false;

  // ========== CONTROL DE EJECUCIÓN CONCURRENTE ==========
  bool _isExecutingAllOrders = false;
  bool _isExecutingUserOrders = false;
  bool _isExecutingBusinessOrders = false;


  // ========== DATOS ==========
  List<OrderEntity> _userOrders = [];
  List<OrderEntity> _businessOrders = [];
  List<OrderEntity> _allOrders = [];
  OrderEntity? _currentOrder;

  // ========== BÚSQUEDA Y FILTROS ==========
  String _userSearchQuery = '';
  String _businessSearchQuery = '';
  String _adminSearchQuery = '';

  // ========== GETTERS ==========
  bool get isLoading => _isLoading;
  bool get isLoadingUserOrders => _isLoadingUserOrders;
  bool get isLoadingBusinessOrders => _isLoadingBusinessOrders;
  bool get isLoadingAllOrders => _isLoadingAllOrders;
  String get errorMessage => _errorMessage;
  String get successMessage => _successMessage;

  List<OrderEntity> get userOrders => _userOrders;
  List<OrderEntity> get businessOrders => _businessOrders;
  List<OrderEntity> get allOrders => _allOrders;
  OrderEntity? get currentOrder => _currentOrder;

  // ========== MÉTODOS DE USUARIO ==========
  Future<void> loadUserOrders(String userId) async {
    if (_isLoadingUserOrders && _userOrdersLoaded) return;

    _isLoadingUserOrders = true;
    _errorMessage = '';
    notifyListeners();

    try {
      print('🔄 Cargando pedidos del usuario: $userId');
      _userOrders = await _orderService.getOrdersByUser(userId);
      _userOrdersLoaded = true;
      _errorMessage = '';

      print('✅ ${_userOrders.length} pedidos de usuario cargados');
    } catch (e) {
      _errorMessage = 'Error cargando tus pedidos: $e';
      _userOrders = [];
      print('❌ Error cargando pedidos de usuario: $e');
    } finally {
      _isLoadingUserOrders = false;
      notifyListeners();
    }
  }

  // ========== MÉTODOS DE NEGOCIO ==========
  Future<void> loadBusinessOrders(String businessId) async {
    if (_isLoadingBusinessOrders && _businessOrdersLoaded) return;
    _isExecutingBusinessOrders = true;
    _isLoadingBusinessOrders = true;
    _isLoadingBusinessOrders = true;
    _errorMessage = '';
    notifyListeners();

    try {
      print('🔄 Cargando pedidos del negocio: $businessId');
      _businessOrders = await _orderService.getOrdersByBusiness(businessId);
      _businessOrdersLoaded = true;
      _errorMessage = '';

      print('✅ ${_businessOrders.length} pedidos de negocio cargados');
    } catch (e) {
      _errorMessage = 'Error cargando pedidos del negocio: $e';
      _businessOrders = [];
      print('❌ Error cargando pedidos de negocio: $e');
    } finally {
      _isLoadingBusinessOrders = false;
      notifyListeners();
    }
  }

  // ========== MÉTODOS DE ADMIN ==========
  Future<void> loadAllOrders() async {
    // ✅ PREVENIR EJECUCIÓN CONCURRENTE Y RECARGAS MÚLTIPLES
    if (_isExecutingAllOrders || (_isLoadingAllOrders && _allOrdersLoaded)) {
      print('⏳ Carga de pedidos en progreso, ignorando llamada...');
      return;
    }
    _isExecutingUserOrders = true;
    _isLoadingUserOrders = true;
    _isExecutingAllOrders = true;
    _isLoadingAllOrders = true;
    _errorMessage = '';
    notifyListeners();

    try {
      print('🔄 Cargando todos los pedidos...');
      _allOrders = await _orderService.getAllOrders();
      _allOrdersLoaded = true;
      _errorMessage = '';

      print('✅ ${_allOrders.length} pedidos totales cargados');
    } catch (e) {
      _errorMessage = 'Error cargando todos los pedidos: $e';
      _allOrders = [];
      print('❌ Error cargando todos los pedidos: $e');
    } finally {
      _isLoadingAllOrders = false;
      _isExecutingAllOrders = false;
      notifyListeners();
    }
  }


  // ========== OPERACIONES COMUNES ==========
  Future<bool> createOrder(OrderEntity order) async {
    _isLoading = true;
    _errorMessage = '';
    _successMessage = '';
    notifyListeners();

    try {
      print('🔄 Creando nuevo pedido: ${order.id}');

      await _orderService.createOrder(
        orderId: order.id,
        userId: order.userId,
        businessId: order.businessId,
        userName: order.userName,
        businessName: order.businessName,
        totalAmount: order.totalAmount,
        subtotal: order.subtotal,
        deliveryFee: order.deliveryFee,
        tax: order.tax,
        items: order.items,
        userNote: order.userNote,
        deliveryAddress: order.deliveryAddress,
        paymentMethod: order.paymentMethod,
      );

      // Actualizar listas locales
      _userOrders.insert(0, order);
      _businessOrders.insert(0, order);
      _allOrders.insert(0, order);

      _successMessage = '¡Pedido creado exitosamente!';
      print('✅ Pedido creado: ${order.id}');
      return true;
    } catch (e) {
      _errorMessage = 'Error creando pedido: $e';
      print('❌ Error creando pedido: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateOrderStatus(String orderId, String status, {String? rejectionReason}) async {
    _isLoading = true;
    _errorMessage = '';
    _successMessage = '';
    notifyListeners();

    try {
      print('🔄 Actualizando estado del pedido: $orderId -> $status');

      await _orderService.updateOrderStatus(orderId, status);

      // Actualizar en listas locales
      _updateOrderInLists(orderId, (order) => order.copyWith(status: status));

      _successMessage = 'Estado del pedido actualizado exitosamente';
      print('✅ Estado actualizado: $orderId -> $status');
      return true;
    } catch (e) {
      _errorMessage = 'Error actualizando estado del pedido: $e';
      print('❌ Error actualizando estado: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePaymentStatus(String orderId, String paymentStatus) async {
    _isLoading = true;
    _errorMessage = '';
    _successMessage = '';
    notifyListeners();

    try {
      print('🔄 Actualizando estado de pago: $orderId -> $paymentStatus');

      await _orderService.updatePaymentStatus(orderId, paymentStatus);

      // Actualizar en listas locales
      _updateOrderInLists(orderId, (order) => order.copyWith(paymentStatus: paymentStatus));

      _successMessage = 'Estado de pago actualizado exitosamente';
      print('✅ Estado de pago actualizado: $orderId -> $paymentStatus');
      return true;
    } catch (e) {
      _errorMessage = 'Error actualizando estado de pago: $e';
      print('❌ Error actualizando estado de pago: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addOrderNote(String orderId, String note) async {
    try {
      print('🔄 Agregando nota al pedido: $orderId');

      await _orderService.addOrderNote(orderId, note);

      // Actualizar en listas locales
      _updateOrderInLists(orderId, (order) {
        final currentNotes = order.orderNotes ?? [];
        return order.copyWith(orderNotes: [...currentNotes, note]);
      });

      print('✅ Nota agregada al pedido: $orderId');
      return true;
    } catch (e) {
      _errorMessage = 'Error agregando nota al pedido: $e';
      print('❌ Error agregando nota: $e');
      return false;
    }
  }

  // ========== MÉTODOS DE BÚSQUEDA Y FILTRADO ==========
  List<OrderEntity> searchUserOrders(String query) {
    if (query.isEmpty) return _userOrders;

    return _userOrders.where((order) {
      return order.id.toLowerCase().contains(query.toLowerCase()) ||
          order.businessName.toLowerCase().contains(query.toLowerCase()) ||
          order.status.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  List<OrderEntity> searchBusinessOrders(String query) {
    if (query.isEmpty) return _businessOrders;

    return _businessOrders.where((order) {
      return order.id.toLowerCase().contains(query.toLowerCase()) ||
          order.userName.toLowerCase().contains(query.toLowerCase()) ||
          order.status.toLowerCase().contains(query.toLowerCase()) ||
          (order.userNote?.toLowerCase().contains(query.toLowerCase()) ?? false);
    }).toList();
  }

  List<OrderEntity> searchAllOrders(String query) {
    if (query.isEmpty) return _allOrders;

    return _allOrders.where((order) {
      return order.id.toLowerCase().contains(query.toLowerCase()) ||
          order.userName.toLowerCase().contains(query.toLowerCase()) ||
          order.businessName.toLowerCase().contains(query.toLowerCase()) ||
          order.status.toLowerCase().contains(query.toLowerCase()) ||
          (order.userNote?.toLowerCase().contains(query.toLowerCase()) ?? false);
    }).toList();
  }

  // ========== MÉTODOS DE ESTADÍSTICAS ==========
  Map<String, dynamic> getUserOrderStats(String userId) {
    final userOrders = _userOrders.where((order) => order.userId == userId).toList();

    final totalSpent = userOrders.fold(0.0, (sum, order) => sum + order.totalAmount);
    final averageOrderValue = userOrders.isNotEmpty ? totalSpent / userOrders.length : 0;

    return {
      'totalOrders': userOrders.length,
      'pendingOrders': userOrders.where((o) => o.isPending).length,
      'confirmedOrders': userOrders.where((o) => o.isConfirmed).length,
      'preparingOrders': userOrders.where((o) => o.isPreparing).length,
      'readyOrders': userOrders.where((o) => o.isReady).length,
      'deliveredOrders': userOrders.where((o) => o.isDelivered).length,
      'cancelledOrders': userOrders.where((o) => o.isCancelled).length,
      'activeOrders': userOrders.where((o) => o.isActive).length,
      'totalSpent': totalSpent,
      'averageOrderValue': averageOrderValue,
    };
  }

  Map<String, dynamic> getBusinessOrderStats(String businessId) {
    final businessOrders = _businessOrders.where((order) => order.businessId == businessId).toList();

    final totalRevenue = businessOrders.fold(0.0, (sum, order) => sum + order.totalAmount);
    final averageOrderValue = businessOrders.isNotEmpty ? totalRevenue / businessOrders.length : 0;
    final completionRate = businessOrders.isNotEmpty
        ? (businessOrders.where((o) => o.isDelivered).length / businessOrders.length) * 100
        : 0;

    return {
      'totalOrders': businessOrders.length,
      'pendingOrders': businessOrders.where((o) => o.isPending).length,
      'confirmedOrders': businessOrders.where((o) => o.isConfirmed).length,
      'preparingOrders': businessOrders.where((o) => o.isPreparing).length,
      'readyOrders': businessOrders.where((o) => o.isReady).length,
      'deliveredOrders': businessOrders.where((o) => o.isDelivered).length,
      'cancelledOrders': businessOrders.where((o) => o.isCancelled).length,
      'totalRevenue': totalRevenue,
      'averageOrderValue': averageOrderValue,
      'completionRate': completionRate,
      'cancellationRate': businessOrders.isNotEmpty
          ? (businessOrders.where((o) => o.isCancelled).length / businessOrders.length) * 100
          : 0,
    };
  }

  Map<String, dynamic> getAdminOrderStats() {
    final totalRevenue = _allOrders.fold(0.0, (sum, order) => sum + order.totalAmount);
    final averageOrderValue = _allOrders.isNotEmpty ? totalRevenue / _allOrders.length : 0;

    // Estadísticas por estado
    final statusStats = {
      'pending': _allOrders.where((o) => o.isPending).length,
      'confirmed': _allOrders.where((o) => o.isConfirmed).length,
      'preparing': _allOrders.where((o) => o.isPreparing).length,
      'ready': _allOrders.where((o) => o.isReady).length,
      'delivered': _allOrders.where((o) => o.isDelivered).length,
      'cancelled': _allOrders.where((o) => o.isCancelled).length,
    };

    return {
      'totalOrders': _allOrders.length,
      'totalRevenue': totalRevenue,
      'averageOrderValue': averageOrderValue,
      'statusStats': statusStats,
      'completionRate': _allOrders.isNotEmpty
          ? (_allOrders.where((o) => o.isDelivered).length / _allOrders.length) * 100
          : 0,
      'cancellationRate': _allOrders.isNotEmpty
          ? (_allOrders.where((o) => o.isCancelled).length / _allOrders.length) * 100
          : 0,
    };
  }

  // ========== MÉTODOS DE OBTENCIÓN DE DATOS ESPECÍFICOS ==========
  OrderEntity? getOrderById(String orderId) {
    try {
      return _allOrders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  List<OrderEntity> getOrdersByBusinessAndStatus(String businessId, String status) {
    return _businessOrders.where((order) =>
    order.businessId == businessId && order.status == status
    ).toList();
  }

  List<OrderEntity> getRecentOrders({int limit = 10, String? businessId, String? userId}) {
    List<OrderEntity> source = _allOrders;

    if (businessId != null) {
      source = _businessOrders.where((order) => order.businessId == businessId).toList();
    } else if (userId != null) {
      source = _userOrders.where((order) => order.userId == userId).toList();
    }

    final sortedOrders = List<OrderEntity>.from(source)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return sortedOrders.take(limit).toList();
  }

  List<OrderEntity> getTodaysOrders({String? businessId}) {
    final today = DateTime.now();
    List<OrderEntity> source = businessId != null
        ? _businessOrders.where((order) => order.businessId == businessId).toList()
        : _allOrders;

    return source.where((order) =>
    order.createdAt.day == today.day &&
        order.createdAt.month == today.month &&
        order.createdAt.year == today.year
    ).toList();
  }

  // ========== MÉTODOS DE ACTUALIZACIÓN EN TIEMPO REAL ==========
  Future<void> refreshUserOrders(String userId) async {
    _userOrdersLoaded = false;
    await loadUserOrders(userId);
  }

  Future<void> refreshBusinessOrders(String businessId) async {
    _businessOrdersLoaded = false;
    await loadBusinessOrders(businessId);
  }

  Future<void> refreshAllOrders() async {
    _allOrdersLoaded = false;
    await loadAllOrders();
  }

  void updateOrderLocally(OrderEntity updatedOrder) {
    _updateOrderInLists(updatedOrder.id, (_) => updatedOrder);
    notifyListeners();
    print('✅ Pedido actualizado localmente: ${updatedOrder.id}');
  }

  // ========== MÉTODOS AUXILIARES PRIVADOS ==========
  void _updateOrderInLists(String orderId, OrderEntity Function(OrderEntity) updateFn) {
    // Actualizar en userOrders
    final userIndex = _userOrders.indexWhere((order) => order.id == orderId);
    if (userIndex != -1) {
      _userOrders[userIndex] = updateFn(_userOrders[userIndex]);
    }

    // Actualizar en businessOrders
    final businessIndex = _businessOrders.indexWhere((order) => order.id == orderId);
    if (businessIndex != -1) {
      _businessOrders[businessIndex] = updateFn(_businessOrders[businessIndex]);
    }

    // Actualizar en allOrders
    final allIndex = _allOrders.indexWhere((order) => order.id == orderId);
    if (allIndex != -1) {
      _allOrders[allIndex] = updateFn(_allOrders[allIndex]);
    }

    // Actualizar currentOrder si es el mismo
    if (_currentOrder?.id == orderId) {
      _currentOrder = updateFn(_currentOrder!);
    }
  }

  // ========== MÉTODOS DE VALIDACIÓN ==========
  bool isValidOrderStatus(String status) {
    return const [
      'pending', 'confirmed', 'preparing', 'ready', 'delivered', 'cancelled'
    ].contains(status);
  }

  bool isValidPaymentStatus(String status) {
    return const [
      'pending', 'paid', 'failed', 'refunded'
    ].contains(status);
  }

  bool canUpdateOrderStatus(OrderEntity order, String newStatus) {
    // Lógica de transiciones de estado válidas
    final validTransitions = {
      'pending': ['confirmed', 'cancelled'],
      'confirmed': ['preparing', 'cancelled'],
      'preparing': ['ready', 'cancelled'],
      'ready': ['delivered'],
      'delivered': [], // Estado final
      'cancelled': [], // Estado final
    };

    return validTransitions[order.status]?.contains(newStatus) ?? false;
  }

  // ========== MÉTODOS PARA TRANSICIONES DE ESTADO ==========
  List<String> getAvailableStatusTransitions(String currentStatus) {
    final Map<String, List<String>> transitions = {
      'pending': ['confirmed', 'cancelled'],
      'confirmed': ['preparing', 'cancelled'],
      'preparing': ['ready', 'cancelled'],
      'ready': ['delivered'],
      'delivered': [],
      'cancelled': [],
    };

    return transitions[currentStatus] ?? [];
  }

  // ========== MÉTODOS DE ESTADÍSTICAS ADICIONALES ==========
  Map<String, double> getDailyRevenue(String businessId) {
    final businessOrders = _businessOrders.where((order) =>
    order.businessId == businessId && order.isDelivered
    ).toList();

    final dailyRevenue = <String, double>{};

    for (var order in businessOrders) {
      final dateKey = '${order.createdAt.day}/${order.createdAt.month}';
      dailyRevenue[dateKey] = (dailyRevenue[dateKey] ?? 0) + order.totalAmount;
    }

    return dailyRevenue;
  }

  Map<int, int> getOrdersByHour(String businessId) {
    final businessOrders = _businessOrders.where((order) =>
    order.businessId == businessId
    ).toList();

    final ordersByHour = <int, int>{};

    for (var hour = 0; hour < 24; hour++) {
      ordersByHour[hour] = businessOrders.where((order) =>
      order.createdAt.hour == hour
      ).length;
    }

    return ordersByHour;
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
    _adminSearchQuery = '';
    notifyListeners();
  }

  void reset() {
    _isLoading = false;
    _isLoadingUserOrders = false;
    _isLoadingBusinessOrders = false;
    _isLoadingAllOrders = false;
    _errorMessage = '';
    _successMessage = '';

    _userOrders.clear();
    _businessOrders.clear();
    _allOrders.clear();
    _currentOrder = null;

    _userOrdersLoaded = false;
    _businessOrdersLoaded = false;
    _allOrdersLoaded = false;

    _userSearchQuery = '';
    _businessSearchQuery = '';
    _adminSearchQuery = '';

    notifyListeners();
  }

  // ========== MÉTODOS DE DEBUG ==========
  void debugPrintOrderStats() {
    print('=== ESTADÍSTICAS DE PEDIDOS ===');
    print('👤 Pedidos de usuario: ${_userOrders.length}');
    print('🏢 Pedidos de negocio: ${_businessOrders.length}');
    print('👑 Todos los pedidos: ${_allOrders.length}');

    if (_allOrders.isNotEmpty) {
      final stats = getAdminOrderStats();
      print('💰 Ingreso total: \$${stats['totalRevenue']?.toStringAsFixed(2)}');
      print('📊 Tasa de finalización: ${stats['completionRate']?.toStringAsFixed(1)}%');
    }
    print('================================');
  }

  @override
  void dispose() {
    // Limpiar cualquier suscripción si es necesario
    super.dispose();
  }
}