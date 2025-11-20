// lib/domain/entities/order_entity.dart
import 'package:flutter/material.dart';

class OrderEntity {
  final String id;
  final String userId;
  final String businessId;
  final String userName;
  final String businessName;
  final String status; // pending, confirmed, preparing, ready, delivered, cancelled
  final double totalAmount;
  final double subtotal;
  final double deliveryFee;
  final double tax;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deliveredAt;
  final List<OrderItem> items;
  final String? userNote;
  final String? deliveryAddress;
  final String? paymentMethod;
  final String? paymentStatus; // pending, paid, failed, refunded
  final double? rating;
  final String? review;
  final String? businessLogoUrl;
  final String? userPhone;
  final List<String>? orderNotes; // Notas del negocio sobre el pedido
  final double? preparationTime; // Tiempo estimado en minutos
  final String? rejectionReason; // Motivo de rechazo si aplica


  OrderEntity({
    required this.id,
    required this.userId,
    required this.businessId,
    required this.userName,
    required this.businessName,
    required this.status,
    required this.totalAmount,
    required this.subtotal,
    required this.deliveryFee,
    required this.tax,
    required this.createdAt,
    this.updatedAt,
    this.deliveredAt,
    required this.items,
    this.userNote,
    this.deliveryAddress,
    this.paymentMethod,
    this.paymentStatus,
    this.rating,
    this.review,
    this.businessLogoUrl,
    this.userPhone,
    this.orderNotes,
    this.preparationTime,
    this.rejectionReason,
  });

  // ✅ AGREGAR ESTE MÉTODO copyWith
  OrderEntity copyWith({
    String? id,
    String? userId,
    String? businessId,
    String? userName,
    String? businessName,
    String? status,
    double? totalAmount,
    double? subtotal,
    double? deliveryFee,
    double? tax,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deliveredAt,
    List<OrderItem>? items,
    String? userNote,
    String? deliveryAddress,
    String? paymentMethod,
    String? paymentStatus,
    double? rating,
    String? review,
    String? businessLogoUrl,
    String? userPhone,
    List<String>? orderNotes,
    double? preparationTime,
    String? rejectionReason,
  }) {
    return OrderEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessId: businessId ?? this.businessId,
      userName: userName ?? this.userName,
      businessName: businessName ?? this.businessName,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      tax: tax ?? this.tax,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      items: items ?? this.items,
      userNote: userNote ?? this.userNote,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      businessLogoUrl: businessLogoUrl ?? this.businessLogoUrl,
      userPhone: userPhone ?? this.userPhone,
      orderNotes: orderNotes ?? this.orderNotes,
      preparationTime: preparationTime ?? this.preparationTime,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OrderEntity &&
        other.id == id &&
        other.userId == userId &&
        other.businessId == businessId &&
        other.status == status &&
        other.totalAmount == totalAmount;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    userId.hashCode ^
    businessId.hashCode ^
    status.hashCode ^
    totalAmount.hashCode;
  }

  @override
  String toString() {
    return 'OrderEntity(id: $id, status: $status, total: \$$totalAmount, user: $userName)';
  }

  // ✅ AGREGAR ESTOS GETTERS QUE FALTABAN
  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isPreparing => status == 'preparing';
  bool get isReady => status == 'ready';
  bool get isDelivered => status == 'delivered'; // ✅ ESTE FALTABA
  bool get isCancelled => status == 'cancelled';

  bool get isActive => !isDelivered && !isCancelled; // ✅ ESTE FALTABA

  String get statusDisplayText {
    switch (status) {
      case 'pending': return 'Pendiente';
      case 'confirmed': return 'Confirmado';
      case 'preparing': return 'En preparación';
      case 'ready': return 'Listo';
      case 'delivered': return 'Entregado';
      case 'cancelled': return 'Cancelado';
      default: return 'Desconocido';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'preparing': return Colors.purple;
      case 'ready': return Colors.green;
      case 'delivered': return Colors.teal;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String get formattedCreatedAt {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  Duration get processingTime {
    if (deliveredAt != null) {
      return deliveredAt!.difference(createdAt);
    }
    return DateTime.now().difference(createdAt);
  }

  String get processingTimeText {
    final duration = processingTime;
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes} min';
    } else if (duration.inHours < 24) {
      return '${duration.inHours} h ${duration.inMinutes.remainder(60)} min';
    } else {
      return '${duration.inDays} días';
    }
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final String? notes;
  final List<String>? modifications;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    this.notes,
    this.modifications,
  });

  double get totalPrice => price * quantity;

  // ✅ AGREGAR copyWith PARA OrderItem TAMBIÉN
  OrderItem copyWith({
    String? productId,
    String? productName,
    int? quantity,
    double? price,
    String? notes,
    List<String>? modifications,
  }) {
    return OrderItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      notes: notes ?? this.notes,
      modifications: modifications ?? this.modifications,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OrderItem &&
        other.productId == productId &&
        other.productName == productName &&
        other.quantity == quantity &&
        other.price == price;
  }

  @override
  int get hashCode {
    return productId.hashCode ^
    productName.hashCode ^
    quantity.hashCode ^
    price.hashCode;
  }
}