// lib/data/models/user_model.dart
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    required String id,
    required String email,
    String? name,
    String? photoUrl,
    required String role,
    // ✅ AGREGAR CAMPOS DE NEGOCIO
    String? businessName,
    String? businessEmail,
    String? businessCategory,
    String? businessAddress,
    String? businessPhone,
  }) : super(
    id: id,
    email: email,
    name: name,
    photoUrl: photoUrl,
    role: role,
    businessName: businessName,
    businessEmail: businessEmail,
    businessCategory: businessCategory,
    businessAddress: businessAddress,
    businessPhone: businessPhone,
  );

  // ✅ ACTUALIZAR CONSTRUCTOR
  factory UserModel.fromFirebaseUser(User user, {String role = 'user'}) {
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      name: user.displayName,
      photoUrl: user.photoURL,
      role: role,
    );
  }

  // ✅ ACTUALIZAR copyWith CON CAMPOS DE NEGOCIO
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    String? role,
    String? businessName,
    String? businessEmail,
    String? businessCategory,
    String? businessAddress,
    String? businessPhone,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      businessName: businessName ?? this.businessName,
      businessEmail: businessEmail ?? this.businessEmail,
      businessCategory: businessCategory ?? this.businessCategory,
      businessAddress: businessAddress ?? this.businessAddress,
      businessPhone: businessPhone ?? this.businessPhone,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'role': role,
      'businessName': businessName,
      'businessEmail': businessEmail,
      'businessCategory': businessCategory,
      'businessAddress': businessAddress,
      'businessPhone': businessPhone,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      photoUrl: json['photoUrl'],
      role: json['role'] ?? 'user',
      businessName: json['businessName'],
      businessEmail: json['businessEmail'],
      businessCategory: json['businessCategory'],
      businessAddress: json['businessAddress'],
      businessPhone: json['businessPhone'],
    );
  }
}