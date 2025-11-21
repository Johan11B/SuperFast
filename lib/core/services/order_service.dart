// order_service.dart - VERSIÓN COMPLETA CON ACTUALIZACIÓN DE STOCK
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
      print('🏢 Negocio: $businessName (ID: $businessId)');
      print('👤 Usuario: $userName (ID: $userId)');

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
      print('📊 Detalles: $businessName - \$$totalAmount');
    } catch (e) {
      print('❌ Error creando pedido: $e');
      rethrow;
    }
  }

  // 🔄 ACTUALIZAR STOCK CUANDO EL PEDIDO ES CONFIRMADO
  Future<void> updateProductStockOnOrder(String orderId) async {
    try {
      print('🔄 Actualizando stock para pedido: $orderId');

      // Obtener el pedido
      final order = await getOrderById(orderId);
      if (order == null) {
        throw Exception('Pedido no encontrado: $orderId');
      }

      // Para cada item en el pedido, reducir el stock
      for (final item in order.items) {
        print('📦 Actualizando stock para producto: ${item.productName} (ID: ${item.productId})');

        // Buscar el producto en la colección de productos
        final productQuery = await _firestore
            .collection('products')
            .where('id', isEqualTo: item.productId)
            .limit(1)
            .get();

        if (productQuery.docs.isNotEmpty) {
          final productDoc = productQuery.docs.first;
          final productData = productDoc.data();
          final currentStock = productData['stock'] ?? 0;
          final newStock = currentStock - item.quantity;

          if (newStock < 0) {
            print('⚠️ Stock insuficiente para ${item.productName}. Stock actual: $currentStock, solicitado: ${item.quantity}');
            throw Exception('Stock insuficiente para ${item.productName}');
          }

          // Actualizar el stock del producto
          await productDoc.reference.update({
            'stock': newStock,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          print('✅ Stock actualizado: ${item.productName} - $currentStock -> $newStock');
        } else {
          print('⚠️ Producto no encontrado: ${item.productId}');
          throw Exception('Producto no encontrado: ${item.productId}');
        }
      }

      print('✅ Stock actualizado exitosamente para pedido: $orderId');
    } catch (e) {
      print('❌ Error actualizando stock: $e');
      rethrow;
    }
  }

  // 🔄 REVERTIR STOCK CUANDO SE CANCELA UN PEDIDO CONFIRMADO
  Future<void> revertProductStockOnCancellation(String orderId) async {
    try {
      print('🔄 Revirtiendo stock para pedido cancelado: $orderId');

      final order = await getOrderById(orderId);
      if (order == null) {
        print('⚠️ Pedido no encontrado para revertir stock: $orderId');
        return;
      }

      for (final item in order.items) {
        print('📦 Revirtiendo stock para producto: ${item.productName}');

        final productQuery = await _firestore
            .collection('products')
            .where('id', isEqualTo: item.productId)
            .limit(1)
            .get();

        if (productQuery.docs.isNotEmpty) {
          final productDoc = productQuery.docs.first;
          final productData = productDoc.data();
          final currentStock = productData['stock'] ?? 0;
          final newStock = currentStock + item.quantity;

          await productDoc.reference.update({
            'stock': newStock,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          print('✅ Stock revertido: ${item.productName} - $currentStock -> $newStock');
        } else {
          print('⚠️ Producto no encontrado al revertir stock: ${item.productId}');
        }
      }

      print('✅ Stock revertido exitosamente para pedido cancelado: $orderId');
    } catch (e) {
      print('❌ Error revirtiendo stock: $e');
      rethrow;
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

  // Obtener todos los pedidos
  Future<List<OrderEntity>> getAllOrders() async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .get();

      final orders = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return _documentToOrder(doc.id, data);
      }).toList();

      print('✅ ${orders.length} pedidos totales cargados');
      return orders;
    } catch (e) {
      print('❌ Error obteniendo pedidos: $e');
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

      final orders = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return _documentToOrder(doc.id, data);
      }).toList();

      print('✅ ${orders.length} pedidos del usuario $userId cargados');
      return orders;
    } catch (e) {
      print('❌ Error obteniendo pedidos por usuario: $e');
      return [];
    }
  }

  // Obtener pedidos por negocio
  Future<List<OrderEntity>> getOrdersByBusiness(String businessId) async {
    try {
      print('🔄 Buscando pedidos para negocio: $businessId');

      final querySnapshot = await _firestore
          .collection('orders')
          .where('businessId', isEqualTo: businessId)
          .orderBy('createdAt', descending: true)
          .get();

      final orders = querySnapshot.docs.map((doc) {
        final data = doc.data();
        final order = _documentToOrder(doc.id, data);
        print('   📦 Pedido encontrado: ${order.id} | Negocio: ${order.businessId} | Estado: ${order.status}');
        return order;
      }).toList();

      print('✅ ${orders.length} pedidos del negocio $businessId cargados');
      return orders;
    } catch (e) {
      print('❌ Error obteniendo pedidos por negocio: $e');
      return [];
    }
  }

  // Obtener pedido por ID
  Future<OrderEntity?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();

      if (doc.exists) {
        return _documentToOrder(doc.id, doc.data()!);
      }
      print('⚠️ Pedido no encontrado: $orderId');
      return null;
    } catch (e) {
      print('❌ Error obteniendo pedido por ID: $e');
      return null;
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

  // Agregar nota al pedido
  Future<void> addOrderNote(String orderId, String note) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'orderNotes': FieldValue.arrayUnion([note]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Nota agregada al pedido $orderId');
    } catch (e) {
      print('❌ Error agregando nota al pedido: $e');
      rethrow;
    }
  }

  // Obtener estadísticas de pedidos para un negocio
  Future<Map<String, dynamic>> getBusinessOrderStats(String businessId) async {
    try {
      final orders = await getOrdersByBusiness(businessId);

      final totalRevenue = orders.fold(0.0, (sum, order) => sum + order.totalAmount);
      final averageOrderValue = orders.isNotEmpty ? totalRevenue / orders.length : 0;

      return {
        'totalOrders': orders.length,
        'pendingOrders': orders.where((o) => o.isPending).length,
        'confirmedOrders': orders.where((o) => o.isConfirmed).length,
        'preparingOrders': orders.where((o) => o.isPreparing).length,
        'readyOrders': orders.where((o) => o.isReady).length,
        'deliveredOrders': orders.where((o) => o.isDelivered).length,
        'cancelledOrders': orders.where((o) => o.isCancelled).length,
        'totalRevenue': totalRevenue,
        'averageOrderValue': averageOrderValue,
        'completionRate': orders.isNotEmpty
            ? (orders.where((o) => o.isDelivered).length / orders.length) * 100
            : 0,
      };
    } catch (e) {
      print('❌ Error obteniendo estadísticas de negocio: $e');
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

    // Helper function para convertir dynamic a DateTime
    DateTime _parseDateTime(dynamic date) {
      if (date == null) return DateTime.now();
      if (date is Timestamp) {
        return date.toDate();
      } else if (date is int) {
        return DateTime.fromMillisecondsSinceEpoch(date);
      } else if (date is String) {
        return DateTime.parse(date);
      } else {
        return DateTime.now();
      }
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
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: data['updatedAt'] != null ? _parseDateTime(data['updatedAt']) : null,
      deliveredAt: data['deliveredAt'] != null ? _parseDateTime(data['deliveredAt']) : null,
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