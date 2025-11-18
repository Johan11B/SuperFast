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
  final String? logoUrl;

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
    this.logoUrl,
  });

  // ✅ PROPIEDADES COMPUTADAS PARA ESTADO
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isSuspended => status == 'suspended';
  bool get isRejected => status == 'rejected';
  bool get isActive => isApproved;

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

    return BusinessEntity(
      id: map['id'] ?? '',
      ownerId: map['userId'] ?? map['ownerId'] ?? '',
      name: map['businessName'] ?? map['name'] ?? '',
      email: map['userEmail'] ?? map['email'] ?? '',
      category: map['category'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      description: map['description'],
      status: map['status'] ?? 'pending',
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: (map['reviewCount'] ?? 0).toInt(),
      logoUrl: map['logoUrl'] ?? map['logo_url'],
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? _parseDateTime(map['updatedAt']) : null,
      approvedAt: map['approvedAt'] != null ? _parseDateTime(map['approvedAt']) : null,
      suspendedAt: map['suspendedAt'] != null ? _parseDateTime(map['suspendedAt']) : null,
      rejectedAt: map['rejectedAt'] != null ? _parseDateTime(map['rejectedAt']) : null,
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
      'logoUrl': logoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'suspendedAt': suspendedAt != null ? Timestamp.fromDate(suspendedAt!) : null,
      'rejectedAt': rejectedAt != null ? Timestamp.fromDate(rejectedAt!) : null,
    };
  }

  // ✅ MÉTODO COPYWITH COMPLETO
  BusinessEntity copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? email,
    String? category,
    String? address,
    String? phone,
    String? description,
    String? status,
    double? rating,
    int? reviewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? approvedAt,
    DateTime? suspendedAt,
    DateTime? rejectedAt,
    String? logoUrl,
  }) {
    return BusinessEntity(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      email: email ?? this.email,
      category: category ?? this.category,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      description: description ?? this.description,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      suspendedAt: suspendedAt ?? this.suspendedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
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