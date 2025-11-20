// lib/presentation/viewmodels/order_viewmodel.dart
import 'package:flutter/material.dart';
import '../../domain/entities/order_entity.dart';
import '../../core/services/order_service.dart';

class OrderViewModel with ChangeNotifier {
  final OrderService _orderService;

  OrderViewModel({required OrderService orderService})
      : _orderService = orderService;

  // ========== ESTADOS ==========
  bool _isLoading = false;
  String _errorMessage = '';
  String _successMessage = '';

  // ========== DATOS ==========
  List<OrderEntity> _userOrders = [];
  List<OrderEntity> _businessOrders = [];
  List<OrderEntity> _allOrders = [];
  OrderEntity? _currentOrder;

  // ========== GETTERS ==========
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get successMessage => _successMessage;

  List<OrderEntity> get userOrders => _userOrders;
  List<OrderEntity> get businessOrders => _businessOrders;
  List<OrderEntity> get allOrders => _allOrders;
  OrderEntity? get currentOrder => _currentOrder;

  // ========== MÉTODOS DE USUARIO ==========
  Future<void> loadUserOrders(String userId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _userOrders = await _orderService.getOrdersByUser(userId);
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Error cargando pedidos: $e';
      _userOrders = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== MÉTODOS DE NEGOCIO ==========
  Future<void> loadBusinessOrders(String businessId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Primero obtener todos los pedidos
      _allOrders = await _orderService.getAllOrders();
      // Filtrar por negocio
      _businessOrders = _allOrders.where((order) => order.businessId == businessId).toList();
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Error cargando pedidos del negocio: $e';
      _businessOrders = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== MÉTODOS DE ADMIN ==========
  Future<void> loadAllOrders() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _allOrders = await _orderService.getAllOrders();
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Error cargando todos los pedidos: $e';
      _allOrders = [];
    } finally {
      _isLoading = false;
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

      _successMessage = 'Pedido creado exitosamente';
      return true;
    } catch (e) {
      _errorMessage = 'Error creando pedido: $e';
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
      await _orderService.updateOrderStatus(orderId, status);

      if (rejectionReason != null) {
        // Aquí podrías actualizar también el motivo de rechazo
      }

      _successMessage = 'Estado del pedido actualizado';
      return true;
    } catch (e) {
      _errorMessage = 'Error actualizando pedido: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== ESTADÍSTICAS ==========
  Map<String, dynamic> getUserOrderStats(String userId) {
    final userOrders = _userOrders.where((order) => order.userId == userId).toList();

    return {
      'totalOrders': userOrders.length,
      'pendingOrders': userOrders.where((o) => o.isPending).length,
      'completedOrders': userOrders.where((o) => o.isDelivered).length,
      'cancelledOrders': userOrders.where((o) => o.isCancelled).length,
      'totalSpent': userOrders.fold(0.0, (sum, order) => sum + order.totalAmount),
    };
  }

  Map<String, dynamic> getBusinessOrderStats(String businessId) {
    final businessOrders = _businessOrders.where((order) => order.businessId == businessId).toList();

    return {
      'totalOrders': businessOrders.length,
      'pendingOrders': businessOrders.where((o) => o.isPending).length,
      'confirmedOrders': businessOrders.where((o) => o.isConfirmed).length,
      'preparingOrders': businessOrders.where((o) => o.isPreparing).length,
      'readyOrders': businessOrders.where((o) => o.isReady).length,
      'deliveredOrders': businessOrders.where((o) => o.isDelivered).length,
      'cancelledOrders': businessOrders.where((o) => o.isCancelled).length,
      'totalRevenue': businessOrders.fold(0.0, (sum, order) => sum + order.totalAmount),
    };
  }

  void clearMessages() {
    _errorMessage = '';
    _successMessage = '';
    notifyListeners();
  }
}