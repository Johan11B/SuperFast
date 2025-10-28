class UserEntity {
  final String id;
  final String email;
  final String? name;
  final String? photoUrl;

  UserEntity({
    required this.id,
    required this.email,
    this.name,
    this.photoUrl,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserEntity &&
        other.id == id &&
        other.email == email &&
        other.name == name &&
        other.photoUrl == photoUrl;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    email.hashCode ^
    name.hashCode ^
    photoUrl.hashCode;
  }
}