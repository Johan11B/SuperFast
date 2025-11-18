// lib/domain/entities/business_entity.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessEntity {
  final String id;
  final String ownerId;
  final String name;
  final String email;
  final String category;
  final String address;
  final String phone;
  final String? description;
  final String status; // pending, approved, suspended, rejected
  final double rating;
  final int reviewCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? approvedAt;
  final DateTime? suspendedAt;
  final DateTime? rejectedAt;
  final String? logoUrl; // ✅ NUEVO CAMPO AGREGADO

  const BusinessEntity({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.email,
    required this.category,
    required this.address,
    required this.phone,
    this.description,
    required this.status,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.approvedAt,
    this.suspendedAt,
    this.rejectedAt,
    this.logoUrl, // ✅ AGREGADO AL CONSTRUCTOR
  });

  // ✅ PROPIEDADES COMPUTADAS PARA ESTADO
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isSuspended => status == 'suspended';
  bool get isRejected => status == 'rejected';
  bool get isActive => isApproved; // Solo las aprobadas están activas

  // ✅ COLORES SEGÚN ESTADO
  Color get statusColor {
    switch (status) {
      case 'approved': return Colors.green;
      case 'pending': return Colors.orange;
      case 'suspended': return Colors.red;
      case 'rejected': return Colors.grey;
      default: return Colors.grey;
    }
  }

  // ✅ TEXTO LEGIBLE DEL ESTADO
  String get statusDisplayText {
    switch (status) {
      case 'approved': return 'Aprobada';
      case 'pending': return 'Pendiente';
      case 'suspended': return 'Suspendida';
      case 'rejected': return 'Rechazada';
      default: return status;
    }
  }

  // Convertir desde Map
  factory BusinessEntity.fromMap(Map<String, dynamic> map) {
    return BusinessEntity(
      id: map['id'] ?? '',
      ownerId: map['userId'] ?? map['ownerId'] ?? '',
      name: map['businessName'] ?? map['name'] ?? '', // ✅ SOPORTA AMBOS NOMBRES
      email: map['userEmail'] ?? map['email'] ?? '', // ✅ SOPORTA AMBOS NOMBRES
      category: map['category'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      description: map['description'],
      status: map['status'] ?? 'pending',
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: (map['reviewCount'] ?? 0).toInt(),
      logoUrl: map['logoUrl'] ?? map['logo_url'], // ✅ SOPORTA AMBOS NOMBRES
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'].toString()))
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['updatedAt'].toString()))
          : null,
      approvedAt: map['approvedAt'] != null
          ? (map['approvedAt'] is Timestamp
          ? (map['approvedAt'] as Timestamp).toDate()
          : DateTime.parse(map['approvedAt'].toString()))
          : null,
      suspendedAt: map['suspendedAt'] != null
          ? (map['suspendedAt'] is Timestamp
          ? (map['suspendedAt'] as Timestamp).toDate()
          : DateTime.parse(map['suspendedAt'].toString()))
          : null,
      rejectedAt: map['rejectedAt'] != null
          ? (map['rejectedAt'] is Timestamp
          ? (map['rejectedAt'] as Timestamp).toDate()
          : DateTime.parse(map['rejectedAt'].toString()))
          : null,
    );
  }

  // Convertir a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': ownerId,
      'businessName': name,
      'userEmail': email,
      'category': category,
      'address': address,
      'phone': phone,
      'description': description,
      'status': status,
      'rating': rating,
      'reviewCount': reviewCount,
      'logoUrl': logoUrl, // ✅ AGREGADO
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'approvedAt': approvedAt?.millisecondsSinceEpoch,
      'suspendedAt': suspendedAt?.millisecondsSinceEpoch,
      'rejectedAt': rejectedAt?.millisecondsSinceEpoch,
    };
  }

  // ✅ MÉTODO COPYWITH PARA ACTUALIZACIONES
  BusinessEntity copyWith({
    String? name,
    String? description,
    String? category,
    String? address,
    String? phone,
    String? logoUrl,
  }) {
    return BusinessEntity(
      id: id,
      ownerId: ownerId,
      name: name ?? this.name,
      email: email,
      category: category ?? this.category,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      description: description ?? this.description,
      status: status,
      rating: rating,
      reviewCount: reviewCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      approvedAt: approvedAt,
      suspendedAt: suspendedAt,
      rejectedAt: rejectedAt,
      logoUrl: logoUrl ?? this.logoUrl,
    );
  }

  @override
  String toString() {
    return 'BusinessEntity(id: $id, name: $name, status: $status, logoUrl: $logoUrl)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BusinessEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}