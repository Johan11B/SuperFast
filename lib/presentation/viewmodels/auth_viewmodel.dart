import 'package:flutter/material.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';

class AuthViewModel with ChangeNotifier {
  final IAuthRepository authRepository;

  UserEntity? _currentUser;
  bool _isLoading = false;
  String _errorMessage = '';

  AuthViewModel({required this.authRepository});

  // Getters
  UserEntity? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  // Setters
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  set errorMessage(String value) {
    _errorMessage = value;
    notifyListeners();
  }

  // Methods
  Future<bool> login(String email, String password) async {
    try {
      isLoading = true;
      errorMessage = '';

      final user = await authRepository.signInWithEmail(email, password);

      if (user != null) {
        _currentUser = user;
        isLoading = false;
        return true;
      } else {
        errorMessage = 'Error al iniciar sesión. Verifica tus credenciales.';
        isLoading = false;
        return false;
      }
    } catch (e) {
      errorMessage = 'Error al iniciar sesión: $e';
      isLoading = false;
      return false;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    try {
      isLoading = true;
      errorMessage = '';

      final user = await authRepository.signUpWithEmail(email, password, name);

      if (user != null) {
        _currentUser = user;
        isLoading = false;
        return true;
      } else {
        errorMessage = 'Error al registrar usuario.';
        isLoading = false;
        return false;
      }
    } catch (e) {
      errorMessage = 'Error al registrar: $e';
      isLoading = false;
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    try {
      isLoading = true;
      errorMessage = '';

      final user = await authRepository.signInWithGoogle();

      if (user != null) {
        _currentUser = user;
        isLoading = false;
        return true;
      } else {
        errorMessage = 'Error al iniciar sesión con Google.';
        isLoading = false;
        return false;
      }
    } catch (e) {
      errorMessage = 'Error Google Sign-In: $e';
      isLoading = false;
      return false;
    }
  }

  Future<void> logout() async {
    try {
      isLoading = true;
      await authRepository.signOut();
      _currentUser = null;
      isLoading = false;
    } catch (e) {
      errorMessage = 'Error al cerrar sesión: $e';
      isLoading = false;
      rethrow;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      isLoading = true;
      errorMessage = '';

      await authRepository.resetPassword(email);
      isLoading = false;
      return true;
    } catch (e) {
      errorMessage = 'Error al resetear password: $e';
      isLoading = false;
      return false;
    }
  }

  void clearError() {
    errorMessage = '';
  }

  // Listen to auth state changes
  void initializeAuthListener() {
    authRepository.authStateChanges.listen((UserEntity? user) {
      _currentUser = user;
      notifyListeners();
    });
  }
}