// lib/presentation/viewmodels/auth_viewmodel.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../core/utils/performance_manager.dart';
import '../../core/services/role_service.dart';
import '../screens/auth/login_page.dart';
import '../screens/admin/admin_panel.dart';
import '../screens/business/business_panel.dart';
import '../screens/user/user_dashboard.dart';

class AuthViewModel with ChangeNotifier {
  final IAuthRepository authRepository;
  final RoleService roleService;

  AuthViewModel({
    required this.authRepository,
    required this.roleService,
  });

  UserEntity? _currentUser;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isLoggingOut = false;
  StreamSubscription<UserEntity?>? _authSubscription;

  UserEntity? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoggingOut => _isLoggingOut;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setErrorMessage(String value) {
    _errorMessage = value;
    notifyListeners();
  }

  void setLoggingOut(bool value) {
    _isLoggingOut = value;
    notifyListeners();
  }

  Widget getHomeScreenByRole() {
    if (_currentUser == null) {
      return const LoginPage();
    }

    switch (_currentUser!.role) {
      case 'admin':
        return const AdminPanel();
      case 'business':
        return const BusinessPanel();
      case 'user':
        return const UserDashboard();
      default:
        return const UserDashboard();
    }
  }

  bool canAccess(String feature) {
    if (_currentUser == null) return false;

    final permissions = {
      'admin': ['all'],
      'business': ['manage_products', 'view_orders', 'analytics'],
      'user': ['place_orders', 'view_history', 'rate_products'],
    };

    final userPermissions = permissions[_currentUser!.role] ?? [];
    return userPermissions.contains('all') || userPermissions.contains(feature);
  }

  Future<bool> login(String email, String password) async {
    return await PerformanceManager.measure(
      'Complete Login Process',
          () async {
        try {
          setLoading(true);
          setErrorMessage('');

          final user = await authRepository.signInWithEmail(email, password);

          if (user != null) {
            _currentUser = user;
            setLoading(false);
            return true;
          } else {
            setErrorMessage('Error al iniciar sesión. Verifica tus credenciales.');
            setLoading(false);
            return false;
          }
        } on FirebaseAuthException catch (e) {
          // ✅ MEJORADO: Manejo específico de errores de Firebase
          String errorMessage;
          switch (e.code) {
            case 'invalid-credential':
            case 'wrong-password':
            case 'user-not-found':
              errorMessage = 'Credenciales incorrectas. Verifica tu email y contraseña.';
              break;
            case 'user-disabled':
              errorMessage = 'Esta cuenta ha sido deshabilitada. Contacta al soporte.';
              break;
            case 'too-many-requests':
              errorMessage = 'Demasiados intentos fallidos. Espera un momento e inténtalo de nuevo.';
              break;
            case 'network-request-failed':
              errorMessage = 'Error de conexión. Verifica tu internet e inténtalo de nuevo.';
              break;
            case 'invalid-email':
              errorMessage = 'El formato del email es inválido. Verifícalo.';
              break;
            default:
              errorMessage = 'Error al iniciar sesión: ${e.message}';
          }
          setErrorMessage(errorMessage);
          setLoading(false);
          return false;
        } catch (e) {
          setErrorMessage('Error inesperado al iniciar sesión. Inténtalo de nuevo.');
          setLoading(false);
          return false;
        }
      },
    );
  }

  Future<bool> register(String email, String password, String name) async {
    return await PerformanceManager.measure(
      'Complete Registration Process',
          () async {
        try {
          setLoading(true);
          setErrorMessage('');

          final user = await authRepository.signUpWithEmail(email, password, name);

          if (user != null) {
            _currentUser = user;
            setLoading(false);
            return true;
          } else {
            setErrorMessage('Error al registrar usuario.');
            setLoading(false);
            return false;
          }
        } on FirebaseAuthException catch (e) {
          // ✅ MEJORADO: Manejo específico de errores de registro
          String errorMessage;
          switch (e.code) {
            case 'email-already-in-use':
              errorMessage = 'Este email ya está registrado. Inicia sesión o usa otro email.';
              break;
            case 'weak-password':
              errorMessage = 'La contraseña es muy débil. Usa al menos 6 caracteres.';
              break;
            case 'invalid-email':
              errorMessage = 'El formato del email es inválido. Verifícalo.';
              break;
            default:
              errorMessage = 'Error al registrar: ${e.message}';
          }
          setErrorMessage(errorMessage);
          setLoading(false);
          return false;
        } catch (e) {
          setErrorMessage('Error inesperado al registrar. Inténtalo de nuevo.');
          setLoading(false);
          return false;
        }
      },
    );
  }

  Future<bool> loginWithGoogle() async {
    return await PerformanceManager.measure(
      'Complete Google Sign-In Process',
          () async {
        try {
          setLoading(true);
          setErrorMessage('');

          final user = await authRepository.signInWithGoogle();

          if (user != null) {
            _currentUser = user;
            setLoading(false);
            return true;
          } else {
            setErrorMessage('Error al iniciar sesión con Google.');
            setLoading(false);
            return false;
          }
        } on FirebaseAuthException catch (e) {
          String errorMessage;
          switch (e.code) {
            case 'account-exists-with-different-credential':
              errorMessage = 'Ya existe una cuenta con este email usando otro método de inicio de sesión.';
              break;
            case 'network-request-failed':
              errorMessage = 'Error de conexión. Verifica tu internet e inténtalo de nuevo.';
              break;
            default:
              errorMessage = 'Error Google Sign-In: ${e.message}';
          }
          setErrorMessage(errorMessage);
          setLoading(false);
          return false;
        } catch (e) {
          setErrorMessage('Error inesperado con Google Sign-In. Inténtalo de nuevo.');
          setLoading(false);
          return false;
        }
      },
    );
  }

  Future<void> logout() async {
    return await PerformanceManager.measure(
      'Complete Logout Process',
          () async {
        try {
          setLoggingOut(true);
          setLoading(true);

          await authRepository.signOut();

          _currentUser = null;
          setLoading(false);
          setLoggingOut(false);
        } catch (e) {
          setErrorMessage('Error al cerrar sesión: $e');
          setLoading(false);
          setLoggingOut(false);
          rethrow;
        }
      },
    );
  }

  Future<bool> resetPassword(String email) async {
    return await PerformanceManager.measure(
      'Complete Password Reset Process',
          () async {
        try {
          setLoading(true);
          setErrorMessage('');

          await authRepository.resetPassword(email);
          setLoading(false);
          return true;
        } on FirebaseAuthException catch (e) {
          String errorMessage;
          switch (e.code) {
            case 'user-not-found':
              errorMessage = 'No existe una cuenta con este email.';
              break;
            case 'invalid-email':
              errorMessage = 'El formato del email es inválido.';
              break;
            default:
              errorMessage = 'Error al resetear password: ${e.message}';
          }
          setErrorMessage(errorMessage);
          setLoading(false);
          return false;
        } catch (e) {
          setErrorMessage('Error inesperado al resetear password.');
          setLoading(false);
          return false;
        }
      },
    );
  }

  void clearError() {
    setErrorMessage('');
  }

  void initializeAuthListener() {
    if (_authSubscription != null) return;

    _authSubscription = authRepository.authStateChanges.listen(
          (UserEntity? user) {
        debugPrint('🔄 AuthListener - Usuario recibido: ${user?.email}');

        // Si estamos en proceso de logout, ignorar cambios temporales
        if (_isLoggingOut && user != null) {
          debugPrint('🔄 AuthListener - Ignorando usuario durante logout');
          return;
        }

        _currentUser = user;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('❌ Error en auth listener: $error');
        setErrorMessage('Error en autenticación: $error');
      },
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}