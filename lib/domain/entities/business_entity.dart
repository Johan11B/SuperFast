// lib/domain/entities/business_entity.dart
import 'package:flutter/material.dart';

class BusinessEntity {
  final String id;
  final String name;
  final String email;
  final String ownerId;
  final String status;
  final String category;
  final String address;
  final String? phone;
  final String? description;
  final String? imageUrl;
  final double? rating;
  final int reviewCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BusinessEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.ownerId,
    required this.status,
    required this.category,
    required this.address,
    this.phone,
    this.description,
    this.imageUrl,
    this.rating,
    this.reviewCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  // Getters para UI
  Color get statusColor {
    switch (status) {
      case 'approved': return Colors.green;
      case 'pending': return Colors.orange;
      case 'rejected': return Colors.red;
      case 'suspended': return Colors.grey;
      default: return Colors.grey;
    }
  }

  String get statusDisplayText {
    switch (status) {
      case 'approved': return 'APROBADO';
      case 'pending': return 'PENDIENTE';
      case 'rejected': return 'RECHAZADO';
      case 'suspended': return 'SUSPENDIDO';
      default: return status.toUpperCase();
    }
  }

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
  bool get isSuspended => status == 'suspended';

  // Factory constructor desde Map
  factory BusinessEntity.fromMap(Map<String, dynamic> map) {
    return BusinessEntity(
      id: map['id'] ?? '',
      name: map['businessName'] ?? map['name'] ?? 'Sin nombre',
      email: map['userEmail'] ?? map['email'] ?? 'Sin email',
      ownerId: map['userId'] ?? map['ownerId'] ?? '',
      status: map['status'] ?? 'pending',
      category: map['category'] ?? 'General',
      address: map['address'] ?? 'Sin dirección',
      phone: map['phone'],
      description: map['description'],
      imageUrl: map['imageUrl'],
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: (map['reviewCount'] ?? 0).toInt(),
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt']
          : (map['createdAt'] != null ? map['createdAt'].toDate() : DateTime.now()),
      updatedAt: map['updatedAt'] is DateTime
          ? map['updatedAt']
          : (map['updatedAt'] != null ? map['updatedAt'].toDate() : null),
    );
  }

  // Convertir a mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'ownerId': ownerId,
      'status': status,
      'category': category,
      'address': address,
      'phone': phone,
      'description': description,
      'imageUrl': imageUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  @override
  String toString() {
    return 'BusinessEntity(id: $id, name: $name, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BusinessEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}