// lib/domain/entities/user_entity.dart (ACTUALIZADO)
class UserEntity {
  final String id;
  final String email;
  final String? name;
  final String? photoUrl;
  final String role;

  UserEntity({
    required this.id,
    required this.email,
    this.name,
    this.photoUrl,
    required this.role,
  });

  // Método para convertir a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'role': role,
    };
  }

  // Factory constructor desde Map
  factory UserEntity.fromMap(Map<String, dynamic> map) {
    return UserEntity(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'],
      photoUrl: map['photoUrl'],
      role: map['role'] ?? 'user',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserEntity &&
        other.id == id &&
        other.email == email &&
        other.name == name &&
        other.photoUrl == photoUrl &&
        other.role == role;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    email.hashCode ^
    name.hashCode ^
    photoUrl.hashCode ^
    role.hashCode;
  }

  @override
  String toString() {
    return 'UserEntity(id: $id, email: $email, name: $name, role: $role)';
  }
}