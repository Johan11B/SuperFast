// lib/core/services/order_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/order_entity.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Crear un nuevo pedido
  Future<void> createOrder({
    required String orderId,
    required String userId,
    required String businessId,
    required String userName,
    required String businessName,
    required double totalAmount,
    required double subtotal,
    required double deliveryFee,
    required double tax,
    required List<OrderItem> items,
    String? userNote,
    String? deliveryAddress,
    String? paymentMethod,
  }) async {
    try {
      print('🛒 Creando pedido: $orderId');

      // Convertir items a formato Firestore
      final itemsData = items.map((item) => {
        'productId': item.productId,
        'productName': item.productName,
        'quantity': item.quantity,
        'price': item.price,
        'notes': item.notes,
        'modifications': item.modifications,
      }).toList();

      await _firestore.collection('orders').doc(orderId).set({
        'userId': userId,
        'businessId': businessId,
        'userName': userName,
        'businessName': businessName,
        'status': 'pending',
        'totalAmount': totalAmount,
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'tax': tax,
        'items': itemsData,
        'userNote': userNote,
        'deliveryAddress': deliveryAddress,
        'paymentMethod': paymentMethod,
        'paymentStatus': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Pedido creado exitosamente: $orderId');
    } catch (e) {
      print('❌ Error creando pedido: $e');
      rethrow;
    }
  }

  // Obtener todos los pedidos
  Future<List<OrderEntity>> getAllOrders() async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return _documentToOrder(doc.id, data);
      }).toList();
    } catch (e) {
      print('❌ Error obteniendo pedidos: $e');
      return [];
    }
  }

  // Obtener pedidos por estado
  Future<List<OrderEntity>> getOrdersByStatus(String status) async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return _documentToOrder(doc.id, data);
      }).toList();
    } catch (e) {
      print('❌ Error obteniendo pedidos por estado: $e');
      return [];
    }
  }

  // Obtener pedidos por usuario
  Future<List<OrderEntity>> getOrdersByUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return _documentToOrder(doc.id, data);
      }).toList();
    } catch (e) {
      print('❌ Error obteniendo pedidos por usuario: $e');
      return [];
    }
  }

  // Actualizar estado de un pedido
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      if (!['pending', 'confirmed', 'preparing', 'ready', 'delivered', 'cancelled'].contains(status)) {
        throw ArgumentError('Estado inválido: $status');
      }

      final updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Si se marca como entregado, agregar timestamp de entrega
      if (status == 'delivered') {
        updateData['deliveredAt'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('orders').doc(orderId).update(updateData);

      print('✅ Estado del pedido $orderId actualizado a: $status');
    } catch (e) {
      print('❌ Error actualizando estado del pedido: $e');
      rethrow;
    }
  }

  // Actualizar estado de pago
  Future<void> updatePaymentStatus(String orderId, String paymentStatus) async {
    try {
      if (!['pending', 'paid', 'failed', 'refunded'].contains(paymentStatus)) {
        throw ArgumentError('Estado de pago inválido: $paymentStatus');
      }

      await _firestore.collection('orders').doc(orderId).update({
        'paymentStatus': paymentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Estado de pago del pedido $orderId actualizado a: $paymentStatus');
    } catch (e) {
      print('❌ Error actualizando estado de pago: $e');
      rethrow;
    }
  }
  // 🔹 Obtener pedidos por negocio
  Future<List<OrderEntity>> getOrdersByBusiness(String businessId) async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .where('businessId', isEqualTo: businessId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return _documentToOrder(doc.id, data);
      }).toList();
    } catch (e) {
      print('❌ Error obteniendo pedidos por negocio: $e');
      return [];
    }
  }

  // 🔹 Obtener pedidos por estado y negocio
  Future<List<OrderEntity>> getBusinessOrdersByStatus(String businessId, String status) async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .where('businessId', isEqualTo: businessId)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return _documentToOrder(doc.id, data);
      }).toList();
    } catch (e) {
      print('❌ Error obteniendo pedidos por estado: $e');
      return [];
    }
  }

  // 🔹 Agregar nota al pedido
  Future<void> addOrderNote(String orderId, String note) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'orderNotes': FieldValue.arrayUnion([note]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error agregando nota al pedido: $e');
      rethrow;
    }
  }

  // 🔹 Obtener estadísticas de pedidos
  Future<Map<String, dynamic>> getOrderStats(String businessId) async {
    try {
      final orders = await getOrdersByBusiness(businessId);

      return {
        'total': orders.length,
        'pending': orders.where((o) => o.isPending).length,
        'confirmed': orders.where((o) => o.isConfirmed).length,
        'preparing': orders.where((o) => o.isPreparing).length,
        'ready': orders.where((o) => o.isReady).length,
        'delivered': orders.where((o) => o.isDelivered).length,
        'cancelled': orders.where((o) => o.isCancelled).length,
        'totalRevenue': orders.fold(0.0, (sum, order) => sum + order.totalAmount),
      };
    } catch (e) {
      print('❌ Error obteniendo estadísticas: $e');
      return {};
    }
  }
  // Método auxiliar para convertir documento a OrderEntity
  OrderEntity _documentToOrder(String id, Map<String, dynamic> data) {
    // Convertir items
    final List<OrderItem> items = [];
    final itemsData = data['items'] as List<dynamic>? ?? [];
    for (var item in itemsData) {
      items.add(OrderItem(
        productId: item['productId'] ?? '',
        productName: item['productName'] ?? '',
        quantity: (item['quantity'] ?? 1).toInt(),
        price: (item['price'] ?? 0.0).toDouble(),
        notes: item['notes'],
        modifications: (item['modifications'] as List<dynamic>?)?.cast<String>(),
      ));
    }

    return OrderEntity(
      id: id,
      userId: data['userId'] ?? '',
      businessId: data['businessId'] ?? '',
      userName: data['userName'] ?? 'Cliente',
      businessName: data['businessName'] ?? 'Negocio',
      status: data['status'] ?? 'pending',
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      subtotal: (data['subtotal'] ?? 0.0).toDouble(),
      deliveryFee: (data['deliveryFee'] ?? 0.0).toDouble(),
      tax: (data['tax'] ?? 0.0).toDouble(),
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate(),
      deliveredAt: data['deliveredAt']?.toDate(),
      items: items,
      userNote: data['userNote'],
      deliveryAddress: data['deliveryAddress'],
      paymentMethod: data['paymentMethod'],
      paymentStatus: data['paymentStatus'] ?? 'pending',
      rating: data['rating']?.toDouble(),
      review: data['review'],
    );
  }
}