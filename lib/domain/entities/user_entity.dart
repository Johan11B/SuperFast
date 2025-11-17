// lib/domain/entities/user_entity.dart
class UserEntity {
  final String id;
  final String email;
  final String? name;
  final String? photoUrl;
  final String role;

  // ✅ NUEVOS CAMPOS: Información de empresa
  final String? businessName;
  final String? businessEmail;
  final String? businessCategory;
  final String? businessAddress;
  final String? businessPhone;

  const UserEntity({
    required this.id,
    required this.email,
    this.name,
    this.photoUrl,
    required this.role,
    // ✅ AGREGAR al constructor
    this.businessName,
    this.businessEmail,
    this.businessCategory,
    this.businessAddress,
    this.businessPhone,
  });

  // ✅ MÉTODO PARA OBTENER EL NOMBRE A MOSTRAR
  String get displayName {
    if (role == 'business' && businessName != null && businessName!.isNotEmpty) {
      return businessName!;
    }
    return name ?? email.split('@')[0];
  }

  // ✅ MÉTODO PARA OBTENER EL EMAIL A MOSTRAR
  String get displayEmail {
    if (role == 'business' && businessEmail != null && businessEmail!.isNotEmpty) {
      return businessEmail!;
    }
    return email;
  }

  // ✅ VERIFICAR SI TIENE INFORMACIÓN DE EMPRESA
  bool get hasBusinessInfo {
    return businessName != null && businessName!.isNotEmpty;
  }

  @override
  String toString() {
    return 'UserEntity(id: $id, email: $email, role: $role, businessName: $businessName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserEntity && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}