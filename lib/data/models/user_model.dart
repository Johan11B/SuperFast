import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    required String id,
    required String email,
    String? name,
    String? photoUrl,
  }) : super(id: id, email: email, name: name, photoUrl: photoUrl);

  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      name: user.displayName,
      photoUrl: user.photoURL,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      photoUrl: json['photoUrl'],
    );
  }
}