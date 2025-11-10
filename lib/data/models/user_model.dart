import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    required String id,
    required String email,
    String? name,
    String? photoUrl,
    required String role, // ✅ AGREGAR
  }) : super(id: id, email: email, name: name, photoUrl: photoUrl, role: role);

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

  // ✅ NUEVO MÉTODO
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    String? role,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'role': role, // ✅ INCLUIR
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      photoUrl: json['photoUrl'],
      role: json['role'] ?? 'user', // ✅ OBTENER
    );
  }
}