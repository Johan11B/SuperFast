// lib/domain/entities/auth_state.dart
import 'package:flutter/material.dart';
import 'user_entity.dart';

@immutable
class AuthState {
  final UserEntity? user;
  final bool isLoading;
  final String? error;
  final bool isLoggingOut;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isLoggingOut = false,
  });

  factory AuthState.unauthenticated() => const AuthState();

  factory AuthState.authenticated(UserEntity user) =>
      AuthState(user: user);

  factory AuthState.loading() => const AuthState(isLoading: true);

  factory AuthState.error(String error) => AuthState(error: error);

  factory AuthState.loggingOut() => const AuthState(isLoggingOut: true);

  bool get isAuthenticated => user != null;
  bool get hasError => error != null;

  AuthState copyWith({
    UserEntity? user,
    bool? isLoading,
    String? error,
    bool? isLoggingOut,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isLoggingOut: isLoggingOut ?? this.isLoggingOut,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AuthState &&
        runtimeType == other.runtimeType &&
        user?.id == other.user?.id &&
        isLoading == other.isLoading &&
        error == other.error &&
        isLoggingOut == other.isLoggingOut;
  }

  @override
  int get hashCode =>
      user!.id.hashCode ^
      isLoading.hashCode ^
      error.hashCode ^
      isLoggingOut.hashCode;

  @override
  String toString() {
    return 'AuthState{user: ${user?.email}, isLoading: $isLoading, error: $error, isLoggingOut: $isLoggingOut}';
  }
}